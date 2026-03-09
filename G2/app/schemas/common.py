"""
app/schemas/common.py

Shared building blocks used across all schema files.

Provides:
- PaginationParams  : query-parameter schema for paginated list endpoints.
- PaginatedResponse : generic wrapper for paginated list responses.
- SuccessResponse   : standard envelope for non-list mutation responses.
- ErrorDetail       : single validation or domain error description.
- ErrorResponse     : standard error envelope returned by the error middleware.

Usage pattern in endpoints:
    @router.get("/patients", response_model=PaginatedResponse[PatientResponse])
    def list_patients(pagination: PaginationParams = Depends(), ...):
        ...

    @router.post("/patients", response_model=SuccessResponse[PatientResponse])
    def create_patient(...):
        ...
"""

from __future__ import annotations

from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field

# Generic type variable for the `data` field of response wrappers.
T = TypeVar("T")


# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------

class PaginationParams(BaseModel):
    """
    Standard query parameters for all list/collection endpoints.
    Injected via FastAPI's Depends() mechanism.

    Defaults: page 1, 20 items per page, max 100 per page.
    """

    model_config = ConfigDict(from_attributes=True)

    page: int = Field(
        default=1,
        ge=1,
        description="1-based page number.",
    )
    page_size: int = Field(
        default=20,
        ge=1,
        le=100,
        description="Number of items per page. Maximum 100.",
    )

    @property
    def offset(self) -> int:
        """SQLAlchemy-compatible offset for the current page."""
        return (self.page - 1) * self.page_size

    @property
    def limit(self) -> int:
        """SQLAlchemy-compatible limit (alias for page_size)."""
        return self.page_size


class PaginationMeta(BaseModel):
    """
    Metadata block embedded in every paginated response.
    Gives clients everything they need to render pagination controls.
    """

    model_config = ConfigDict(from_attributes=True)

    page: int = Field(description="Current page number (1-based).")
    page_size: int = Field(description="Items per page requested.")
    total_items: int = Field(description="Total number of matching records.")
    total_pages: int = Field(description="Total number of pages for this result set.")
    has_next: bool = Field(description="True if a next page exists.")
    has_previous: bool = Field(description="True if a previous page exists.")


class PaginatedResponse(BaseModel, Generic[T]):
    """
    Generic wrapper for all paginated list endpoints.

    Example JSON:
    {
        "success": true,
        "data": [...],
        "meta": { "page": 1, "page_size": 20, ... }
    }
    """

    model_config = ConfigDict(from_attributes=True)

    success: bool = True
    data: list[T]
    meta: PaginationMeta


# ---------------------------------------------------------------------------
# Standard success envelope
# ---------------------------------------------------------------------------

class StandardResponse(BaseModel, Generic[T]):
    """
    Generic wrapper for create / update / retrieve single-item responses.

    Example JSON:
    {
        "success": true,
        "message": "Patient created successfully.",
        "data": { ... }
    }
    """

    model_config = ConfigDict(from_attributes=True)

    success: bool = True
    message: str | None = None
    data: T | None = None


class MessageResponse(BaseModel):
    """
    Lightweight response for actions that produce no data payload
    (e.g. logout, deactivate user, delete record).

    Example JSON:
    {
        "success": true,
        "message": "User deactivated successfully."
    }
    """

    model_config = ConfigDict(from_attributes=True)

    success: bool = True
    message: str


# ---------------------------------------------------------------------------
# Error responses
# ---------------------------------------------------------------------------

class ErrorDetail(BaseModel):
    """
    Describes a single error or validation failure.
    Used both for field-level validation errors (loc is set) and
    domain-level errors (loc is None).
    """

    model_config = ConfigDict(from_attributes=True)

    loc: list[str] | None = Field(
        default=None,
        description="JSON path to the field that caused the error, e.g. ['body', 'email'].",
    )
    msg: str = Field(description="Human-readable error description.")
    type: str = Field(description="Machine-readable error code, e.g. 'value_error.email'.")


class ErrorResponse(BaseModel):
    """
    Standard error envelope returned by the global error middleware for
    all 4xx and 5xx responses.

    Example JSON (validation error):
    {
        "success": false,
        "message": "Validation failed.",
        "errors": [
            { "loc": ["body", "email"], "msg": "Invalid email address.", "type": "value_error.email" }
        ]
    }

    Example JSON (domain error):
    {
        "success": false,
        "message": "Patient not found.",
        "errors": []
    }
    """

    model_config = ConfigDict(from_attributes=True)

    success: bool = False
    message: str
    errors: list[ErrorDetail] = []