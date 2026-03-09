"""
Logging middleware.

Logs all incoming requests and outgoing responses with timing information.
"""

import time
import logging
from typing import Callable
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

# Configure logger
logger = logging.getLogger("api")


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware for structured request/response logging.
    
    Logs:
    - Request method, path, and client IP
    - User ID (if authenticated via request.state)
    - Response status code
    - Request duration in milliseconds
    """
    
    async def dispatch(self, request: Request, call_next: Callable):
        """
        Log request and response with timing.
        
        Args:
            request: Incoming HTTP request
            call_next: Next middleware or endpoint handler
            
        Returns:
            Response from next handler
        """
        # Start timing
        start_time = time.time()
        
        # Extract request info
        method = request.method
        path = request.url.path
        client_ip = request.client.host if request.client else "unknown"
        
        # Get user_id if available (set by auth middleware)
        user_id = getattr(request.state, "user_id", None)
        
        # Log incoming request
        logger.info(
            f"Request started: {method} {path}",
            extra={
                "method": method,
                "path": path,
                "client_ip": client_ip,
                "user_id": user_id,
                "event": "request_started"
            }
        )
        
        # Process request
        try:
            response = await call_next(request)
        except Exception as e:
            # Log exception
            duration_ms = (time.time() - start_time) * 1000
            logger.error(
                f"Request failed: {method} {path} - {str(e)}",
                extra={
                    "method": method,
                    "path": path,
                    "client_ip": client_ip,
                    "user_id": user_id,
                    "duration_ms": round(duration_ms, 2),
                    "error": str(e),
                    "event": "request_failed"
                },
                exc_info=True
            )
            raise
        
        # Calculate duration
        duration_ms = (time.time() - start_time) * 1000
        
        # Log response
        logger.info(
            f"Request completed: {method} {path} - {response.status_code}",
            extra={
                "method": method,
                "path": path,
                "client_ip": client_ip,
                "user_id": user_id,
                "status_code": response.status_code,
                "duration_ms": round(duration_ms, 2),
                "event": "request_completed"
            }
        )
        
        return response
