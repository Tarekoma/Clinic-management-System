"""
app/services/user_service.py

User account and profile management service.

Use cases implemented
---------------------
- create_doctor()        : create User + Doctor atomically
- create_assistant()     : create User + Assistant atomically
- create_admin()         : create User + Admin atomically
- get_doctor()           : fetch doctor profile by id
- get_assistant()        : fetch assistant profile by id
- get_admin()            : fetch admin profile by id
- get_user()             : fetch base user by id
- list_users()           : paginated list of all users (admin)
- update_doctor()        : patch doctor profile fields
- update_assistant()     : patch assistant profile fields
- update_admin()         : patch admin profile fields
- set_user_active()      : activate / deactivate a user account
- get_doctor_by_user_id(): resolve doctor profile from JWT user_id

Business rules
--------------
- Only admins may create or deactivate user accounts. (Enforced in API layer
  via require_role, but services also validate for defence-in-depth.)
- Email must be globally unique across all users regardless of role.
- Doctors must have a unique license_number if one is provided.
- Creating any user type creates both the User row and the profile row
  inside a single transaction — partial states are impossible.
- Admins cannot deactivate themselves.

Audit events
------------
- USER_CREATED, USER_UPDATED, USER_ACTIVATED, USER_DEACTIVATED
"""
from __future__ import annotations
import json
import logging
from sqlalchemy.orm import Session
from app.core.constants import AuditAction, UserRole
from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError, ValidationError
from app.core.security import hash_password
from app.models.report_models import AuditLog
from app.models.user_models import Admin, Assistant, Doctor, User
from app.schemas.auth_schemas import AuthenticatedUser
from app.schemas.user_schemas import (
    AdminCreate,
    AdminResponse,
    AdminUpdate,
    AssistantCreate,
    AssistantResponse,
    AssistantUpdate,
    DoctorCreate,
    DoctorResponse,
    DoctorUpdate,
    UserResponse,
    UserStatusUpdate,
)

logger = logging.getLogger(__name__)


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


def _assert_email_unique(db: Session, email: str, exclude_user_id: int | None = None) -> None:
    q = db.query(User).filter(User.email == email)
    if exclude_user_id:
        q = q.filter(User.id != exclude_user_id)
    if q.first():
        raise ConflictError(f"Email '{email}' is already registered.")


def _assert_license_unique(db: Session, license_number: str, exclude_doctor_id: int | None = None) -> None:
    if not license_number:
        return
    q = db.query(Doctor).filter(Doctor.license_number == license_number)
    if exclude_doctor_id:
        q = q.filter(Doctor.id != exclude_doctor_id)
    if q.first():
        raise ConflictError(f"License number '{license_number}' is already registered.")


def _get_doctor_or_404(db: Session, doctor_id: int) -> Doctor:
    doc = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doc:
        raise NotFoundError("Doctor", doctor_id)
    return doc


def _get_assistant_or_404(db: Session, assistant_id: int) -> Assistant:
    asst = db.query(Assistant).filter(Assistant.id == assistant_id).first()
    if not asst:
        raise NotFoundError("Assistant", assistant_id)
    return asst


def _get_admin_or_404(db: Session, admin_id: int) -> Admin:
    adm = db.query(Admin).filter(Admin.id == admin_id).first()
    if not adm:
        raise NotFoundError("Admin", admin_id)
    return adm


def _build_doctor_response(doctor: Doctor) -> DoctorResponse:
    """Flatten the Doctor + User relationship into the response schema."""
    return DoctorResponse(
        id=doctor.id,
        user_id=doctor.user_id,
        email=doctor.user.email,
        role=doctor.user.role,
        is_active=doctor.user.is_active,
        first_name=doctor.first_name,
        last_name=doctor.last_name,
        date_of_birth=doctor.date_of_birth,
        gender=doctor.gender,
        phone_number=doctor.phone_number,
        country=doctor.country,
        region=doctor.region,
        city=doctor.city,
        clinic_name=doctor.clinic_name,
        specialization=doctor.specialization,
        license_number=doctor.license_number,
    )


def _build_assistant_response(assistant: Assistant) -> AssistantResponse:
    return AssistantResponse(
        id=assistant.id,
        user_id=assistant.user_id,
        email=assistant.user.email,
        role=assistant.user.role,
        is_active=assistant.user.is_active,
        first_name=assistant.first_name,
        last_name=assistant.last_name,
        date_of_birth=assistant.date_of_birth,
        gender=assistant.gender,
        phone_number=assistant.phone_number,
        country=assistant.country,
        region=assistant.region,
        city=assistant.city,
        clinic_name=assistant.clinic_name,
    )


def _build_admin_response(admin: Admin) -> AdminResponse:
    return AdminResponse(
        id=admin.id,
        user_id=admin.user_id,
        email=admin.user.email,
        role=admin.user.role,
        is_active=admin.user.is_active,
        first_name=admin.first_name,
        last_name=admin.last_name,
    )


# ---------------------------------------------------------------------------
# Doctor CRUD
# ---------------------------------------------------------------------------

def create_doctor(
    db: Session,
    current_user: AuthenticatedUser,
    data: DoctorCreate,
) -> DoctorResponse:
    """
    Create a new doctor account and profile in one transaction.

    Raises
    ------
    ForbiddenError    : caller is not an admin.
    ConflictError     : email or license_number already exists.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can create doctor accounts.")

    _assert_email_unique(db, data.email)
    _assert_license_unique(db, data.license_number or "")

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.DOCTOR,
        is_active=True,
    )
    db.add(user)
    db.flush()   # get user.id before creating profile

    doctor = Doctor(
        user_id=user.id,
        first_name=data.first_name,
        last_name=data.last_name,
        date_of_birth=data.date_of_birth,
        gender=data.gender,
        phone_number=data.phone_number,
        country=data.country,
        region=data.region,
        city=data.city,
        clinic_name=data.clinic_name,
        specialization=data.specialization,
        license_number=data.license_number,
    )
    db.add(doctor)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.USER_CREATED,
        "doctor", doctor.id,
        {"email": data.email, "name": f"{data.first_name} {data.last_name}"},
    )
    db.commit()
    db.refresh(doctor)

    logger.info("Doctor %d created by admin %d.", doctor.id, current_user.id)
    return _build_doctor_response(doctor)


def get_doctor(db: Session, doctor_id: int) -> DoctorResponse:
    """Fetch a doctor profile by doctor.id (not user.id)."""
    doctor = _get_doctor_or_404(db, doctor_id)
    return _build_doctor_response(doctor)


def get_doctor_by_user_id(db: Session, user_id: int) -> DoctorResponse:
    """Resolve a doctor profile from a user.id (useful after JWT decode)."""
    doctor = db.query(Doctor).filter(Doctor.user_id == user_id).first()
    if not doctor:
        raise NotFoundError("Doctor profile", user_id)
    return _build_doctor_response(doctor)


def list_doctors(
    db: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[DoctorResponse]:
    """
    Paginated list of all doctors.
    """
    doctors = db.query(Doctor).offset(skip).limit(limit).all()
    return [_build_doctor_response(doc) for doc in doctors]


def update_doctor(
    db: Session,
    current_user: AuthenticatedUser,
    doctor_id: int,
    data: DoctorUpdate,
) -> DoctorResponse:
    """
    Patch a doctor's profile. Doctors can update their own profile;
    admins can update any doctor's profile.

    Raises
    ------
    NotFoundError  : doctor not found.
    ForbiddenError : caller is neither the doctor nor an admin.
    ConflictError  : new license_number clashes with another doctor.
    """
    doctor = _get_doctor_or_404(db, doctor_id)

    is_own_profile = (current_user.role == UserRole.DOCTOR and doctor.user_id == current_user.id)
    is_admin = current_user.role == UserRole.ADMIN

    if not (is_own_profile or is_admin):
        raise ForbiddenError("You can only update your own profile.")

    if data.license_number is not None:
        _assert_license_unique(db, data.license_number, exclude_doctor_id=doctor_id)

    changed: dict = {}
    for field, value in data.model_dump(exclude_none=True).items():
        if getattr(doctor, field) != value:
            setattr(doctor, field, value)
            changed[field] = str(value)

    if changed:
        db.add(doctor)
        _write_audit(db, current_user.id, AuditAction.USER_UPDATED, "doctor", doctor_id, changed)
        db.commit()
        db.refresh(doctor)

    return _build_doctor_response(doctor)


# ---------------------------------------------------------------------------
# Assistant CRUD
# ---------------------------------------------------------------------------

def create_assistant(
    db: Session,
    current_user: AuthenticatedUser,
    data: AssistantCreate,
) -> AssistantResponse:
    """
    Create a new assistant account and profile in one transaction.

    Raises
    ------
    ForbiddenError : caller is not an admin.
    ConflictError  : email already exists.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can create assistant accounts.")

    _assert_email_unique(db, data.email)

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.ASSISTANT,
        is_active=True,
    )
    db.add(user)
    db.flush()

    assistant = Assistant(
        user_id=user.id,
        first_name=data.first_name,
        last_name=data.last_name,
        date_of_birth=data.date_of_birth,
        gender=data.gender,
        phone_number=data.phone_number,
        country=data.country,
        region=data.region,
        city=data.city,
        clinic_name=data.clinic_name,
    )
    db.add(assistant)
    db.flush()

    _write_audit(
        db, current_user.id, AuditAction.USER_CREATED,
        "assistant", assistant.id,
        {"email": data.email},
    )
    db.commit()
    db.refresh(assistant)

    logger.info("Assistant %d created by admin %d.", assistant.id, current_user.id)
    return _build_assistant_response(assistant)


def get_assistant(db: Session, assistant_id: int) -> AssistantResponse:
    assistant = _get_assistant_or_404(db, assistant_id)
    return _build_assistant_response(assistant)


def list_assistants(
    db: Session,
    skip: int = 0,
    limit: int = 100,
) -> list[AssistantResponse]:
    """
    Paginated list of all assistants.
    """
    assistants = db.query(Assistant).offset(skip).limit(limit).all()
    return [_build_assistant_response(assis) for assis in assistants]



def update_assistant(
    db: Session,
    current_user: AuthenticatedUser,
    assistant_id: int,
    data: AssistantUpdate,
) -> AssistantResponse:
    """Assistants can update their own profile; admins can update any."""
    assistant = _get_assistant_or_404(db, assistant_id)

    is_own = (current_user.role == UserRole.ASSISTANT and assistant.user_id == current_user.id)
    is_admin = current_user.role == UserRole.ADMIN

    if not (is_own or is_admin):
        raise ForbiddenError("You can only update your own profile.")

    changed: dict = {}
    for field, value in data.model_dump(exclude_none=True).items():
        if getattr(assistant, field) != value:
            setattr(assistant, field, value)
            changed[field] = str(value)

    if changed:
        db.add(assistant)
        _write_audit(db, current_user.id, AuditAction.USER_UPDATED, "assistant", assistant_id, changed)
        db.commit()
        db.refresh(assistant)

    return _build_assistant_response(assistant)


# ---------------------------------------------------------------------------
# Admin CRUD
# ---------------------------------------------------------------------------

def create_admin(
    db: Session,
    current_user: AuthenticatedUser,
    data: AdminCreate,
) -> AdminResponse:
    """
    Create a new admin account.

    Raises
    ------
    ForbiddenError : caller is not an admin.
    ConflictError  : email already exists.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can create admin accounts.")

    _assert_email_unique(db, data.email)

    user = User(
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole.ADMIN,
        is_active=True,
    )
    db.add(user)
    db.flush()

    admin = Admin(
        user_id=user.id,
        first_name=data.first_name,
        last_name=data.last_name,
    )
    db.add(admin)
    db.flush()

    _write_audit(db, current_user.id, AuditAction.USER_CREATED, "admin", admin.id, {"email": data.email})
    db.commit()
    db.refresh(admin)

    logger.info("Admin %d created by admin %d.", admin.id, current_user.id)
    return _build_admin_response(admin)


def get_admin(db: Session, admin_id: int) -> AdminResponse:
    admin = _get_admin_or_404(db, admin_id)
    return _build_admin_response(admin)


def update_admin(
    db: Session,
    current_user: AuthenticatedUser,
    admin_id: int,
    data: AdminUpdate,
) -> AdminResponse:
    """Admins can update their own profile or another admin's profile."""
    admin = _get_admin_or_404(db, admin_id)

    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can update admin profiles.")

    changed: dict = {}
    for field, value in data.model_dump(exclude_none=True).items():
        if getattr(admin, field) != value:
            setattr(admin, field, value)
            changed[field] = str(value)

    if changed:
        db.add(admin)
        _write_audit(db, current_user.id, AuditAction.USER_UPDATED, "admin", admin_id, changed)
        db.commit()
        db.refresh(admin)

    return _build_admin_response(admin)


# ---------------------------------------------------------------------------
# User account management
# ---------------------------------------------------------------------------

def get_user(db: Session, user_id: int) -> UserResponse:
    """Fetch base user account info (no profile fields)."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundError("User", user_id)
    return UserResponse(id=user.id, email=user.email, role=user.role, is_active=user.is_active)


def list_users(
    db: Session,
    current_user: AuthenticatedUser,
    offset: int = 0,
    limit: int = 20,
    role: str | None = None,
) -> tuple[list[UserResponse], int]:
    """
    Paginated list of all users. Admin only.

    Returns
    -------
    (list of UserResponse, total_count)
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can list all users.")

    q = db.query(User)
    if role:
        q = q.filter(User.role == role)

    total = q.count()
    users = q.order_by(User.id).offset(offset).limit(limit).all()
    return [UserResponse(id=u.id, email=u.email, role=u.role, is_active=u.is_active) for u in users], total


def set_user_active(
    db: Session,
    current_user: AuthenticatedUser,
    user_id: int,
    data: UserStatusUpdate,
) -> UserResponse:
    """
    Activate or deactivate a user account. Admin only.

    Business rules:
    - Admins cannot deactivate their own account.

    Raises
    ------
    ForbiddenError    : caller is not an admin, or self-deactivation attempt.
    NotFoundError     : user not found.
    """
    if current_user.role != UserRole.ADMIN:
        raise ForbiddenError("Only administrators can change user account status.")

    if current_user.id == user_id and not data.is_active:
        raise ForbiddenError("Administrators cannot deactivate their own account.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundError("User", user_id)

    if user.is_active == data.is_active:
        # No change needed — return current state without writing anything
        return UserResponse(id=user.id, email=user.email, role=user.role, is_active=user.is_active)

    user.is_active = data.is_active
    db.add(user)

    action = AuditAction.ACTIVATE if data.is_active else AuditAction.DEACTIVATE
    _write_audit(db, current_user.id, action, "user", user_id)
    db.commit()

    logger.info("User %d %s by admin %d.", user_id, "activated" if data.is_active else "deactivated", current_user.id)
    return UserResponse(id=user.id, email=user.email, role=user.role, is_active=user.is_active)