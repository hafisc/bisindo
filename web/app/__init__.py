from pathlib import Path

from dotenv import load_dotenv

# .env harus dibaca sebelum Config di-import, karena Config membaca environment.
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from flask import Flask, redirect, url_for  # noqa: E402

from .config import INSTANCE_DIR, Config  # noqa: E402
from .extensions import db  # noqa: E402


def create_app(config_overrides: dict | None = None) -> Flask:
    app = Flask(__name__, instance_path=str(INSTANCE_DIR))
    app.config.from_object(Config)
    if config_overrides:
        app.config.update(config_overrides)

    INSTANCE_DIR.mkdir(parents=True, exist_ok=True)
    db.init_app(app)

    # Blueprint lain (auth, predict, history, dll) didaftarkan di sini.
    from .admin import bp as admin_bp

    app.register_blueprint(admin_bp)

    @app.get("/")
    def root():
        return redirect(url_for("admin.dashboard"))

    from . import models  # noqa: F401  (supaya tabel terdaftar sebelum create_all)

    with app.app_context():
        db.create_all()

    return app
