"""
app/models/user_models.py

Identity and authentication models.
Covers: users, doctors, assistants, admins.

Design notes:
- `users` is the single authentication anchor. Every person who can log in
  has exactly one row here, regardless of role.
- Role-specific data lives in the profile tables (doctors, assistants, admins).
  Each profile table carries a unique FK to users.id (enforcing the 1:1 relationship).
- Soft-deletion is handled via users.is_active; no hard deletes for user records.
- All timestamps are timezone-aware (TIMESTAMP WITH TIME ZONE).
"""

from __future__ import annotations

from datetime import date, datetime, timezone

import sqlalchemy as sa
from sqlalchemy import (
    Boolean,
    Date,
    Enum as SAEnum,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base
from app.core.constants import Gender, UserRole


# ---------------------------------------------------------------------------
# Timestamp mixin
# ---------------------------------------------------------------------------

class TimestampMixin:
    """
    Reusable mixin that adds created_at / updated_at to any model.

    - created_at  : set once at INSERT using the database server clock.
    - updated_at  : set at INSERT and refreshed on every UPDATE via
                    onupdate=func.now().  SQLAlchemy fires this whenever
                    the ORM emits an UPDATE statement for the row.
    """

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


# ---------------------------------------------------------------------------
# users
# ---------------------------------------------------------------------------

class User(TimestampMixin, Base):
    """
    Core authentication table.  One row per login credential.
    The `role` column determines which profile table holds the rest
    of this person's data.

    Indexes
    -------
    - ix_users_email  : fast lookup during login (also enforces uniqueness).
    - ix_users_role   : filtered queries by role in admin views.
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    email: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        unique=True,
        index=True,          # ix_users_email
        comment="Login identifier — must be globally unique across all roles.",
    )

    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        comment="bcrypt hash of the user's password. Never store plaintext.",
    )

    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole, name="user_role", create_type=True),
        nullable=False,
        index=True,           # ix_users_role
        comment="Determines which profile table this user's details live in.",
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=sa.text("true"),
        comment="Soft-deletion flag. Deactivated users cannot log in.",
    )

    # ------------------------------------------------------------------
    # Relationships — back-populated from profile tables
    # ------------------------------------------------------------------

    doctor: Mapped["Doctor | None"] = relationship(
        "Doctor",
        back_populates="user",
        uselist=False,          # 1:1
        cascade="all, delete-orphan",
    )

    assistant: Mapped["Assistant | None"] = relationship(
        "Assistant",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    admin: Mapped["Admin | None"] = relationship(
        "Admin",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    audit_logs: Mapped[list["AuditLog"]] = relationship(   # noqa: F821
        "AuditLog",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r} role={self.role}>"


# ---------------------------------------------------------------------------
# doctors
# ---------------------------------------------------------------------------

class Doctor(TimestampMixin, Base):
    """
    Professional profile for users with role=DOCTOR.

    Key constraints
    ---------------
    - user_id    : UNIQUE — one doctor profile per user account.
    - license_number : UNIQUE — two doctors cannot share a license.

    Indexes
    -------
    - ix_doctors_user_id         : fast reverse-lookup from User → Doctor.
    - ix_doctors_specialization  : filter/search doctors by specialty.
    - ix_doctors_clinic_name     : filter doctors by clinic.
    """

    __tablename__ = "doctors"

    __table_args__ = (
        UniqueConstraint("user_id",       name="uq_doctors_user_id"),
        UniqueConstraint("license_number", name="uq_doctors_license_number"),
        Index("ix_doctors_user_id",        "user_id"),
        Index("ix_doctors_specialization", "specialization"),
        Index("ix_doctors_clinic_name",    "clinic_name"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        comment="FK to users. CASCADE ensures profile is removed with the account.",
    )

    # Personal details
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name:  Mapped[str] = mapped_column(String(100), nullable=False)

    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)

    gender: Mapped[Gender | None] = mapped_column(
        SAEnum(Gender, name="gender", create_type=True),
        nullable=True,
    )

    phone_number: Mapped[str | None] = mapped_column(String(30), nullable=True)

    # Location
    country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    region:  Mapped[str | None] = mapped_column(String(100), nullable=True)
    city:    Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Professional details
    clinic_name:     Mapped[str | None] = mapped_column(String(200), nullable=True)
    specialization:  Mapped[str | None] = mapped_column(String(150), nullable=True)
    license_number:  Mapped[str | None] = mapped_column(String(100), nullable=True)
    patients:        Mapped[list["Patient"]] = relationship("Patient", back_populates="doctor")

    # ------------------------------------------------------------------
    # Relationships
    # ------------------------------------------------------------------

    user: Mapped["User"] = relationship("User", back_populates="doctor")

    # A doctor defines the appointment types available in their clinic
    appointment_types: Mapped[list["AppointmentType"]] = relationship(  # noqa: F821
        "AppointmentType",
        back_populates="doctor",
        cascade="all, delete-orphan",
    )

    # All appointments ever booked for this doctor
    appointments: Mapped[list["Appointment"]] = relationship(            # noqa: F821
        "Appointment",
        back_populates="doctor",
        cascade="all, delete-orphan",
    )

    # All medical reports authored by this doctor
    medical_reports: Mapped[list["MedicalReport"]] = relationship(       # noqa: F821
        "MedicalReport",
        back_populates="doctor",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<Doctor id={self.id} "
            f"name={self.first_name!r} {self.last_name!r} "
            f"specialization={self.specialization!r}>"
        )


# ---------------------------------------------------------------------------
# assistants
# ---------------------------------------------------------------------------

class Assistant(TimestampMixin, Base):
    """
    Profile for users with role=ASSISTANT (receptionist / medical secretary).

    Constraints
    -----------
    - user_id : UNIQUE — one assistant profile per user account.
    """

    __tablename__ = "assistants"

    __table_args__ = (
        UniqueConstraint("user_id", name="uq_assistants_user_id"),
        Index("ix_assistants_user_id",   "user_id"),
        Index("ix_assistants_clinic_name", "clinic_name"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    # Personal details
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name:  Mapped[str] = mapped_column(String(100), nullable=False)

    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)

    gender: Mapped[Gender | None] = mapped_column(
        # Re-use the already-created "gender" type; create_type=False avoids
        # attempting to CREATE TYPE again (it was created by Doctor above).
        SAEnum(Gender, name="gender", create_type=False),
        nullable=True,
    )

    phone_number: Mapped[str | None] = mapped_column(String(30), nullable=True)

    # Location
    country: Mapped[str | None] = mapped_column(String(100), nullable=True)
    region:  Mapped[str | None] = mapped_column(String(100), nullable=True)
    city:    Mapped[str | None] = mapped_column(String(100), nullable=True)

    clinic_name: Mapped[str | None] = mapped_column(String(200), nullable=True)

    # ------------------------------------------------------------------
    # Relationships
    # ------------------------------------------------------------------

    user: Mapped["User"] = relationship("User", back_populates="assistant")

    def __repr__(self) -> str:
        return (
            f"<Assistant id={self.id} "
            f"name={self.first_name!r} {self.last_name!r}>"
        )


# ---------------------------------------------------------------------------
# admins
# ---------------------------------------------------------------------------

class Admin(TimestampMixin, Base):
    """
    Minimal profile for users with role=ADMIN.
    Admins require no clinic-specific data — only identity.

    Constraints
    -----------
    - user_id : UNIQUE — one admin profile per user account.
    """

    __tablename__ = "admins"

    __table_args__ = (
        UniqueConstraint("user_id", name="uq_admins_user_id"),
        Index("ix_admins_user_id", "user_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name:  Mapped[str] = mapped_column(String(100), nullable=False)

    # ------------------------------------------------------------------
    # Relationships
    # ------------------------------------------------------------------

    user: Mapped["User"] = relationship("User", back_populates="admin")

    def __repr__(self) -> str:
        return (
            f"<Admin id={self.id} "
            f"name={self.first_name!r} {self.last_name!r}>"
        )


# ---------------------------------------------------------------------------
# Deferred import — AuditLog lives in report_models.py.
# The relationship is declared as a string reference to avoid circular imports.
# ---------------------------------------------------------------------------
# from app.models.report_models import AuditLog   ← DO NOT import here.