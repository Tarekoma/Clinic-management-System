"""
app/services/clinic_service.py

Operational clinic workflow service.

Use cases implemented
---------------------
Patient management:
  - create_patient()
  - get_patient()
  - list_patients()
  - update_patient()
  - delete_patient()

Medical condition catalogue:
  - create_condition()
  - list_conditions()
  - update_condition()

Patient condition assignments:
  - assign_condition_to_patient()
  - update_patient_condition()
  - remove_patient_condition()
  - get_patient_conditions()

Appointment types:
  - create_appointment_type()
  - get_appointment_types_for_doctor()
  - update_appointment_type()
  - delete_appointment_type()

Appointment scheduling:
  - schedule_appointment()
  - get_appointment()
  - list_appointments()
  - update_appointment()
  - update_appointment_status()
  - check_doctor_availability()

Visit management:
  - start_visit()
  - get_visit()
  - record_vitals()
  - update_visit()
  - update_visit_status()
  - complete_visit()

Business rules enforced
-----------------------
- Appointments cannot be scheduled in the past.
- Doctor availability is checked against confirmed/scheduled appointments.
- Only the owning doctor (or admin) can modify appointment types.
- Assistants and doctors can create/update patients and appointments.
- Only doctors can complete visits; assistants can start/update them.
- A visit can only be created for an appointment in CONFIRMED or SCHEDULED status.
- Completing a visit also transitions the parent appointment to COMPLETED.
- A patient cannot have the same condition assigned twice.
- Deleting a patient is admin-only and permanently removes their record.

Audit events
------------
PATIENT_CREATED, PATIENT_UPDATED, PATIENT_DELETED,
APPOINTMENT_CREATED, APPOINTMENT_UPDATED, APPOINTMENT_CANCELLED,
APPOINTMENT_COMPLETED, VISIT_STARTED, VISIT_UPDATED, VISIT_COMPLETED
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from sqlalchemy import or_

from sqlalchemy.orm import Session, joinedload

from app.core.constants import (
    AppointmentStatus,
    AuditAction,
    UserRole,
    VisitStatus,
)
from app.core.exceptions import (
    BusinessRuleError,
    ConflictError,
    ForbiddenError,
    NotFoundError,
    ValidationError,
)
from app.models.clinic_models import (
    Appointment,
    AppointmentType,
    MedicalCondition,
    Patient,
    PatientCondition,
    Visit,
)
from app.models.user_models import Doctor, Assistant
from app.models.report_models import AuditLog
from app.schemas.auth_schemas import AuthenticatedUser
from app.schemas.clinic_schemas import (
    AppointmentCreate,
    AppointmentResponse,
    AppointmentStatusUpdate,
    AppointmentSummary,
    AppointmentTypeCreate,
    AppointmentTypeResponse,
    AppointmentTypeSummary,
    AppointmentTypeUpdate,
    AppointmentUpdate,
    MedicalConditionCreate,
    MedicalConditionResponse,
    MedicalConditionSummary,
    MedicalConditionUpdate,
    PatientConditionAssign,
    PatientConditionResponse,
    PatientConditionUpdate,
    PatientCreate,
    PatientResponse,
    PatientSummary,
    PatientUpdate,
    VisitCreate,
    VisitResponse,
    VisitStatusUpdate,
    VisitSummary,
    VisitUpdate,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Allowed appointment status transitions
# ---------------------------------------------------------------------------
_APPOINTMENT_TRANSITIONS: dict[AppointmentStatus, set[AppointmentStatus]] = {
    AppointmentStatus.SCHEDULED:   {AppointmentStatus.CONFIRMED, AppointmentStatus.CANCELLED, AppointmentStatus.NO_SHOW},
    AppointmentStatus.CONFIRMED:   {AppointmentStatus.IN_PROGRESS, AppointmentStatus.CANCELLED, AppointmentStatus.NO_SHOW},
    AppointmentStatus.IN_PROGRESS: {AppointmentStatus.COMPLETED, AppointmentStatus.CANCELLED},
    AppointmentStatus.COMPLETED:   set(),
    AppointmentStatus.CANCELLED:   set(),
    AppointmentStatus.NO_SHOW:     set(),
}

# Allowed visit status transitions
_VISIT_TRANSITIONS: dict[VisitStatus, set[VisitStatus]] = {
    VisitStatus.WAITING:     {VisitStatus.IN_PROGRESS, VisitStatus.CANCELLED},
    VisitStatus.IN_PROGRESS: {VisitStatus.COMPLETED, VisitStatus.CANCELLED},
    VisitStatus.COMPLETED:   set(),
    VisitStatus.CANCELLED:   set(),
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


def _is_clinic_staff(role: UserRole) -> bool:
    return role in (UserRole.DOCTOR, UserRole.ASSISTANT, UserRole.ADMIN)


def _get_patient_or_404(db: Session, patient_id: int) -> Patient:
    p = (
        db.query(Patient)
        .options(
            joinedload(Patient.patient_conditions).joinedload(PatientCondition.condition)
        )
        .filter(Patient.id == patient_id)
        .first()
    )
    if not p:
        raise NotFoundError("Patient", patient_id)
    return p


def _get_appointment_or_404(db: Session, appointment_id: int) -> Appointment:
    a = (
        db.query(Appointment)
        .options(
            joinedload(Appointment.patient),
            joinedload(Appointment.doctor),
            joinedload(Appointment.appointment_type),
        )
        .filter(Appointment.id == appointment_id)
        .first()
    )
    if not a:
        raise NotFoundError("Appointment", appointment_id)
    return a


def _get_visit_or_404(db: Session, visit_id: int) -> Visit:
    v = (
        db.query(Visit)
        .options(joinedload(Visit.appointment))
        .filter(Visit.id == visit_id)
        .first()
    )
    if not v:
        raise NotFoundError("Visit", visit_id)
    return v


def _build_patient_response(patient: Patient) -> PatientResponse:
    conditions = []
    for pc in patient.patient_conditions:
        conditions.append(PatientConditionResponse(
            id=pc.id,
            patient_id=pc.patient_id,
            diagnosed_date=pc.diagnosed_date,
            notes=pc.notes,
            condition=MedicalConditionSummary(
                id=pc.condition.id,
                name=pc.condition.name,
                category=pc.condition.category,
            ),
        ))
    return PatientResponse(
        id=patient.id,
        first_name=patient.first_name,
        last_name=patient.last_name,
        date_of_birth=patient.date_of_birth,
        gender=patient.gender,
        national_id=patient.national_id,
        phone=patient.phone,
        email=patient.email,
        address=patient.address,
        patient_conditions=conditions,
    )


def _build_appointment_response(appt: Appointment) -> AppointmentResponse:
    patient_summary = PatientSummary(
        id=appt.patient.id,
        first_name=appt.patient.first_name,
        last_name=appt.patient.last_name,
        date_of_birth=appt.patient.date_of_birth,
        phone=appt.patient.phone,
        national_id=appt.patient.national_id,
    )
    type_summary = None
    if appt.appointment_type:
        type_summary = AppointmentTypeSummary(
            id=appt.appointment_type.id,
            name=appt.appointment_type.name,
            duration_minutes=appt.appointment_type.duration_minutes,
        )
    return AppointmentResponse(
        id=appt.id,
        status=appt.status,
        start_time=appt.start_time,
        reason=appt.reason,
        is_urgent=appt.is_urgent,
        is_paid=appt.is_paid,
        fee=appt.fee,
        patient=patient_summary,
        appointment_type=type_summary,
        patient_id=appt.patient_id,
        doctor_id=appt.doctor_id,
        appointment_type_id=appt.appointment_type_id,
    )


def _build_visit_response(visit: Visit) -> VisitResponse:
    appt = visit.appointment
    appt_summary = AppointmentSummary(
        id=appt.id,
        status=appt.status,
        start_time=appt.start_time,
        patient_id=appt.patient_id,
        doctor_id=appt.doctor_id,
    )
    return VisitResponse(
        id=visit.id,
        appointment_id=visit.appointment_id,
        status=visit.status,
        chief_complaint=visit.chief_complaint,
        blood_pressure=visit.blood_pressure,
        heart_rate=visit.heart_rate,
        temperature=float(visit.temperature) if visit.temperature is not None else None,
        weight=float(visit.weight) if visit.weight is not None else None,
        height=float(visit.height) if visit.height is not None else None,
        notes=visit.notes,
        start_time=visit.start_time,
        end_time=visit.end_time,
        appointment=appt_summary,
    )

def _resolve_doctor_id(db: Session, current_user: User) -> int | None:
    """
    Returns the doctor_id that should own a new patient.
    - If the caller IS a doctor  → use their own doctor.id
    - If the caller is assistant → find the doctor by matching clinic_name
    - If admin                   → no ownership, return None
    """
    if current_user.role == UserRole.DOCTOR:
        doctor = db.query(Doctor).filter(
            Doctor.user_id == current_user.id
        ).first()
        return doctor.id if doctor else None

    elif current_user.role == UserRole.ASSISTANT:
        assistant = db.query(Assistant).filter(
            Assistant.user_id == current_user.id
        ).first()
        if assistant and assistant.clinic_name:
            # Find the doctor who owns this clinic
            doctor = db.query(Doctor).filter(
                Doctor.clinic_name == assistant.clinic_name
            ).first()
            return doctor.id if doctor else None

    return None  # Admin creates unowned patients

# ===========================================================================
# PATIENT MANAGEMENT
# ===========================================================================

def create_patient(
    db: Session,
    current_user: AuthenticatedUser,
    data: PatientCreate,
) -> PatientResponse:
    """
    Register a new patient.

    Raises
    ------
    ForbiddenError  : caller is not clinic staff.
    ConflictError   : national_id already registered.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can register patients.")

    if data.national_id:
        existing = db.query(Patient).filter(Patient.national_id == data.national_id).first()
        if existing:
            raise ConflictError(
                f"A patient with national ID '{data.national_id}' is already registered "
                f"(Patient #{existing.id}: {existing.first_name} {existing.last_name})."
            )
    # Secondary check when no national_id provided
    if not data.national_id and data.date_of_birth:
        existing = db.query(Patient).filter(
            Patient.first_name.ilike(data.first_name),
            Patient.last_name.ilike(data.last_name),
            Patient.date_of_birth == data.date_of_birth,
        ).first()
        if existing:
            raise ConflictError(
                f"A patient with the same name and date of birth "
                f"already exists (Patient ID: {existing.id})."
            )

    # 1. Resolve the doctor_id based on the current user
    doctor_id = _resolve_doctor_id(db, current_user)

    # 2. Create the Patient object
    # We use model_dump() for brevity, but handle email conversion and doctor_id explicitly.
    patient = Patient(
        **data.model_dump(),
        doctor_id=doctor_id,  # Added as requested
    )
    
    db.add(patient)
    db.flush()

    _write_audit(db, current_user.id, AuditAction.PATIENT_CREATED, "patient", patient.id,
                 {"name": f"{data.first_name} {data.last_name}"})
    db.commit()
    db.refresh(patient)

    # Reload with relationships
    return _build_patient_response(_get_patient_or_404(db, patient.id))


def get_patient(db: Session, patient_id: int) -> PatientResponse:
    """Fetch a patient with their assigned conditions."""
    return _build_patient_response(_get_patient_or_404(db, patient_id))


def list_patients(
    db: Session,
    current_user: User,
    search: str | None = None,
    skip: int = 0,
    limit: int = 20,
) -> tuple[list[PatientResponse], int]:

    q = db.query(Patient)

    # ── OWNERSHIP FILTER ──────────────────────────────────
    if current_user.role == UserRole.DOCTOR:
        doctor = db.query(Doctor).filter(
            Doctor.user_id == current_user.id
        ).first()
        if doctor:
            q = q.filter(Patient.doctor_id == doctor.id)

    elif current_user.role == UserRole.ASSISTANT:
        assistant = db.query(Assistant).filter(
            Assistant.user_id == current_user.id
        ).first()
        if assistant and assistant.clinic_name:
            doctor = db.query(Doctor).filter(
                Doctor.clinic_name == assistant.clinic_name
            ).first()
            if doctor:
                q = q.filter(Patient.doctor_id == doctor.id)
    # Admin: no filter → sees all patients
    # ─────────────────────────────────────────────────────

    if search:
        q = q.filter(
            or_(
                Patient.first_name.ilike(f"%{search}%"),
                Patient.last_name.ilike(f"%{search}%"),
                Patient.phone.ilike(f"%{search}%"),
                Patient.national_id.ilike(f"%{search}%"),
            )
        )

    total = q.count()
    patients = q.offset(skip).limit(limit).all()
    return [PatientResponse.model_validate(p) for p in patients], total


def update_patient(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int,
    data: PatientUpdate,
) -> PatientResponse:
    """
    Update patient demographic fields.

    Raises
    ------
    ForbiddenError : caller is not clinic staff.
    NotFoundError  : patient not found.
    ConflictError  : new national_id clashes with another patient.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update patient records.")

    patient = _get_patient_or_404(db, patient_id)

    if data.national_id and data.national_id != patient.national_id:
        existing = db.query(Patient).filter(
            Patient.national_id == data.national_id,
            Patient.id != patient_id,
        ).first()
        if existing:
            raise ConflictError(f"National ID '{data.national_id}' is already assigned to another patient.")

    changed: dict = {}
    for field, value in data.model_dump(exclude_none=True).items():
        current_val = getattr(patient, field)
        str_value = str(value) if value is not None else None
        if current_val != str_value and current_val != value:
            setattr(patient, field, str_value if field == "email" else value)
            changed[field] = str(value)

    if changed:
        db.add(patient)
        _write_audit(db, current_user.id, AuditAction.PATIENT_UPDATED, "patient", patient_id, changed)
        db.commit()
        db.refresh(patient)

    return _build_patient_response(_get_patient_or_404(db, patient_id))


def delete_patient(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int,
) -> None:
    """
    Permanently delete a patient and all associated data. Admin only.

    Raises
    ------
    ForbiddenError : caller is not an admin.
    NotFoundError  : patient not found.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can permanently delete patient records.")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise NotFoundError("Patient", patient_id)

    _write_audit(db, current_user.id, AuditAction.PATIENT_DELETED, "patient", patient_id,
                 {"name": f"{patient.first_name} {patient.last_name}"})
    db.delete(patient)
    db.commit()
    logger.info("Patient %d deleted by admin %d.", patient_id, current_user.id)


# ===========================================================================
# MEDICAL CONDITIONS CATALOGUE
# ===========================================================================

def create_condition(
    db: Session,
    current_user: AuthenticatedUser,
    data: MedicalConditionCreate,
) -> MedicalConditionResponse:
    """Add a new condition to the reference catalogue. Admin only."""
    if current_user.role not in (UserRole.ADMIN, UserRole.DOCTOR):
        raise ForbiddenError("Only doctors or administrators can manage the medical conditions catalogue.")

    existing = db.query(MedicalCondition).filter(MedicalCondition.name == data.name).first()
    if existing:
        raise ConflictError(f"A condition named '{data.name}' already exists.")

    condition = MedicalCondition(
        name=data.name,
        category=data.category,
        description=data.description,
    )
    db.add(condition)
    db.commit()
    db.refresh(condition)

    return MedicalConditionResponse(
        id=condition.id,
        name=condition.name,
        category=condition.category,
        description=condition.description,
    )


def list_conditions(
    db: Session,
    search: str | None = None,
    offset: int = 0,
    limit: int = 100,
) -> tuple[list[MedicalConditionResponse], int]:
    """Paginated list of all medical conditions. Available to all staff."""
    q = db.query(MedicalCondition)
    if search:
        q = q.filter(MedicalCondition.name.ilike(f"%{search}%"))

    total = q.count()
    items = q.order_by(MedicalCondition.name).offset(offset).limit(limit).all()
    return [
        MedicalConditionResponse(id=c.id, name=c.name, category=c.category, description=c.description)
        for c in items
    ], total


def update_condition(
    db: Session,
    current_user: AuthenticatedUser,
    condition_id: int,
    data: MedicalConditionUpdate,
) -> MedicalConditionResponse:
    """Update a catalogue condition. Admin only."""
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can update medical conditions.")

    condition = db.query(MedicalCondition).filter(MedicalCondition.id == condition_id).first()
    if not condition:
        raise NotFoundError("MedicalCondition", condition_id)

    if data.name and data.name != condition.name:
        clash = db.query(MedicalCondition).filter(
            MedicalCondition.name == data.name,
            MedicalCondition.id != condition_id,
        ).first()
        if clash:
            raise ConflictError(f"A condition named '{data.name}' already exists.")

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(condition, field, value)

    db.add(condition)
    db.commit()
    db.refresh(condition)

    return MedicalConditionResponse(
        id=condition.id, name=condition.name,
        category=condition.category, description=condition.description,
    )


# ===========================================================================
# PATIENT CONDITIONS (assignments)
# ===========================================================================

def assign_condition_to_patient(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int,
    data: PatientConditionAssign,
) -> PatientConditionResponse:
    """
    Assign a catalogue condition to a patient.

    Raises
    ------
    NotFoundError  : patient or condition not found.
    ConflictError  : condition already assigned to this patient.
    ForbiddenError : caller is not clinic staff.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can assign conditions to patients.")

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise NotFoundError("Patient", patient_id)

    condition = db.query(MedicalCondition).filter(MedicalCondition.id == data.condition_id).first()
    if not condition:
        raise NotFoundError("MedicalCondition", data.condition_id)

    existing = db.query(PatientCondition).filter(
        PatientCondition.patient_id == patient_id,
        PatientCondition.condition_id == data.condition_id,
    ).first()
    if existing:
        raise ConflictError(
            f"Condition '{condition.name}' is already assigned to this patient."
        )

    pc = PatientCondition(
        patient_id=patient_id,
        condition_id=data.condition_id,
        diagnosed_date=data.diagnosed_date,
        notes=data.notes,
    )
    db.add(pc)
    db.commit()
    db.refresh(pc)

    return PatientConditionResponse(
        id=pc.id,
        patient_id=pc.patient_id,
        diagnosed_date=pc.diagnosed_date,
        notes=pc.notes,
        condition=MedicalConditionSummary(
            id=condition.id, name=condition.name, category=condition.category
        ),
    )


def update_patient_condition(
    db: Session,
    current_user: AuthenticatedUser,
    patient_condition_id: int,
    data: PatientConditionUpdate,
) -> PatientConditionResponse:
    """Update notes or diagnosed_date on an existing patient-condition assignment."""
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update patient conditions.")

    pc = db.query(PatientCondition).filter(PatientCondition.id == patient_condition_id).first()
    if not pc:
        raise NotFoundError("PatientCondition", patient_condition_id)

    if data.diagnosed_date is not None:
        pc.diagnosed_date = data.diagnosed_date
    if data.notes is not None:
        pc.notes = data.notes

    db.add(pc)
    db.commit()
    db.refresh(pc)

    condition = db.query(MedicalCondition).filter(MedicalCondition.id == pc.condition_id).first()
    return PatientConditionResponse(
        id=pc.id,
        patient_id=pc.patient_id,
        diagnosed_date=pc.diagnosed_date,
        notes=pc.notes,
        condition=MedicalConditionSummary(
            id=condition.id, name=condition.name, category=condition.category
        ),
    )


def remove_patient_condition(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int,
    condition_id: int,
) -> None:
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can remove patient conditions.")

    pc = db.query(PatientCondition).filter(
        PatientCondition.patient_id == patient_id,
        PatientCondition.condition_id == condition_id,
    ).first()

    if not pc:
        raise NotFoundError("PatientCondition", condition_id)

    db.delete(pc)
    db.commit()


def get_patient_conditions(db: Session, patient_id: int) -> list[PatientConditionResponse]:
    """Return all conditions assigned to a patient."""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise NotFoundError("Patient", patient_id)

    pcs = (
        db.query(PatientCondition)
        .options(joinedload(PatientCondition.condition))
        .filter(PatientCondition.patient_id == patient_id)
        .all()
    )
    return [
        PatientConditionResponse(
            id=pc.id,
            patient_id=pc.patient_id,
            diagnosed_date=pc.diagnosed_date,
            notes=pc.notes,
            condition=MedicalConditionSummary(
                id=pc.condition.id,
                name=pc.condition.name,
                category=pc.condition.category,
            ),
        )
        for pc in pcs
    ]


# ===========================================================================
# APPOINTMENT TYPES
# ===========================================================================

def create_appointment_type(
    db: Session,
    current_user: AuthenticatedUser,
    doctor_id: int,
    data: AppointmentTypeCreate,
) -> AppointmentTypeResponse:
    """
    Create an appointment type for a specific doctor.
    Only the doctor themselves or an admin can define their types.
    """
    from app.models.user_models import Doctor

    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise NotFoundError("Doctor", doctor_id)

    is_own = (current_user.role == UserRole.DOCTOR and doctor.user_id == current_user.id)
    if not (is_own or current_user.role == UserRole.ADMIN):
        raise ForbiddenError("Only the owning doctor or an admin can manage appointment types.")

    apt_type = AppointmentType(
        doctor_id=doctor_id,
        name=data.name,
        description=data.description,
        duration_minutes=data.duration_minutes,
        default_fee=data.default_fee,
    )
    db.add(apt_type)
    db.commit()
    db.refresh(apt_type)

    return AppointmentTypeResponse(
        id=apt_type.id,
        doctor_id=apt_type.doctor_id,
        name=apt_type.name,
        description=apt_type.description,
        duration_minutes=apt_type.duration_minutes,
        default_fee=apt_type.default_fee,
    )


def list_appointment_types(
    db: Session,
    doctor_id: int,
) -> list[AppointmentTypeResponse]:
    """Return all appointment types defined by a doctor."""
    from app.models.user_models import Doctor
    if not db.query(Doctor).filter(Doctor.id == doctor_id).first():
        raise NotFoundError("Doctor", doctor_id)

    types = db.query(AppointmentType).filter(AppointmentType.doctor_id == doctor_id).all()
    return [
        AppointmentTypeResponse(
            id=t.id, doctor_id=t.doctor_id, name=t.name,
            description=t.description, duration_minutes=t.duration_minutes,
            default_fee=t.default_fee,
        )
        for t in types
    ]


def update_appointment_type(
    db: Session,
    current_user: AuthenticatedUser,
    type_id: int,
    data: AppointmentTypeUpdate,
) -> AppointmentTypeResponse:
    """Update an appointment type. Doctor-owner or admin only."""
    apt_type = db.query(AppointmentType).filter(AppointmentType.id == type_id).first()
    if not apt_type:
        raise NotFoundError("AppointmentType", type_id)

    from app.models.user_models import Doctor
    doctor = db.query(Doctor).filter(Doctor.id == apt_type.doctor_id).first()
    is_own = (current_user.role == UserRole.DOCTOR and doctor and doctor.user_id == current_user.id)

    if not (is_own or current_user.role == UserRole.ADMIN):
        raise ForbiddenError("Only the owning doctor or an admin can update appointment types.")

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(apt_type, field, value)

    db.add(apt_type)
    db.commit()
    db.refresh(apt_type)

    return AppointmentTypeResponse(
        id=apt_type.id, doctor_id=apt_type.doctor_id, name=apt_type.name,
        description=apt_type.description, duration_minutes=apt_type.duration_minutes,
        default_fee=apt_type.default_fee,
    )


def delete_appointment_type(
    db: Session,
    current_user: AuthenticatedUser,
    type_id: int,
) -> None:
    """Delete an appointment type. Doctor-owner or admin only."""
    apt_type = db.query(AppointmentType).filter(AppointmentType.id == type_id).first()
    if not apt_type:
        raise NotFoundError("AppointmentType", type_id)

    from app.models.user_models import Doctor
    doctor = db.query(Doctor).filter(Doctor.id == apt_type.doctor_id).first()
    is_own = (current_user.role == UserRole.DOCTOR and doctor and doctor.user_id == current_user.id)

    if not (is_own or current_user.role == UserRole.ADMIN):
        raise ForbiddenError("Only the owning doctor or an admin can delete appointment types.")

    db.delete(apt_type)
    db.commit()


# ===========================================================================
# APPOINTMENT SCHEDULING
# ===========================================================================

def check_doctor_availability(
    db: Session,
    doctor_id: int,
    start_time: datetime,
    duration_minutes: int = 30,
    exclude_appointment_id: int | None = None,
) -> bool:
    """
    Return True if the doctor has no overlapping confirmed/scheduled
    appointment at the requested time window.

    Overlap check: any existing appointment whose start_time falls within
    [start_time, start_time + duration_minutes) is considered a conflict.
    In v1 we use a simple time-window overlap; a production hardening step
    would use a proper interval check with appointment end times.
    """
    from datetime import timedelta

    end_time = start_time + timedelta(minutes=duration_minutes)

    conflict_statuses = [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED, AppointmentStatus.IN_PROGRESS]

    q = db.query(Appointment).filter(
        Appointment.doctor_id == doctor_id,
        Appointment.status.in_(conflict_statuses),
        Appointment.start_time < end_time,
        Appointment.start_time >= start_time,
    )
    if exclude_appointment_id:
        q = q.filter(Appointment.id != exclude_appointment_id)

    return q.first() is None


def schedule_appointment(
    db: Session,
    current_user: AuthenticatedUser,
    data: AppointmentCreate,
) -> AppointmentResponse:
    """
    Schedule a new appointment.

    Business rules:
    - start_time must be in the future.
    - Doctor must exist and be active.
    - Patient must exist.
    - appointment_type_id must belong to the specified doctor (if provided).
    - Doctor must be available (no overlapping confirmed/scheduled appointments).
    - fee defaults to appointment_type.default_fee if not provided.

    Raises
    ------
    ForbiddenError     : caller is not clinic staff.
    NotFoundError      : patient, doctor, or appointment type not found.
    ValidationError    : start_time is in the past.
    BusinessRuleError  : doctor is unavailable or appointment type belongs to wrong doctor.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can schedule appointments.")

    now = datetime.now(timezone.utc)
    if data.start_time.replace(tzinfo=timezone.utc) < now:
        raise ValidationError("Appointment start_time must be in the future.", field="start_time")

    # Validate patient
    patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
    if not patient:
        raise NotFoundError("Patient", data.patient_id)

    # Validate doctor (must exist and be active)
    from app.models.user_models import Doctor, User
    doctor = (
        db.query(Doctor)
        .join(User, Doctor.user_id == User.id)
        .filter(Doctor.id == data.doctor_id, User.is_active == True)  # noqa: E712
        .first()
    )
    if not doctor:
        raise NotFoundError("Active Doctor", data.doctor_id)

    # Validate appointment type belongs to this doctor
    fee = data.fee
    duration = 30  # default overlap check window
    apt_type = None

    if data.appointment_type_id:
        apt_type = db.query(AppointmentType).filter(AppointmentType.id == data.appointment_type_id).first()
        if not apt_type:
            raise NotFoundError("AppointmentType", data.appointment_type_id)
        if apt_type.doctor_id != data.doctor_id:
            raise BusinessRuleError(
                f"AppointmentType #{data.appointment_type_id} does not belong to Doctor #{data.doctor_id}."
            )
        if fee is None and apt_type.default_fee is not None:
            fee = apt_type.default_fee
        if apt_type.duration_minutes:
            duration = apt_type.duration_minutes

    # Check availability
    if not check_doctor_availability(db, data.doctor_id, data.start_time, duration):
        raise BusinessRuleError(
            f"Doctor #{data.doctor_id} is not available at {data.start_time.isoformat()}. "
            "Please choose a different time."
        )

    appointment = Appointment(
        patient_id=data.patient_id,
        doctor_id=data.doctor_id,
        appointment_type_id=data.appointment_type_id,
        start_time=data.start_time,
        status=AppointmentStatus.SCHEDULED,
        reason=data.reason,
        is_urgent=data.is_urgent,
        is_paid=data.is_paid,
        fee=fee,
    )
    db.add(appointment)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.APPOINTMENT_CREATED, "appointment", appointment.id,
        {"patient_id": data.patient_id, "doctor_id": data.doctor_id, "start_time": str(data.start_time)},
    )
    db.commit()

    return _build_appointment_response(_get_appointment_or_404(db, appointment.id))


def get_appointment(db: Session, appointment_id: int) -> AppointmentResponse:
    return _build_appointment_response(_get_appointment_or_404(db, appointment_id))


def list_appointments(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int | None = None,
    doctor_id: int | None = None,
    status: AppointmentStatus | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    offset: int = 0,
    limit: int = 20,
) -> tuple[list[AppointmentResponse], int]:
    """Paginated appointment list with optional filters."""
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can view appointments.")

    q = db.query(Appointment).options(
        joinedload(Appointment.patient),
        joinedload(Appointment.doctor),
        joinedload(Appointment.appointment_type),
    )

    if patient_id:
        q = q.filter(Appointment.patient_id == patient_id)
    if doctor_id:
        q = q.filter(Appointment.doctor_id == doctor_id)
    if status:
        q = q.filter(Appointment.status == status)

    # Doctors only see their own appointments
    if current_user.role == UserRole.DOCTOR:
        from app.models.user_models import Doctor
        doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
        if doctor:
            q = q.filter(Appointment.doctor_id == doctor.id)
    if date_from:
        q = q.filter(Appointment.start_time >= date_from)
    if date_to:
        q = q.filter(Appointment.start_time <= date_to)

    total = q.count()
    appts = q.order_by(Appointment.start_time.desc()).offset(offset).limit(limit).all()
    return [_build_appointment_response(a) for a in appts], total


def update_appointment(
    db: Session,
    current_user: AuthenticatedUser,
    appointment_id: int,
    data: AppointmentUpdate,
) -> AppointmentResponse:
    """
    Update mutable appointment fields (time, reason, fee, urgency).
    Only allowed for SCHEDULED or CONFIRMED appointments.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update appointments.")

    appt = _get_appointment_or_404(db, appointment_id)

    if appt.status not in (AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED):
        raise BusinessRuleError(
            f"Cannot update appointment in status '{appt.status.value}'. "
            "Only SCHEDULED or CONFIRMED appointments can be modified."
        )

    if data.start_time is not None:
        now = datetime.now(timezone.utc)
        if data.start_time.replace(tzinfo=timezone.utc) < now:
            raise ValidationError("Appointment start_time must be in the future.", field="start_time")

        duration = 30
        if appt.appointment_type and appt.appointment_type.duration_minutes:
            duration = appt.appointment_type.duration_minutes

        if not check_doctor_availability(db, appt.doctor_id, data.start_time, duration, exclude_appointment_id=appointment_id):
            raise BusinessRuleError(
                f"Doctor #{appt.doctor_id} is not available at {data.start_time.isoformat()}."
            )
        appt.start_time = data.start_time

    changed: dict = {}
    for field in ("reason", "is_urgent", "is_paid", "fee"):
        value = getattr(data, field, None)
        if value is not None and getattr(appt, field) != value:
            setattr(appt, field, value)
            changed[field] = str(value)

    if data.appointment_type_id is not None:
        apt_type = db.query(AppointmentType).filter(AppointmentType.id == data.appointment_type_id).first()
        if not apt_type or apt_type.doctor_id != appt.doctor_id:
            raise BusinessRuleError("AppointmentType does not belong to this appointment's doctor.")
        appt.appointment_type_id = data.appointment_type_id
        changed["appointment_type_id"] = str(data.appointment_type_id)

    if changed:
        db.add(appt)
        _write_audit(db, current_user.id, AuditAction.APPOINTMENT_UPDATED, "appointment", appointment_id, changed)
        db.commit()

    return _build_appointment_response(_get_appointment_or_404(db, appointment_id))


def update_appointment_status(
    db: Session,
    current_user: AuthenticatedUser,
    appointment_id: int,
    data: AppointmentStatusUpdate,
) -> AppointmentResponse:
    """
    Transition an appointment to a new status following allowed transitions.

    Raises
    ------
    BusinessRuleError : invalid status transition.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update appointment status.")

    appt = _get_appointment_or_404(db, appointment_id)
    allowed = _APPOINTMENT_TRANSITIONS.get(appt.status, set())

    if data.status not in allowed:
        raise BusinessRuleError(
            f"Cannot transition appointment from '{appt.status.value}' to '{data.status.value}'. "
            f"Allowed transitions: {[s.value for s in allowed] or 'none (terminal state)'}."
        )

    old_status = appt.status
    appt.status = data.status
    db.add(appt)

    action = AuditAction.APPOINTMENT_CANCELLED if data.status == AppointmentStatus.CANCELLED \
        else AuditAction.APPOINTMENT_COMPLETED if data.status == AppointmentStatus.COMPLETED \
        else AuditAction.APPOINTMENT_UPDATED

    _write_audit(
        db, current_user.id, action, "appointment", appointment_id,
        {"from": old_status.value, "to": data.status.value},
    )
    db.commit()

    return _build_appointment_response(_get_appointment_or_404(db, appointment_id))


# ===========================================================================
# VISIT MANAGEMENT
# ===========================================================================

def start_visit(
    db: Session,
    current_user: AuthenticatedUser,
    data: VisitCreate,
) -> VisitResponse:
    """
    Create a visit record when a patient is checked in.

    Business rules:
    - Appointment must be SCHEDULED or CONFIRMED to check in.
    - Appointment cannot already have a visit.
    - Starting a visit auto-transitions the appointment to IN_PROGRESS.

    Raises
    ------
    NotFoundError     : appointment not found.
    BusinessRuleError : appointment status doesn't allow check-in.
    ConflictError     : appointment already has a visit.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can start a visit.")

    appt = _get_appointment_or_404(db, data.appointment_id)

    if appt.status not in (AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED):
        raise BusinessRuleError(
            f"Cannot start a visit for appointment in status '{appt.status.value}'. "
            "Appointment must be SCHEDULED or CONFIRMED."
        )

    existing_visit = db.query(Visit).filter(Visit.appointment_id == data.appointment_id).first()
    if existing_visit:
        raise ConflictError(f"Appointment #{data.appointment_id} already has a visit (Visit #{existing_visit.id}).")

    visit = Visit(
        appointment_id=data.appointment_id,
        chief_complaint=data.chief_complaint,
        blood_pressure=data.blood_pressure,
        heart_rate=data.heart_rate,
        temperature=data.temperature,
        weight=data.weight,
        height=data.height,
        notes=data.notes,
        status=VisitStatus.WAITING,
        start_time=datetime.now(timezone.utc),
    )
    db.add(visit)
    db.flush()

    # Transition appointment → IN_PROGRESS
    appt.status = AppointmentStatus.IN_PROGRESS
    db.add(appt)

    _write_audit(
        db, current_user.id, AuditAction.VISIT_STARTED, "visit", visit.id,
        {"appointment_id": data.appointment_id},
    )
    db.commit()

    return _build_visit_response(_get_visit_or_404(db, visit.id))


def get_visit(db: Session, visit_id: int) -> VisitResponse:
    """Fetch a visit with its parent appointment."""
    return _build_visit_response(_get_visit_or_404(db, visit_id))


def list_visits(
    db: Session,
    current_user: AuthenticatedUser,
    patient_id: int | None = None,
    doctor_id: int | None = None,
    status: VisitStatus | None = None,
    offset: int = 0,
    limit: int = 20,
) -> tuple[list[VisitResponse], int]:
    """Paginated visit list with optional filters."""
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can view visits.")

    q = db.query(Visit).options(joinedload(Visit.appointment))  # ✅ essential

    if status:
        q = q.filter(Visit.status == status)

    # Filter by patient or doctor — must join through Appointment
    if patient_id or doctor_id or current_user.role == UserRole.DOCTOR:
        q = q.join(Appointment)

        if patient_id:
            q = q.filter(Appointment.patient_id == patient_id)
        if doctor_id:
            q = q.filter(Appointment.doctor_id == doctor_id)

        # Doctors only see their own visits
        if current_user.role == UserRole.DOCTOR:
            from app.models.user_models import Doctor
            doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
            if doctor:
                q = q.filter(Appointment.doctor_id == doctor.id)

    total = q.count()
    visits = q.order_by(Visit.start_time.desc()).offset(offset).limit(limit).all()
    return [_build_visit_response(v) for v in visits], total


def get_visit_by_appointment(db: Session, appointment_id: int) -> VisitResponse:
    """Fetch the visit for a specific appointment."""
    visit = (
        db.query(Visit)
        .options(joinedload(Visit.appointment))
        .filter(Visit.appointment_id == appointment_id)
        .first()
    )
    if not visit:
        raise NotFoundError("Visit for appointment", appointment_id)
    return _build_visit_response(visit)


def record_vitals(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    data: VisitUpdate,
) -> VisitResponse:
    """
    Record or update clinical vitals for an active visit.
    Alias for update_visit — provided as a named use case for clarity.
    Only allowed for WAITING or IN_PROGRESS visits.
    """
    return update_visit(db, current_user, visit_id, data)


def update_visit(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    data: VisitUpdate,
) -> VisitResponse:
    """
    Update visit fields (vitals, notes, chief complaint).
    Only allowed while visit is WAITING or IN_PROGRESS.

    Raises
    ------
    BusinessRuleError : visit is in a terminal state.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update visit records.")

    visit = _get_visit_or_404(db, visit_id)

    if visit.status in (VisitStatus.COMPLETED, VisitStatus.CANCELLED):
        raise BusinessRuleError(
            f"Cannot update a visit in status '{visit.status.value}'. Visit is in a terminal state."
        )

    changed: dict = {}
    for field, value in data.model_dump(exclude_none=True).items():
        if getattr(visit, field) != value:
            setattr(visit, field, value)
            changed[field] = str(value)

    if changed:
        db.add(visit)
        _write_audit(db, current_user.id, AuditAction.VISIT_UPDATED, "visit", visit_id, changed)
        db.commit()

    return _build_visit_response(_get_visit_or_404(db, visit_id))


def update_visit_status(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
    data: VisitStatusUpdate,
) -> VisitResponse:
    """
    Transition a visit to a new status.

    Business rules:
    - Status must follow allowed transitions.
    - Only doctors can COMPLETE a visit.
    - Completing a visit also marks the parent appointment as COMPLETED.
    """
    if not _is_clinic_staff(current_user.role):
        raise ForbiddenError("Only clinic staff can update visit status.")

    if data.status == VisitStatus.COMPLETED and current_user.role != UserRole.DOCTOR:
        raise ForbiddenError("Only doctors can mark a visit as completed.")

    visit = _get_visit_or_404(db, visit_id)
    allowed = _VISIT_TRANSITIONS.get(visit.status, set())

    if data.status not in allowed:
        raise BusinessRuleError(
            f"Cannot transition visit from '{visit.status.value}' to '{data.status.value}'. "
            f"Allowed: {[s.value for s in allowed] or 'none (terminal state)'}."
        )

    old_status = visit.status
    visit.status = data.status

    if data.status == VisitStatus.COMPLETED:
        visit.end_time = datetime.now(timezone.utc)
        # Cascade completion to appointment
        appt = _get_appointment_or_404(db, visit.appointment_id)
        appt.status = AppointmentStatus.COMPLETED
        db.add(appt)

    db.add(visit)
    action = AuditAction.VISIT_COMPLETED if data.status == VisitStatus.COMPLETED else AuditAction.VISIT_UPDATED
    _write_audit(
        db, current_user.id, action, "visit", visit_id,
        {"from": old_status.value, "to": data.status.value},
    )
    db.commit()

    return _build_visit_response(_get_visit_or_404(db, visit_id))


def complete_visit(
    db: Session,
    current_user: AuthenticatedUser,
    visit_id: int,
) -> VisitResponse:
    """
    Convenience method: complete a visit in a single call.
    Equivalent to update_visit_status(... COMPLETED).
    Doctors only.
    """
    return update_visit_status(
        db, current_user, visit_id,
        VisitStatusUpdate(status=VisitStatus.COMPLETED),
    )