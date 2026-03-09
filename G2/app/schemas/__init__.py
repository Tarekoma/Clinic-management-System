"""
app/schemas/__init__.py

Central re-export hub for all Pydantic schemas.

Services and endpoints import from here rather than from individual
schema files. This keeps import paths short and makes refactoring
(e.g. moving a schema between files) a single-location change.

Usage:
    from app.schemas import PatientCreate, PatientResponse
    from app.schemas import TokenResponse, LoginRequest
"""

# ---------------------------------------------------------------------------
# Common / shared
# ---------------------------------------------------------------------------
from app.schemas.common import (                    # noqa: F401
    ErrorDetail,
    ErrorResponse,
    MessageResponse,
    PaginatedResponse,
    PaginationMeta,
    PaginationParams,
    StandardResponse,
)

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------
from app.schemas.auth_schemas import (              # noqa: F401
    AuthenticatedUser,
    LoginRequest,
    PasswordChangeRequest,
    RefreshTokenRequest,
    TokenPayload,
    TokenResponse,
)

# ---------------------------------------------------------------------------
# User profiles
# ---------------------------------------------------------------------------
from app.schemas.user_schemas import (              # noqa: F401
    AdminCreate,
    AdminResponse,
    AdminUpdate,
    AssistantCreate,
    AssistantResponse,
    AssistantSummary,
    AssistantUpdate,
    DoctorCreate,
    DoctorResponse,
    DoctorSummary,
    DoctorUpdate,
    UserResponse,
    UserStatusUpdate,
)

# ---------------------------------------------------------------------------
# Clinic operations
# ---------------------------------------------------------------------------
from app.schemas.clinic_schemas import (            # noqa: F401
    AppointmentCreate,
    AppointmentResponse,
    AppointmentStatusUpdate,
    AppointmentSummary,
    AppointmentTypeCreate,
    AppointmentTypeResponse,
    AppointmentTypeSummary,
    AppointmentTypeUpdate,
    AppointmentUpdate,
    MedicalConditionCreate,
    MedicalConditionResponse,
    MedicalConditionSummary,
    MedicalConditionUpdate,
    PatientConditionAssign,
    PatientConditionResponse,
    PatientConditionUpdate,
    PatientCreate,
    PatientResponse,
    PatientSummary,
    PatientUpdate,
    VisitCreate,
    VisitResponse,
    VisitStatusUpdate,
    VisitSummary,
    VisitUpdate,
)

# ---------------------------------------------------------------------------
# Clinical reports & audit
# ---------------------------------------------------------------------------
from app.schemas.report_schemas import (            # noqa: F401
    AIMedication,
    AIReportDraft,
    AuditLogFilter,
    AuditLogResponse,
    LabReportCreate,
    LabReportResponse,
    LabReportUpdate,
    MedicalImageCreate,
    MedicalImageResponse,
    MedicalImageUpdate,
    MedicalReportCreate,
    MedicalReportResponse,
    MedicalReportStatusUpdate,
    MedicalReportSummary,
    MedicalReportUpdate,
)
