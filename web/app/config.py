import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
INSTANCE_DIR = BASE_DIR / "instance"


class Config:
    """Konfigurasi dasar. Nilainya dibaca dari environment (file .env)."""

    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-ganti-di-env")

    ADMIN_USERNAME = os.environ.get("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "admin123")

    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL") or (
        f"sqlite:///{(INSTANCE_DIR / 'bisindo.db').as_posix()}"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Path model machine learning BISINDO (artefak joblib hasil ml/src/training/train_svm.py)
    MODEL_PATH = os.environ.get("MODEL_PATH") or (
        (BASE_DIR.parent / "ml" / "models" / "svm_rbf_bisindo.joblib").as_posix()
    )

    # Folder unggahan lewat panel admin. Isinya tidak masuk git.
    DATASET_DIR = (INSTANCE_DIR / "datasets").as_posix()
    MODEL_UPLOAD_DIR = (INSTANCE_DIR / "models").as_posix()

    # Batas ukuran unggahan: dataset landmark sekitar 9 MB, model sekitar 2 MB.
    MAX_CONTENT_LENGTH = 64 * 1024 * 1024  # 64 MB

    # Jumlah baris per halaman pada tabel admin.
    ADMIN_PER_PAGE = 10
