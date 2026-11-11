"""Helper identitas pengguna untuk endpoint /api/*.

Aplikasi mobile sudah login lewat Firebase Auth, jadi identitas yang dikirim
ke API adalah Firebase UID. Nilai ini dibaca dari header `X-User-Id`, dengan
fallback ke query string `user_id` atau body JSON `user_id`.

Catatan keamanan: UID belum diverifikasi tanda tangan (butuh firebase-admin
untuk itu). Ini sejalan dengan `/api/predict` yang juga mempercayai `user_id`
dari body. Lihat README bagian "Keamanan API" untuk rencana peningkatan.
"""

from flask import request
from sqlalchemy import select

from ..extensions import db
from ..models import User


class IdentityError(Exception):
    """Identitas pengguna tidak ditemukan pada request."""

    def __init__(self, message: str, status: int = 401):
        super().__init__(message)
        self.message = message
        self.status = status


def get_firebase_uid() -> str:
    """Ambil Firebase UID dari header, query string, atau body JSON."""
    uid = (request.headers.get("X-User-Id") or "").strip()

    if not uid:
        uid = (request.args.get("user_id") or "").strip()

    if not uid:
        payload = request.get_json(silent=True)
        if isinstance(payload, dict):
            uid = str(payload.get("user_id") or "").strip()

    if not uid:
        raise IdentityError(
            "Header X-User-Id wajib diisi dengan Firebase UID pengguna."
        )

    return uid


def find_user(uid: str) -> User | None:
    """Cari pengguna berdasarkan Firebase UID."""
    return db.session.scalar(select(User).where(User.firebase_uid == uid))


def require_user() -> User:
    """Ambil pengguna yang sedang login, atau lempar IdentityError 404."""
    uid = get_firebase_uid()
    user = find_user(uid)

    if user is None:
        raise IdentityError(
            "Profil belum tersinkron. Kirim PUT /api/profile terlebih dahulu.",
            status=404,
        )

    return user


def resolve_user_id(raw) -> int | None:
    """Ubah nilai `user_id` dari payload menjadi primary key `users.id`.

    Aplikasi mobile mengirim Firebase UID (string), sedangkan
    `DetectionLog.user_id` adalah foreign key integer. Nilai integer
    diperlakukan sebagai primary key apa adanya.
    """
    if raw is None or raw == "" or isinstance(raw, bool):
        return None

    if isinstance(raw, int):
        return raw

    uid = str(raw).strip()

    if not uid:
        return None

    if uid.isdigit():
        return int(uid)

    user = find_user(uid)
    return user.id if user is not None else None
