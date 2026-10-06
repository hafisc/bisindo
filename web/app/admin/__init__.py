from flask import Blueprint

from . import queries
from .auth import get_csrf_token, is_logged_in

bp = Blueprint("admin", __name__, url_prefix="/admin")


@bp.app_template_filter("wib")
def format_wib(value):
    """Tampilkan waktu UTC dari database sebagai WIB, contoh: 4 Okt 2026, 03:51."""
    if value is None:
        return "-"
    local = queries.to_wib(value)
    return f"{local.day} {queries.BULAN[local.month - 1]} {local.year}, {local:%H:%M}"


@bp.app_template_filter("percent")
def format_percent(value):
    if value is None:
        return "-"
    number = value * 100
    return f"{number:.1f}".rstrip("0").rstrip(".") + "%"


@bp.app_context_processor
def inject_helpers():
    return {"csrf_token": get_csrf_token, "admin_logged_in": is_logged_in}


from . import routes  # noqa: E402,F401  (mendaftarkan route ke blueprint)
