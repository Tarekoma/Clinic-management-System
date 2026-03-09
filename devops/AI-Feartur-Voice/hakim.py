# app.py
import os
import tempfile
import shutil
from dotenv import load_dotenv
load_dotenv()
from datetime import date
from enum import Enum
from pydantic import ConfigDict
from typing import Annotated
import torch
from faster_whisper import WhisperModel
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.concurrency import run_in_threadpool
import psycopg2
from pydantic import BaseModel, Field, EmailStr
from typing import List

from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI

import psycopg
from typing import List, Dict, Tuple
import json
import os

def get_connection():
    """Get a single database connection."""
    conn = psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        dbname=os.getenv("DB_NAME"),
        client_encoding='utf8'
    )
    print("Connected to database")
    return conn

conn = get_connection()

# =========================
# إعداد FastAPI + CORS
# =========================
app = FastAPI(title="Intelligent Medical Assistant - ASR API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # عدّلها في الإنتاج
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# API KEY لسيرفرك (لـ Flutter/Postman)
# =========================
BACKEND_API_KEY = os.getenv("BACKEND_API_KEY", "change-me")

# =========================
# 1) تعريف الـ Schemas
# =========================
class Medication(BaseModel):
    name: str = Field(..., description="اسم الدواء باللغة الإنجليزية فقط")
    dose: str
    frequency: str
    duration: str
    notes: str

class MedicalReport(BaseModel):
    diagnosis: str
    medications: List[Medication]
    recommendations: List[str]
    follow_up: str

# =========================
# 2) تحميل نموذج Whisper مرة واحدة (تسريع CPU)
# =========================
# بما إنك قلت السيرفر CPU، خلّيه CPU مباشرة
device = "cpu"
# ✅ بدل medium إلى small (أسرع بكثير على CPU)
from faster_whisper import WhisperModel
asr_model = WhisperModel("small", device="cpu", compute_type="int8")


# =========================
# 3) إعداد Gemini + LangChain
# =========================
google_key = os.getenv("GOOGLE_API_KEY")
if not google_key:
    raise RuntimeError("GOOGLE_API_KEY is not set. Please set it as an environment variable on the server.")

os.environ["GOOGLE_API_KEY"] = google_key

parser = PydanticOutputParser(pydantic_object=MedicalReport)
format_instructions = parser.get_format_instructions()

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0.2,
)

prompt = ChatPromptTemplate.from_template("""
أنت مساعد طبي متخصص في تنظيم تقارير العيادات.

سيتم تزويدك بنص مفرغ من حديث الطبيب مع المريض.
مهمتك:
1. استخراج التشخيص بالعربية.
2. استخراج خطة العلاج الدوائية بحيث تكون أسماء الأدوية بالإنجليزية فقط مع الجرعة والمواعيد والمدة والملاحظات بالعربي.
3. استخراج التوصيات والإرشادات (نظام غذائي، رياضة، نمط حياة، تحذيرات...).
4. استخراج خطة المتابعة (موعد مراجعة، إعادة تحاليل، مراجعة طوارئ إن ذُكرت).
5. إذا لم يُذكر جزء ما، اجعله "غير مذكور" أو قائمة فارغة حيث يناسب.
6. الإخراج يجب أن يكون JSON صالح 100% ومتطابق مع الـ schema التالية بدون نص إضافي.

{format_instructions}

النص المفرغ (كلام الطبيب مع المريض):
--------------------
{transcript}
--------------------
""")

chain = prompt | llm | parser

def build_medical_report(full_transcript: str) -> MedicalReport:
    return chain.invoke({
        "transcript": full_transcript,
        "format_instructions": format_instructions
    })

# =========================
# 4) دالة مساعدة لتفريغ الملف (تسريع CPU)
# =========================
def transcribe_file_to_text(path: str) -> str:
    segments, info = asr_model.transcribe(path, language="ar", beam_size=1)
    return "".join(seg.text for seg in segments).strip()


# =========================
# 5) الـ Endpoint الرئيسي
# =========================
@app.post("/transcribe-report", response_model=MedicalReport)
async def transcribe_report(
    file: UploadFile = File(...),
    x_api_key: str = Header(None)  # يقرأ Header: X-API-KEY
):
    # ✅ تحقق API KEY
    if x_api_key != BACKEND_API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized: invalid or missing API key")

    # تحقق من نوع الملف (خليه مرن شوية عشان Postman أحيانًا يبعت octet-stream)
    if file.content_type and not (file.content_type.startswith("audio/") or file.content_type.startswith("video/") or file.content_type == "application/octet-stream"):
        raise HTTPException(status_code=400, detail=f"الملف يجب أن يكون صوتياً. content-type={file.content_type}")

    # حفظ الملف مؤقتاً
    temp_path = None
    try:
        suffix = os.path.splitext(file.filename or "")[1] or ".ogg"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            temp_path = tmp.name
            shutil.copyfileobj(file.file, tmp)
    except Exception:
        raise HTTPException(status_code=500, detail="خطأ في حفظ الملف")
    finally:
        await file.close()

    try:
        # ✅ شغل Whisper في threadpool عشان ما يهنّج السيرفر
        full_transcript = await run_in_threadpool(transcribe_file_to_text, temp_path)
        if not full_transcript:
            raise HTTPException(status_code=422, detail="لم يتم استخراج نص من الصوت")

        # ✅ شغل Gemini/LangChain في threadpool برضه
        report = await run_in_threadpool(build_medical_report, full_transcript)

        return report
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ أثناء المعالجة: {type(e).__name__}: {e}")
    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)



# ------------------------------------------------- DB -------------------------------------------
class PatientCreate(BaseModel):
    """
    Payload for POST /patients  (assistant or doctor).
    first_name and last_name are required — all other fields are optional
    to accommodate incomplete registration at walk-in.
    """
    id : int = Field(...)
    first_name: str = Field(..., max_length=100)
    last_name:  str = Field(..., max_length=100)

    date_of_birth: date | None = None
    gender:        str | None = None

    national_id: str | None = Field(
        default=None,
        max_length=50,
        description="National identity number. Must be unique if provided.",
    )
    phone: str | None = Field(default=None, max_length=30)


    email: Annotated[str, EmailStr] | None = Field(default=None,
                                                   escription="Optional contact email. Not used for system authentication.",
                                                   )
    address: str | None = None


def upsert_new_patient(first_name: str, last_name: str, date_of_birth: date | None,
                      gender: str | None, national_id: str | None,
                      phone: str | None, email: str | None, address: str | None, id: int) -> int:
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO patients (id, first_name, last_name, date_of_birth, gender, national_id, phone, email, address)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO UPDATE SET
                    first_name = EXCLUDED.first_name,
                    last_name = EXCLUDED.last_name,
                    date_of_birth = EXCLUDED.date_of_birth,
                    gender = EXCLUDED.gender,
                    national_id = EXCLUDED.national_id,
                    phone = EXCLUDED.phone,
                    email = EXCLUDED.email,
                    address = EXCLUDED.address
                RETURNING id;
                """,
                (
                    id,
                    first_name,
                    last_name,
                    date_of_birth,
                    gender,
                    national_id,
                    phone,
                    email,
                    address
                )
            )
            new_id = cur.fetchone()[0]
        conn.commit()
        return new_id
    except Exception:
        conn.rollback()
        raise


def delete_patient_db(id: int) -> int:
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                DELETE FROM patients WHERE id = %s RETURNING id;
                """,
                (id,)
            )
            deleted_id = cur.fetchone()[0]
        conn.commit()
        return deleted_id
    except Exception:
        conn.rollback()
        raise


@app.post("/db/create_patient")
async def create_patient(request: Request, patient: PatientCreate):
    try:
        new_gender = patient.gender.upper() if patient.gender else None
        new_patient= upsert_new_patient(
            first_name=patient.first_name,
            last_name=patient.last_name,
            date_of_birth=patient.date_of_birth,
            gender=new_gender,
            national_id=patient.national_id,
            phone=patient.phone,
            email=patient.email,
            address=patient.address,
            id=patient.id
        )
        return {"message": f"Patient created with ID {new_patient}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating patient: {e}")


@app.post("/db/delete_patient")
async def delete_patient(request: Request, id: int):
    try:
        result = delete_patient_db(id)
        return {"message": f"Patient deleted with ID {id}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting patient: {e}")