"""
Clinic operations endpoints.

Handles:
- Patient management (CRUD)
- Medical conditions
- Appointment scheduling
- Visit management
- Vital signs recording
"""

from typing import Annotated, List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import (
    get_current_user,
    RequireDoctor,
    RequireAdmin,
    RequireAssistant,
    RequireDoctorOrAssistant
)
from app.services import clinic_service
from app.schemas.clinic_schemas import (
    PatientCreate,
    PatientUpdate,
    PatientResponse,
    PatientSummary,
    MedicalConditionCreate,
    MedicalConditionResponse,
    PatientConditionAssign,
    AppointmentTypeCreate,
    AppointmentTypeUpdate,
    AppointmentTypeResponse,
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse,
    AppointmentStatusUpdate,
    VisitCreate,
    VisitResponse,
    VisitUpdate,
    VisitStatusUpdate
)
from app.schemas.common import StandardResponse
from app.core.exceptions import (
    NotFoundError,
    ConflictError,
    ValidationError as DomainValidationError,
    ForbiddenError
)
from app.core.constants import UserRole, AppointmentStatus, VisitStatus
from app.models.user_models import User

router = APIRouter(prefix="/clinic", tags=["Clinic Operations"])


# ============================================================================
# PATIENT ENDPOINTS
# ============================================================================

@router.post("/patients", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
def create_patient(
    patient_data: PatientCreate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new patient (Doctor or Assistant).
    
    Args:
        patient_data: Patient information
        current_user: Authenticated user
        db: Database session
        
    Returns:
        PatientResponse: Created patient
        
    Raises:
        409: Patient with same national ID already exists
        400: Validation error
    """
    try:
        patient = clinic_service.create_patient(db, current_user, patient_data)
        return patient
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


@router.get("/patients/{patient_id}", response_model=PatientResponse)
def get_patient(
    patient_id: int,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get patient by ID with full medical history.
    
    Args:
        patient_id: Patient ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        PatientResponse: Patient with conditions
        
    Raises:
        404: Patient not found
    """
    try:
        patient = clinic_service.get_patient(db, patient_id)
        return patient
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/patients", response_model=List[PatientResponse])
def list_patients(
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    search: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List all patients with optional search.
    
    Args:
        current_user: Authenticated user
        db: Database session
        search: Search by name or national ID
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[PatientResponse]: List of patients
    """
    patients, total = clinic_service.list_patients(db,current_user, search=search, skip=skip, limit=limit)
    return patients


@router.patch("/patients/{patient_id}", response_model=PatientResponse)
def update_patient(
    patient_id: int,
    update_data: PatientUpdate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update patient information.
    
    Args:
        patient_id: Patient ID
        update_data: Fields to update
        current_user: Authenticated user
        db: Database session
        
    Returns:
        PatientResponse: Updated patient
        
    Raises:
        404: Patient not found
    """
    try:
        patient = clinic_service.update_patient(db, current_user, patient_id, update_data)
        return patient
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.delete("/patients/{patient_id}", response_model=StandardResponse)
def delete_patient(
    patient_id: int,
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Delete a patient (soft delete - marks as inactive).
    
    Args:
        patient_id: Patient ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        StandardResponse: Success message
        
    Raises:
        404: Patient not found
    """
    try:
        clinic_service.delete_patient(db, current_user, patient_id)
        return StandardResponse(
            success=True,
            message="Patient deleted successfully"
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


# ============================================================================
# MEDICAL CONDITION ENDPOINTS
# ============================================================================

@router.post("/conditions", response_model=MedicalConditionResponse, status_code=status.HTTP_201_CREATED)
def create_condition(
    condition_data: MedicalConditionCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new medical condition in the catalog (Admin or Doctor).
    
    Args:
        condition_data: Condition information
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalConditionResponse: Created condition
    """
    try:
        condition = clinic_service.create_condition(db, current_user, condition_data)
        return condition
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )


@router.get("/conditions", response_model=List[MedicalConditionResponse])
def list_conditions(
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    search: Optional[str] = Query(None)
):
    """
    List all medical conditions with optional search.
    
    Args:
        current_user: Authenticated user
        db: Database session
        search: Search by condition name
        
    Returns:
        List[MedicalConditionResponse]: List of conditions
    """
    conditions, total = clinic_service.list_conditions(db, search=search)
    return conditions


@router.post("/patients/{patient_id}/conditions", response_model=StandardResponse, status_code=status.HTTP_201_CREATED)
def assign_condition_to_patient(
    patient_id: int,
    assignment: PatientConditionAssign,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Assign a medical condition to a patient (Doctor only).
    
    Args:
        patient_id: Patient ID
        assignment: Condition assignment data
        current_user: Doctor user
        db: Database session
        
    Returns:
        StandardResponse: Success message
        
    Raises:
        404: Patient or condition not found
        409: Condition already assigned
    """
    try:
        clinic_service.assign_condition_to_patient(db, current_user, patient_id, assignment)
        return StandardResponse(
            success=True,
            message="Condition assigned to patient successfully"
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )


@router.delete("/patients/{patient_id}/conditions/{condition_id}", response_model=StandardResponse)
def remove_condition_from_patient(
    patient_id: int,
    condition_id: int,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Remove a medical condition from a patient (Doctor only).
    
    Args:
        patient_id: Patient ID
        condition_id: Condition ID
        current_user: Doctor user
        db: Database session
        
    Returns:
        StandardResponse: Success message
        
    Raises:
        404: Assignment not found
    """
    try:
        clinic_service.remove_patient_condition(db, current_user, patient_id, condition_id)
        return StandardResponse(
            success=True,
            message="Condition removed from patient successfully"
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


# ============================================================================
# APPOINTMENT TYPE ENDPOINTS
# ============================================================================

@router.post("/appointment-types", response_model=AppointmentTypeResponse, status_code=status.HTTP_201_CREATED)
def create_appointment_type(
    type_data: AppointmentTypeCreate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a new appointment type (Doctor only).
    
    Args:
        type_data: Appointment type details
        current_user: Doctor user
        db: Database session
        
    Returns:
        AppointmentTypeResponse: Created appointment type
    """
    from app.models.user_models import Doctor

    # Get doctor.id from user.id
    doctor = db.query(Doctor).filter(Doctor.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor profile not found for current user"
        )

    appointment_type = clinic_service.create_appointment_type(db, current_user, doctor.id, type_data)
    return appointment_type


@router.get("/appointment-types", response_model=List[AppointmentTypeResponse])
def list_appointment_types(
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    doctor_id: Optional[int] = Query(None)
):
    """
    List appointment types, optionally filtered by doctor.
    
    Args:
        current_user: Authenticated user
        db: Database session
        doctor_id: Optional filter by doctor
        
    Returns:
        List[AppointmentTypeResponse]: List of appointment types
    """
    appointment_types = clinic_service.list_appointment_types(db, doctor_id=doctor_id)
    return appointment_types


@router.patch("/appointment-types/{type_id}", response_model=AppointmentTypeResponse)
def update_appointment_type(
    type_id: int,
    update_data: AppointmentTypeUpdate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update appointment type (Doctor can only update their own types).
    
    Args:
        type_id: Appointment type ID
        update_data: Fields to update
        current_user: Doctor user
        db: Database session
        
    Returns:
        AppointmentTypeResponse: Updated appointment type
        
    Raises:
        404: Appointment type not found
        403: Not authorized
    """
    try:
        appointment_type = clinic_service.update_appointment_type(db, current_user, type_id, update_data)
        return appointment_type
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


# ============================================================================
# APPOINTMENT ENDPOINTS
# ============================================================================

@router.post("/appointments", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
def schedule_appointment(
    appointment_data: AppointmentCreate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Schedule a new appointment.
    
    Args:
        appointment_data: Appointment details
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AppointmentResponse: Created appointment
        
    Raises:
        404: Patient, doctor, or appointment type not found
        409: Doctor unavailable at requested time
        400: Validation error
    """
    try:
        appointment = clinic_service.schedule_appointment(db, current_user, appointment_data)
        return appointment
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
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


@router.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(
    appointment_id: int,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get appointment by ID.
    
    Args:
        appointment_id: Appointment ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AppointmentResponse: Appointment details
        
    Raises:
        404: Appointment not found
    """
    try:
        appointment = clinic_service.get_appointment(db, appointment_id)
        return appointment
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/appointments", response_model=List[AppointmentResponse])
def list_appointments(
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    doctor_id: Optional[int] = Query(None),
    patient_id: Optional[int] = Query(None),
    status: Optional[AppointmentStatus] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List appointments with optional filters.
    
    Args:
        current_user: Authenticated user
        db: Database session
        doctor_id: Filter by doctor
        patient_id: Filter by patient
        status: Filter by status
        date_from: Filter appointments from this date
        date_to: Filter appointments until this date
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[AppointmentResponse]: List of appointments
    """
    appointments, total = clinic_service.list_appointments(
        db,
        current_user,
        doctor_id=doctor_id,
        patient_id=patient_id,
        status=status,
        date_from=date_from,
        date_to=date_to,
        offset=skip,
        limit=limit
    )
    return appointments


@router.patch("/appointments/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(
    appointment_id: int,
    update_data: AppointmentUpdate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update appointment details.
    
    Args:
        appointment_id: Appointment ID
        update_data: Fields to update
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AppointmentResponse: Updated appointment
        
    Raises:
        404: Appointment not found
        409: New time conflicts with existing appointment
    """
    try:
        appointment = clinic_service.update_appointment(db, current_user, appointment_id, update_data)
        return appointment
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )


@router.patch("/appointments/{appointment_id}/status", response_model=AppointmentResponse)
def update_appointment_status(
    appointment_id: int,
    status_data: AppointmentStatusUpdate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update appointment status.
    
    Args:
        appointment_id: Appointment ID
        status_data: New status
        current_user: Authenticated user
        db: Database session
        
    Returns:
        AppointmentResponse: Updated appointment
        
    Raises:
        404: Appointment not found
        400: Invalid status transition
    """
    try:
        appointment = clinic_service.update_appointment_status(db, current_user, appointment_id, status_data)
        return appointment
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/doctors/{doctor_id}/availability")
def check_doctor_availability(
    doctor_id: int,
    appointment_datetime: datetime,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    duration_minutes: int = Query(30, ge=15, le=240)
):
    """
    Check if doctor is available at a specific time.
    
    Args:
        doctor_id: Doctor ID
        appointment_datetime: Requested appointment time
        duration_minutes: Appointment duration
        current_user: Authenticated user
        db: Database session
        
    Returns:
        dict: Availability status
    """
    is_available = clinic_service.check_doctor_availability(
        db,
        doctor_id,
        appointment_datetime,
        duration_minutes
    )
    return {
        "doctor_id": doctor_id,
        "appointment_datetime": appointment_datetime,
        "duration_minutes": duration_minutes,
        "is_available": is_available
    }


# ============================================================================
# VISIT ENDPOINTS
# ============================================================================

@router.post("/visits", response_model=VisitResponse, status_code=status.HTTP_201_CREATED)
def start_visit(
    visit_data: VisitCreate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Start a new visit (check-in patient).
    
    Args:
        visit_data: Visit details and appointment reference
        current_user: Authenticated user
        db: Database session
        
    Returns:
        VisitResponse: Created visit
        
    Raises:
        404: Appointment not found
        400: Validation error
    """
    try:
        visit = clinic_service.start_visit(db, current_user, visit_data)
        return visit
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/visits/{visit_id}", response_model=VisitResponse)
def get_visit(
    visit_id: int,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get visit by ID.
    
    Args:
        visit_id: Visit ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        VisitResponse: Visit details
        
    Raises:
        404: Visit not found
    """
    try:
        visit = clinic_service.get_visit(db, visit_id)
        return visit
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/visits", response_model=List[VisitResponse])
def list_visits(
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)],
    doctor_id: Optional[int] = Query(None),
    patient_id: Optional[int] = Query(None),
    status: Optional[VisitStatus] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List visits with optional filters.
    
    Args:
        current_user: Authenticated user
        db: Database session
        doctor_id: Filter by doctor
        patient_id: Filter by patient
        status: Filter by status
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[VisitResponse]: List of visits
    """
    visits, total = clinic_service.list_visits(
        db,
        current_user,
        doctor_id=doctor_id,
        patient_id=patient_id,
        status=status,
        offset=skip,
        limit=limit
    )
    return visits


"""@router.patch("/visits/{visit_id}/vitals", response_model=VisitResponse)
def record_vitals(
    visit_id: int,
    vitals_data: VitalsUpdate,
    current_user: Annotated[User, RequireDoctorOrAssistant],
    db: Annotated[Session, Depends(get_db)]
):
  """"""
    Record vital signs for a visit.
    
    Args:
        visit_id: Visit ID
        vitals_data: Vital signs
        current_user: Authenticated user
        db: Database session
        
    Returns:
        VisitResponse: Updated visit
        
    Raises:
        404: Visit not found
    """"""
    try:
        visit = clinic_service.record_vitals(db, current_user, visit_id, vitals_data)
        return visit
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
"""


@router.patch("/visits/{visit_id}", response_model=VisitResponse)
def update_visit(
    visit_id: int,
    update_data: VisitUpdate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update visit information (Doctor only).
    
    Args:
        visit_id: Visit ID
        update_data: Fields to update
        current_user: Doctor user
        db: Database session
        
    Returns:
        VisitResponse: Updated visit
        
    Raises:
        404: Visit not found
    """
    try:
        visit = clinic_service.update_visit(db, current_user, visit_id, update_data)
        return visit
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.patch("/visits/{visit_id}/status", response_model=VisitResponse)
def update_visit_status(
    visit_id: int,
    status_data: VisitStatusUpdate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update visit status (Doctor only).
    
    Args:
        visit_id: Visit ID
        status_data: New status
        current_user: Doctor user
        db: Database session
        
    Returns:
        VisitResponse: Updated visit
        
    Raises:
        404: Visit not found
        400: Invalid status transition
    """
    try:
        visit = clinic_service.update_visit_status(db, current_user, visit_id, status_data)
        return visit
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )