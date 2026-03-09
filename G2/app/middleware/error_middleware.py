"""
Error handling middleware.

Catches all unhandled exceptions and converts them to proper HTTP responses.
Maps domain exceptions to appropriate HTTP status codes.
"""

import logging
from typing import Callable
from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.exceptions import (
    AppException,
    NotFoundError,
    UnauthorizedError,
    ForbiddenError,
    ConflictError,
    ValidationError as DomainValidationError,
    AIProcessingError
)

# Configure logger
logger = logging.getLogger("api.errors")


class ErrorMiddleware(BaseHTTPMiddleware):
    """
    Global error handling middleware.
    
    Catches all exceptions and converts them to standardized JSON responses.
    Domain exceptions are mapped to appropriate HTTP status codes.
    Unexpected exceptions return 500 with sanitized error messages.
    """
    
    async def dispatch(self, request: Request, call_next: Callable):
        """
        Catch and handle all exceptions.
        
        Args:
            request: Incoming HTTP request
            call_next: Next middleware or endpoint handler
            
        Returns:
            Response from next handler or error response
        """
        try:
            response = await call_next(request)
            return response
            
        except NotFoundError as e:
            # Resource not found - 404
            logger.warning(
                f"NotFoundError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "NotFoundError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_404_NOT_FOUND,
                content={
                    "detail": str(e),
                    "error_type": "not_found"
                }
            )
            
        except UnauthorizedError as e:
            # Authentication failed - 401
            logger.warning(
                f"UnauthorizedError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "UnauthorizedError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": str(e),
                    "error_type": "unauthorized"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
            
        except ForbiddenError as e:
            # Insufficient permissions - 403
            logger.warning(
                f"ForbiddenError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "ForbiddenError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={
                    "detail": str(e),
                    "error_type": "forbidden"
                }
            )
            
        except ConflictError as e:
            # Resource conflict - 409
            logger.warning(
                f"ConflictError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "ConflictError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_409_CONFLICT,
                content={
                    "detail": str(e),
                    "error_type": "conflict"
                }
            )
            
        except DomainValidationError as e:
            # Validation error - 400
            logger.warning(
                f"ValidationError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "ValidationError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={
                    "detail": str(e),
                    "error_type": "validation_error"
                }
            )
            
        except AIProcessingError as e:
            # AI processing failed - 400
            logger.warning(
                f"AIProcessingError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "AIProcessingError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={
                    "detail": f"AI processing failed: {str(e)}",
                    "error_type": "ai_processing_error"
                }
            )
            
        except AppException as e:
            # Base application exception - 500
            logger.error(
                f"AppException: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "AppException",
                    "error_message": str(e)
                },
                exc_info=True
            )
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={
                    "detail": str(e),
                    "error_type": "application_error"
                }
            )
            
        except ValueError as e:
            # Invalid value - 400
            logger.warning(
                f"ValueError: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": "ValueError",
                    "error_message": str(e)
                }
            )
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={
                    "detail": str(e),
                    "error_type": "invalid_value"
                }
            )
            
        except Exception as e:
            # Unexpected error - 500
            logger.error(
                f"Unexpected error: {str(e)}",
                extra={
                    "path": request.url.path,
                    "error_type": type(e).__name__,
                    "error_message": str(e)
                },
                exc_info=True
            )
            
            # Don't expose internal error details in production
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={
                    "detail": "An internal error occurred. Please contact support if the problem persists.",
                    "error_type": "internal_server_error"
                }
            )
