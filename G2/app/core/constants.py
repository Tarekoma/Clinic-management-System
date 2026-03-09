"""
app/core/constants.py

Central registry for all system-wide enumerations.
These enums match the Final Simple Schema.
"""

import enum


# ---------------------------------------------------------------------------
# Authentication & User Management
# ---------------------------------------------------------------------------

class UserRole(str, enum.Enum):
    DOCTOR    = "DOCTOR"
    ASSISTANT = "ASSISTANT"
    ADMIN     = "ADMIN"


class Gender(str, enum.Enum):
    MALE   = "MALE"
    FEMALE = "FEMALE"


# ---------------------------------------------------------------------------
# Medical Reference Data
# ---------------------------------------------------------------------------

class ConditionCategory(str, enum.Enum):
    CHRONIC = "CHRONIC"
    ALLERGY = "ALLERGY"


# ---------------------------------------------------------------------------
# Appointment & Scheduling
# ---------------------------------------------------------------------------

class AppointmentStatus(str, enum.Enum):
    SCHEDULED   = "SCHEDULED"
    COMPLETED   = "COMPLETED"
    CANCELLED   = "CANCELLED"
    NO_SHOW     = "NO_SHOW"
    CONFIRMED   = "CONFIRMED"
    IN_PROGRESS = "IN_PROGRESS"


# ---------------------------------------------------------------------------
# Visit Management
# ---------------------------------------------------------------------------

class VisitStatus(str, enum.Enum):
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED   = "COMPLETED"
    WAITING     = "WAITING"
    CANCELLED   = "CANCELLED"


# ---------------------------------------------------------------------------
# Medical Reports & AI Output
# ---------------------------------------------------------------------------

class ReportStatus(str, enum.Enum):
    DRAFT     = "DRAFT"
    CONFIRMED = "CONFIRMED"
    REVIEWED  = "REVIEWED"
    CANCELLED = "CANCELLED"
    APPROVED  = "APPROVED"
    FINALIZED = "FINALIZED"


class ImageType(str, enum.Enum):
    XRAY = "XRAY"
    SKIN = "SKIN"


# ---------------------------------------------------------------------------
# Audit & Compliance
# ---------------------------------------------------------------------------


class AuditAction(str, enum.Enum):
    USER_CREATED          = "USER_CREATED"
    USER_UPDATED          = "USER_UPDATED"
    USER_DELETED          = "USER_DELETED"
    LOGIN           = "LOGIN"
    TOKEN_REFRESH   = "TOKEN_REFRESH"
    LOGOUT          = "LOGOUT"
    ACTIVATE        = "ACTIVATE"
    DEACTIVATE      = "DEACTIVATE"
    PASSWORD_CHANGE = "PASSWORD_CHANGED"

    PATIENT_CREATED = "PATIENT_CREATED"
    PATIENT_DELETED = "PATIENT_DELETED"
    PATIENT_UPDATED = "PATIENT_UPDATED"

    REPORT_CREATED  = "REPORT_CREATED"
    REPORT_UPDATED      = "REPORT_UPDATED"
    REPORT_APPROVED     = "REPORT_APPROVED"
    REPORT_FINALIZED    = "REPORT_FINALIZED"
    IMAGE_UPLOADED      = "IMAGE_UPLOADED"
    LAB_UPLOADED        = "LAB_UPLOADED"
    APPOINTMENT_CREATED = "APPOINTMENT_CREATED"
    APPOINTMENT_UPDATED = "APPOINTMENT_UPDATED"
    APPOINTMENT_CANCELLED   = "APPOINTMENT_CANCELLED"
    APPOINTMENT_COMPLETED   = "APPOINTMENT_COMPLETED"
    VISIT_STARTED           = "VISIT_STARTED"
    VISIT_UPDATED           = "VISIT_UPDATED"
    VISIT_COMPLETED         = "VISIT_COMPLETED"