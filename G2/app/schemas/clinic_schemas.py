"""
app/schemas/clinic_schemas.py

Request and response schemas for all operational clinic workflows.

Covers:
- MedicalCondition  (reference data)
- Patient           (demographic registration)
- PatientCondition  (chronic condition assignment)
- AppointmentType   (doctor-defined consultation categories)
- Appointment       (booking)
- Visit             (clinical encounter + vitals)

Nesting strategy
----------------
Response schemas embed related objects as Summary types (id + display fields).
This avoids circular references and keeps serialization depth at 1.

Example depth:
    AppointmentResponse
        └─ patient:    PatientSummary        (id, full_name, dob, phone)
        └─ doctor:     DoctorSummary         (id, name, specialization)
        └─ apt_type:   AppointmentTypeSummary (id, name, duration_minutes)

Vitals validation
-----------------
heart_rate:  1–300 bpm
temperature: 30.0–45.0 °C
weight:      1.0–500.0 kg
height:      30.0–300.0 cm
"""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Annotated

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.constants import (
    AppointmentStatus,
    ConditionCategory,
    Gender,
    VisitStatus,
)


# ===========================================================================
# MEDICAL CONDITION
# ===========================================================================

class MedicalConditionCreate(BaseModel):
    """
    Payload for POST /conditions  (admin only).
    Adds an entry to the canonical condition catalogue.
    """

    model_config = ConfigDict(from_attributes=True)

    name: str = Field(
        max_length=200,
        description="Standardised condition name (e.g. 'Type 2 Diabetes Mellitus').",
    )
    category:    ConditionCategory | None = None
    description: str | None = None


class MedicalConditionUpdate(BaseModel):
    """Payload for PATCH /conditions/{id}. All fields optional."""

    model_config = ConfigDict(from_attributes=True)

    name:        str | None = Field(default=None, max_length=200)
    category:    ConditionCategory | None = None
    description: str | None = None


class MedicalConditionResponse(BaseModel):
    """Full condition entry as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id:          int
    name:        str
    category:    ConditionCategory | None
    description: str | None


class MedicalConditionSummary(BaseModel):
    """
    Compact representation for embedding inside PatientConditionResponse.
    """

    model_config = ConfigDict(from_attributes=True)

    id:       int
    name:     str
    category: ConditionCategory | None


# ===========================================================================
# PATIENT
# ===========================================================================

class PatientCreate(BaseModel):
    """
    Payload for POST /patients  (assistant or doctor).
    first_name and last_name are required — all other fields are optional
    to accommodate incomplete registration at walk-in.
    """

    model_config = ConfigDict(from_attributes=True)

    first_name: str = Field(max_length=100)
    last_name:  str = Field(max_length=100)

    date_of_birth: date | None = None
    gender:        Gender | None = None

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


class PatientUpdate(BaseModel):
    """Payload for PATCH /patients/{id}. All fields optional."""

    model_config = ConfigDict(from_attributes=True)

    first_name:    str | None = Field(default=None, max_length=100)
    last_name:     str | None = Field(default=None, max_length=100)
    date_of_birth: date | None = None
    gender:        Gender | None = None
    national_id:   str | None = Field(default=None, max_length=50)
    phone:         str | None = Field(default=None, max_length=30)
    email:         EmailStr | None = None
    address:       str | None = None


class PatientResponse(BaseModel):
    """
    Full patient record as returned to clients.
    Includes the list of diagnosed conditions as PatientConditionResponse
    objects (shallow — each contains a MedicalConditionSummary, not the
    full condition object with all its relationships).
    """

    model_config = ConfigDict(from_attributes=True)

    id:            int
    first_name:    str
    last_name:     str
    date_of_birth: date | None
    gender:        Gender | None
    national_id:   str | None
    phone:         str | None
    email:         str | None
    address:       str | None

    # Shallow list of assigned conditions
    patient_conditions: list["PatientConditionResponse"] = []


class PatientSummary(BaseModel):
    """
    Compact patient representation for embedding inside Appointment
    and Visit responses. Contains only fields needed for display.
    """

    model_config = ConfigDict(from_attributes=True)

    id:            int
    first_name:    str
    last_name:     str
    date_of_birth: date | None
    phone:         str | None
    national_id:   str | None


# ===========================================================================
# PATIENT CONDITION  (association: patient ↔ medical_condition)
# ===========================================================================

class PatientConditionAssign(BaseModel):
    """
    Payload for POST /patients/{patient_id}/conditions.
    Links a patient to an existing condition from the catalogue.
    """

    model_config = ConfigDict(from_attributes=True)

    condition_id:   int = Field(description="PK of the MedicalCondition to assign.")
    diagnosed_date: date | None = Field(
        default=None,
        description="Date the condition was first diagnosed. Optional.",
    )
    notes: str | None = Field(
        default=None,
        description="Free-text context: severity, treatment stage, etc.",
    )


class PatientConditionUpdate(BaseModel):
    """
    Payload for PATCH /patients/{patient_id}/conditions/{id}.
    Used to update the diagnosed_date or notes on an existing assignment.
    condition_id is not updatable — delete and re-assign instead.
    """

    model_config = ConfigDict(from_attributes=True)

    diagnosed_date: date | None = None
    notes:          str | None = None


class PatientConditionResponse(BaseModel):
    """
    A single patient-condition assignment with the condition embedded as a
    shallow MedicalConditionSummary. No circular back-references.
    """

    model_config = ConfigDict(from_attributes=True)

    id:             int
    patient_id:     int
    diagnosed_date: date | None
    notes:          str | None

    # Shallow embed of the condition details
    condition: MedicalConditionSummary


# ===========================================================================
# APPOINTMENT TYPE
# ===========================================================================

class AppointmentTypeCreate(BaseModel):
    """
    Payload for POST /doctors/{doctor_id}/appointment-types.
    Only the owning doctor (or an admin) can create types.
    """

    model_config = ConfigDict(from_attributes=True)

    name: str = Field(
        max_length=150,
        description="Human-readable label shown in the booking UI.",
        examples=["Initial Consultation", "Follow-up", "Procedure"],
    )
    description:      str | None = None
    duration_minutes: int | None = Field(
        default=None,
        ge=1,
        le=480,
        description="Expected duration in minutes. Max 8 hours.",
    )
    default_fee: Decimal | None = Field(
        default=None,
        ge=0,
        description="Default fee in local currency. Overridable per appointment.",
    )


class AppointmentTypeUpdate(BaseModel):
    """Payload for PATCH /appointment-types/{id}. All fields optional."""

    model_config = ConfigDict(from_attributes=True)

    name:             str | None = Field(default=None, max_length=150)
    description:      str | None = None
    duration_minutes: int | None = Field(default=None, ge=1, le=480)
    default_fee:      Decimal | None = Field(default=None, ge=0)


class AppointmentTypeResponse(BaseModel):
    """Full appointment type as returned to clients."""

    model_config = ConfigDict(from_attributes=True)

    id:               int
    doctor_id:        int
    name:             str
    description:      str | None
    duration_minutes: int | None
    default_fee:      Decimal | None


class AppointmentTypeSummary(BaseModel):
    """
    Compact appointment type for embedding inside AppointmentResponse.
    """

    model_config = ConfigDict(from_attributes=True)

    id:               int
    name:             str
    duration_minutes: int | None


# ===========================================================================
# APPOINTMENT
# ===========================================================================

class AppointmentCreate(BaseModel):
    """
    Payload for POST /appointments  (assistant or doctor).

    start_time must be a timezone-aware datetime.
    fee is optional — if omitted the service layer copies the type's
    default_fee at booking time.
    """

    model_config = ConfigDict(from_attributes=True)

    patient_id:          int = Field(description="PK of the patient being booked.")
    doctor_id:           int = Field(description="PK of the doctor being booked.")
    appointment_type_id: int | None = Field(
        default=None,
        description="PK of the appointment type. Optional for walk-ins.",
    )
    start_time: datetime = Field(
        description="Scheduled start datetime. Must be timezone-aware (ISO 8601 with offset).",
    )
    reason:    str | None = Field(
        default=None,
        description="Chief reason for the booking, noted at scheduling time.",
    )
    is_urgent: bool = Field(
        default=False,
        description="Flag urgent cases for queue prioritisation.",
    )
    is_paid: bool = Field(
        default=False,
        description="Set true if payment is collected at booking time.",
    )
    fee: Decimal | None = Field(
        default=None,
        ge=0,
        description="Charge for this appointment. Overrides the type default.",
    )

    @field_validator("start_time")
    @classmethod
    def start_time_must_be_aware(cls, v: datetime) -> datetime:
        if v.tzinfo is None:
            raise ValueError(
                "start_time must be a timezone-aware datetime "
                "(include UTC offset, e.g. 2025-06-15T09:00:00+02:00)."
            )
        return v


class AppointmentUpdate(BaseModel):
    """
    Payload for PATCH /appointments/{id}.

    start_time and reason can be changed while the appointment is still
    SCHEDULED or CONFIRMED. Status transitions use the dedicated
    PATCH /appointments/{id}/status endpoint instead.
    """

    model_config = ConfigDict(from_attributes=True)

    appointment_type_id: int | None = None
    start_time:          datetime | None = None
    reason:              str | None = None
    is_urgent:           bool | None = None
    is_paid:             bool | None = None
    fee:                 Decimal | None = Field(default=None, ge=0)

    @field_validator("start_time")
    @classmethod
    def start_time_must_be_aware(cls, v: datetime | None) -> datetime | None:
        if v is not None and v.tzinfo is None:
            raise ValueError("start_time must be timezone-aware.")
        return v


class AppointmentStatusUpdate(BaseModel):
    """
    Dedicated payload for PATCH /appointments/{id}/status.
    Separating status transitions from field updates enforces explicit intent.
    """

    model_config = ConfigDict(from_attributes=True)

    status: AppointmentStatus = Field(
        description="Target status. Must be a valid transition from the current state.",
    )


class AppointmentResponse(BaseModel):
    """
    Full appointment as returned to clients.
    Related objects are embedded as summaries — no deep nesting.
    """

    model_config = ConfigDict(from_attributes=True)

    id:        int
    status:    AppointmentStatus
    start_time: datetime
    reason:    str | None
    is_urgent: bool
    is_paid:   bool
    fee:       Decimal | None

    # Shallow embeds
    patient:          PatientSummary
    appointment_type: AppointmentTypeSummary | None

    # IDs for efficient client-side lookups
    patient_id:          int
    doctor_id:           int
    appointment_type_id: int | None


class AppointmentSummary(BaseModel):
    """
    Compact appointment for embedding inside VisitResponse.
    """

    model_config = ConfigDict(from_attributes=True)

    id:         int
    status:     AppointmentStatus
    start_time: datetime
    patient_id: int
    doctor_id:  int


# ===========================================================================
# VISIT
# ===========================================================================

class VisitCreate(BaseModel):
    """
    Payload for POST /visits  (assistant checks patient in).
    Creates a visit record linked to an existing appointment.
    chief_complaint and vitals are optional at check-in — they can be
    added/updated during the consultation via VisitUpdate.
    """

    model_config = ConfigDict(from_attributes=True)

    appointment_id: int = Field(
        description="PK of the appointment this visit corresponds to.",
    )
    chief_complaint: str | None = Field(
        default=None,
        description="Patient's primary complaint in their own words.",
    )

    # Optional vitals at check-in
    blood_pressure: str | None = Field(
        default=None,
        max_length=20,
        description="e.g. '120/80'. Free-form string.",
    )
    heart_rate:  int | None = Field(default=None, ge=1, le=300)
    temperature: float | None = Field(default=None, ge=30.0, le=45.0)
    weight:      float | None = Field(default=None, ge=1.0, le=500.0)
    height:      float | None = Field(default=None, ge=30.0, le=300.0)
    notes:       str | None = None


class VisitUpdate(BaseModel):
    """
    Payload for PATCH /visits/{id}.
    All fields optional — used for updating vitals, notes, or status
    during or after the consultation.
    """

    model_config = ConfigDict(from_attributes=True)

    chief_complaint: str | None = None
    blood_pressure:  str | None = Field(default=None, max_length=20)
    heart_rate:      int | None = Field(default=None, ge=1, le=300)
    temperature:     float | None = Field(default=None, ge=30.0, le=45.0)
    weight:          float | None = Field(default=None, ge=1.0, le=500.0)
    height:          float | None = Field(default=None, ge=30.0, le=300.0)
    notes:           str | None = None


class VisitStatusUpdate(BaseModel):
    """
    Dedicated payload for PATCH /visits/{id}/status.
    Separates clinical status transitions from field edits.
    """

    model_config = ConfigDict(from_attributes=True)

    status: VisitStatus = Field(
        description="Target visit status. Must be a valid transition.",
    )


class VisitResponse(BaseModel):
    """
    Full visit record as returned to clients.
    Embeds the parent appointment as a shallow summary.
    Does NOT embed medical_report, medical_images, or lab_reports
    to avoid large payloads — those are fetched via their own endpoints.
    """

    model_config = ConfigDict(from_attributes=True)

    id:              int
    appointment_id:  int
    status:          VisitStatus
    chief_complaint: str | None
    blood_pressure:  str | None
    heart_rate:      int | None
    temperature:     float | None
    weight:          float | None
    height:          float | None
    notes:           str | None
    start_time:      datetime | None
    end_time:        datetime | None

    # Shallow embed of the parent appointment
    appointment: AppointmentSummary


class VisitSummary(BaseModel):
    """
    Compact visit for embedding inside MedicalReportResponse.
    """

    model_config = ConfigDict(from_attributes=True)

    id:             int
    appointment_id: int
    status:         VisitStatus
    start_time:     datetime | None


# ---------------------------------------------------------------------------
# Resolve forward references for PatientResponse → PatientConditionResponse
# ---------------------------------------------------------------------------
PatientResponse.model_rebuild()