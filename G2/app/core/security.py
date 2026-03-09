"""
app/core/security.py

Cryptographic utilities for the Intelligent Medical Assistant.

Provides:
- Password hashing and verification (bcrypt via passlib)
- JWT access token creation and decoding
- Refresh token generation (opaque random string stored as-is)

All cryptographic configuration is read from app.config.settings.
This module is imported only by auth_service.py and api/deps.py.
No other module should touch cryptographic primitives directly.
"""

from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings
from app.core.constants import UserRole

# ---------------------------------------------------------------------------
# Password hashing
# ---------------------------------------------------------------------------

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain_password: str) -> str:
    """Return a bcrypt hash of the given plain-text password."""
    return _pwd_context.hash(plain_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Return True if plain_password matches the stored bcrypt hash."""
    return _pwd_context.verify(plain_password, hashed_password)


# ---------------------------------------------------------------------------
# JWT access tokens
# ---------------------------------------------------------------------------

def create_access_token(user_id: int, role: UserRole) -> tuple[str, int]:
    """
    Create a signed JWT access token.

    Returns
    -------
    (token_string, expires_in_seconds)
    """
    expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    expire = datetime.now(timezone.utc) + expires_delta

    payload = {
        "sub": str(user_id),
        "role": role.value,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return token, int(expires_delta.total_seconds())


def decode_access_token(token: str) -> dict:
    """
    Decode and validate a JWT access token.

    Returns the raw payload dict on success.
    Raises JWTError (from python-jose) on any failure — callers convert
    this to UnauthorizedError.
    """
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


# ---------------------------------------------------------------------------
# Refresh tokens
# ---------------------------------------------------------------------------

def generate_refresh_token() -> str:
    """
    Generate a cryptographically secure opaque refresh token.

    Refresh tokens are 64-byte URL-safe random strings stored in a
    dedicated table (or as a hashed value). They are not JWTs — they
    carry no payload and cannot be decoded without database lookup.
    """
    return secrets.token_urlsafe(64)


def get_refresh_token_expiry() -> datetime:
    """Return the UTC expiry datetime for a new refresh token."""
    return datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)