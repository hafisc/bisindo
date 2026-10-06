import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
INSTANCE_DIR = BASE_DIR / "instance"


class Config:
    """Konfigurasi dasar. Nilainya dibaca dari environment (file .env)."""

    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-ganti-di-env")

    ADMIN_USERNAME = os.environ.get("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "admin123")

    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL") or (
        f"sqlite:///{(INSTANCE_DIR / 'bisindo.db').as_posix()}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Jumlah baris per halaman pada tabel admin.
    ADMIN_PER_PAGE = 10
