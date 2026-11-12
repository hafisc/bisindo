import json
from datetime import datetime, timezone

from .extensions import db


def utcnow() -> datetime:
    """Waktu UTC tanpa tzinfo, supaya konsisten dengan SQLite."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


class User(db.Model):
    """Pengguna aplikasi mobile.

    Baris dibuat oleh `PUT /api/profile` (sinkronisasi pertama kali setelah
    login di aplikasi mobile). Halaman admin hanya membacanya.
    """

    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)

    # Firebase UID dari aplikasi mobile. Menjadi identitas utama untuk
    # endpoint /api/profile dan /api/history.
    firebase_uid = db.Column(db.String(128), unique=True, index=True, nullable=True)

    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(255), nullable=False, unique=True, index=True)
    password_hash = db.Column(db.String(255), nullable=True)

    # Data profil tambahan (dikelola lewat PUT /api/profile).
    student_id = db.Column(db.String(32), nullable=True)
    role = db.Column(db.String(32), nullable=True)
    avatar_url = db.Column(db.String(512), nullable=True)

    created_at = db.Column(db.DateTime, nullable=False, default=utcnow)

    logs = db.relationship("DetectionLog", back_populates="user")

    def to_dict(self) -> dict:
        """Representasi JSON untuk endpoint /api/profile."""
        return {
            "id": self.id,
            "firebase_uid": self.firebase_uid,
            "name": self.name,
            "email": self.email,
            "student_id": self.student_id,
            "role": self.role,
            "avatar_url": self.avatar_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class DatasetSnapshot(db.Model):
    """Satu berkas dataset CSV landmark yang diunggah lewat panel admin.

    Berkasnya disimpan di ``web/instance/datasets/`` dan tidak masuk git.
    Statistik dihitung sekali saat unggah, supaya halaman admin tidak perlu
    membaca ulang CSV berukuran besar setiap kali dibuka.
    """

    __tablename__ = "dataset_snapshots"

    id = db.Column(db.Integer, primary_key=True)

    filename = db.Column(db.String(255), nullable=False)
    stored_name = db.Column(db.String(255), nullable=False, unique=True)
    size_bytes = db.Column(db.Integer, nullable=False, default=0)
    checksum = db.Column(db.String(64), nullable=False, index=True)

    row_count = db.Column(db.Integer, nullable=False, default=0)
    class_count = db.Column(db.Integer, nullable=False, default=0)
    feature_count = db.Column(db.Integer, nullable=False, default=0)
    shared_filename_count = db.Column(db.Integer, nullable=False, default=0)

    # Ringkasan per kelas, disimpan sebagai JSON: {"A": 120, "B": 118, ...}
    class_distribution = db.Column(db.Text, nullable=True)

    is_active = db.Column(db.Boolean, nullable=False, default=False, index=True)
    note = db.Column(db.String(255), nullable=True)
    uploaded_by = db.Column(db.String(120), nullable=True)
    uploaded_at = db.Column(db.DateTime, nullable=False, default=utcnow, index=True)

    @property
    def size_label(self) -> str:
        """Ukuran berkas dalam satuan yang mudah dibaca."""
        size = float(self.size_bytes or 0)
        for unit in ("B", "KB", "MB", "GB"):
            if size < 1024 or unit == "GB":
                return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} GB"

    def distribution(self) -> dict:
        """Kembalikan ringkasan per kelas sebagai dict."""
        if not self.class_distribution:
            return {}
        try:
            return json.loads(self.class_distribution)
        except ValueError:
            return {}

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "filename": self.filename,
            "size_bytes": self.size_bytes,
            "size_label": self.size_label,
            "checksum": self.checksum,
            "row_count": self.row_count,
            "class_count": self.class_count,
            "feature_count": self.feature_count,
            "shared_filename_count": self.shared_filename_count,
            "class_distribution": self.distribution(),
            "is_active": self.is_active,
            "note": self.note,
            "uploaded_by": self.uploaded_by,
            "uploaded_at": self.uploaded_at.isoformat() if self.uploaded_at else None,
        }


class ModelVersion(db.Model):
    """Satu versi model SVM yang diunggah lewat panel admin.

    Setiap versi disimpan di direktorinya sendiri di ``web/instance/models/``
    berisi ``model.joblib``, ``label_map.json``, dan ``metrics.json``. Hanya
    satu versi yang aktif dan dipakai server untuk prediksi.
    """

    __tablename__ = "model_versions"

    id = db.Column(db.Integer, primary_key=True)

    label = db.Column(db.String(120), nullable=False)
    filename = db.Column(db.String(255), nullable=False)
    stored_name = db.Column(db.String(255), nullable=False, unique=True)
    size_bytes = db.Column(db.Integer, nullable=False, default=0)
    checksum = db.Column(db.String(64), nullable=False, index=True)

    algorithm = db.Column(db.String(32), nullable=True)
    variant = db.Column(db.String(64), nullable=True)
    kernel = db.Column(db.String(32), nullable=True)
    accuracy = db.Column(db.Float, nullable=True)
    f1_score = db.Column(db.Float, nullable=True)
    feature_count = db.Column(db.Integer, nullable=False, default=0)
    class_count = db.Column(db.Integer, nullable=False, default=0)

    is_active = db.Column(db.Boolean, nullable=False, default=False, index=True)
    note = db.Column(db.String(255), nullable=True)
    uploaded_by = db.Column(db.String(120), nullable=True)
    uploaded_at = db.Column(db.DateTime, nullable=False, default=utcnow, index=True)

    @property
    def size_label(self) -> str:
        size = float(self.size_bytes or 0)
        for unit in ("B", "KB", "MB", "GB"):
            if size < 1024 or unit == "GB":
                return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} GB"

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "label": self.label,
            "filename": self.filename,
            "size_bytes": self.size_bytes,
            "size_label": self.size_label,
            "checksum": self.checksum,
            "algorithm": self.algorithm,
            "variant": self.variant,
            "kernel": self.kernel,
            "accuracy": self.accuracy,
            "f1_score": self.f1_score,
            "feature_count": self.feature_count,
            "class_count": self.class_count,
            "is_active": self.is_active,
            "note": self.note,
            "uploaded_by": self.uploaded_by,
            "uploaded_at": self.uploaded_at.isoformat() if self.uploaded_at else None,
        }


class DetectionLog(db.Model):
    """Satu entri riwayat terjemahan dari aplikasi mobile.

    Awalnya hanya menyimpan hasil prediksi huruf (kolom `letter`). Sejak
    endpoint /api/history ditambahkan, entri juga bisa berupa kata dengan
    metadata tambahan (title, type, category, mode).
    """

    __tablename__ = "detection_logs"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True, index=True)

    # Huruf hasil prediksi model. Nullable karena entri "Kata" tidak punya huruf.
    letter = db.Column(db.String(8), nullable=True, index=True)

    # Metadata riwayat dari aplikasi mobile.
    title = db.Column(db.String(120), nullable=True)
    type = db.Column(db.String(16), nullable=True)  # 'Kata' | 'Huruf'
    category = db.Column(db.String(16), nullable=True)  # 'Teks' | 'Suara'
    mode = db.Column(db.String(32), nullable=True)
    image_path = db.Column(db.String(512), nullable=True)

    confidence = db.Column(db.Float, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=utcnow, index=True)

    user = db.relationship("User", back_populates="logs")

    @property
    def display_label(self) -> str:
        """Teks yang ditampilkan di panel admin (judul kata atau huruf)."""
        return self.title or self.letter or "-"

    def to_dict(self) -> dict:
        """Representasi JSON untuk endpoint /api/history."""
        return {
            "id": self.id,
            "title": self.title,
            "type": self.type,
            "category": self.category,
            "mode": self.mode,
            "letter": self.letter,
            "confidence": self.confidence,
            "image_path": self.image_path,
            "timestamp": self.created_at.isoformat() if self.created_at else None,
        }
