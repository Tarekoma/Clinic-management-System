from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse
from app.core.config import settings


class ApiKeyMiddleware(BaseHTTPMiddleware):

    async def dispatch(self, request: Request, call_next):

        print(">>> API KEY CHECK:", request.url.path)

        path = request.url.path

        # Allow ONLY exact safe endpoints
        
        if (
            path == "/"
            or path == "/health"
            or path.startswith("/docs")
            or path.startswith("/redoc")
            or path.startswith("/openapi")
            or path.startswith("/api/v1/auth")  # login & refresh are public
        ):
            return await call_next(request)

        api_key = request.headers.get("x-api-key")

        if api_key != settings.API_ACCESS_KEY:
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid or missing API key"},
            )

        return await call_next(request)
