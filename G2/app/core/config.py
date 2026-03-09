"""
app/config.py

Centralised application configuration loaded from environment variables.

All settings are read from the environment (or a .env file in development).
No secrets or environment-specific values are hard-coded anywhere else in
the codebase — everything is imported from this module via `settings`.

Usage:
    from app.config import settings
    print(settings.DATABASE_URL)
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings.  pydantic-settings automatically reads from:
    1. Environment variables (case-insensitive).
    2. A .env file in the project root (when ENV_FILE is present).

    All fields with no default are REQUIRED — the application will fail
    to start if they are absent from the environment.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="allow"
    )

    # ------------------------------------------------------------------
    # Application
    # ------------------------------------------------------------------
    APP_NAME: str = "Intelligent Medical Assistant"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"    # development | staging | production
    DEBUG: bool = False

    # ------------------------------------------------------------------
    # Database
    # ------------------------------------------------------------------
    DATABASE_URL: str                   # e.g. postgresql://user:pass@host/dbname
    DB_ECHO: bool = False               # Set True in dev to log all SQL statements

    # ------------------------------------------------------------------
    # Authentication (JWT)
    # ------------------------------------------------------------------
    SECRET_KEY: str                     # Long random string — never commit to git
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ------------------------------------------------------------------
    # File storage
    # ------------------------------------------------------------------
    STORAGE_ROOT: str = "storage"       # Root directory for local file storage
    MAX_UPLOAD_SIZE_MB: int = 20        # Maximum allowed file upload size

    # ------------------------------------------------------------------
    # AI module configuration
    # ------------------------------------------------------------------
    WHISPER_MODEL: str = "base"         # OpenAI Whisper model size
    AI_CONFIDENCE_THRESHOLD: float = 0.6  # Minimum confidence for AI suggestions

    # ------------------------------------------------------------------
    # CORS (populate with actual frontend origin in production)
    # ------------------------------------------------------------------
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000", "http://localhost:5173"]


    # ------------------------------------------------------------------
    # API Gateway Protection
    # ------------------------------------------------------------------
    API_ACCESS_KEY: str   # Required — app will not start without it



# Singleton instance — import this everywhere, never instantiate Settings again
settings = Settings()