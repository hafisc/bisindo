"""Validasi payload JSON yang dipakai bersama endpoint /api/*."""

from flask import request


class ValidationError(Exception):
    """Payload request tidak valid."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


def json_body() -> dict:
    """Ambil body JSON dan pastikan berbentuk object."""
    payload = request.get_json(silent=True)

    if not isinstance(payload, dict):
        raise ValidationError("Body request harus berupa JSON object.")

    return payload


def clean_text(
    payload: dict,
    key: str,
    max_length: int,
    required: bool = False,
) -> str | None:
    """Ambil dan validasi field teks opsional atau wajib.

    Nilai kosong dianggap tidak dikirim (None), kecuali field wajib.
    """
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
        raise ValidationError(f"Field '{key}' maksimal {max_length} karakter.")

    return value
