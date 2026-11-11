"""Endpoint profil pengguna untuk aplikasi mobile.

Profil disimpan pada tabel `users` dengan `firebase_uid` sebagai identitas
utama. Baris pertama dibuat oleh `PUT /api/profile` sesaat setelah pengguna
login di aplikasi mobile, lalu endpoint riwayat memakai baris yang sama.
"""

from flask import Blueprint, jsonify
from sqlalchemy import select

from ..extensions import db
from ..models import User
from .identity import find_user, get_firebase_uid, require_user
from .validation import ValidationError, clean_text, json_body

# Blueprint ini di-register sebagai nested blueprint di dalam `api.bp`
# (url_prefix "/api"), jadi prefix di sini cukup "/profile".
bp = Blueprint("profile", __name__, url_prefix="/profile")

MAX_NAME = 120
MAX_EMAIL = 255
MAX_STUDENT_ID = 32
MAX_ROLE = 32
MAX_AVATAR_URL = 512


def _parse_email(payload: dict, required: bool) -> str | None:
    """Validasi field email dan normalkan menjadi huruf kecil."""
    email = clean_text(payload, "email", MAX_EMAIL, required=required)

    if email is None:
        return None

    local, separator, domain = email.partition("@")

    if (
        not separator
        or not local
        or not domain
        or "." not in domain
        or domain.startswith(".")
        or domain.endswith(".")
    ):
        raise ValidationError("Field 'email' bukan alamat email yang valid.")

    return email.lower()


def _clearable_text(payload: dict, key: str, max_length: int):
    """Baca field yang boleh dikosongkan.

    Mengembalikan pasangan `(dikirim, nilai)`. String kosong dianggap
    permintaan mengosongkan nilai, bukan diabaikan.
    """
    if key not in payload:
        return False, None

    raw = payload.get(key)

    if raw is None:
        return True, None

    if not isinstance(raw, str):
        raise ValidationError(f"Field '{key}' harus berupa string.")

    value = raw.strip()

    if not value:
        return True, None

    if len(value) > max_length:
        raise ValidationError(f"Field '{key}' maksimal {max_length} karakter.")

    return True, value


@bp.get("")
@bp.get("/")
def get_profile():
    """Ambil profil pengguna yang sedang login."""
    user = require_user()
    return jsonify(user.to_dict())


@bp.put("")
@bp.put("/")
def update_profile():
    """Buat atau perbarui profil pengguna (upsert berdasarkan Firebase UID)."""
    uid = get_firebase_uid()
    payload = json_body()

    user = find_user(uid)
    creating = user is None

    name = clean_text(payload, "name", MAX_NAME, required=creating)
    email = _parse_email(payload, required=creating)

    student_id_sent, student_id = _clearable_text(payload, "student_id", MAX_STUDENT_ID)
    role_sent, role = _clearable_text(payload, "role", MAX_ROLE)
    avatar_sent, avatar_url = _clearable_text(payload, "avatar_url", MAX_AVATAR_URL)

    if email is not None:
        owner = db.session.scalar(select(User).where(User.email == email))
        if owner is not None and owner is not user:
            return jsonify({"error": "Email sudah dipakai pengguna lain."}), 409

    if creating:
        user = User(firebase_uid=uid, name=name, email=email)
        db.session.add(user)
    else:
        if name is not None:
            user.name = name
        if email is not None:
            user.email = email

    if student_id_sent:
        user.student_id = student_id
    if role_sent:
        user.role = role
    if avatar_sent:
        user.avatar_url = avatar_url

    db.session.commit()

    return jsonify(user.to_dict()), 201 if creating else 200
