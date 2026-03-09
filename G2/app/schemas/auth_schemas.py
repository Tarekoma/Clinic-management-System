"""
app/schemas/auth_schemas.py

Request and response schemas for the authentication flow.

Covers:
- Login request / response
- Token refresh request / response
- Password change request
- The authenticated user context embedded in JWT payloads

Security notes:
- Passwords are accepted as plain strings here (min 8 chars enforced).
  Hashing is the responsibility of auth_service.py — never done in schemas.
- Tokens are opaque strings from the schema layer's perspective.
  Decoding/validation is the responsibility of core/security.py.
- password_hash is NEVER exposed in any response schema.
"""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.constants import UserRole


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class LoginRequest(BaseModel):
    """
    Credentials submitted to POST /auth/login.
    email + password are the only accepted login method.
    """

    model_config = ConfigDict(from_attributes=True)

    email: EmailStr = Field(
        description="Registered email address of the user.",
        examples=["admin@system.com"],
    )
    password: str = Field(
        min_length=8,
        description="Plain-text password. Must be at least 8 characters.",
        examples=["Admin123!"],
    )


class RefreshTokenRequest(BaseModel):
    """
    Body submitted to POST /auth/refresh.
    The client sends the refresh token it received at login.
    """

    model_config = ConfigDict(from_attributes=True)

    refresh_token: str = Field(
        description="The refresh token issued at login or the last refresh.",
    )


class PasswordChangeRequest(BaseModel):
    """
    Body submitted to POST /auth/change-password.
    Requires the current password for confirmation before accepting the new one.
    """

    model_config = ConfigDict(from_attributes=True)

    current_password: str = Field(
        min_length=8,
        description="The user's current password for verification.",
    )
    new_password: str = Field(
        min_length=8,
        description="The desired new password. Must be at least 8 characters.",
    )
    confirm_new_password: str = Field(
        min_length=8,
        description="Must match new_password exactly.",
    )

    @field_validator("confirm_new_password")
    @classmethod
    def passwords_match(cls, v: str, info) -> str:
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Passwords do not match")
        return v


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class TokenResponse(BaseModel):
    """
    Returned by POST /auth/login and POST /auth/refresh.
    Contains both the short-lived access token and the long-lived refresh token.

    token_type is always "bearer" — included so clients can construct
    the Authorization header value without hard-coding the scheme.
    """

    model_config = ConfigDict(from_attributes=True)

    access_token: str = Field(
        description="Short-lived JWT. Include in Authorization: Bearer <token> header.",
    )
    refresh_token: str = Field(
        description="Long-lived token used to obtain a new access token.",
    )
    token_type: str = Field(
        default="bearer",
        description="Always 'bearer'. Used to build the Authorization header.",
    )
    expires_in: int = Field(
        description="Access token lifetime in seconds.",
    )


class TokenPayload(BaseModel):
    """
    The decoded contents of a valid JWT access token.
    Used internally by core/security.py and api/deps.py — not returned to clients.

    sub  : the user's integer primary key, stored as a string per JWT convention.
    role : the user's role, used for RBAC checks without an extra DB query.
    """

    model_config = ConfigDict(from_attributes=True)

    sub: str = Field(description="Subject — the user's id as a string.")
    role: UserRole = Field(description="User's role for RBAC checks.")
    exp: int = Field(description="Unix timestamp of token expiry.")


class AuthenticatedUser(BaseModel):
    """
    The current-user context object resolved by api/deps.get_current_user().
    Injected into every protected endpoint via FastAPI's Depends() mechanism.

    This is NOT a response schema — it lives only in the request lifecycle.
    It is placed here because it is derived from auth and used across layers.
    """

    model_config = ConfigDict(from_attributes=True)

    id: int = Field(description="User primary key.")
    email: str = Field(description="User's email address.")
    role: UserRole = Field(description="User's role for permission checks.")
    is_active: bool = Field(description="Whether the account is currently active.")