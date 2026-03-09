"""
Dependency injection for FastAPI endpoints.

Provides:
- Database session management
- Current user extraction from JWT
- Role-based access control dependencies
"""

from typing import Annotated, List
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.core.exceptions import UnauthorizedError, ForbiddenError
from app.core.constants import UserRole
from app.models.user_models import User

# Security scheme for JWT Bearer token
security = HTTPBearer()


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: Annotated[Session, Depends(get_db)]
) -> User:
    """
    Extract and validate current user from JWT token.
    
    Args:
        credentials: Bearer token from Authorization header
        db: Database session
        
    Returns:
        User: Authenticated user object
        
    Raises:
        HTTPException 401: If token is invalid or user not found
        HTTPException 403: If user is inactive
    """
    try:
        token = credentials.credentials
        payload = decode_access_token(token)
        user_id: int = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Load user from database
    user = db.query(User).filter(User.id == user_id).first()
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user account"
        )
    
    return user


def require_role(allowed_roles: List[UserRole]):
    """
    Factory function to create role-checking dependency.
    
    Args:
        allowed_roles: List of UserRole enums that are allowed
        
    Returns:
        Dependency function that checks user role
        
    Usage:
        @router.get("/admin-only")
        async def admin_endpoint(
            current_user: Annotated[User, Depends(require_role([UserRole.ADMIN]))]
        ):
            ...
    """
    def role_checker(current_user: Annotated[User, Depends(get_current_user)]) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {[r.value for r in allowed_roles]}"
            )
        return current_user
    
    return role_checker


# Convenience dependencies for common role checks
RequireDoctor = Depends(require_role([UserRole.DOCTOR]))
RequireAssistant = Depends(require_role([UserRole.ASSISTANT]))
RequireAdmin = Depends(require_role([UserRole.ADMIN]))
RequireDoctorOrAssistant = Depends(require_role([UserRole.DOCTOR, UserRole.ASSISTANT]))
RequireAnyRole = Depends(get_current_user)