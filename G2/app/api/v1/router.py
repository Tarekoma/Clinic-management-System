"""
Main API v1 router.

Aggregates all endpoint routers and provides the main API entry point.
"""

from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, clinic, reports

# Create main API v1 router
api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(clinic.router)
api_router.include_router(reports.router)