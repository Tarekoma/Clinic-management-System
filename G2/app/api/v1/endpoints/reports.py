"""
Medical reports and AI-assisted documentation endpoints.

Handles:
- Voice recording transcription
- Medical report generation and management
- Medical image upload and AI analysis
- Lab report upload and interpretation
- Audit log access
"""

from typing import Annotated, List, Optional
from datetime import datetime
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
    Query,
    UploadFile,
    File,
    Form
)
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user, RequireDoctor, RequireAdmin
from app.services import report_service
from app.schemas.report_schemas import (
    MedicalReportCreate,
    MedicalReportUpdate,
    MedicalReportResponse,
    MedicalReportStatusUpdate,
    MedicalImageResponse,
    LabReportResponse,
    AuditLogResponse,
    AuditLogFilter,
    AIReportDraft
)
from app.schemas.common import StandardResponse
from app.core.exceptions import (
    NotFoundError,
    ForbiddenError,
    ValidationError as DomainValidationError,
    AIProcessingError
)
from app.core.constants import UserRole, ReportStatus, ImageType, AuditAction
from app.models.user_models import User

router = APIRouter(prefix="/reports", tags=["Medical Reports"])


# ============================================================================
# VOICE RECORDING AND TRANSCRIPTION
# ============================================================================

@router.post("/transcribe", response_model=MedicalReportResponse, status_code=status.HTTP_201_CREATED)
async def process_voice_recording(
    visit_id: int = Form(...),
    audio_file: UploadFile = File(...),
    current_user: Annotated[User, RequireDoctor] = None,
    db: Annotated[Session, Depends(get_db)] = None
):
    """
    Process doctor's voice recording and generate AI-assisted medical report.
    
    Workflow:
    1. Transcribe audio to text
    2. Extract medical entities (symptoms, diagnoses, medications)
    3. Generate structured SOAP format report
    4. Create draft medical report in database
    
    Args:
        visit_id: Visit ID for this report
        audio_file: Audio file (WAV, MP3, M4A)
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalReportResponse: Draft medical report with AI suggestions
        
    Raises:
        404: Visit not found
        400: Invalid audio file or processing error
    """
    try:
        # Save audio file temporarily
        file_content = await audio_file.read()
        
        # Process voice recording through service
        report = report_service.process_voice_recording(
            db,
            current_user,
            visit_id,
            file_content,
            audio_file.filename
        )
        return report
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except AIProcessingError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"AI processing failed: {str(e)}"
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


# ============================================================================
# MEDICAL REPORT ENDPOINTS
# ============================================================================

@router.post("/medical-reports", response_model=MedicalReportResponse, status_code=status.HTTP_201_CREATED)
def create_report_manually(
    report_data: MedicalReportCreate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Create a medical report manually (without voice recording).
    
    Args:
        report_data: Report content
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalReportResponse: Created medical report
        
    Raises:
        404: Visit not found
        403: Not authorized to create report for this visit
    """
    try:
        report = report_service.create_report_manually(db, current_user, report_data)
        return report
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


@router.get("/medical-reports/{report_id}", response_model=MedicalReportResponse)
def get_medical_report(
    report_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get medical report by ID.
    
    Args:
        report_id: Report ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        MedicalReportResponse: Medical report details
        
    Raises:
        404: Report not found
    """
    try:
        report = report_service.get_report(db, report_id)
        return report
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/medical-reports", response_model=List[MedicalReportResponse])
def list_medical_reports(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    visit_id: Optional[int] = Query(None),
    patient_id: Optional[int] = Query(None),
    doctor_id: Optional[int] = Query(None),
    status: Optional[ReportStatus] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    List medical reports with optional filters.
    
    Args:
        current_user: Authenticated user
        db: Database session
        visit_id: Filter by visit
        patient_id: Filter by patient
        doctor_id: Filter by doctor
        status: Filter by status
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[MedicalReportResponse]: List of medical reports
    """
    reports = report_service.list_reports(
        db,
        visit_id=visit_id,
        patient_id=patient_id,
        doctor_id=doctor_id,
        status=status,
        skip=skip,
        limit=limit
    )
    return reports


@router.patch("/medical-reports/{report_id}", response_model=MedicalReportResponse)
def update_medical_report(
    report_id: int,
    update_data: MedicalReportUpdate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update medical report content.
    
    Doctor can edit their own draft reports.
    
    Args:
        report_id: Report ID
        update_data: Fields to update
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalReportResponse: Updated medical report
        
    Raises:
        404: Report not found
        403: Not authorized to edit this report
        400: Cannot edit finalized report
    """
    try:
        report = report_service.update_report(db, current_user, report_id, update_data)
        return report
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
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.patch("/medical-reports/{report_id}/status", response_model=MedicalReportResponse)
def update_report_status(
    report_id: int,
    status_data: MedicalReportStatusUpdate,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Update medical report status.
    
    Transitions:
    - draft -> final (approve and finalize)
    - final -> revised (reopen for edits)
    
    Args:
        report_id: Report ID
        status_data: New status
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalReportResponse: Updated medical report
        
    Raises:
        404: Report not found
        403: Not authorized
        400: Invalid status transition
    """
    try:
        report = report_service.update_report_status(db, current_user, report_id, status_data.status)
        return report
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
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/medical-reports/{report_id}/finalize", response_model=dict)
async def finalize_report(
    report_id: int,
    current_user: Annotated[User, RequireDoctor],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Finalize medical report and generate PDF/DOCX export.
    
    Args:
        report_id: Report ID
        current_user: Doctor user
        db: Database session
        
    Returns:
        dict: Download URLs for generated documents
        
    Raises:
        404: Report not found
        403: Not authorized
        400: Report already finalized
    """
    try:
        result = report_service.finalize_report(db, current_user, report_id)
        return {
            "success": True,
            "message": "Report finalized successfully",
            "pdf_url": result.get("pdf_path"),
            "docx_url": result.get("docx_path")
        }
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
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


# ============================================================================
# MEDICAL IMAGE ENDPOINTS
# ============================================================================

@router.post("/medical-images", response_model=MedicalImageResponse, status_code=status.HTTP_201_CREATED)
async def upload_medical_image(
    visit_id: int = Form(...),
    image_type: ImageType = Form(...),
    description: Optional[str] = Form(None),
    image_file: UploadFile = File(...),
    current_user: Annotated[User, RequireDoctor] = None,
    db: Annotated[Session, Depends(get_db)] = None
):
    """
    Upload medical image and trigger AI analysis.
    
    Supported types:
    - X-RAY: Chest X-rays with AI diagnostic suggestion
    - SKIN_PHOTO: Skin condition images with AI detection
    - LAB_RESULT: Lab result images
    - OTHER: General medical images
    
    Args:
        visit_id: Visit ID
        image_type: Type of medical image
        description: Optional description
        image_file: Image file (JPEG, PNG)
        current_user: Doctor user
        db: Database session
        
    Returns:
        MedicalImageResponse: Uploaded image with AI analysis
        
    Raises:
        404: Visit not found
        400: Invalid image file or AI processing error
    """
    try:
        # Read image content
        file_content = await image_file.read()
        
        # Upload and analyze image
        result = report_service.upload_medical_image(
            db,
            current_user,
            visit_id,
            image_type,
            file_content,
            image_file.filename,
            description
        )
        return result
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except AIProcessingError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"AI analysis failed: {str(e)}"
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/medical-images/{image_id}", response_model=MedicalImageResponse)
def get_medical_image(
    image_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get medical image by ID.
    
    Args:
        image_id: Image ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        MedicalImageResponse: Image details with AI analysis
        
    Raises:
        404: Image not found
    """
    try:
        image = report_service.get_medical_image(db, image_id)
        return image
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/visits/{visit_id}/medical-images", response_model=List[MedicalImageResponse])
def list_visit_images(
    visit_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    List all medical images for a visit.
    
    Args:
        visit_id: Visit ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        List[MedicalImageResponse]: List of images
    """
    images = report_service.list_visit_images(db, visit_id)
    return images


# ============================================================================
# LAB REPORT ENDPOINTS
# ============================================================================

@router.post("/lab-reports", response_model=LabReportResponse, status_code=status.HTTP_201_CREATED)
async def upload_lab_report(
    visit_id: int = Form(...),
    test_name: str = Form(...),
    lab_name: Optional[str] = Form(None),
    report_file: UploadFile = File(...),
    current_user: Annotated[User, RequireDoctor] = None,
    db: Annotated[Session, Depends(get_db)] = None
):
    """
    Upload lab report and trigger AI interpretation.
    
    The AI extracts text from the PDF, identifies abnormal values,
    and provides an interpreted summary.
    
    Args:
        visit_id: Visit ID
        test_name: Name of the lab test
        lab_name: Optional laboratory name
        report_file: PDF file of lab results
        current_user: Doctor user
        db: Database session
        
    Returns:
        LabReportResponse: Uploaded lab report with AI interpretation
        
    Raises:
        404: Visit not found
        400: Invalid file or AI processing error
    """
    try:
        # Read file content
        file_content = await report_file.read()
        
        # Upload and interpret lab report
        result = report_service.upload_lab_report(
            db,
            current_user,
            visit_id,
            test_name,
            file_content,
            report_file.filename,
            lab_name
        )
        return result
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except AIProcessingError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"AI interpretation failed: {str(e)}"
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/lab-reports/{report_id}", response_model=LabReportResponse)
def get_lab_report(
    report_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Get lab report by ID.
    
    Args:
        report_id: Lab report ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        LabReportResponse: Lab report with AI interpretation
        
    Raises:
        404: Lab report not found
    """
    try:
        lab_report = report_service.get_lab_report(db, report_id)
        return lab_report
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/visits/{visit_id}/lab-reports", response_model=List[LabReportResponse])
def list_visit_lab_reports(
    visit_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    List all lab reports for a visit.
    
    Args:
        visit_id: Visit ID
        current_user: Authenticated user
        db: Database session
        
    Returns:
        List[LabReportResponse]: List of lab reports
    """
    reports = report_service.list_visit_lab_reports(db, visit_id)
    return reports


# ============================================================================
# AUDIT LOG ENDPOINTS (Admin only)
# ============================================================================

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    current_user: Annotated[User, RequireAdmin],
    db: Annotated[Session, Depends(get_db)],
    user_id: Optional[int] = Query(None),
    action: Optional[AuditAction] = Query(None),
    entity_type: Optional[str] = Query(None),
    entity_id: Optional[int] = Query(None),
    date_from: Optional[datetime] = Query(None),
    date_to: Optional[datetime] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100)
):
    """
    Retrieve audit logs with filters (Admin only).
    
    Args:
        current_user: Admin user
        db: Database session
        user_id: Filter by user
        action: Filter by action type
        entity_type: Filter by entity type
        entity_id: Filter by entity ID
        date_from: Filter from this date
        date_to: Filter until this date
        skip: Number of records to skip
        limit: Maximum number of records to return
        
    Returns:
        List[AuditLogResponse]: List of audit log entries
    """
    filters = AuditLogFilter(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        date_from=date_from,
        date_to=date_to
    )
    
    logs = report_service.get_audit_logs(db, filters, skip=skip, limit=limit)
    return logs