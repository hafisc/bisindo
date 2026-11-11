"""Penyesuaian skema untuk database yang sudah terlanjur dibuat.

`db.create_all()` hanya membuat tabel yang belum ada; kolom baru pada tabel
lama tidak ikut ditambahkan. Modul ini menambal itu supaya instalasi lama
tetap jalan tanpa perlu menghapus `web/instance/bisindo.db`.

Pendekatan ini sengaja dipilih daripada Alembic karena proyek masih memakai
SQLite lokal dan belum butuh riwayat migrasi penuh.
"""

from sqlalchemy import inspect, text

from .extensions import db

# Kolom yang ditambahkan setelah rilis awal: (tabel, kolom, tipe DDL)
ADDED_COLUMNS = [
    ("users", "firebase_uid", "VARCHAR(128)"),
    ("users", "student_id", "VARCHAR(32)"),
    ("users", "role", "VARCHAR(32)"),
    ("users", "avatar_url", "VARCHAR(512)"),
    ("detection_logs", "title", "VARCHAR(120)"),
    ("detection_logs", "type", "VARCHAR(16)"),
    ("detection_logs", "category", "VARCHAR(16)"),
    ("detection_logs", "mode", "VARCHAR(32)"),
    ("detection_logs", "image_path", "VARCHAR(512)"),
]

# Definisi tabel detection_logs versi baru, dipakai saat rebuild SQLite.
_DETECTION_LOGS_DDL = """
CREATE TABLE detection_logs_new (
    id INTEGER NOT NULL,
    user_id INTEGER,
    letter VARCHAR(8),
    title VARCHAR(120),
    type VARCHAR(16),
    category VARCHAR(16),
    mode VARCHAR(32),
    image_path VARCHAR(512),
    confidence FLOAT NOT NULL,
    created_at DATETIME NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(user_id) REFERENCES users (id)
)
"""

_COPIED_COLUMNS = [
    "id",
    "user_id",
    "letter",
    "confidence",
    "created_at",
]


def _table_columns(inspector, table: str) -> dict:
    return {column["name"]: column for column in inspector.get_columns(table)}


def _add_missing_columns(inspector, tables: set[str]) -> None:
    for table, column, ddl_type in ADDED_COLUMNS:
        if table not in tables:
            continue
        if column in _table_columns(inspector, table):
            continue
        db.session.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {ddl_type}"))
        db.session.commit()


def _make_letter_nullable(inspector, tables: set[str]) -> None:
    """Ubah detection_logs.letter menjadi nullable pada SQLite.

    SQLite tidak mendukung `ALTER COLUMN`, jadi tabel dibangun ulang: salin
    data ke tabel baru, hapus tabel lama, lalu ganti nama. Hanya dijalankan
    sekali, ketika kolom masih NOT NULL.
    """
    if "detection_logs" not in tables:
        return

    columns = _table_columns(inspector, "detection_logs")
    letter = columns.get("letter")
    if letter is None or letter.get("nullable", True):
        return

    if db.engine.dialect.name != "sqlite":
        # Database lain (mis. Postgres) bisa memakai ALTER COLUMN langsung.
        db.session.execute(
            text("ALTER TABLE detection_logs ALTER COLUMN letter DROP NOT NULL")
        )
        db.session.commit()
        return

    db.session.execute(text("PRAGMA foreign_keys=OFF"))
    db.session.execute(text(_DETECTION_LOGS_DDL))

    target_columns = ", ".join(_COPIED_COLUMNS)
    db.session.execute(
        text(
            f"INSERT INTO detection_logs_new ({target_columns}) "
            f"SELECT {target_columns} FROM detection_logs"
        )
    )

    db.session.execute(text("DROP TABLE detection_logs"))
    db.session.execute(
        text("ALTER TABLE detection_logs_new RENAME TO detection_logs")
    )

    # Index ikut hilang saat tabel di-drop, jadi dibuat ulang.
    db.session.execute(
        text(
            "CREATE INDEX ix_detection_logs_user_id ON detection_logs (user_id)"
        )
    )
    db.session.execute(
        text("CREATE INDEX ix_detection_logs_letter ON detection_logs (letter)")
    )
    db.session.execute(
        text(
            "CREATE INDEX ix_detection_logs_created_at "
            "ON detection_logs (created_at)"
        )
    )

    db.session.commit()
    db.session.execute(text("PRAGMA foreign_keys=ON"))


def ensure_schema() -> None:
    """Pastikan database memakai skema terbaru. Aman dipanggil berulang."""
    inspector = inspect(db.engine)
    tables = set(inspector.get_table_names())

    _add_missing_columns(inspector, tables)

    # Inspector perlu dibuat ulang setelah ALTER TABLE.
    inspector = inspect(db.engine)
    _make_letter_nullable(inspector, tables)
