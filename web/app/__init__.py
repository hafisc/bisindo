import secrets
from pathlib import Path

from dotenv import load_dotenv

# .env harus dibaca sebelum Config di-import, karena Config membaca environment.
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from flask import Flask, redirect, url_for  # noqa: E402

from .config import INSTANCE_DIR, Config  # noqa: E402
from .extensions import db  # noqa: E402


def _load_or_create_secret_key() -> str:
    """Kunci acak per instalasi, disimpan di INSTANCE_DIR (tidak masuk git).

    Disimpan ke berkas supaya sesi admin tetap berlaku setelah server dijalankan
    ulang. Di cloud, isi env SECRET_KEY agar semua worker memakai kunci sama.
    """
    path = INSTANCE_DIR / "secret_key"
    try:
        existing = path.read_text(encoding="utf-8").strip()
        if existing:
            return existing
    except FileNotFoundError:
        pass

    key = secrets.token_hex(32)
    path.write_text(key, encoding="utf-8")
    return key


def create_app(config_overrides: dict | None = None) -> Flask:
    app = Flask(__name__, instance_path=str(INSTANCE_DIR))
    app.config.from_object(Config)
    if config_overrides:
        app.config.update(config_overrides)

    INSTANCE_DIR.mkdir(parents=True, exist_ok=True)
    if not app.config.get("SECRET_KEY"):
        app.config["SECRET_KEY"] = _load_or_create_secret_key()
    db.init_app(app)

    @app.after_request
    def _security_headers(response):
        # Halaman admin tidak boleh dimuat di dalam iframe situs lain, dan
        # browser tidak boleh menebak jenis berkas sendiri.
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "same-origin")
        return response

    try:
        from flask_cors import CORS

        CORS(app, resources={r"/api/*": {"origins": "*"}})
    except ImportError:
        pass

    # Blueprint didaftarkan di sini:
    from .admin import bp as admin_bp
    from .api import bp as api_bp
    from .dictionary import bp as dictionary_bp

    app.register_blueprint(admin_bp)
    app.register_blueprint(api_bp)
    app.register_blueprint(dictionary_bp)

    @app.get("/")
    def root():
        return redirect(url_for("admin.dashboard"))

    from . import models  # noqa: F401  (supaya tabel terdaftar sebelum create_all)
    from .schema import ensure_schema

    with app.app_context():
        db.create_all()
        # Tambal kolom baru pada database lama (lihat app/schema.py).
        ensure_schema()

        # Pakai model yang terakhir diaktifkan lewat panel admin, bila ada.
        from .admin.assets import apply_active_assets

        apply_active_assets(app)

    return app
