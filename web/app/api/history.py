"""Endpoint riwayat terjemahan untuk aplikasi mobile.

Blueprint ini melayani CRUD riwayat pada tabel `detection_logs` milik satu
pengguna. Semua query dibatasi pada pemilik data, sehingga pengguna lain tidak
bisa membaca atau menghapus entri yang bukan miliknya.
"""

from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from sqlalchemy import delete, func, select

from ..extensions import db
from ..models import DetectionLog
from .identity import IdentityError, require_user

# Blueprint ini di-register sebagai nested blueprint di dalam `api.bp`
# (url_prefix "/api"), jadi prefix di sini cukup "/history".
bp = Blueprint("history", __name__, url_prefix="/history")

# Nilai yang diterima pada kolom type dan category.
VALID_TYPES = {"Kata", "Huruf"}
VALID_CATEGORIES = {"Teks", "Suara"}

MAX_TITLE = 120
MAX_TYPE = 16
MAX_CATEGORY = 16
MAX_MODE = 32
MAX_IMAGE_PATH = 512

DEFAULT_LIMIT = 50
MAX_LIMIT = 200


class ValidationError(Exception):
    """Payload riwayat tidak valid."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


def _parse_timestamp(raw) -> datetime:
    """Ubah timestamp ISO-8601 dari mobile menjadi datetime UTC tanpa tzinfo."""
    if raw is None or raw == "":
        return datetime.now(timezone.utc).replace(tzinfo=None)

    if not isinstance(raw, str):
        raise ValidationError("Field 'timestamp' harus berupa string ISO-8601.")

    text = raw.strip()
    # Python 3.11+ menerima 'Z', tapi tetap dinormalkan agar aman di 3.10.
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"

    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        raise ValidationError(
            "Field 'timestamp' bukan format ISO-8601 yang valid."
        ) from None

    if parsed.tzinfo is not None:
        parsed = parsed.astimezone(timezone.utc).replace(tzinfo=None)

    return parsed


def _clean_text(payload: dict, key: str, max_length: int, required: bool = False):
    """Ambil dan validasi field teks opsional/wajib."""
    value = payload.get(key)

    if value is None:
        if required:
            raise ValidationError(f"Field '{key}' wajib diisi.")
        return None

    if not isinstance(value, str):
        raise ValidationError(f"Field '{key}' harus berupa string.")

    value = value.strip()

    if not value:
        if required:
            raise ValidationError(f"Field '{key}' tidak boleh kosong.")
        return None

    if len(value) > max_length:
        raise ValidationError(
            f"Field '{key}' maksimal {max_length} karakter."
        )

    return value


def _parse_confidence(payload: dict) -> float:
    raw = payload.get("confidence")

    if raw is None:
        raise ValidationError("Field 'confidence' wajib diisi.")

    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        raise ValidationError("Field 'confidence' harus berupa angka.")

    value = float(raw)

    if not 0.0 <= value <= 1.0:
        raise ValidationError("Field 'confidence' harus di antara 0.0 dan 1.0.")

    return value


def _build_log(user_id: int, payload: dict) -> DetectionLog:
    """Validasi payload lalu bentuk objek DetectionLog baru."""
    title = _clean_text(payload, "title", MAX_TITLE, required=True)
    entry_type = _clean_text(payload, "type", MAX_TYPE, required=True)
    category = _clean_text(payload, "category", MAX_CATEGORY, required=True)
    mode = _clean_text(payload, "mode", MAX_MODE)
    image_path = _clean_text(payload, "image_path", MAX_IMAGE_PATH)

    if entry_type not in VALID_TYPES:
        raise ValidationError(
            "Field 'type' harus salah satu dari: " + ", ".join(sorted(VALID_TYPES))
        )

    if category not in VALID_CATEGORIES:
        raise ValidationError(
            "Field 'category' harus salah satu dari: "
            + ", ".join(sorted(VALID_CATEGORIES))
        )

    return DetectionLog(
        user_id=user_id,
        title=title,
        type=entry_type,
        category=category,
        mode=mode,
        image_path=image_path,
        confidence=_parse_confidence(payload),
        created_at=_parse_timestamp(payload.get("timestamp")),
    )


def _json_body() -> dict:
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        raise ValidationError("Body request harus berupa JSON object.")
    return payload


@bp.get("")
@bp.get("/")
def list_history():
    """Ambil riwayat deteksi milik pengguna, terbaru lebih dulu."""
    user = require_user()

    limit = request.args.get("limit", DEFAULT_LIMIT, type=int) or DEFAULT_LIMIT
    offset = request.args.get("offset", 0, type=int) or 0
    limit = max(1, min(limit, MAX_LIMIT))
    offset = max(0, offset)

    base = select(DetectionLog).where(DetectionLog.user_id == user.id)

    total = (
        db.session.scalar(
            select(func.count()).select_from(base.subquery())
        )
        or 0
    )

    rows = db.session.scalars(
        base.order_by(DetectionLog.created_at.desc(), DetectionLog.id.desc())
        .limit(limit)
        .offset(offset)
    ).all()

    return jsonify(
        {
            "items": [row.to_dict() for row in rows],
            "total": total,
            "limit": limit,
            "offset": offset,
        }
    )


@bp.post("")
@bp.post("/")
def create_history():
    """Simpan satu entri riwayat baru."""
    user = require_user()
    payload = _json_body()

    log = _build_log(user.id, payload)

    db.session.add(log)
    db.session.commit()

    return jsonify(log.to_dict()), 201


@bp.delete("/<int:log_id>")
def delete_history_item(log_id: int):
    """Hapus satu entri riwayat milik pengguna."""
    user = require_user()

    log = db.session.scalar(
        select(DetectionLog).where(
            DetectionLog.id == log_id,
            DetectionLog.user_id == user.id,
        )
    )

    if log is None:
        return jsonify({"error": "Entri riwayat tidak ditemukan."}), 404

    db.session.delete(log)
    db.session.commit()

    return jsonify({"deleted": 1, "id": log_id})


@bp.delete("")
@bp.delete("/")
def clear_history():
    """Hapus seluruh riwayat milik pengguna."""
    user = require_user()

    result = db.session.execute(
        delete(DetectionLog).where(DetectionLog.user_id == user.id)
    )
    db.session.commit()

    return jsonify({"deleted": result.rowcount or 0})


# ── Error handler khusus blueprint ───────────────────────────────────────────


@bp.errorhandler(ValidationError)
def handle_validation_error(error: ValidationError):
    return jsonify({"error": error.message}), 400


@bp.errorhandler(IdentityError)
def handle_identity_error(error: IdentityError):
    return jsonify({"error": error.message}), error.status
