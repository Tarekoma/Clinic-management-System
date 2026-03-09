"""
app/models/__init__.py

Central import hub for all ORM models.

WHY THIS FILE EXISTS
--------------------
Alembic's autogenerate feature (used by `alembic revision --autogenerate`)
discovers database schema changes by inspecting the SQLAlchemy metadata
that is registered on the Base class. A model is only registered on Base
when its module has been imported.

This file ensures that every model module is imported before Alembic (or
any other tool) inspects Base.metadata. Without these imports, autogenerate
would see an empty metadata object and generate DROP TABLE migrations for
every table in the database.

HOW TO USE
----------
In alembic/env.py, add:

    from app.models import *          # noqa: F401, F403
    from app.database import Base
    target_metadata = Base.metadata

In app/database.py, the Base is defined as:

    from sqlalchemy.orm import DeclarativeBase
    class Base(DeclarativeBase):
        pass

All models inherit from this Base.
"""

# User identity and authentication
from app.models.user_models import (       # noqa: F401
    User,
    Doctor,
    Assistant,
    Admin,
)

# Operational clinic workflow
from app.models.clinic_models import (     # noqa: F401
    Patient,
    MedicalCondition,
    PatientCondition,
    AppointmentType,
    Appointment,
    Visit,
)

# Clinical outputs and compliance
from app.models.report_models import (     # noqa: F401
    MedicalReport,
    MedicalImage,
    LabReport,
    AuditLog,
)

__all__ = [
    # User models
    "User",
    "Doctor",
    "Assistant",
    "Admin",
    # Clinic models
    "Patient",
    "MedicalCondition",
    "PatientCondition",
    "AppointmentType",
    "Appointment",
    "Visit",
    # Report models
    "MedicalReport",
    "MedicalImage",
    "LabReport",
    "AuditLog",
]
