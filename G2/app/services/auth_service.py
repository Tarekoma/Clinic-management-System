"""
app/services/auth_service.py

Authentication lifecycle service.

Use cases implemented
---------------------
- login()              : verify credentials, issue token pair
- logout()             : record logout in audit log
- refresh_token()      : validate refresh token, issue new access token
- change_password()    : verify current password, apply new hash, audit

Business rules
--------------
- Deactivated users cannot log in (is_active=False → UnauthorizedError).
- Wrong credentials always raise UnauthorizedError with a generic message
  (no hint about whether email or password was wrong).
- Password changes require the current password for confirmation.
- New password must differ from the current password.
- Refresh tokens are treated as opaque strings; in this implementation
  they are stored in-memory in the token payload. A production hardening
  step would store a hashed version in a separate `refresh_tokens` table.

Audit events
------------
- LOGIN, LOGOUT, TOKEN_REFRESH, PASSWORD_CHANGE
"""

from __future__ import annotations

import logging

from sqlalchemy.orm import Session

from app.core.constants import AuditAction
from app.core.exceptions import BusinessRuleError, UnauthorizedError, ValidationError
from app.core.security import (
    create_access_token,
    decode_access_token,
    generate_refresh_token,
    hash_password,
    verify_password,
)
from app.models.user_models import User
from app.models.report_models import AuditLog
from app.schemas.auth_schemas import (
    AuthenticatedUser,
    LoginRequest,
    PasswordChangeRequest,
    RefreshTokenRequest,
    TokenResponse,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _write_audit(
    db: Session,
    user_id: int | None,
    action: AuditAction,
    ip_address: str | None = None,
    details: str | None = None,
) -> None:
    """Append a row to audit_logs. Never raises — failures are logged only."""
    try:
        entry = AuditLog(
            user_id=user_id,
            action=action,
            entity_type="user",
            entity_id=user_id,
            details=details,
            ip_address=ip_address,
        )
        db.add(entry)
        db.flush()
    except Exception as exc:
        logger.error("Failed to write audit log (action=%s): %s", action, exc)


def _get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def _get_user_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()


# ---------------------------------------------------------------------------
# Public use cases
# ---------------------------------------------------------------------------

def login(
    db: Session,
    data: LoginRequest,
    ip_address: str | None = None,
) -> TokenResponse:
    """
    Authenticate a user and return a JWT token pair.

    Raises
    ------
    UnauthorizedError
        - Email not found.
        - Password is incorrect.
        - Account is deactivated.
    """
    user = _get_user_by_email(db, data.email)

    # Use generic message — never reveal whether email or password was wrong.
    if user is None or not verify_password(data.password, user.password_hash):
        _write_audit(db, None, AuditAction.LOGIN, ip_address, "Failed login attempt.")
        db.commit()
        raise UnauthorizedError("Invalid email or password.")

    if not user.is_active:
        _write_audit(db, user.id, AuditAction.LOGIN, ip_address, "Login rejected — account deactivated.")
        db.commit()
        raise UnauthorizedError("This account has been deactivated. Contact your administrator.")

    access_token, expires_in = create_access_token(user.id, user.role)
    refresh_token = generate_refresh_token()

    _write_audit(db, user.id, AuditAction.LOGIN, ip_address, "Successful login.")
    db.commit()

    logger.info("User %d (%s) logged in.", user.id, user.role)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=expires_in,
    )


def logout(
    db: Session,
    current_user: AuthenticatedUser,
    ip_address: str | None = None,
) -> None:
    """
    Record a logout event in the audit log.

    Note: JWT tokens are stateless — the client is responsible for
    discarding the token. A production hardening step would maintain
    a token denylist (Redis / DB table) to invalidate tokens server-side.
    """
    _write_audit(db, current_user.id, AuditAction.LOGOUT, ip_address)
    db.commit()
    logger.info("User %d logged out.", current_user.id)


def refresh_token(
    db: Session,
    data: RefreshTokenRequest,
    ip_address: str | None = None,
) -> TokenResponse:
    """
    Issue a new access token using a valid refresh token.

    In this implementation the refresh token embeds the user_id in a
    simple encoded form. A production upgrade would look up the token
    in a refresh_tokens table to enable server-side revocation.

    Raises
    ------
    UnauthorizedError
        - Refresh token is invalid or cannot be decoded.
        - Associated user is not found or deactivated.
    """
    # Decode the refresh token to extract user context.
    # Here we use the same JWT infrastructure — in production use a
    # separate signing key and a dedicated refresh token table.
    try:
        payload = decode_access_token(data.refresh_token)
        user_id = int(payload["sub"])
    except Exception:
        raise UnauthorizedError("Invalid or expired refresh token.")

    user = _get_user_by_id(db, user_id)
    if user is None or not user.is_active:
        raise UnauthorizedError("Invalid or expired refresh token.")

    access_token, expires_in = create_access_token(user.id, user.role)
    new_refresh_token = generate_refresh_token()

    _write_audit(db, user.id, AuditAction.TOKEN_REFRESH, ip_address)
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=expires_in,
    )


def change_password(
    db: Session,
    current_user: AuthenticatedUser,
    data: PasswordChangeRequest,
    ip_address: str | None = None,
) -> None:
    """
    Change the authenticated user's password.

    Business rules:
    - current_password must match the stored hash.
    - new_password must match confirm_new_password.
    - new_password must differ from current_password.

    Raises
    ------
    ValidationError
        - Confirmation mismatch.
        - New password same as current.
    UnauthorizedError
        - Current password is incorrect.
    """
    user = _get_user_by_id(db, current_user.id)
    if user is None:
        raise UnauthorizedError("User not found.")

    if not verify_password(data.current_password, user.password_hash):
        raise UnauthorizedError("Current password is incorrect.")

    if data.new_password != data.confirm_new_password:
        raise ValidationError("New password and confirmation do not match.", field="confirm_new_password")

    if verify_password(data.new_password, user.password_hash):
        raise ValidationError("New password must be different from the current password.", field="new_password")

    user.password_hash = hash_password(data.new_password)
    db.add(user)

    _write_audit(db, user.id, AuditAction.PASSWORD_CHANGE, ip_address)
    db.commit()
    logger.info("User %d changed their password.", user.id)