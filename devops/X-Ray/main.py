"""
MedVision AI — FastAPI Endpoint
POST /analyze  →  Upload image + patient info → Get structured medical report
"""

import io
import json
import random
import re
import string
import time
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

import faiss
import fitz
import numpy as np
import requests
from fastapi import FastAPI, File, Form, HTTPException, Security, UploadFile
from fastapi.responses import JSONResponse
from fastapi.security import APIKeyHeader
from google import genai
from google.genai import types
from google.genai.errors import ClientError
from PIL import Image
from rank_bm25 import BM25Okapi
from sentence_transformers import SentenceTransformer

# ── Config ────────────────────────────────────────────────────────
GEMINI_API_KEY  = "AIzaSyDeBLijs7kvUnoe_QxIOyYDZVjdzVHNAbg"   
ENDPOINT_API_KEY = "zzzzz11111zzzzz"  
MODEL          = "gemini-2.5-flash"
PDF_PATHS      = []                      

# ── Gemini client ─────────────────────────────────────────────────
client = genai.Client(api_key=GEMINI_API_KEY)

# ── Endpoint API Key Auth ────────────────────────────────────────
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != ENDPOINT_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key.")


# ── System Prompt ─────────────────────────────────────────────────
SYSTEM_PROMPT = """\
You are an expert dermatologist/radiologist generating a concise clinical report FOR A PHYSICIAN.
Be direct and specific. No hedging. No disclaimers.

Rules:
- Max 3 findings (most significant only)
- Max 1 leading impression + 3 differentials with probability %
- Max 2 recommendations (highest priority only)
- Summary: 2 sentences max — diagnosis + immediate action

Return ONLY valid JSON:
{
  "imageType": "xray|skin|other",
  "region": "<specific region>",
  "quality": "good|adequate|limited",
  "findings": ["<finding — max 3, each under 15 words>"],
  "impressions": ["<MOST LIKELY: Diagnosis — key visual evidence>"],
  "differentials": [
    "<Dx1 (~X%) — one distinguishing feature>",
    "<Dx2 (~X%) — one distinguishing feature>",
    "<Dx3 (~X%) — one distinguishing feature>"
  ],
  "recommendations": ["<action 1 — specific>", "<action 2 — specific>"],
  "urgency": "routine|urgent|emergent",
  "urgency_reason": "<one sentence, max 12 words>",
  "rag_query": "<precise search query>",
  "summary": "<diagnosis + immediate priority, 2 sentences max>"
}"""

# ── Built-in knowledge ────────────────────────────────────────────
BUILTIN_KNOWLEDGE = [
    {"text": "Pulmonary infiltrates on chest X-ray may indicate pneumonia, pulmonary edema, or hemorrhage. Lobar consolidation suggests bacterial pneumonia while bilateral interstitial infiltrates suggest viral or atypical pneumonia.", "source": "Radiology Guidelines", "type": "builtin"},
    {"text": "Cardiomegaly is defined as a cardiothoracic ratio greater than 0.5 on a PA chest radiograph. It may indicate dilated cardiomyopathy, pericardial effusion, or congestive heart failure.", "source": "Cardiology Reference", "type": "builtin"},
    {"text": "Pleural effusion presents as blunting of the costophrenic angles on chest X-ray. Massive effusion can cause mediastinal shift away from the affected side.", "source": "Radiology Guidelines", "type": "builtin"},
    {"text": "Pneumothorax appears as hyperlucency with absent lung markings peripherally. Tension pneumothorax causes mediastinal shift toward the contralateral side and is a medical emergency.", "source": "Emergency Medicine", "type": "builtin"},
    {"text": "ABCDE criteria for melanoma: Asymmetry, Border irregularity, Color variation, Diameter >6mm, Evolution. Any lesion meeting 2+ criteria requires urgent dermatology referral.", "source": "Dermatology Guidelines", "type": "builtin"},
    {"text": "Basal cell carcinoma presents as a pearly translucent papule with telangiectasia and rolled borders, typically on sun-exposed areas. It rarely metastasizes.", "source": "Dermatology Reference", "type": "builtin"},
    {"text": "Squamous cell carcinoma presents as an erythematous scaly plaque or ulcerating lesion. It can metastasize, particularly in immunocompromised patients.", "source": "Dermatology Reference", "type": "builtin"},
    {"text": "Psoriasis presents as well-demarcated erythematous plaques with silvery-white scale on extensor surfaces. Auspitz sign (pinpoint bleeding on scale removal) is characteristic.", "source": "Dermatology Reference", "type": "builtin"},
    {"text": "Lytic bone lesions may represent metastatic disease, multiple myeloma, or osteomyelitis. Sclerotic lesions may indicate osteoblastic metastases or Paget's disease.", "source": "Orthopedic Radiology", "type": "builtin"},
    {"text": "Atelectasis on chest X-ray presents as plate-like linear opacities, often in lower lobes. Caused by mucus plugging, compression, or post-surgical changes.", "source": "Radiology Guidelines", "type": "builtin"},
]

WHO_CDC_GUIDELINES = [
    {"text": "WHO TB chest X-ray: Primary TB shows hilar lymphadenopathy and lower lobe consolidation. Post-primary TB shows upper lobe cavitary lesions and fibrosis. Miliary TB presents as diffuse 1-3mm nodules.", "source": "WHO TB Guidelines 2023", "type": "who_cdc"},
    {"text": "CDC pneumonia: Typical CAP (S. pneumoniae) shows lobar consolidation. Atypical CAP (Mycoplasma) shows bilateral interstitial infiltrates. Healthcare-associated pneumonia carries higher drug-resistant organism risk.", "source": "CDC Pneumonia Guidelines", "type": "who_cdc"},
    {"text": "WHO COVID-19 chest X-ray: Bilateral peripheral ground-glass opacities are hallmark findings. Lower lobe predominance typical. Progression to consolidation indicates severe disease.", "source": "WHO COVID-19 Clinical Guidelines 2023", "type": "who_cdc"},
    {"text": "WHO skin cancer prevention: SPF 30+ sunscreen reduces SCC risk by 40% and melanoma risk by 50%. Annual clinical skin exam for high-risk individuals.", "source": "WHO Cancer Prevention Guidelines", "type": "who_cdc"},
    {"text": "CDC melanoma detection: Suspicious lesions require excisional biopsy with 1-3mm margins. Sentinel lymph node biopsy for melanomas >1mm Breslow thickness.", "source": "CDC Melanoma Guidelines", "type": "who_cdc"},
    {"text": "WHO osteoporosis: T-score ≤ -2.5 on DXA defines osteoporosis. T-score -1.0 to -2.5 defines osteopenia. Treatment threshold: 10-year major fracture risk ≥20%.", "source": "WHO Osteoporosis Guidelines", "type": "who_cdc"},
    {"text": "WHO radiological emergencies: Tension pneumothorax, massive hemothorax, aortic dissection (widened mediastinum >8cm), cardiac tamponade — require immediate clinical notification.", "source": "WHO Emergency Radiology Protocol", "type": "who_cdc"},
    {"text": "CDC fracture management: Open fractures require urgent surgical debridement and antibiotics within 6 hours. Growth plate fractures in children require orthopedic consultation.", "source": "CDC Orthopedic Guidelines", "type": "who_cdc"},
]


# ── Helpers ───────────────────────────────────────────────────────
def load_pdf_chunks(pdf_path: str, chunk_size=400, overlap=80) -> list:
    path = Path(pdf_path)
    if not path.exists():
        return []
    doc = fitz.open(pdf_path)
    full_text = re.sub(r'\s+', ' ', " ".join(p.get_text("text") for p in doc)).strip()
    doc.close()
    words = full_text.split()
    chunks = []
    for i in range(0, len(words), chunk_size - overlap):
        chunk = " ".join(words[i:i + chunk_size])
        if len(chunk.strip()) > 50:
            chunks.append({"text": chunk, "source": path.name, "type": "pdf"})
    return chunks


def search_pubmed(query: str, max_results=4) -> list:
    base = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
    try:
        r = requests.get(f"{base}/esearch.fcgi",
                         params={"db": "pubmed", "term": query, "retmax": max_results,
                                 "retmode": "json", "sort": "relevance"}, timeout=10)
        pmids = r.json()["esearchresult"]["idlist"]
        if not pmids:
            return []
        r2 = requests.get(f"{base}/efetch.fcgi",
                          params={"db": "pubmed", "id": ",".join(pmids),
                                  "rettype": "abstract", "retmode": "text"}, timeout=15)
        chunks = []
        for i, block in enumerate(re.split(r'\n\d+\.\s', r2.text)[:max_results]):
            if len(block.strip()) > 100:
                chunks.append({"text": block.strip()[:800],
                                "source": f"PubMed PMID-{pmids[i] if i < len(pmids) else 'N/A'}",
                                "type": "pubmed"})
        return chunks
    except Exception:
        return []


class HybridRAG:
    def __init__(self, embed_model):
        self.embed_model = embed_model
        self.documents   = []
        self.faiss_index = None
        self.bm25_index  = None

    def build(self, documents: list):
        self.documents = documents
        texts = [d["text"] for d in documents]
        emb = np.array(self.embed_model.encode(texts, batch_size=32)).astype("float32")
        faiss.normalize_L2(emb)
        self.faiss_index = faiss.IndexFlatIP(emb.shape[1])
        self.faiss_index.add(emb)
        self.bm25_index = BM25Okapi([t.lower().split() for t in texts])

    def retrieve(self, query: str, top_k=6) -> list:
        n = len(self.documents)
        q = np.array(self.embed_model.encode([query])).astype("float32")
        faiss.normalize_L2(q)
        scores_raw, idx_raw = self.faiss_index.search(q, n)
        fs = np.zeros(n)
        for rank, idx in enumerate(idx_raw[0]):
            if 0 <= idx < n:
                fs[idx] = scores_raw[0][rank]
        bs_raw = np.array(self.bm25_index.get_scores(query.lower().split()))
        bs = bs_raw / (bs_raw.max() + 1e-9)
        hybrid = 0.55 * fs + 0.45 * bs
        return [dict(**self.documents[i], score=round(float(hybrid[i]), 4))
                for i in np.argsort(hybrid)[::-1][:top_k]]


def compress_image(pil_img: Image.Image, max_size=512) -> Image.Image:
    img = pil_img.convert("RGB")
    w, h = img.size
    if max(w, h) > max_size:
        s = max_size / max(w, h)
        img = img.resize((int(w * s), int(h * s)), Image.LANCZOS)
    return img


def pil_to_part(pil_img: Image.Image) -> types.Part:
    buf = io.BytesIO()
    compress_image(pil_img).save(buf, format="JPEG", quality=82)
    return types.Part.from_bytes(data=buf.getvalue(), mime_type="image/jpeg")


def call_gemini(pil_img: Image.Image, prompt: str) -> dict:
    img_part = pil_to_part(pil_img)
    for attempt in range(1, 4):
        try:
            resp = client.models.generate_content(
                model=MODEL,
                contents=[img_part, prompt],
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_PROMPT,
                    max_output_tokens=1500,
                    response_mime_type="application/json",
                )
            )
            return json.loads(resp.text)
        except ClientError as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                wait = 30 * attempt
                time.sleep(wait)
            else:
                raise HTTPException(status_code=502, detail=f"Gemini error: {e}")
    raise HTTPException(status_code=429, detail="Gemini quota exhausted. Try again later.")


# ── App startup: build RAG index once ────────────────────────────
rag: HybridRAG = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global rag
    print("⏳ Loading embedding model...")
    embed_model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
    pdf_chunks = []
    for p in PDF_PATHS:
        pdf_chunks.extend(load_pdf_chunks(p))
    all_docs = pdf_chunks + BUILTIN_KNOWLEDGE + WHO_CDC_GUIDELINES
    print(f"⏳ Building RAG index ({len(all_docs)} documents)...")
    rag = HybridRAG(embed_model)
    rag.build(all_docs)
    print(f"✅ Ready — model: {MODEL}")
    yield


# ── FastAPI app ───────────────────────────────────────────────────
app = FastAPI(
    title="MedVision AI",
    description="Medical Image Analysis API — Gemini Vision + Hybrid RAG",
    version="1.0.0",
    lifespan=lifespan,
)


# ── Endpoint ──────────────────────────────────────────────────────
@app.post("/analyze")
async def analyze(
    image: UploadFile = File(..., description="Medical image (JPG/PNG)"),
    patient_name: str = Form(default="Anonymous"),
    patient_age:  str = Form(default="N/A"),
    _: None = Security(verify_api_key),
):
    # 1. Load image
    try:
        img_bytes = await image.read()
        img = Image.open(io.BytesIO(img_bytes))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file.")

    # 2. Stage 1 — Vision analysis
    initial_data = call_gemini(img, "Analyze this medical image. Return ONLY valid JSON.")

    # 3. Stage 2 — Hybrid RAG + PubMed
    rag_query = (initial_data.get("rag_query") or
                 f"{initial_data.get('imageType','')} {initial_data.get('region','')} "
                 + " ".join(initial_data.get("differentials", [])[:2]))

    hybrid_results = rag.retrieve(rag_query, top_k=5)
    pubmed_results = search_pubmed(rag_query, max_results=4)
    all_context    = hybrid_results + pubmed_results

    # 4. Stage 3 — Refined report
    context_text = "".join(
        f"[{i}] Source: {c['source']} ({c['type'].upper()})\n    {c['text'][:500]}\n\n"
        for i, c in enumerate(all_context, 1)
    )
    refinement_prompt = (
        f"Refine your medical report using this evidence-based context.\n\n"
        f"=== CONTEXT ===\n{context_text}================\n\n"
        f"Previous summary: {initial_data.get('summary', '')}\n\n"
        "Instructions: integrate retrieved knowledge, cite source types in recommendations, "
        "prioritize WHO/CDC for urgency, use PubMed for differentials. "
        "Return ONLY valid JSON with the same schema."
    )
    final_report = call_gemini(img, refinement_prompt)

    # 5. Build response
    return JSONResponse({
        "report_id":    "".join(random.choices(string.ascii_uppercase + string.digits, k=8)),
        "generated_at": datetime.now().isoformat(),
        "model":        MODEL,
        "patient": {
            "name": patient_name,
            "age":  patient_age,
        },
        "report":       final_report,
        "rag_sources": [
            {"source": c["source"], "type": c["type"], "score": c.get("score")}
            for c in all_context
        ],
    })


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL, "rag_ready": rag is not None}

