"""
Authentication middleware.

Intercepts all requests and verifies JWT tokens for protected routes.
Public routes are explicitly allowed to pass through without authentication.
"""

from typing import Callable
from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.security import decode_access_token


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Middleware for JWT token verification.
    
    Behavior:
    - Public routes: Pass through without authentication
    - Protected routes: Require valid JWT token in Authorization header
    - Invalid/expired tokens: Return 401 Unauthorized
    - Missing tokens on protected routes: Return 401 Unauthorized
    
    Note: This middleware only verifies token EXISTENCE and VALIDITY.
    User loading and role-based authorization happen in dependencies (get_current_user, require_role).
    """
    
    # Routes that don't require authentication
    PUBLIC_ROUTES = {
        "/docs",
        "/redoc",
        "/openapi.json",
        "/api/v1/auth/login",
        "/api/v1/auth/refresh",
    }
    
    async def dispatch(self, request: Request, call_next: Callable):
        """
        Intercept request and verify authentication for protected routes.
        
        Args:
            request: Incoming HTTP request
            call_next: Next middleware or endpoint handler
            
        Returns:
            Response from next handler or 401 error
        """
        # Check if route is public
        if self._is_public_route(request.url.path):
            # Allow public routes through without authentication
            return await call_next(request)
        
        # Extract Authorization header
        auth_header = request.headers.get("Authorization")
        
        if not auth_header:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Missing authentication credentials",
                    "error": "No Authorization header provided"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        # Verify Bearer token format
        if not auth_header.startswith("Bearer "):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Invalid authentication credentials",
                    "error": "Authorization header must start with 'Bearer '"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        # Extract token
        token = auth_header.replace("Bearer ", "").strip()
        
        if not token:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Invalid authentication credentials",
                    "error": "Empty token provided"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        # Validate JWT token
        try:
            # This will raise an exception if token is invalid or expired
            payload = decode_access_token(token)
            
            # Verify token has required claims
            if "sub" not in payload:
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "detail": "Invalid token payload",
                        "error": "Token missing 'sub' claim"
                    },
                    headers={"WWW-Authenticate": "Bearer"}
                )
            
            # Token is valid - store user_id in request state for potential use
            request.state.user_id = payload.get("sub")
            
        except Exception as e:
            # Token validation failed (expired, invalid signature, malformed, etc.)
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "Could not validate credentials",
                    "error": str(e) if str(e) else "Invalid or expired token"
                },
                headers={"WWW-Authenticate": "Bearer"}
            )
        
        # Token is valid - proceed to endpoint
        # Note: User loading and role checks happen in dependencies
        response = await call_next(request)
        return response
    
    def _is_public_route(self, path: str) -> bool:
        """
        Check if a route is public (doesn't require authentication).
        
        Args:
            path: Request URL path
            
        Returns:
            bool: True if route is public, False otherwise
        """
        # Exact match for public routes
        if path in self.PUBLIC_ROUTES:
            return True
        
        # Allow paths that start with public route prefixes
        for public_route in self.PUBLIC_ROUTES:
            if path.startswith(public_route):
                return True
        
        return False
