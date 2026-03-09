# app/utils/file_handler.py
import uuid
from pathlib import Path
from app.core.config import settings

def save_upload(file_bytes: bytes, filename: str, subfolder: str) -> str:
    """Save uploaded bytes to disk, return relative path string."""
    ext = Path(filename).suffix.lower()
    unique_name = f'{uuid.uuid4().hex}{ext}'
    dest_dir = Path(settings.STORAGE_ROOT) / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / unique_name
    dest_path.write_bytes(file_bytes)
    return str(dest_path)
