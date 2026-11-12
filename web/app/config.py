import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Folder data yang ditulis saat runtime: database SQLite, dataset unggahan, dan
# model unggahan. Di cloud, arahkan ke volume persisten lewat env INSTANCE_DIR,
# karena filesystem container dibuang setiap redeploy.
INSTANCE_DIR = Path(os.environ.get("INSTANCE_DIR") or (BASE_DIR / "instance"))


def _database_uri() -> str:
    """URI database, dengan dukungan Postgres untuk deployment cloud.

    Sebagian penyedia cloud memberi ``postgres://``, sedangkan SQLAlchemy 2
    hanya menerima ``postgresql://``. Nilai itu dinormalkan di sini supaya
    pengguna tidak perlu mengubahnya sendiri.
    """
    url = (os.environ.get("DATABASE_URL") or "").strip()

    if not url:
        return f"sqlite:///{(INSTANCE_DIR / 'bisindo.db').as_posix()}"

    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://") :]

    return url


class Config:
    """Konfigurasi dasar. Nilainya dibaca dari environment (file .env)."""

    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-ganti-di-env")

    ADMIN_USERNAME = os.environ.get("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "admin123")

    SQLALCHEMY_DATABASE_URI = _database_uri()
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
