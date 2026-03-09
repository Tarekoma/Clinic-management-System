"""
app/services/ai_service.py

Facade over all AI modules for the Intelligent Medical Assistant.

Design contract
---------------
- This is the ONLY file in the service layer that imports from app/ai/.
- report_service.py calls methods here — never raw AI modules directly.
- Every method normalises AI output into clean typed structures before
  returning, so report_service never has to parse raw AI responses.
- AI failures raise AIProcessingError. The calling service decides
  whether to propagate (hard failure) or degrade gracefully (soft failure).
- No database access in this service — pure AI orchestration.
- No FastAPI imports.

Stub behaviour (development / testing)
---------------------------------------
When AI modules are not yet loaded (import fails or model weights absent),
methods return clearly labelled stub responses so the rest of the system
can be developed and tested without live AI infrastructure.
"""

from __future__ import annotations

import logging
from pathlib import Path

from app.core.exceptions import AIProcessingError

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Typed return structures
# (Plain dataclasses — not Pydantic — so this file stays framework-free)
# ---------------------------------------------------------------------------

from dataclasses import dataclass, field


@dataclass
class TranscriptionResult:
    """Output of the speech-to-text module."""
    text: str
    language: str = "en"          # detected language code
    confidence: float = 1.0       # 0.0–1.0


@dataclass
class MedicalNLPResult:
    """Structured output of the medical NLP module."""
    soap_summary: str             # Full SOAP-format narrative
    diagnosis: str                # Structured diagnosis string
    medications: list[dict]       # [{name, dose, frequency, duration, route, notes}]
    recommendations: list[str]    # Free-text lifestyle / follow-up items
    follow_up: str                # e.g. "Return in 2 weeks if symptoms persist"
    extracted_symptoms: list[str] = field(default_factory=list)
    extracted_diagnoses: list[str] = field(default_factory=list)


@dataclass
class ImageAnalysisResult:
    """Output of the X-ray or skin analysis module."""
    image_type: str               # "xray" | "skin" | etc.
    findings: str                 # Human-readable diagnostic findings
    confidence: float             # 0.0–1.0
    labels: list[str] = field(default_factory=list)   # Top predicted labels


@dataclass
class LabInterpretationResult:
    """Output of the lab report interpreter."""
    interpreted_summary: str       # Plain-language summary
    original_text: str             # Raw extracted text from the document
    abnormal_flags: list[str] = field(default_factory=list)   # Flagged abnormal values


# ---------------------------------------------------------------------------
# AI Module loaders (lazy import to avoid hard crash on missing weights)
# ---------------------------------------------------------------------------

def _load_speech_module():
    try:
        from app.ai import speech_to_text
        return speech_to_text
    except ImportError:
        logger.warning("speech_to_text module not available — using stub.")
        return None


def _load_nlp_module():
    try:
        from app.ai import medical_nlp
        return medical_nlp
    except ImportError:
        logger.warning("medical_nlp module not available — using stub.")
        return None


def _load_xray_module():
    try:
        from app.ai import xray_analysis
        return xray_analysis
    except ImportError:
        logger.warning("xray_analysis module not available — using stub.")
        return None


def _load_skin_module():
    try:
        from app.ai import skin_analysis
        return skin_analysis
    except ImportError:
        logger.warning("skin_analysis module not available — using stub.")
        return None


def _load_lab_module():
    try:
        from app.ai import lab_interpreter
        return lab_interpreter
    except ImportError:
        logger.warning("lab_interpreter module not available — using stub.")
        return None


# ---------------------------------------------------------------------------
# Public service methods
# ---------------------------------------------------------------------------

def transcribe_audio(audio_path: str | Path) -> TranscriptionResult:
    """
    Convert a doctor's recorded audio file to plain text.

    Parameters
    ----------
    audio_path : str | Path
        Path to the saved audio file (WAV, MP3, M4A supported by Whisper).

    Returns
    -------
    TranscriptionResult
        Verbatim transcription with detected language and confidence.

    Raises
    ------
    AIProcessingError
        If the audio cannot be transcribed (corrupted file, silence, etc.)
    """
    module = _load_speech_module()

    if module is None:
        logger.warning("Using stub transcription — speech_to_text unavailable.")
        return TranscriptionResult(
            text="[STUB] Transcription unavailable — AI module not loaded.",
            language="en",
            confidence=0.0,
        )

    try:
        raw = module.transcribe(str(audio_path))
        return TranscriptionResult(
            text=raw.get("text", ""),
            language=raw.get("language", "en"),
            confidence=raw.get("confidence", 1.0),
        )
    except Exception as exc:
        logger.error("Speech-to-text failed for %s: %s", audio_path, exc)
        raise AIProcessingError("speech_to_text", str(exc)) from exc


def generate_medical_report(
    transcription: str,
    patient_conditions: list[str],
    existing_medications: list[str] | None = None,
) -> MedicalNLPResult:
    """
    Process a transcription into a structured SOAP medical report.

    Parameters
    ----------
    transcription : str
        Raw text from speech-to-text (or manually typed notes).
    patient_conditions : list[str]
        List of the patient's known chronic conditions (by name).
        Injected into the NLP context so the model can account for
        existing diagnoses and drug interactions.
    existing_medications : list[str] | None
        Names of medications the patient is currently taking.

    Returns
    -------
    MedicalNLPResult
        SOAP summary, medications list, recommendations, follow-up.

    Raises
    ------
    AIProcessingError
        If the NLP module fails to process the input.
    """
    module = _load_nlp_module()

    if module is None:
        logger.warning("Using stub NLP — medical_nlp unavailable.")
        return MedicalNLPResult(
            soap_summary="[STUB] NLP module not available.",
            diagnosis="[STUB] Diagnosis unavailable.",
            medications=[],
            recommendations=["[STUB] Recommendations unavailable."],
            follow_up="[STUB] Follow-up unavailable.",
        )

    try:
        raw = module.extract_and_structure(
            text=transcription,
            patient_conditions=patient_conditions,
            existing_medications=existing_medications or [],
        )
        return MedicalNLPResult(
            soap_summary=raw.get("soap_summary", ""),
            diagnosis=raw.get("diagnosis", ""),
            medications=raw.get("medications", []),
            recommendations=raw.get("recommendations", []),
            follow_up=raw.get("follow_up", ""),
            extracted_symptoms=raw.get("symptoms", []),
            extracted_diagnoses=raw.get("diagnoses", []),
        )
    except Exception as exc:
        logger.error("Medical NLP failed: %s", exc)
        raise AIProcessingError("medical_nlp", str(exc)) from exc


def analyze_image(image_path: str | Path, image_type: str) -> ImageAnalysisResult:
    """
    Analyse a medical image and return AI-generated diagnostic findings.

    Routes to the correct sub-module based on image_type:
    - "xray"  → xray_analysis module
    - "skin"  → skin_analysis module
    - All others: returns a stub (not analysed in v1)

    Parameters
    ----------
    image_path : str | Path
        Saved image file path.
    image_type : str
        Value from the ImageType enum (e.g. "xray", "skin").

    Returns
    -------
    ImageAnalysisResult
        Findings, confidence, and label list.

    Raises
    ------
    AIProcessingError
        If the analysis module fails.
    """
    image_type = image_type.lower()

    if image_type == "xray":
        module = _load_xray_module()
        module_name = "xray_analysis"
    elif image_type == "skin":
        module = _load_skin_module()
        module_name = "skin_analysis"
    else:
        # Image types other than xray/skin are stored but not analysed in v1
        logger.info("Image type '%s' not supported for AI analysis in v1.", image_type)
        return ImageAnalysisResult(
            image_type=image_type,
            findings=f"AI analysis not available for image type '{image_type}'.",
            confidence=0.0,
        )

    if module is None:
        logger.warning("Using stub analysis — %s unavailable.", module_name)
        return ImageAnalysisResult(
            image_type=image_type,
            findings=f"[STUB] {module_name} module not loaded.",
            confidence=0.0,
        )

    try:
        raw = module.analyse(str(image_path))
        return ImageAnalysisResult(
            image_type=image_type,
            findings=raw.get("findings", ""),
            confidence=raw.get("confidence", 0.0),
            labels=raw.get("labels", []),
        )
    except Exception as exc:
        logger.error("%s failed for %s: %s", module_name, image_path, exc)
        raise AIProcessingError(module_name, str(exc)) from exc


def interpret_lab_report(file_path: str | Path) -> LabInterpretationResult:
    """
    Extract text from a lab report document and generate a plain-language
    interpretation highlighting abnormal values.

    Parameters
    ----------
    file_path : str | Path
        Path to the uploaded lab report file (PDF or image).

    Returns
    -------
    LabInterpretationResult
        Interpreted summary, raw extracted text, and abnormal flags.

    Raises
    ------
    AIProcessingError
        If the extraction or interpretation fails.
    """
    module = _load_lab_module()

    if module is None:
        logger.warning("Using stub lab interpretation — lab_interpreter unavailable.")
        return LabInterpretationResult(
            interpreted_summary="[STUB] Lab interpreter not available.",
            original_text="",
        )

    try:
        raw = module.interpret(str(file_path))
        return LabInterpretationResult(
            interpreted_summary=raw.get("summary", ""),
            original_text=raw.get("original_text", ""),
            abnormal_flags=raw.get("abnormal_flags", []),
        )
    except Exception as exc:
        logger.error("Lab interpreter failed for %s: %s", file_path, exc)
        raise AIProcessingError("lab_interpreter", str(exc)) from exc