"""Penyimpanan dan validasi berkas unggahan panel admin.

Modul ini menangani dua jenis unggahan:

- **Dataset CSV** berisi 127 kolom fitur landmark ditambah kolom ``label``.
  Statistik dihitung saat unggah memakai modul ``csv`` bawaan Python, bukan
  pandas, supaya server web tidak menambah dependensi besar hanya untuk
  membaca berkas.

- **Model joblib** berisi ``Pipeline(StandardScaler, SVC)`` hasil
  ``ml/src/training/train_svm.py``, beserta ``label_map.json`` dan
  ``metrics.json`` bila tersedia.

Berkas disimpan di ``web/instance/`` sehingga tidak masuk git.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path

POINT_COUNT = 21
AXES = ("x", "y", "z")

HAND1_COLUMNS = [f"h1_pt{point}_{axis}" for point in range(POINT_COUNT) for axis in AXES]
HAND2_COLUMNS = [f"h2_pt{point}_{axis}" for point in range(POINT_COUNT) for axis in AXES]
TWO_HANDED_COLUMN = "is_two_handed"

FEATURE_COLUMNS = HAND1_COLUMNS + HAND2_COLUMNS + [TWO_HANDED_COLUMN]
FEATURE_COUNT = len(FEATURE_COLUMNS)

REQUIRED_DATASET_COLUMNS = ["label", *FEATURE_COLUMNS]

ALLOWED_DATASET_SUFFIXES = {".csv"}
ALLOWED_MODEL_SUFFIXES = {".joblib", ".pkl"}

# Nama berkas disimpan ulang dengan pola aman agar tidak bisa keluar folder.
_SAFE_NAME = re.compile(r"[^A-Za-z0-9._-]+")


class UploadError(ValueError):
    """Kesalahan unggahan yang aman ditampilkan ke pengguna."""


def safe_name(filename: str) -> str:
    """Ubah nama berkas kiriman pengguna menjadi nama yang aman."""
    base = Path(filename or "").name
    cleaned = _SAFE_NAME.sub("_", base).strip("._-")
    return cleaned or "berkas"


def checksum_of(path: Path) -> str:
    """Hitung SHA-256 isi berkas, dipakai untuk mendeteksi unggahan ganda."""
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _check_suffix(filename: str, allowed: set[str]) -> None:
    suffix = Path(filename or "").suffix.lower()
    if suffix not in allowed:
        daftar = ", ".join(sorted(allowed))
        raise UploadError(f"Jenis berkas {suffix or '(tanpa ekstensi)'} tidak diterima. Gunakan {daftar}.")


def save_upload(file_storage, target_dir: Path, stored_name: str, allowed: set[str]) -> Path:
    """Simpan berkas unggahan ke ``target_dir`` dan kembalikan path-nya."""
    filename = getattr(file_storage, "filename", "") or ""
    if not filename:
        raise UploadError("Berkas belum dipilih.")

    _check_suffix(filename, allowed)

    target_dir.mkdir(parents=True, exist_ok=True)
    destination = target_dir / stored_name

    file_storage.save(destination)

    if not destination.exists() or destination.stat().st_size == 0:
        destination.unlink(missing_ok=True)
        raise UploadError("Berkas kosong atau gagal disimpan.")

    return destination


def analyze_dataset_csv(path: Path) -> dict:
    """Validasi CSV landmark dan hitung statistiknya.

    Mengembalikan dict berisi ``row_count``, ``class_count``, ``feature_count``,
    ``class_distribution``, dan ``shared_filename_count``. Melempar
    :class:`UploadError` bila kolom wajib tidak lengkap.
    """
    with open(path, newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)

        if reader.fieldnames is None:
            raise UploadError("Berkas CSV tidak memiliki baris judul kolom.")

        header = [name.strip() for name in reader.fieldnames]
        missing = [column for column in REQUIRED_DATASET_COLUMNS if column not in header]

        if missing:
            preview = ", ".join(missing[:6])
            sisa = "" if len(missing) <= 6 else f", dan {len(missing) - 6} kolom lain"
            raise UploadError(
                f"Kolom wajib tidak ditemukan: {preview}{sisa}. "
                f"Dataset harus memuat kolom 'label' dan {FEATURE_COUNT} kolom fitur."
            )

        distribution: dict[str, int] = {}
        filenames: dict[str, set[str]] = {}
        rows = 0

        for row in reader:
            label = (row.get("label") or "").strip().upper()
            if not label:
                continue
            rows += 1
            distribution[label] = distribution.get(label, 0) + 1

            name = (row.get("filename") or "").strip()
            if name:
                filenames.setdefault(name, set()).add(label)

    if rows == 0:
        raise UploadError("Berkas CSV tidak memiliki baris data.")

    # Nama berkas yang dipakai di lebih dari satu kelas menandakan augmentasi
    # dilakukan sebelum pembagian data. Angka ini ditampilkan sebagai
    # peringatan, bukan penghalang unggah.
    shared = sum(1 for labels in filenames.values() if len(labels) > 1)

    return {
        "row_count": rows,
        "class_count": len(distribution),
        "feature_count": FEATURE_COUNT,
        "class_distribution": dict(sorted(distribution.items())),
        "shared_filename_count": shared,
        "unique_filename_count": len(filenames),
    }


def read_json_sidecar(directory: Path, name: str) -> dict:
    """Baca berkas JSON pendamping bila ada. Kembalikan dict kosong bila tidak."""
    path = directory / name
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return {}
    return data if isinstance(data, dict) else {}


def inspect_model(model_path: Path) -> dict:
    """Muat model joblib sebentar untuk membaca jumlah fitur dan kelas.

    Tujuannya menolak berkas yang bukan model, atau model yang jumlah fiturnya
    tidak cocok dengan kontrak 127 fitur, sebelum versi itu diaktifkan.
    """
    try:
        import joblib
    except ImportError as error:  # pragma: no cover - dependensi wajib
        raise UploadError("joblib belum terpasang di server.") from error

    try:
        model = joblib.load(model_path)
    except Exception as error:
        raise UploadError(
            "Berkas tidak bisa dibaca sebagai model joblib. "
            "Pastikan berkas hasil train_svm.py, bukan berkas lain."
        ) from error

    feature_count = int(getattr(model, "n_features_in_", 0) or 0)

    classes = []
    try:
        # Pipeline menyimpan estimator pada langkah terakhir.
        estimator = model.steps[-1][1] if hasattr(model, "steps") else model
        classes = list(estimator.classes_)
    except Exception:
        classes = []

    return {
        "feature_count": feature_count,
        "class_count": len(classes),
        "classes": classes,
        "is_pipeline": hasattr(model, "steps"),
        "has_proba": hasattr(model, "predict_proba"),
    }


def validate_model_upload(model_path: Path, expected_features: int = FEATURE_COUNT) -> dict:
    """Pastikan model bisa dipakai server: 127 fitur dan punya predict_proba."""
    info = inspect_model(model_path)

    if info["feature_count"] and info["feature_count"] != expected_features:
        raise UploadError(
            f"Model memakai {info['feature_count']} fitur, sedangkan server "
            f"mengharapkan {expected_features}. Periksa versi dataset dan train_svm.py."
        )

    if not info["has_proba"]:
        raise UploadError(
            "Model tidak memiliki predict_proba. Latih ulang dengan "
            "SVC(probability=True) agar confidence bisa dilaporkan."
        )

    return info
