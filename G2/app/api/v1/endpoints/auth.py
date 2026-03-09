"""
Authentication endpoints.

Handles:
- User login (POST /auth/login)
- Token refresh (POST /auth/refresh)
- Password change (POST /auth/change-password)
"""

from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.api.deps import get_current_user
from app.services import auth_service
from app.schemas.auth_schemas import (
    LoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    PasswordChangeRequest
)
from app.schemas.common import StandardResponse
from app.core.exceptions import (
    UnauthorizedError,
    NotFoundError,
    ValidationError as DomainValidationError
)
from app.models.user_models import User

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_200_OK)
def login(
    login_data: LoginRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Authenticate user and return JWT tokens.
    
    Args:
        login_data: Email and password
        db: Database session
        
    Returns:
        TokenResponse: Access and refresh tokens
        
    Raises:
        401: Invalid credentials
    """
    try:
        tokens = auth_service.login(db, login_data)
        return tokens
    except UnauthorizedError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during login"
        )


@router.post("/refresh", response_model=TokenResponse, status_code=status.HTTP_200_OK)
def refresh_token(
    refresh_data: RefreshTokenRequest,
    db: Annotated[Session, Depends(get_db)]
):
    """
    Refresh access token using refresh token.
    
    Args:
        refresh_data: Refresh token
        db: Database session
        
    Returns:
        TokenResponse: New access and refresh tokens
        
    Raises:
        401: Invalid or expired refresh token
    """
    try:
        tokens = auth_service.refresh_token(db, refresh_data)
        return tokens
    except UnauthorizedError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during token refresh"
        )


@router.post("/change-password", response_model=StandardResponse, status_code=status.HTTP_200_OK)
def change_password(
    password_data: PasswordChangeRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    Change user password.
    
    Args:
        password_data: Current and new password
        current_user: Authenticated user
        db: Database session
        
    Returns:
        StandardResponse: Success message
        
    Raises:
        401: Invalid current password
        400: Validation error
    """
    try:
        auth_service.change_password(db, current_user, password_data)
        return StandardResponse(
            success=True,
            message="Password changed successfully"
        )
    except UnauthorizedError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except DomainValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during password change"
        )


@router.post("/logout", response_model=StandardResponse, status_code=status.HTTP_200_OK)
def logout(
    current_user: Annotated[User, Depends(get_current_user)]
):
    """
    Logout user (client-side token invalidation).
    
    Note: Since we're using stateless JWT, actual logout happens client-side
    by discarding the token. This endpoint is provided for semantic completeness.
    
    Args:
        current_user: Authenticated user
        
    Returns:
        StandardResponse: Success message
    """
    return StandardResponse(
        success=True,
        message="Logged out successfully. Please discard your tokens."
    )