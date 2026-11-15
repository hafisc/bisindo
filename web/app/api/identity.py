"""Helper identitas pengguna untuk endpoint /api/*.

Aplikasi mobile login lewat Firebase Auth, jadi identitas pengguna adalah
Firebase UID. UID diambil dengan urutan berikut:

1. Header `Authorization: Bearer <Firebase ID token>`. Tanda tangan token
   diperiksa dengan kunci publik Google, jadi UID tidak bisa dipalsukan.
2. Bila `REQUIRE_FIREBASE_AUTH` mati (bawaan untuk pengembangan lokal), header
   `X-User-Id`, query `user_id`, atau body JSON `user_id`. Nilai ini tidak
   diverifikasi, jadi nyalakan `REQUIRE_FIREBASE_AUTH` di server publik.
"""

import jwt
from flask import current_app, request
from sqlalchemy import select

from ..extensions import db
from ..models import User


class IdentityError(Exception):
    """Identitas pengguna tidak ditemukan pada request."""

    def __init__(self, message: str, status: int = 401):
        super().__init__(message)
        self.message = message
        self.status = status


# Kunci publik yang dipakai Firebase untuk menandatangani ID token.
FIREBASE_JWKS_URL = (
    "https://www.googleapis.com/service_accounts/v1/jwk/"
    "securetoken@system.gserviceaccount.com"
)

_jwks_client: jwt.PyJWKClient | None = None


def _signing_key(token: str):
    """Kunci publik yang cocok dengan header `kid` token. Hasil unduhan
    disimpan di memori oleh PyJWKClient, jadi tidak diunduh setiap request."""
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = jwt.PyJWKClient(FIREBASE_JWKS_URL, cache_keys=True, lifespan=3600)
    return _jwks_client.get_signing_key_from_jwt(token).key


def verify_firebase_token(token: str) -> str:
    """Periksa Firebase ID token dan kembalikan UID pemiliknya."""
    project_id = (current_app.config.get("FIREBASE_PROJECT_ID") or "").strip()
    if not project_id:
        raise IdentityError(
            "Server belum diatur: isi FIREBASE_PROJECT_ID untuk memeriksa token login.",
            status=500,
        )

    try:
        claims = jwt.decode(
            token,
            _signing_key(token),
            algorithms=["RS256"],
            audience=project_id,
            issuer=f"https://securetoken.google.com/{project_id}",
            options={"require": ["exp", "iat", "sub"]},
            leeway=60,
        )
    except jwt.PyJWKClientConnectionError as error:
        raise IdentityError(
            "Server tidak bisa mengambil kunci verifikasi login. Coba lagi sebentar.",
            status=503,
        ) from error
    except (jwt.PyJWTError, ValueError) as error:
        raise IdentityError("Token login tidak valid atau sudah kedaluwarsa.") from error

    uid = str(claims.get("sub") or "").strip()
    if not uid:
        raise IdentityError("Token login tidak berisi UID pengguna.")
    return uid


def _bearer_token() -> str:
    header = (request.headers.get("Authorization") or "").strip()
    scheme, _, token = header.partition(" ")
    return token.strip() if scheme.lower() == "bearer" else ""


def get_firebase_uid() -> str:
    """Ambil Firebase UID dari token login, atau dari X-User-Id bila mode
    verifikasi wajib dimatikan."""
    token = _bearer_token()
    if token:
        return verify_firebase_token(token)

    if current_app.config.get("REQUIRE_FIREBASE_AUTH"):
        raise IdentityError(
            "Login diperlukan. Kirim header Authorization: Bearer <Firebase ID token>."
        )

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
