"""
app/models/report_models.py

Clinical output and compliance models.
Updated to match Simple Constants.
"""

from __future__ import annotations

from datetime import datetime

import sqlalchemy as sa
from sqlalchemy import (
    DateTime,
    Enum as SAEnum,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base
from app.core.constants import AuditAction, ImageType, ReportStatus


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class MedicalReport(TimestampMixin, Base):
    __tablename__ = "medical_reports"

    __table_args__ = (
        sa.UniqueConstraint("visit_id", name="uq_medical_reports_visit_id"),
        Index("ix_medical_reports_visit_id",   "visit_id"),
        Index("ix_medical_reports_doctor_id",  "doctor_id"),
        Index("ix_medical_reports_status",     "status"),
        Index("ix_medical_reports_created_at", "created_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    visit_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("visits.id", ondelete="CASCADE"),
        nullable=False,
    )

    doctor_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False,
    )

    # AI-generated content
    doctor_voice_transcription: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_diagnosis: Mapped[str | None] = mapped_column(Text, nullable=True)

    ai_medications: Mapped[dict | list | None] = mapped_column(
        JSONB,
        nullable=True,
    )

    ai_recommendations: Mapped[dict | list | None] = mapped_column(
        JSONB,
        nullable=True,
    )

    ai_follow_up: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Doctor's manual input
    doctor_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[ReportStatus] = mapped_column(
        SAEnum(ReportStatus, name="report_status", create_type=True),
        nullable=False,
        default=ReportStatus.DRAFT, # Corrected from draft
        server_default=sa.text("'draft'"), # Corrected from draft
    )

    # Relationships
    visit: Mapped["Visit"] = relationship("Visit", back_populates="medical_report")
    doctor: Mapped["Doctor"] = relationship("Doctor", back_populates="medical_reports")

    def __repr__(self) -> str:
        return (
            f"<MedicalReport id={self.id} "
            f"visit_id={self.visit_id} "
            f"status={self.status}>"
        )


class MedicalImage(TimestampMixin, Base):
    __tablename__ = "medical_images"

    __table_args__ = (
        Index("ix_medical_images_visit_id",   "visit_id"),
        Index("ix_medical_images_image_type", "image_type"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    visit_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("visits.id", ondelete="CASCADE"),
        nullable=False,
    )

    image_url: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )

    image_type: Mapped[ImageType] = mapped_column(
        SAEnum(ImageType, name="image_type", create_type=True),
        nullable=False,
    )

    ai_diagnosis: Mapped[str | None] = mapped_column(Text, nullable=True)
    doctor_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    visit: Mapped["Visit"] = relationship("Visit", back_populates="medical_images")

    def __repr__(self) -> str:
        return (
            f"<MedicalImage id={self.id} "
            f"visit_id={self.visit_id} "
            f"image_type={self.image_type}>"
        )


class LabReport(TimestampMixin, Base):
    __tablename__ = "lab_reports"

    __table_args__ = (
        Index("ix_lab_reports_visit_id", "visit_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    visit_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("visits.id", ondelete="CASCADE"),
        nullable=False,
    )

    report_url: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )

    ai_interpreted_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    original_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Relationships
    visit: Mapped["Visit"] = relationship("Visit", back_populates="lab_reports")

    def __repr__(self) -> str:
        return (
            f"<LabReport id={self.id} "
            f"visit_id={self.visit_id}>"
        )


class AuditLog(Base):
    """
    AuditLog inherits directly from Base, not TimestampMixin.
    It only has created_at — no updated_at.
    """
    __tablename__ = "audit_logs"

    __table_args__ = (
        Index("ix_audit_logs_user_id",    "user_id"),
        Index("ix_audit_logs_action",     "action"),
        Index(
            "ix_audit_logs_entity",
            "entity_type", "entity_id",
        ),
        Index("ix_audit_logs_created_at", "created_at"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    user_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    action: Mapped[AuditAction] = mapped_column(
        SAEnum(AuditAction, name="audit_action", create_type=True),
        nullable=False,
    )

    entity_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    entity_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    details: Mapped[str | None] = mapped_column(Text, nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["User | None"] = relationship(
        "User",
        back_populates="audit_logs",
    )

    def __repr__(self) -> str:
        return (
            f"<AuditLog id={self.id} "
            f"user_id={self.user_id} "
            f"action={self.action} "
            f"entity={self.entity_type}:{self.entity_id}>"
        )