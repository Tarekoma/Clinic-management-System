"""
app/database.py

Database connection management.

Provides:
- Base      : the shared DeclarativeBase all ORM models inherit from.
- engine    : the SQLAlchemy async-compatible engine (sync here; swap to
              AsyncEngine when async SQLAlchemy is adopted).
- SessionLocal : the session factory used by get_db().
- get_db    : FastAPI dependency that yields a session per HTTP request
              and guarantees the session is closed afterwards.

Configuration is read entirely from app.config.settings so that no
database credentials are hard-coded in this file.
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings


# ---------------------------------------------------------------------------
# Declarative base — shared by ALL ORM models
# ---------------------------------------------------------------------------

class Base(DeclarativeBase):
    """
    The single metadata registry for every SQLAlchemy model in the project.

    All models must inherit from this class (not sqlalchemy.orm.Base or
    any other base) so that:
    1. Alembic autogenerate sees every table in one metadata object.
    2. Relationships can be resolved across model files without circular imports.
    """
    pass


# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------

engine = create_engine(
    settings.DATABASE_URL,
    # Pool settings tuned for a small clinic application running on a single
    # server. Adjust pool_size / max_overflow for higher-traffic deployments.
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,      # Detect stale connections before use
    pool_recycle=3600,       # Recycle connections after 1 hour
    echo=settings.DB_ECHO,   # Log all SQL in dev; disabled in prod via config
)


# ---------------------------------------------------------------------------
# Session factory
# ---------------------------------------------------------------------------

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,   # Explicit transaction control in services
    autoflush=False,    # Services call db.flush() or db.commit() explicitly
    expire_on_commit=False,  # Keep objects usable after commit without re-query
)


# ---------------------------------------------------------------------------
# FastAPI dependency
# ---------------------------------------------------------------------------

def get_db() -> Generator[Session, None, None]:
    """
    Yields a SQLAlchemy Session for the duration of one HTTP request.

    Usage in endpoint:
        @router.get("/example")
        def example(db: Session = Depends(get_db)):
            ...

    The finally block guarantees the session is closed even if the
    request handler raises an unhandled exception, preventing connection
    pool exhaustion.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
