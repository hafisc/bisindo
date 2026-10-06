from datetime import datetime, timezone

from .extensions import db


def utcnow() -> datetime:
    """Waktu UTC tanpa tzinfo, supaya konsisten dengan SQLite."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


class User(db.Model):
    """Pengguna aplikasi mobile.

    Tabel ini diisi oleh endpoint auth (`/api/auth/register`). Halaman admin
    hanya membacanya.
    """

    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(255), nullable=False, unique=True, index=True)
    password_hash = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=utcnow)

    logs = db.relationship("DetectionLog", back_populates="user")


class DetectionLog(db.Model):
    """Satu hasil deteksi huruf dari aplikasi mobile.

    Tabel ini diisi oleh endpoint predict atau history. Halaman admin hanya
    membacanya.
    """

    __tablename__ = "detection_logs"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True, index=True)
    letter = db.Column(db.String(8), nullable=False, index=True)
    confidence = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=utcnow, index=True)

    user = db.relationship("User", back_populates="logs")
