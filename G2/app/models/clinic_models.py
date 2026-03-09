"""
app/models/clinic_models.py

Operational clinic workflow models.
Updated to match Simple Constants.
"""

from __future__ import annotations

from datetime import date, datetime

import sqlalchemy as sa
from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum as SAEnum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base
from app.core.constants import (
    AppointmentStatus,
    ConditionCategory,
    Gender,
    VisitStatus,
)


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class Patient(TimestampMixin, Base):
    __tablename__ = "patients"

    __table_args__ = (
        UniqueConstraint("national_id", name="uq_patients_national_id"),
        Index("ix_patients_national_id", "national_id"),
        Index("ix_patients_last_name",   "last_name"),
        Index("ix_patients_phone",       "phone"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    first_name: Mapped[str]  = mapped_column(String(100), nullable=False)
    last_name: Mapped[str]  = mapped_column(String(100), nullable=False)

    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)

    gender: Mapped[Gender | None] = mapped_column(
        SAEnum(Gender, name="gender", create_type=False),
        nullable=True,
    )

    national_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    patient_conditions: Mapped[list["PatientCondition"]] = relationship(
        "PatientCondition",
        back_populates="patient",
        cascade="all, delete-orphan",
    )

    conditions: Mapped[list["MedicalCondition"]] = relationship(
        "MedicalCondition",
        secondary="patient_conditions",
        viewonly=True,
        overlaps="patient_conditions",
    )

    appointments: Mapped[list["Appointment"]] = relationship(
        "Appointment",
        back_populates="patient",
        cascade="all, delete-orphan",
    )

    doctor_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("doctors.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    doctor: Mapped["Doctor | None"] = relationship(
        "Doctor", back_populates="patients"
    )

    def __repr__(self) -> str:
        return (
            f"<Patient id={self.id} "
            f"name={self.first_name!r} {self.last_name!r}>"
        )


class MedicalCondition(TimestampMixin, Base):
    __tablename__ = "medical_conditions"

    __table_args__ = (
        UniqueConstraint("name", name="uq_medical_conditions_name"),
        Index("ix_medical_conditions_category", "category"),
        Index("ix_medical_conditions_name",     "name"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    category: Mapped[ConditionCategory | None] = mapped_column(
        SAEnum(ConditionCategory, name="condition_category", create_type=True),
        nullable=True,
    )

    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    patient_conditions: Mapped[list["PatientCondition"]] = relationship(
        "PatientCondition",
        back_populates="condition",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<MedicalCondition id={self.id} name={self.name!r}>"


class PatientCondition(TimestampMixin, Base):
    __tablename__ = "patient_conditions"

    __table_args__ = (
        UniqueConstraint(
            "patient_id", "condition_id",
            name="uq_patient_conditions_patient_condition",
        ),
        Index("ix_patient_conditions_patient_id",   "patient_id"),
        Index("ix_patient_conditions_condition_id",  "condition_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    patient_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
    )

    condition_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("medical_conditions.id", ondelete="CASCADE"),
        nullable=False,
    )

    diagnosed_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    patient:   Mapped["Patient"]          = relationship("Patient",   back_populates="patient_conditions")
    condition: Mapped["MedicalCondition"] = relationship("MedicalCondition", back_populates="patient_conditions")

    def __repr__(self) -> str:
        return (
            f"<PatientCondition "
            f"patient_id={self.patient_id} "
            f"condition_id={self.condition_id}>"
        )


class AppointmentType(TimestampMixin, Base):
    __tablename__ = "appointment_types"

    __table_args__ = (
        Index("ix_appointment_types_doctor_id", "doctor_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    doctor_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False,
    )

    name: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    duration_minutes: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    default_fee: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True,
    )

    # Relationships
    doctor:       Mapped["Doctor"]           = relationship("Doctor",      back_populates="appointment_types")
    appointments: Mapped[list["Appointment"]] = relationship("Appointment", back_populates="appointment_type")

    def __repr__(self) -> str:
        return (
            f"<AppointmentType id={self.id} "
            f"name={self.name!r} "
            f"doctor_id={self.doctor_id}>"
        )


class Appointment(TimestampMixin, Base):
    __tablename__ = "appointments"

    __table_args__ = (
        Index("ix_appointments_patient_id",           "patient_id"),
        Index("ix_appointments_doctor_id",            "doctor_id"),
        Index("ix_appointments_appointment_type_id",  "appointment_type_id"),
        Index("ix_appointments_start_time",           "start_time"),
        Index("ix_appointments_status",               "status"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    patient_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
    )

    doctor_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False,
    )

    appointment_type_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("appointment_types.id", ondelete="SET NULL"),
        nullable=True,
    )

    start_time: Mapped[datetime] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=False,
    )

    status: Mapped[AppointmentStatus] = mapped_column(
        SAEnum(AppointmentStatus, name="appointment_status", create_type=True),
        nullable=False,
        default=AppointmentStatus.SCHEDULED,
        server_default=sa.text("'scheduled'"),
    )

    reason: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    is_urgent: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=sa.text("false"),
    )

    is_paid: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=sa.text("false"),
    )

    fee: Mapped[float | None] = mapped_column(
        Numeric(10, 2),
        nullable=True,
    )

    # Relationships
    patient:          Mapped["Patient"]          = relationship("Patient",         back_populates="appointments")
    doctor:           Mapped["Doctor"]           = relationship("Doctor",          back_populates="appointments")
    appointment_type: Mapped["AppointmentType | None"] = relationship("AppointmentType", back_populates="appointments")

    # At most one visit results from an appointment
    visit: Mapped["Visit | None"] = relationship(
        "Visit",
        back_populates="appointment",
        uselist=False,
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<Appointment id={self.id} "
            f"patient_id={self.patient_id} "
            f"doctor_id={self.doctor_id} "
            f"status={self.status} "
            f"start_time={self.start_time}>"
        )


class Visit(TimestampMixin, Base):
    __tablename__ = "visits"

    __table_args__ = (
        UniqueConstraint("appointment_id", name="uq_visits_appointment_id"),
        Index("ix_visits_appointment_id", "appointment_id"),
        Index("ix_visits_status",         "status"),
        Index("ix_visits_start_time",     "start_time"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    appointment_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("appointments.id", ondelete="CASCADE"),
        nullable=False,
    )

    chief_complaint: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # Vitals
    blood_pressure: Mapped[str | None] = mapped_column(
        String(20),
        nullable=True,
    )

    heart_rate: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    temperature: Mapped[float | None] = mapped_column(
        Numeric(4, 1),
        nullable=True,
    )

    weight: Mapped[float | None] = mapped_column(
        Numeric(5, 2),
        nullable=True,
    )

    height: Mapped[float | None] = mapped_column(
        Numeric(5, 2),
        nullable=True,
    )

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[VisitStatus] = mapped_column(
        SAEnum(VisitStatus, name="visit_status", create_type=True),
        nullable=False,
        default=VisitStatus.IN_PROGRESS, # Corrected from WAITING
        server_default=sa.text("'in_progress'"), # Corrected from 'waiting'
    )

    start_time: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=True,
    )

    end_time: Mapped[datetime | None] = mapped_column(
        sa.DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    appointment: Mapped["Appointment"] = relationship(
        "Appointment",
        back_populates="visit",
    )

    medical_report: Mapped["MedicalReport | None"] = relationship(
        "MedicalReport",
        back_populates="visit",
        uselist=False,
        cascade="all, delete-orphan",
    )

    medical_images: Mapped[list["MedicalImage"]] = relationship(
        "MedicalImage",
        back_populates="visit",
        cascade="all, delete-orphan",
    )

    lab_reports: Mapped[list["LabReport"]] = relationship(
        "LabReport",
        back_populates="visit",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<Visit id={self.id} "
            f"appointment_id={self.appointment_id} "
            f"status={self.status}>"
        )