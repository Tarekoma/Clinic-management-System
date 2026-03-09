"""
app/core/exceptions.py

Domain exception hierarchy for the Intelligent Medical Assistant.

Design contract
---------------
- Services raise these exceptions — never HTTPException.
- The global error middleware (app/middleware/error_middleware.py) catches
  every AppException subclass and maps it to the correct HTTP status code.
- This separation keeps services 100% free of HTTP/FastAPI knowledge.

HTTP mapping (handled in middleware):
    NotFoundError        → 404
    UnauthorizedError    → 401
    ForbiddenError       → 403
    ConflictError        → 409
    ValidationError      → 422
    BusinessRuleError    → 400
    AIProcessingError    → 502
    AppException (base)  → 500
"""


class AppException(Exception):
    """
    Base class for all application domain exceptions.
    Carries a human-readable message and an optional machine-readable code
    for structured error responses.
    """

    def __init__(self, message: str, code: str = "internal_error") -> None:
        super().__init__(message)
        self.message = message
        self.code = code

    def __str__(self) -> str:
        return self.message


# ---------------------------------------------------------------------------
# 404 – Resource not found
# ---------------------------------------------------------------------------

class NotFoundError(AppException):
    """
    Raised when a requested resource does not exist in the database.

    Examples:
        - GET /patients/999 where patient 999 doesn't exist
        - Assigning a condition_id that isn't in medical_conditions
    """

    def __init__(self, resource: str, identifier: int | str | None = None) -> None:
        if identifier is not None:
            message = f"{resource} with id '{identifier}' was not found."
        else:
            message = f"{resource} was not found."
        super().__init__(message, code="not_found")
        self.resource = resource
        self.identifier = identifier


# ---------------------------------------------------------------------------
# 401 – Authentication failure
# ---------------------------------------------------------------------------

class UnauthorizedError(AppException):
    """
    Raised when an unauthenticated request attempts a protected action,
    or when credentials (password, token) are invalid.

    Examples:
        - Invalid login credentials
        - Expired or tampered JWT
        - Refresh token not found
    """

    def __init__(self, message: str = "Authentication is required.") -> None:
        super().__init__(message, code="unauthorized")


# ---------------------------------------------------------------------------
# 403 – Authorisation failure
# ---------------------------------------------------------------------------

class ForbiddenError(AppException):
    """
    Raised when an authenticated user attempts an action their role
    does not permit, or when they try to access another user's data.

    Examples:
        - Assistant trying to approve a medical report
        - Doctor trying to access another doctor's patients
        - Non-admin trying to deactivate a user
    """

    def __init__(self, message: str = "You do not have permission to perform this action.") -> None:
        super().__init__(message, code="forbidden")


# ---------------------------------------------------------------------------
# 409 – Conflict / duplicate
# ---------------------------------------------------------------------------

class ConflictError(AppException):
    """
    Raised when a create/update operation would violate a uniqueness
    constraint or produce an irreconcilable state conflict.

    Examples:
        - Registering a patient with a national_id that already exists
        - Creating a doctor account for an email already in use
        - Assigning the same condition to a patient twice
        - Creating a visit for an appointment that already has one
    """

    def __init__(self, message: str, code: str = "conflict") -> None:
        super().__init__(message, code=code)


# ---------------------------------------------------------------------------
# 422 – Domain-level validation failure
# ---------------------------------------------------------------------------

class ValidationError(AppException):
    """
    Raised when data passes Pydantic structural validation but fails
    domain-specific business validation rules.

    Examples:
        - Scheduling an appointment in the past
        - Setting a visit end_time before start_time
        - Password confirmation mismatch
        - new_password same as current_password
    """

    def __init__(self, message: str, field: str | None = None) -> None:
        super().__init__(message, code="validation_error")
        self.field = field


# ---------------------------------------------------------------------------
# 400 – Business rule violation
# ---------------------------------------------------------------------------

class BusinessRuleError(AppException):
    """
    Raised when an operation is structurally valid but violates a
    business process rule that cannot be expressed as a simple constraint.

    Examples:
        - Trying to approve a report that is still DRAFT (must be REVIEWED first)
        - Completing an appointment that has no visit
        - Scheduling an appointment for a doctor who is not active
        - Attempting an invalid status transition
        - Trying to finalize a report that hasn't been approved
    """

    def __init__(self, message: str, code: str = "business_rule_violation") -> None:
        super().__init__(message, code=code)


# ---------------------------------------------------------------------------
# 502 – AI module failure
# ---------------------------------------------------------------------------

class AIProcessingError(AppException):
    """
    Raised when an AI module (speech-to-text, NLP, image analysis,
    lab interpretation) fails to produce a usable result.

    Services that catch this error may choose to:
        1. Re-raise it to propagate a 502 to the client, or
        2. Store a partial result and flag the record for manual review.

    Examples:
        - Whisper model fails to transcribe (corrupted audio)
        - Image analysis model returns below-threshold confidence
        - Lab report text extraction produces no usable content
    """

    def __init__(self, module: str, reason: str) -> None:
        message = f"AI module '{module}' failed: {reason}"
        super().__init__(message, code="ai_processing_error")
        self.module = module
        self.reason = reason
