"""Pemuatan dataset landmark BISINDO untuk pelatihan model.

Dataset yang dipakai adalah ``ml/src/dataset/dataset_bisindo_landmarks.csv``
hasil ekstraksi MediaPipe. Setiap baris berisi 21 titik landmark tangan
pertama, 21 titik tangan kedua, dan satu penanda apakah sampel memakai dua
tangan.

Susunan 127 fitur di sini harus sama persis dengan yang dipakai saat
pelatihan model SVM (``dataset_bisindo_landmarks.npz``) dan dengan yang
dikirim aplikasi mobile ke ``POST /api/predict``.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# 21 titik x 3 sumbu untuk masing-masing tangan.
POINT_COUNT = 21
AXES = ("x", "y", "z")

HAND1_COLUMNS = [
    f"h1_pt{point}_{axis}"
    for point in range(POINT_COUNT)
    for axis in AXES
]
HAND2_COLUMNS = [
    f"h2_pt{point}_{axis}"
    for point in range(POINT_COUNT)
    for axis in AXES
]

# Fitur ke-127: 1 bila sampel memakai dua tangan, 0 bila satu tangan.
TWO_HANDED_COLUMN = "is_two_handed"

FEATURE_COLUMNS = HAND1_COLUMNS + HAND2_COLUMNS + [TWO_HANDED_COLUMN]

# 63 + 63 + 1
FEATURE_COUNT = len(FEATURE_COLUMNS)

REQUIRED_COLUMNS = ["label", *FEATURE_COLUMNS]

DEFAULT_CSV = (
    Path(__file__).resolve().parent / "dataset_bisindo_landmarks.csv"
)


def validate_columns(frame: pd.DataFrame) -> None:
    """Pastikan CSV memuat seluruh kolom yang dibutuhkan.

    Melempar ``ValueError`` berisi daftar kolom yang hilang supaya pesan
    errornya langsung bisa ditindaklanjuti.
    """
    missing = [column for column in REQUIRED_COLUMNS if column not in frame.columns]

    if missing:
        preview = ", ".join(missing[:8])
        suffix = "" if len(missing) <= 8 else f", dan {len(missing) - 8} lainnya"
        raise ValueError(f"Kolom wajib tidak ditemukan: {preview}{suffix}")


def load_dataset(csv_path: str | Path | None = None) -> tuple[np.ndarray, np.ndarray]:
    """Baca CSV landmark dan kembalikan ``(X, labels)``.

    ``X`` berbentuk ``(n_samples, 127)`` bertipe float32, sedangkan
    ``labels`` berisi huruf A-Z sebagai string.
    """
    path = Path(csv_path) if csv_path else DEFAULT_CSV

    if not path.exists():
        raise FileNotFoundError(f"Dataset tidak ditemukan: {path}")

    frame = pd.read_csv(path)
    validate_columns(frame)

    features = frame[FEATURE_COLUMNS].to_numpy(dtype=np.float32)

    # Nilai yang tidak terhingga (mis. dari landmark gagal) diganti nol.
    features = np.nan_to_num(features, nan=0.0, posinf=0.0, neginf=0.0)

    labels = frame["label"].astype(str).str.strip().str.upper().to_numpy()

    if features.shape[1] != FEATURE_COUNT:
        raise ValueError(
            f"Jumlah fitur tidak sesuai: {features.shape[1]}, "
            f"seharusnya {FEATURE_COUNT}."
        )

    return features, labels


def encode_labels(labels: np.ndarray) -> tuple[np.ndarray, list[str]]:
    """Ubah label huruf menjadi indeks 0..25.

    Mengembalikan ``(y, class_names)`` dengan urutan kelas yang stabil
    (A-Z) sehingga ``label_map.json`` selalu konsisten.
    """
    encoder = LabelEncoder()
    encoded = encoder.fit_transform(labels)
    return encoded, [str(name) for name in encoder.classes_]


def load_real_data(
    csv_path: str | Path | None = None,
    test_size: float = 0.2,
    random_state: int = 42,
    stratify: bool = True,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, list[str]]:
    """Muat dataset dan bagi menjadi data latih dan data uji.

    Mengembalikan ``(X_train, X_test, y_train, y_test, class_names)``.
    Pembagian memakai stratifikasi per kelas supaya proporsi tiap huruf
    tetap seimbang di kedua bagian.

    Catatan penting soal validitas: dataset tidak menyimpan penanda gambar
    asal. Nama berkas hasil augmentasi (``augmented_image_10.jpg``) dipakai
    ulang di banyak kelas, sehingga tidak bisa dipakai sebagai kunci
    pengelompokan. Karena itu pembagian dilakukan per baris, dan hasil
    evaluasi berpotensi lebih optimistis daripada performa di dunia nyata.
    Lihat ``count_filename_overlap()`` untuk mengukur dampaknya.
    """
    features, labels = load_dataset(csv_path)
    y, class_names = encode_labels(labels)

    return (
        *train_test_split(
            features,
            y,
            test_size=test_size,
            random_state=random_state,
            stratify=y if stratify else None,
        ),
        class_names,
    )


def count_filename_overlap(
    csv_path: str | Path | None = None,
    test_size: float = 0.2,
    random_state: int = 42,
) -> dict:
    """Hitung berapa banyak nama berkas yang muncul di data latih dan uji.

    Dipakai sebagai peringatan kebocoran data: bila satu nama berkas muncul
    di kedua bagian, versi augmentasi dari gambar yang sama ikut terbagi.
    """
    frame = pd.read_csv(Path(csv_path) if csv_path else DEFAULT_CSV)
    validate_columns(frame)

    index_train, index_test = train_test_split(
        np.arange(len(frame)),
        test_size=test_size,
        random_state=random_state,
        stratify=frame["label"].to_numpy(),
    )

    names_train = set(frame.iloc[index_train]["filename"].astype(str))
    names_test = set(frame.iloc[index_test]["filename"].astype(str))
    shared = names_train & names_test

    return {
        "train_rows": int(len(index_train)),
        "test_rows": int(len(index_test)),
        "unique_names_train": len(names_train),
        "unique_names_test": len(names_test),
        "shared_names": len(shared),
        "shared_examples": sorted(shared)[:5],
    }
