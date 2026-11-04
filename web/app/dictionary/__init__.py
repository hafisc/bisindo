from flask import Blueprint

bp = Blueprint("dictionary", __name__, url_prefix="/api/dictionary")

from . import routes  # noqa: E402, F401
