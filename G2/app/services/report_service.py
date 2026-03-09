"""
app/services/report_service.py

AI-assisted clinical report lifecycle service.

Use cases implemented
---------------------
Voice processing:
  - process_voice_recording()     : transcribe audio → NLP → create draft report

Medical reports:
  - get_report()                  : fetch report by id
  - get_report_by_visit()         : fetch report for a specific visit
  - update_report()               : doctor edits AI draft
  - update_report_status()        : lifecycle transitions (draft→reviewed→approved→finalized)
  - finalize_report()             : approve + trigger PDF/DOCX export

Medical images:
  - upload_medical_image()        : save file + trigger AI analysis
  - get_medical_image()           : fetch image record
  - list_visit_images()           : all images for a visit
  - update_image_notes()          : doctor adds/edits notes on an image

Lab reports:
  - upload_lab_report()           : save file + trigger AI interpretation
  - get_lab_report()              : fetch lab report record
  - list_visit_lab_reports()      : all lab reports for a visit

Audit trail:
  - get_audit_logs()              : paginated audit log query (admin only)

Business rules
--------------
- Only doctors can create, update, or approve medical reports.
- A visit can have at most one medical report.
- Report status must follow: DRAFT→REVIEWED→APPROVED→FINALIZED.
- Reports cannot be edited once FINALIZED.
- AI processing is non-blocking for uploads: failures are recorded in the
  AI fields as a stub message; the record is still saved.
- Doctors can override any AI-generated content at any point before FINALIZED.
- Only admins can query audit logs.

AI integration
--------------
All AI calls go through ai_service.py — this service never imports
from app/ai/ directly. If ai_service raises AIProcessingError, the
report is saved with a stub message in the AI fields and a warning logged.
This ensures a corrupted audio file doesn't prevent the doctor from
manually completing the report.

Audit events
------------
REPORT_CREATED, REPORT_UPDATED, REPORT_APPROVED, REPORT_FINALIZED,
IMAGE_UPLOADED, LAB_UPLOADED
"""

from __future__ import annotations

import json
import logging
from pathlib import Path

from sqlalchemy.orm import Session, joinedload

from app.core.constants import AuditAction, ReportStatus, UserRole
from app.core.exceptions import (
    BusinessRuleError,
    ConflictError,
    ForbiddenError,
    NotFoundError,
)
from app.models.clinic_models import Patient, PatientCondition, Visit
from app.models.report_models import AuditLog, LabReport, MedicalImage, MedicalReport
from app.schemas.auth_schemas import AuthenticatedUser
from app.schemas.clinic_schemas import VisitSummary
from app.schemas.report_schemas import (
    AIMedication,
    AuditLogFilter,
    AuditLogResponse,
    LabReportCreate,
    LabReportResponse,
    MedicalImageCreate,
    MedicalImageResponse,
    MedicalReportCreate,
    MedicalReportResponse,
    MedicalReportStatusUpdate,
    MedicalReportSummary,
    MedicalReportUpdate,
)
from app.schemas.user_schemas import DoctorSummary
from app.services import ai_service

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Allowed report status transitions
# ---------------------------------------------------------------------------
_REPORT_TRANSITIONS: dict[ReportStatus, set[ReportStatus]] = {
    ReportStatus.DRAFT:     {ReportStatus.REVIEWED, ReportStatus.CANCELLED},
    ReportStatus.REVIEWED:  {ReportStatus.APPROVED, ReportStatus.DRAFT, ReportStatus.CANCELLED},
    ReportStatus.APPROVED:  {ReportStatus.FINALIZED, ReportStatus.REVIEWED},
    ReportStatus.FINALIZED: set(),
    ReportStatus.CANCELLED: set(),
}


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _write_audit(
    db: Session,
    user_id: int | None,
    action: AuditAction,
    entity_type: str,
    entity_id: int | None,
    details: dict | None = None,
) -> None:
    try:
        entry = AuditLog(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            details=json.dumps(details) if details else None,
        )
        db.add(entry)
        db.flush()
    except Exception as exc:
        logger.error("Audit write failed (action=%s): %s", action, exc)


def _get_visit_or_404(db: Session, visit_id: int) -> Visit:
    visit = db.query(Visit).options(joinedload(Visit.appointment)).filter(Visit.id == visit_id).first()
    if not visit:
        raise NotFoundError("Visit", visit_id)
    return visit


def _get_report_or_404(db: Session, report_id: int) -> MedicalReport:
    report = (
        db.query(MedicalReport)
        .options(
            joinedload(MedicalReport.visit).joinedload(Visit.appointment),
            joinedload(MedicalReport.doctor).joinedload("user"),
        )
        .filter(MedicalReport.id == report_id)
        .first()
    )
    if not report:
        raise NotFoundError("MedicalReport", report_id)
    return report


def _get_doctor_id_for_user(db: Session, user_id: int) -> int:
    from app.models.user_models import Doctor
    doctor = db.query(Doctor).filter(Doctor.user_id == user_id).first()
    if not doctor:
        raise NotFoundError("Doctor profile for user", user_id)
    return doctor.id


def _get_patient_conditions_text(db: Session, patient_id: int) -> list[str]:
    """Return condition names for a patient — injected into AI context."""
    pcs = (
        db.query(PatientCondition)
        .options(joinedload(PatientCondition.condition))
        .filter(PatientCondition.patient_id == patient_id)
        .all()
    )
    return [pc.condition.name for pc in pcs if pc.condition]


def _build_report_response(report: MedicalReport) -> MedicalReportResponse:
    visit = report.visit
    appt = visit.appointment

    visit_summary = VisitSummary(
        id=visit.id,
        appointment_id=visit.appointment_id,
        status=visit.status,
        start_time=visit.start_time,
    )

    doctor = report.doctor
    doctor_summary = DoctorSummary(
        id=doctor.id,
        user_id=doctor.user_id,
        first_name=doctor.first_name,
        last_name=doctor.last_name,
        specialization=doctor.specialization,
        clinic_name=doctor.clinic_name,
    )

    # Deserialise ai_medications from JSONB → list[AIMedication]
    raw_meds = report.ai_medications or []
    medications: list[AIMedication] = []
    if isinstance(raw_meds, list):
        for med in raw_meds:
            if isinstance(med, dict):
                medications.append(AIMedication(**{k: v for k, v in med.items() if k in AIMedication.model_fields}))

    # Deserialise ai_recommendations from JSONB → list[str]
    recommendations: list[str] = []
    raw_recs = report.ai_recommendations or []
    if isinstance(raw_recs, list):
        recommendations = [str(r) for r in raw_recs]

    return MedicalReportResponse(
        id=report.id,
        visit_id=report.visit_id,
        doctor_id=report.doctor_id,
        status=report.status,
        doctor_voice_transcription=report.doctor_voice_transcription,
        ai_diagnosis=report.ai_diagnosis,
        ai_medications=medications if medications else None,
        ai_recommendations=recommendations if recommendations else None,
        ai_follow_up=report.ai_follow_up,
        doctor_notes=report.doctor_notes,
        visit=visit_summary,
        doctor=doctor_summary,
        created_at=report.created_at,
        updated_at=report.updated_at,
    )


def _build_image_response(image: MedicalImage) -> MedicalImageResponse:
    return MedicalImageResponse(
        id=image.id,
        visit_id=image.visit_id,
        image_url=image.image_url,
        image_type=image.image_type,
        ai_diagnosis=image.ai_diagnosis,
        doctor_notes=image.doctor_notes,
        created_at=image.created_at,
    )


def _build_lab_response(lab: LabReport) -> LabReportResponse:
    return LabReportResponse(
        id=lab.id,
        visit_id=lab.visit_id,
        report_url=lab.report_url,
        ai_interpreted_summary=lab.ai_interpreted_summary,
        original_text=lab.original_text,
        created_at=lab.created_at,
    )


# ===========================================================================
# VOICE PROCESSING → REPORT CREATION
# ===========================================================================

def process_voice_recording(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    audio_file_path: str,
) -> MedicalReportResponse:
    """
    Full voice-to-draft-report pipeline.

    Workflow:
    1. Validate the visit exists and belongs to this doctor's patient.
    2. Ensure no report already exists for this visit.
    3. Call ai_service.transcribe_audio() → TranscriptionResult.
    4. Load patient's known conditions for NLP context.
    5. Call ai_service.generate_medical_report() → MedicalNLPResult.
    6. Create MedicalReport row with status=DRAFT.
    7. Write audit log.

    AI failures are non-fatal: if transcription or NLP fails, the report
    is created with stub content and the doctor can fill it in manually.

    Raises
    ------
    ForbiddenError    : caller is not a doctor.
    NotFoundError     : visit not found.
    ConflictError     : report already exists for this visit.
    """
    if current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can create medical reports.")

    visit = _get_visit_or_404(db, visit_id)
    doctor_id = _get_doctor_id_for_user(db, current_user.id)

    # Confirm this doctor is assigned to this visit's appointment
    if visit.appointment.doctor_id != doctor_id:
        raise ForbiddenError("You can only create reports for your own patients.")

    # Prevent duplicate reports
    existing = db.query(MedicalReport).filter(MedicalReport.visit_id == visit_id).first()
    if existing:
        raise ConflictError(f"A medical report already exists for Visit #{visit_id} (Report #{existing.id}).")

    # ── Step 1: Transcribe audio ───────────────────────────────────────────
    transcription_text = ""
    try:
        transcription_result = ai_service.transcribe_audio(audio_file_path)
        transcription_text = transcription_result.text
        logger.info("Visit %d: transcription complete (%d chars).", visit_id, len(transcription_text))
    except Exception as exc:
        logger.warning("Visit %d: transcription failed — %s. Proceeding with empty text.", visit_id, exc)
        transcription_text = f"[Transcription failed: {exc}]"

    # ── Step 2: Load patient context ──────────────────────────────────────
    patient_conditions = _get_patient_conditions_text(db, visit.appointment.patient_id)

    # ── Step 3: Medical NLP ───────────────────────────────────────────────
    ai_diagnosis = None
    ai_medications_raw: list[dict] = []
    ai_recommendations_raw: list[str] = []
    ai_follow_up = None

    if transcription_text and not transcription_text.startswith("[Transcription failed"):
        try:
            nlp_result = ai_service.generate_medical_report(
                transcription=transcription_text,
                patient_conditions=patient_conditions,
            )
            ai_diagnosis = nlp_result.soap_summary
            ai_medications_raw = nlp_result.medications
            ai_recommendations_raw = nlp_result.recommendations
            ai_follow_up = nlp_result.follow_up
            logger.info("Visit %d: NLP complete.", visit_id)
        except Exception as exc:
            logger.warning("Visit %d: NLP failed — %s. Report saved with partial AI content.", visit_id, exc)
            ai_diagnosis = f"[AI diagnosis unavailable: {exc}]"

    # ── Step 4: Persist report ────────────────────────────────────────────
    report = MedicalReport(
        visit_id=visit_id,
        doctor_id=doctor_id,
        doctor_voice_transcription=transcription_text,
        ai_diagnosis=ai_diagnosis,
        ai_medications=ai_medications_raw if ai_medications_raw else None,
        ai_recommendations=ai_recommendations_raw if ai_recommendations_raw else None,
        ai_follow_up=ai_follow_up,
        status=ReportStatus.DRAFT,
    )
    db.add(report)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.REPORT_CREATED, "medical_report", report.id,
        {"visit_id": visit_id, "method": "voice", "has_transcription": bool(transcription_text)},
    )
    db.commit()
    logger.info("MedicalReport %d created (DRAFT) for visit %d.", report.id, visit_id)

    return _build_report_response(_get_report_or_404(db, report.id))


def create_report_manually(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    data: MedicalReportCreate,
) -> MedicalReportResponse:
    """
    Create a medical report without voice — doctor types findings directly.

    Raises
    ------
    ForbiddenError : caller is not a doctor.
    ConflictError  : report already exists for this visit.
    """
    if current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can create medical reports.")

    visit = _get_visit_or_404(db, visit_id)
    doctor_id = _get_doctor_id_for_user(db, current_user.id)

    if visit.appointment.doctor_id != doctor_id:
        raise ForbiddenError("You can only create reports for your own patients.")

    existing = db.query(MedicalReport).filter(MedicalReport.visit_id == visit_id).first()
    if existing:
        raise ConflictError(f"A medical report already exists for Visit #{visit_id}.")

    meds_raw = [m.model_dump() for m in data.ai_medications] if data.ai_medications else None
    recs_raw = data.ai_recommendations or None

    report = MedicalReport(
        visit_id=visit_id,
        doctor_id=doctor_id,
        doctor_voice_transcription=data.doctor_voice_transcription,
        ai_diagnosis=data.ai_diagnosis,
        ai_medications=meds_raw,
        ai_recommendations=recs_raw,
        ai_follow_up=data.ai_follow_up,
        doctor_notes=data.doctor_notes,
        status=ReportStatus.DRAFT,
    )
    db.add(report)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.REPORT_CREATED, "medical_report", report.id,
        {"visit_id": visit_id, "method": "manual"},
    )
    db.commit()

    return _build_report_response(_get_report_or_404(db, report.id))


# ===========================================================================
# MEDICAL REPORT LIFECYCLE
# ===========================================================================

def get_report(db: Session, report_id: int) -> MedicalReportResponse:
    return _build_report_response(_get_report_or_404(db, report_id))


def get_report_by_visit(db: Session, visit_id: int) -> MedicalReportResponse:
    """Fetch the single medical report for a visit."""
    _get_visit_or_404(db, visit_id)  # validate visit exists
    report = db.query(MedicalReport).filter(MedicalReport.visit_id == visit_id).first()
    if not report:
        raise NotFoundError("MedicalReport for visit", visit_id)
    return _build_report_response(_get_report_or_404(db, report.id))


def update_report(
    db: Session,
    current_user: AuthenticatedUser,
    report_id: int,
    data: MedicalReportUpdate,
) -> MedicalReportResponse:
    """
    Doctor edits the AI draft before approval.
    Not allowed once the report is FINALIZED or CANCELLED.

    Raises
    ------
    ForbiddenError    : caller is not the report's doctor (or admin).
    BusinessRuleError : report is in a terminal state.
    """
    if current_user.role not in (UserRole.DOCTOR, UserRole.ADMIN):
        raise ForbiddenError("Only doctors can edit medical reports.")

    report = _get_report_or_404(db, report_id)

    if report.status in (ReportStatus.FINALIZED, ReportStatus.CANCELLED):
        raise BusinessRuleError(
            f"Cannot edit a report in '{report.status.value}' status."
        )

    # Verify ownership (doctors can only edit their own reports)
    if current_user.role == UserRole.DOCTOR:
        doctor_id = _get_doctor_id_for_user(db, current_user.id)
        if report.doctor_id != doctor_id:
            raise ForbiddenError("You can only edit your own medical reports.")

    changed: dict = {}

    if data.doctor_voice_transcription is not None:
        report.doctor_voice_transcription = data.doctor_voice_transcription
        changed["doctor_voice_transcription"] = "updated"

    if data.ai_diagnosis is not None:
        report.ai_diagnosis = data.ai_diagnosis
        changed["ai_diagnosis"] = "updated"

    if data.ai_medications is not None:
        report.ai_medications = [m.model_dump() for m in data.ai_medications]
        changed["ai_medications"] = f"{len(data.ai_medications)} items"

    if data.ai_recommendations is not None:
        report.ai_recommendations = data.ai_recommendations
        changed["ai_recommendations"] = f"{len(data.ai_recommendations)} items"

    if data.ai_follow_up is not None:
        report.ai_follow_up = data.ai_follow_up
        changed["ai_follow_up"] = "updated"

    if data.doctor_notes is not None:
        report.doctor_notes = data.doctor_notes
        changed["doctor_notes"] = "updated"

    if changed:
        db.add(report)
        _write_audit(db, current_user.id, AuditAction.REPORT_UPDATED, "medical_report", report_id, changed)
        db.commit()

    return _build_report_response(_get_report_or_404(db, report_id))


def update_report_status(
    db: Session,
    current_user: AuthenticatedUser,
    report_id: int,
    data: MedicalReportStatusUpdate,
) -> MedicalReportResponse:
    """
    Advance or retreat a report through its lifecycle states.

    Raises
    ------
    ForbiddenError    : caller is not the owning doctor.
    BusinessRuleError : invalid transition.
    """
    if current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can change report status.")

    report = _get_report_or_404(db, report_id)
    doctor_id = _get_doctor_id_for_user(db, current_user.id)

    if report.doctor_id != doctor_id:
        raise ForbiddenError("You can only change the status of your own reports.")

    allowed = _REPORT_TRANSITIONS.get(report.status, set())
    if data.status not in allowed:
        raise BusinessRuleError(
            f"Cannot transition report from '{report.status.value}' to '{data.status.value}'. "
            f"Allowed: {[s.value for s in allowed] or 'none (terminal state)'}."
        )

    old_status = report.status
    report.status = data.status
    db.add(report)

    action = (
        AuditAction.REPORT_APPROVED if data.status == ReportStatus.APPROVED
        else AuditAction.REPORT_FINALIZED if data.status == ReportStatus.FINALIZED
        else AuditAction.REPORT_UPDATED
    )
    _write_audit(
        db, current_user.id, action, "medical_report", report_id,
        {"from": old_status.value, "to": data.status.value},
    )
    db.commit()

    return _build_report_response(_get_report_or_404(db, report_id))


def finalize_report(
    db: Session,
    current_user: AuthenticatedUser,
    report_id: int,
) -> MedicalReportResponse:
    """
    Convenience use case: approve + finalize a report in one call.

    Transitions: REVIEWED → APPROVED → FINALIZED (two steps).
    Triggers PDF/DOCX export via utils/report_generator.py.
    Doctors only.
    """
    if current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can finalize medical reports.")

    report = _get_report_or_404(db, report_id)
    doctor_id = _get_doctor_id_for_user(db, current_user.id)

    if report.doctor_id != doctor_id:
        raise ForbiddenError("You can only finalize your own reports.")

    if report.status == ReportStatus.DRAFT:
        raise BusinessRuleError(
            "Report must be REVIEWED before it can be finalized. "
            "Please mark it as REVIEWED first."
        )

    if report.status == ReportStatus.FINALIZED:
        raise BusinessRuleError("Report is already finalized.")

    if report.status == ReportStatus.CANCELLED:
        raise BusinessRuleError("Cannot finalize a cancelled report.")

    # If REVIEWED → step through APPROVED first
    if report.status == ReportStatus.REVIEWED:
        report.status = ReportStatus.APPROVED
        db.add(report)
        db.flush()
        _write_audit(db, current_user.id, AuditAction.REPORT_APPROVED, "medical_report", report_id,
                     {"step": "auto-approved during finalization"})

    # Now APPROVED → FINALIZED
    report.status = ReportStatus.FINALIZED
    db.add(report)

    # Trigger PDF export (non-fatal if generator unavailable)
    try:
        from app.utils.report_generator import generate_pdf
        pdf_path = generate_pdf(report)
        logger.info("Report %d: PDF generated at %s", report_id, pdf_path)
    except Exception as exc:
        logger.warning("Report %d: PDF generation failed — %s. Report still finalized.", report_id, exc)

    _write_audit(db, current_user.id, AuditAction.REPORT_FINALIZED, "medical_report", report_id)
    db.commit()

    logger.info("MedicalReport %d finalized by doctor (user %d).", report_id, current_user.id)
    return _build_report_response(_get_report_or_404(db, report_id))


# ===========================================================================
# MEDICAL IMAGE UPLOAD + AI ANALYSIS
# ===========================================================================

def upload_medical_image(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    saved_file_path: str,
    data: MedicalImageCreate,
) -> MedicalImageResponse:
    """
    Save a medical image record and trigger AI analysis.

    saved_file_path is set by the API layer after writing the uploaded
    binary to storage via utils/file_handler.py. This service only handles
    the database record and AI call.

    AI failure is non-fatal — the image is saved with an empty ai_diagnosis
    and a warning is logged.

    Raises
    ------
    ForbiddenError : caller is not clinic staff.
    NotFoundError  : visit not found.
    """
    if current_user.role not in (UserRole.DOCTOR, UserRole.ASSISTANT, UserRole.ADMIN):
        raise ForbiddenError("Only clinic staff can upload medical images.")

    _get_visit_or_404(db, visit_id)   # validate visit exists

    # ── AI analysis ───────────────────────────────────────────────────────
    ai_diagnosis_text = None
    try:
        analysis = ai_service.analyze_image(saved_file_path, data.image_type.value)
        ai_diagnosis_text = analysis.findings
        logger.info(
            "Image analysis for visit %d (type=%s): confidence=%.2f",
            visit_id, data.image_type.value, analysis.confidence,
        )
    except Exception as exc:
        logger.warning("Image AI analysis failed for visit %d: %s", visit_id, exc)
        ai_diagnosis_text = f"[AI analysis failed: {exc}]"

    image = MedicalImage(
        visit_id=visit_id,
        image_url=saved_file_path,
        image_type=data.image_type,
        ai_diagnosis=ai_diagnosis_text,
        doctor_notes=data.doctor_notes,
    )
    db.add(image)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.IMAGE_UPLOADED, "medical_image", image.id,
        {"visit_id": visit_id, "image_type": data.image_type.value},
    )
    db.commit()
    db.refresh(image)

    return _build_image_response(image)


def get_medical_image(db: Session, image_id: int) -> MedicalImageResponse:
    image = db.query(MedicalImage).filter(MedicalImage.id == image_id).first()
    if not image:
        raise NotFoundError("MedicalImage", image_id)
    return _build_image_response(image)


def list_visit_images(db: Session, visit_id: int) -> list[MedicalImageResponse]:
    _get_visit_or_404(db, visit_id)
    images = db.query(MedicalImage).filter(MedicalImage.visit_id == visit_id).all()
    return [_build_image_response(img) for img in images]


def update_image_notes(
    db: Session,
    current_user: AuthenticatedUser,
    image_id: int,
    doctor_notes: str,
) -> MedicalImageResponse:
    """Doctor adds or edits clinical notes on a specific image."""
    if current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can add clinical notes to medical images.")

    image = db.query(MedicalImage).filter(MedicalImage.id == image_id).first()
    if not image:
        raise NotFoundError("MedicalImage", image_id)

    image.doctor_notes = doctor_notes
    db.add(image)
    _write_audit(db, current_user.id, AuditAction.REPORT_UPDATED, "medical_image", image_id,
                 {"doctor_notes": "updated"})
    db.commit()
    db.refresh(image)
    return _build_image_response(image)


# ===========================================================================
# LAB REPORT UPLOAD + AI INTERPRETATION
# ===========================================================================

def upload_lab_report(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    saved_file_path: str,
    data: LabReportCreate,
) -> LabReportResponse:
    """
    Save a lab report file reference and trigger AI interpretation.

    AI failure is non-fatal — the record is saved with empty AI fields.

    Raises
    ------
    ForbiddenError : caller is not clinic staff.
    NotFoundError  : visit not found.
    """
    if current_user.role not in (UserRole.DOCTOR, UserRole.ASSISTANT, UserRole.ADMIN):
        raise ForbiddenError("Only clinic staff can upload lab reports.")

    _get_visit_or_404(db, visit_id)

    # ── AI interpretation ─────────────────────────────────────────────────
    interpreted_summary = None
    original_text = None
    try:
        lab_result = ai_service.interpret_lab_report(saved_file_path)
        interpreted_summary = lab_result.interpreted_summary
        original_text = lab_result.original_text
        logger.info("Lab report interpretation complete for visit %d.", visit_id)
    except Exception as exc:
        logger.warning("Lab report AI interpretation failed for visit %d: %s", visit_id, exc)
        interpreted_summary = f"[AI interpretation failed: {exc}]"

    lab = LabReport(
        visit_id=visit_id,
        report_url=saved_file_path,
        ai_interpreted_summary=interpreted_summary,
        original_text=original_text,
    )
    db.add(lab)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.LAB_UPLOADED, "lab_report", lab.id,
        {"visit_id": visit_id},
    )
    db.commit()
    db.refresh(lab)

    return _build_lab_response(lab)


def get_lab_report(db: Session, lab_report_id: int) -> LabReportResponse:
    lab = db.query(LabReport).filter(LabReport.id == lab_report_id).first()
    if not lab:
        raise NotFoundError("LabReport", lab_report_id)
    return _build_lab_response(lab)


def list_visit_lab_reports(db: Session, visit_id: int) -> list[LabReportResponse]:
    _get_visit_or_404(db, visit_id)
    labs = db.query(LabReport).filter(LabReport.visit_id == visit_id).all()
    return [_build_lab_response(lab) for lab in labs]


# ===========================================================================
# AUDIT LOG QUERY
# ===========================================================================

def get_audit_logs(
    db: Session,
    current_user: AuthenticatedUser,
    filters: AuditLogFilter,
    offset: int = 0,
    limit: int = 50,
) -> tuple[list[AuditLogResponse], int]:
    """
    Paginated audit log query. Admin only.

    Raises
    ------
    ForbiddenError : caller is not an admin.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can access audit logs.")

    q = db.query(AuditLog)

    if filters.user_id is not None:
        q = q.filter(AuditLog.user_id == filters.user_id)
    if filters.action is not None:
        q = q.filter(AuditLog.action == filters.action)
    if filters.entity_type is not None:
        q = q.filter(AuditLog.entity_type == filters.entity_type)
    if filters.entity_id is not None:
        q = q.filter(AuditLog.entity_id == filters.entity_id)
    if filters.date_from is not None:
        q = q.filter(AuditLog.created_at >= filters.date_from)
    if filters.date_to is not None:
        q = q.filter(AuditLog.created_at <= filters.date_to)

    total = q.count()
    logs = q.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit).all()

    results = [
        AuditLogResponse(
            id=log.id,
            user_id=log.user_id,
            action=log.action,
            entity_type=log.entity_type,
            entity_id=log.entity_id,
            details=log.details,
            ip_address=log.ip_address,
            created_at=log.created_at,
        )
        for log in logs
    ]

    return results, total