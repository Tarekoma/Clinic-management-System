"""
Application entry point.

Initializes the FastAPI application and wires together all components.
Configures middleware, CORS, routers, and static file serving.
"""

from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.openapi.utils import get_openapi

from app.core.config import settings
from app.api.v1.router import api_router
from app.middleware.error_middleware import ErrorMiddleware
from app.middleware.logging_middleware import LoggingMiddleware
from app.middleware.auth_middleware import AuthMiddleware
from app.middleware.api_key_middleware import ApiKeyMiddleware

from dotenv import load_dotenv
load_dotenv()


# API version prefix
API_V1_STR = "/api/v1"

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
    description="Intelligent Medical Assistant API for clinic management and AI-powered medical record processing"
)


# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# NOTE: add_middleware() runs in REVERSE order (last added = outermost).
# To achieve: Error → Logging → ApiKey → Auth
# We must add them in reverse:
app.add_middleware(AuthMiddleware)      # innermost - runs last
app.add_middleware(ApiKeyMiddleware)    # validates API key
app.add_middleware(LoggingMiddleware)   # logs requests/responses
app.add_middleware(ErrorMiddleware)     # outermost - catches all exceptions

# Include API v1 router with all endpoints
app.include_router(api_router, prefix=API_V1_STR)

# Create storage directory if it doesn't exist and mount for static file serving
storage_path = Path(settings.STORAGE_ROOT)
storage_path.mkdir(parents=True, exist_ok=True)

app.mount(
    "/uploads",
    StaticFiles(directory=str(storage_path)),
    name="uploads"
)


# Custom OpenAPI schema to expose both security schemes in Swagger UI
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    schema = get_openapi(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="Intelligent Medical Assistant API for clinic management and AI-powered medical record processing",
        routes=app.routes,
    )

    # Ensure components section exists
    schema.setdefault("components", {})
    schema["components"].setdefault("securitySchemes", {})

    # Register API key header scheme
    schema["components"]["securitySchemes"]["ApiKeyHeader"] = {
        "type": "apiKey",
        "in": "header",
        "name": "x-api-key",
        "description": "API key required for all requests. Found in your .env as API_ACCESS_KEY."
    }

    # Register Bearer JWT scheme
    schema["components"]["securitySchemes"]["HTTPBearer"] = {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT",
        "description": "JWT access token obtained from /api/v1/auth/login."
    }

    # ✅ Apply both schemes to EVERY individual endpoint (not just globally)
    for path_data in schema.get("paths", {}).values():
        for operation in path_data.values():
            if isinstance(operation, dict):
                operation["security"] = [
                    {"ApiKeyHeader": []},
                    {"HTTPBearer": []}
                ]

    # Also set globally as fallback
    schema["security"] = [
        {"ApiKeyHeader": []},
        {"HTTPBearer": []}
    ]

    app.openapi_schema = schema
    return app.openapi_schema


app.openapi = custom_openapi


# Root endpoint for health checks
@app.get("/", tags=["health"])
async def root():
    """
    Health check endpoint.

    Returns basic application information to verify the API is running.
    Useful for load balancers, monitoring tools, and quick status checks.

    Returns:
        dict: Application name, version, status, and environment
    """
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "healthy",
        "environment": settings.ENVIRONMENT
    }


@app.get("/health", tags=["health"])
async def health_check():
    """
    Detailed health check endpoint.

    Can be extended to include database connectivity checks,
    external service availability, etc.

    Returns:
        dict: Detailed health status
    """
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "debug_mode": settings.DEBUG
    }