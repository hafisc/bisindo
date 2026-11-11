from flask import Blueprint

bp = Blueprint("api", __name__, url_prefix="/api")

from . import history, routes  # noqa: E402,F401  (mendaftarkan route)

bp.register_blueprint(history.bp)
