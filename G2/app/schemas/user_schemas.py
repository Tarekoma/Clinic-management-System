"""
app/schemas/user_schemas.py

Request and response schemas for user identity and profile management.

Covers: User, Doctor, Assistant, Admin

Architecture notes
------------------
Creating a doctor requires two simultaneous operations: creating a User row
(email + password + role) and creating a Doctor row (all profile fields).
The Create schemas for Doctor/Assistant/Admin therefore embed both the
account credentials AND the profile data. The service layer splits them.

Response schemas follow the shallow-nesting rule:
- UserResponse includes the nested profile (Doctor/Assistant/Admin) but
  only with id + display fields — never with their own nested objects.
- DoctorResponse, AssistantResponse, AdminResponse include the base user
  fields (id, email, role, is_active) inline, not as a nested object,
  to keep the response flat and avoid N+1 patterns.

password_hash is NEVER exposed in any response schema.
"""

from __future__ import annotations

from datetime import date

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.constants import Gender, UserRole


# ---------------------------------------------------------------------------
# Shared profile base (fields common to Doctor and Assistant)
# ---------------------------------------------------------------------------

class _ProfileBase(BaseModel):
    """
    Internal base for shared personal and location fields.
    Not exposed directly — subclassed by Doctor and Assistant schemas.
    """

    model_config = ConfigDict(from_attributes=True)

    first_name: str = Field(max_length=100)
    last_name:  str = Field(max_length=100)
    date_of_birth: date | None = None
    gender:        Gender | None = None
    phone_number:  str | None = Field(default=None, max_length=30)
    country:       str | None = Field(default=None, max_length=100)
    region:        str | None = Field(default=None, max_length=100)
    city:          str | None = Field(default=None, max_length=100)
    clinic_name:   str | None = Field(default=None, max_length=200)


# ===========================================================================
# DOCTOR
# ===========================================================================

class DoctorCreate(BaseModel):
    """
    Payload for POST /users/doctors  (admin only).

    Combines account credentials with the full doctor profile.
    The service layer creates both the User row and the Doctor row
    atomically within a single transaction.
    """

    model_config = ConfigDict(from_attributes=True)

    # Account credentials (become the users table row)
    email: EmailStr = Field(
        description="Login email. Must be globally unique.",
        examples=["dr.ahmed@clinic.com"],
    )
    password: str = Field(
        min_length=8,
        description="Initial password. Min 8 characters.",
    )

    # Personal details
    first_name: str = Field(max_length=100)
    last_name:  str = Field(max_length=100)
    date_of_birth: date | None = None
    gender:        Gender | None = None
    phone_number:  str | None = Field(default=None, max_length=30)

    # Location
    country:    str | None = Field(default=None, max_length=100)
    region:     str | None = Field(default=None, max_length=100)
    city:       str | None = Field(default=None, max_length=100)

    # Professional details
    clinic_name:    str | None = Field(default=None, max_length=200)
    specialization: str | None = Field(default=None, max_length=150)
    license_number: str | None = Field(default=None, max_length=100)


class DoctorUpdate(BaseModel):
    """
    Payload for PATCH /users/doctors/{id}.
    All fields optional — partial updates are fully supported.
    email and password are not updatable here; use dedicated endpoints.
    """

    model_config = ConfigDict(from_attributes=True)

    first_name:     str | None = Field(default=None, max_length=100)
    last_name:      str | None = Field(default=None, max_length=100)
    date_of_birth:  date | None = None
    gender:         Gender | None = None
    phone_number:   str | None = Field(default=None, max_length=30)
    country:        str | None = Field(default=None, max_length=100)
    region:         str | None = Field(default=None, max_length=100)
    city:           str | None = Field(default=None, max_length=100)
    clinic_name:    str | None = Field(default=None, max_length=200)
    specialization: str | None = Field(default=None, max_length=150)
    license_number: str | None = Field(default=None, max_length=100)


class DoctorResponse(BaseModel):
    """
    Full doctor profile as returned to clients.

    Includes the base User fields (id, email, role, is_active) inline
    so clients get a single flat object without needing to join.
    password_hash is excluded.
    """

    model_config = ConfigDict(from_attributes=True)

    # Profile pk
    id: int

    # Flattened from the User relationship
    user_id:   int
    email:     str
    role:      UserRole
    is_active: bool

    # Personal details
    first_name:    str
    last_name:     str
    date_of_birth: date | None
    gender:        Gender | None
    phone_number:  str | None

    # Location
    country: str | None
    region:  str | None
    city:    str | None

    # Professional
    clinic_name:    str | None
    specialization: str | None
    license_number: str | None


class DoctorSummary(BaseModel):
    """
    Compact doctor representation for embedding inside other responses
    (e.g. inside AppointmentResponse, MedicalReportResponse).
    Shallow — no nested objects.
    """

    model_config = ConfigDict(from_attributes=True)

    id:             int
    user_id:        int
    first_name:     str
    last_name:      str
    specialization: str | None
    clinic_name:    str | None


# ===========================================================================
# ASSISTANT
# ===========================================================================

class AssistantCreate(BaseModel):
    """
    Payload for POST /users/assistants  (admin only).
    Combines account credentials with the assistant profile.
    """

    model_config = ConfigDict(from_attributes=True)

    # Account credentials
    email: EmailStr = Field(description="Login email. Must be globally unique.")
    password: str = Field(min_length=8)

    # Personal details
    first_name:    str = Field(max_length=100)
    last_name:     str = Field(max_length=100)
    date_of_birth: date | None = None
    gender:        Gender | None = None
    phone_number:  str | None = Field(default=None, max_length=30)

    # Location
    country:    str | None = Field(default=None, max_length=100)
    region:     str | None = Field(default=None, max_length=100)
    city:       str | None = Field(default=None, max_length=100)
    clinic_name: str | None = Field(default=None, max_length=200)


class AssistantUpdate(BaseModel):
    """Payload for PATCH /users/assistants/{id}. All fields optional."""

    model_config = ConfigDict(from_attributes=True)

    first_name:    str | None = Field(default=None, max_length=100)
    last_name:     str | None = Field(default=None, max_length=100)
    date_of_birth: date | None = None
    gender:        Gender | None = None
    phone_number:  str | None = Field(default=None, max_length=30)
    country:       str | None = Field(default=None, max_length=100)
    region:        str | None = Field(default=None, max_length=100)
    city:          str | None = Field(default=None, max_length=100)
    clinic_name:   str | None = Field(default=None, max_length=200)


class AssistantResponse(BaseModel):
    """Full assistant profile. Includes flattened user fields."""

    model_config = ConfigDict(from_attributes=True)

    id:        int
    user_id:   int
    email:     str
    role:      UserRole
    is_active: bool

    first_name:    str
    last_name:     str
    date_of_birth: date | None
    gender:        Gender | None
    phone_number:  str | None
    country:       str | None
    region:        str | None
    city:          str | None
    clinic_name:   str | None


class AssistantSummary(BaseModel):
    """Compact assistant representation for embedding inside other responses."""

    model_config = ConfigDict(from_attributes=True)

    id:         int
    user_id:    int
    first_name: str
    last_name:  str


# ===========================================================================
# ADMIN
# ===========================================================================

class AdminCreate(BaseModel):
    """
    Payload for POST /users/admins  (admin only).
    Admin profiles are minimal — only identity fields needed.
    """

    model_config = ConfigDict(from_attributes=True)

    email:    EmailStr = Field(description="Login email. Must be globally unique.")
    password: str = Field(min_length=8)

    first_name: str = Field(max_length=100)
    last_name:  str = Field(max_length=100)


class AdminUpdate(BaseModel):
    """Payload for PATCH /users/admins/{id}. All fields optional."""

    model_config = ConfigDict(from_attributes=True)

    first_name: str | None = Field(default=None, max_length=100)
    last_name:  str | None = Field(default=None, max_length=100)


class AdminResponse(BaseModel):
    """Full admin profile. Includes flattened user fields."""

    model_config = ConfigDict(from_attributes=True)

    id:        int
    user_id:   int
    email:     str
    role:      UserRole
    is_active: bool

    first_name: str
    last_name:  str


# ===========================================================================
# USER (base account — used in admin list/management views)
# ===========================================================================

class UserResponse(BaseModel):
    """
    Base user account view.
    Used in admin user-management endpoints where the caller needs to
    see account status and role but does NOT need the full profile.

    password_hash is explicitly excluded.
    """

    model_config = ConfigDict(from_attributes=True)

    id:        int
    email:     str
    role:      UserRole
    is_active: bool


class UserStatusUpdate(BaseModel):
    """
    Payload for PATCH /users/{id}/status  (admin only).
    Controls soft-deletion (is_active flag) without touching the profile.
    """

    model_config = ConfigDict(from_attributes=True)

    is_active: bool = Field(
        description="Set to false to deactivate (soft-delete). Set to true to reactivate.",
    )