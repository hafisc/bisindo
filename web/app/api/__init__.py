from flask import Blueprint, jsonify

from .identity import IdentityError
from .validation import ValidationError

bp = Blueprint("api", __name__, url_prefix="/api")

from . import history, profile, routes  # noqa: E402,F401  (mendaftarkan route)

bp.register_blueprint(history.bp)
bp.register_blueprint(profile.bp)


# Error handler dipasang di blueprint induk supaya semua endpoint /api/*
# memakai format respons error yang sama.
@bp.errorhandler(ValidationError)
def handle_validation_error(error: ValidationError):
    return jsonify({"error": error.message}), 400


@bp.errorhandler(IdentityError)
def handle_identity_error(error: IdentityError):
    return jsonify({"error": error.message}), error.status
