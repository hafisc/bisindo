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
