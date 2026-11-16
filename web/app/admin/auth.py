import hmac
import secrets
import time
from functools import wraps
from urllib.parse import urlparse

from flask import abort, current_app, redirect, request, session, url_for


def is_logged_in() -> bool:
    return session.get("is_admin") is True


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if not is_logged_in():
            return redirect(url_for("admin.login", next=request.full_path.rstrip("?")))
        return view(*args, **kwargs)

    return wrapped


def check_credentials(username: str, password: str) -> bool:
    """Bandingkan dengan akun admin di konfigurasi, tahan serangan timing."""
    expected_user = current_app.config["ADMIN_USERNAME"]
    expected_pass = current_app.config["ADMIN_PASSWORD"]
    user_ok = hmac.compare_digest(username.encode(), expected_user.encode())
    pass_ok = hmac.compare_digest(password.encode(), expected_pass.encode())
    return user_ok and pass_ok


def get_csrf_token() -> str:
    token = session.get("_csrf")
    if not token:
        token = secrets.token_hex(16)
        session["_csrf"] = token
    return token


def verify_csrf() -> None:
    sent = request.form.get("csrf_token", "")
    expected = session.get("_csrf", "")
    if not expected or not hmac.compare_digest(sent.encode(), expected.encode()):
        abort(400, description="Token form tidak valid. Muat ulang halaman lalu coba lagi.")


def safe_next_url(target: str | None) -> str:
    """Hanya izinkan redirect ke halaman admin di situs yang sama."""
    default = url_for("admin.dashboard")
    if not target:
        return default
    parsed = urlparse(target)
    if parsed.scheme or parsed.netloc or not parsed.path.startswith("/admin"):
        return default
    return target


# ── Pembatasan percobaan login ────────────────────────────────────────────────
# Disimpan di memori per aplikasi. Server berjalan dengan satu worker (lihat
# Procfile dan Dockerfile), jadi penghitung ini berlaku untuk semua request.


def _attempts() -> dict:
    return current_app.extensions.setdefault("admin_login_attempts", {})


def _client_key() -> str:
    return request.remote_addr or "unknown"


def login_locked_for() -> int:
    """Sisa detik penguncian untuk alamat ini, atau 0 bila boleh mencoba."""
    entry = _attempts().get(_client_key())
    if not entry:
        return 0
    remaining = int(entry.get("locked_until", 0) - time.monotonic())
    return max(remaining, 0)


def record_failed_login() -> None:
    attempts = _attempts()
    key = _client_key()
    now = time.monotonic()
    entry = attempts.get(key)
    lock_expired = bool(entry) and 0 < entry.get("locked_until", 0) <= now
    if not entry or lock_expired:
        entry = {"count": 0, "locked_until": 0}
    entry["count"] += 1
    if entry["count"] >= current_app.config["ADMIN_LOGIN_MAX_ATTEMPTS"]:
        entry["locked_until"] = now + current_app.config["ADMIN_LOGIN_LOCK_SECONDS"]
    attempts[key] = entry


def reset_failed_logins() -> None:
    _attempts().pop(_client_key(), None)
