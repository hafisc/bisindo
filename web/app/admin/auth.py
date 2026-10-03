import hmac
import secrets
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
