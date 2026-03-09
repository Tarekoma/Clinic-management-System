"""
User management endpoints.

Handles:
- User and profile CRUD operations
- Doctor, Assistant, and Admin profile management
- User activation/deactivation
"""

from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, RequireAdmin, RequireDoctor, RequireAssistant
from app.services import user_service
from app.schemas.user_schemas import (
    DoctorCreate,
    DoctorUpdate,
    DoctorResponse,
    AssistantCreate,
    AssistantUpdate,
    AssistantResponse,
    AdminCreate,
    AdminUpdate,
    AdminResponse,
    UserResponse,
    UserStatusUpdate
)
from app.schemas.common import StandardResponse, PaginatedResponse
from app.core.exceptions import (
    NotFoundError,
    ConflictError,
    ValidationError as DomainValidationError,
    ForbiddenError
)
from app.core.constants import UserRole
from app.models.user_models import User

router = APIRouter(prefix="/users", tags=["User Management"])


# ============================================================================
# DOCTOR ENDPOINTS
# ============================================================================

@router.post("/doctors", response_model=DoctorResponse, status_code=status.HTTP_201_CREATED)
def create_doctor(
    doctor_data: DoctorCreate,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new doctor account (Admin only).
    
    Args:
        doctor_data: Doctor profile and credentials
        current_user: Admin user
        db: Database session
        
    Returns:
        DoctorResponse: Created doctor profile
        
    Raises:
        409: Email already exists
        400: Validation error
    """
    try:
        doctor = user_service.create_doctor(db, current_user, doctor_data)
        return doctor
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/doctors/{doctor_id}", response_model=DoctorResponse)
def get_doctor(
    doctor_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get doctor profile by ID.
    
    Args:
        doctor_id: Doctor ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        DoctorResponse: Doctor profile
        
    Raises:
        404: Doctor not found
    """
    try:
        doctor = user_service.get_doctor(db, doctor_id)
        return doctor
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/doctors", response_model=List[DoctorResponse])
def list_doctors(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List all doctors.
    
    Args:
        current_user: Authenticated user
        db: Database session
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[DoctorResponse]: List of doctors
    """
    doctors = user_service.list_doctors(db, skip=skip, limit=limit)
    return doctors


@router.patch("/doctors/{doctor_id}", response_model=DoctorResponse)
def update_doctor(
    doctor_id: int,
    update_data: DoctorUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update doctor profile.
    
    Doctors can update their own profile.
    Admins can update any doctor profile.
    
    Args:
        doctor_id: Doctor ID
        update_data: Fields to update
        current_user: Authenticated user
        db: Database session
        
    Returns:
        DoctorResponse: Updated doctor profile
        
    Raises:
        403: Not authorized to update this doctor
        404: Doctor not found
    """
    try:
        # Check if user is admin or updating their own profile
        if current_user.role != UserRole.ADMIN:
            if current_user.role != UserRole.DOCTOR or current_user.id != doctor_id:
                raise ForbiddenError("You can only update your own profile")
        
        doctor = user_service.update_doctor(db, current_user, doctor_id, update_data)
        return doctor
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


# ============================================================================
# ASSISTANT ENDPOINTS
# ============================================================================

@router.post("/assistants", response_model=AssistantResponse, status_code=status.HTTP_201_CREATED)
def create_assistant(
    assistant_data: AssistantCreate,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new assistant account (Admin only).
    
    Args:
        assistant_data: Assistant profile and credentials
        current_user: Admin user
        db: Database session
        
    Returns:
        AssistantResponse: Created assistant profile
        
    Raises:
        409: Email already exists
        400: Validation error
    """
    try:
        assistant = user_service.create_assistant(db, current_user, assistant_data)
        return assistant
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/assistants/{assistant_id}", response_model=AssistantResponse)
def get_assistant(
    assistant_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get assistant profile by ID.
    
    Args:
        assistant_id: Assistant ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AssistantResponse: Assistant profile
        
    Raises:
        404: Assistant not found
    """
    try:
        assistant = user_service.get_assistant(db, assistant_id)
        return assistant
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/assistants", response_model=List[AssistantResponse])
def list_assistants(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List all assistants.
    
    Args:
        current_user: Authenticated user
        db: Database session
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[AssistantResponse]: List of assistants
    """
    assistants = user_service.list_assistants(db, skip=skip, limit=limit)
    return assistants


@router.patch("/assistants/{assistant_id}", response_model=AssistantResponse)
def update_assistant(
    assistant_id: int,
    update_data: AssistantUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update assistant profile.
    
    Assistants can update their own profile.
    Admins can update any assistant profile.
    
    Args:
        assistant_id: Assistant ID
        update_data: Fields to update
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AssistantResponse: Updated assistant profile
        
    Raises:
        403: Not authorized to update this assistant
        404: Assistant not found
    """
    try:
        # Check if user is admin or updating their own profile
        if current_user.role != UserRole.ADMIN:
            if current_user.role != UserRole.ASSISTANT or current_user.id != assistant_id:
                raise ForbiddenError("You can only update your own profile")
        
        assistant = user_service.update_assistant(db, current_user, assistant_id, update_data)
        return assistant
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


# ============================================================================
# ADMIN ENDPOINTS
# ============================================================================

@router.post("/admins", response_model=AdminResponse, status_code=status.HTTP_201_CREATED)
def create_admin(
    admin_data: AdminCreate,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new admin account (Admin only).
    
    Args:
        admin_data: Admin profile and credentials
        current_user: Admin user
        db: Database session
        
    Returns:
        AdminResponse: Created admin profile
        
    Raises:
        409: Email already exists
        400: Validation error
    """
    try:
        admin = user_service.create_admin(db, current_user, admin_data)
        return admin
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/admins/{admin_id}", response_model=AdminResponse)
def get_admin(
    admin_id: int,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get admin profile by ID (Admin only).
    
    Args:
        admin_id: Admin ID
        current_user: Admin user
        db: Database session
        
    Returns:
        AdminResponse: Admin profile
        
    Raises:
        404: Admin not found
    """
    try:
        admin = user_service.get_admin(db, admin_id)
        return admin
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.patch("/admins/{admin_id}", response_model=AdminResponse)
def update_admin(
    admin_id: int,
    update_data: AdminUpdate,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update admin profile (Admin only).
    
    Args:
        admin_id: Admin ID
        update_data: Fields to update
        current_user: Admin user
        db: Database session
        
    Returns:
        AdminResponse: Updated admin profile
        
    Raises:
        404: Admin not found
    """
    try:
        admin = user_service.update_admin(db, current_user, admin_id, update_data)
        return admin
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


# ============================================================================
# USER STATUS MANAGEMENT
# ============================================================================

@router.patch("/users/{user_id}/status", response_model=StandardResponse)
def update_user_status(
    user_id: int,
    status_data: UserStatusUpdate,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Activate or deactivate a user account (Admin only).
    
    Args:
        user_id: User ID
        status_data: Active status
        current_user: Admin user
        db: Database session
        
    Returns:
        StandardResponse: Success message
        
    Raises:
        404: User not found
    """
    try:
        user_service.set_user_active(db, current_user, user_id, status_data)
        action = "activated" if status_data.is_active else "deactivated"
        return StandardResponse(
            success=True,
            message=f"User {action} successfully"
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/users", response_model=List[UserResponse])
def list_all_users(
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)],
    role: Optional[UserRole] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List all users with optional role filter (Admin only).
    
    Args:
        current_user: Admin user
        db: Database session
        role: Optional role filter
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[UserResponse]: List of users
    """
    users, total = user_service.list_users(db, current_user, offset=skip, limit=limit, role=role)
    return users