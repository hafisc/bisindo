"""Ekstraksi landmark tangan MediaPipe dari foto menjadi CSV dataset.

Menghasilkan CSV dengan kolom yang sama persis dengan
``dataset_bisindo_landmarks.csv``, sehingga hasilnya bisa langsung dipakai
``train_svm.py``. Foto disusun per huruf:

    data/raw/
      A/  foto1.jpg  foto2.png ...
      B/  ...

Jalankan dari akar repositori:

    python ml/src/dataset/extract_landmarks.py --input ml/data/raw --output ml/data/processed/landmarks.csv
    python ml/src/dataset/extract_landmarks.py --input ml/data/raw --output hasil.csv --flip

Normalisasi sama dengan ``web/app/api/services.py`` dan dataset latih:
semua titik dikurangi posisi pergelangan tangan 1, lalu dibagi jarak 3D
pergelangan ke titik 9 tangan 1. Koordinat tangan 2 memakai acuan yang sama,
sehingga posisi kedua tangan terhadap satu sama lain tetap tersimpan.

Urutan tangan: tangan dengan pergelangan paling kiri di gambar menjadi tangan 1.
Aturan ini cocok dengan 96% sampel dua tangan di dataset asli. Script asli
pembuat dataset tidak tersimpan di repo, sehingga aturan pastinya tidak
diketahui. Server tetap aman karena saat prediksi menguji kedua urutan tangan.

Butuh paket ``mediapipe`` dan model ``hand_landmarker.task``. Secara bawaan
model diambil dari aset Android di ``mobile/android/app/src/main/assets``.
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path

import numpy as np

SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.data_loader import (  # noqa: E402
    HAND1_COLUMNS,
    HAND2_COLUMNS,
    POINT_COUNT,
    TWO_HANDED_COLUMN,
)

REPO_ROOT = SRC_DIR.parent.parent
DEFAULT_MODEL = (
    REPO_ROOT / "mobile" / "android" / "app" / "src" / "main" / "assets" / "hand_landmarker.task"
)
IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

CSV_COLUMNS = [
    "label",
    "label_idx",
    "filename",
    "num_hands",
    "is_flip",
    *HAND1_COLUMNS,
    *HAND2_COLUMNS,
    TWO_HANDED_COLUMN,
]


def order_hands(hands: list[np.ndarray]) -> list[np.ndarray]:
    """Urutkan tangan dari pergelangan paling kiri, maksimal dua tangan."""
    return sorted(hands, key=lambda points: float(points[0, 0]))[:2]


def normalize_hands(hands: list[np.ndarray]) -> tuple[np.ndarray, np.ndarray]:
    """Kembalikan ``(hand1, hand2)`` berbentuk (21, 3) yang sudah dinormalkan.

    ``hands`` berisi satu atau dua array (21, 3) dalam koordinat gambar 0-1
    dan sudah diurutkan. Tangan 2 diisi nol bila hanya satu tangan.
    """
    if not hands:
        raise ValueError("Tidak ada tangan untuk dinormalkan.")

    wrist = hands[0][0]
    hand1 = hands[0] - wrist
    hand2 = hands[1] - wrist if len(hands) > 1 else np.zeros((POINT_COUNT, 3))

    scale = float(np.linalg.norm(hand1[9]))
    if not np.isfinite(scale) or scale < 1e-6:
        raise ValueError("Tangan terlalu kecil di gambar untuk dinormalkan.")

    return hand1 / scale, hand2 / scale


def landmarks_to_row(
    hands: list[np.ndarray],
    label: str,
    filename: str,
    is_flip: bool = False,
) -> dict:
    """Ubah landmark satu gambar menjadi satu baris CSV dataset."""
    ordered = order_hands(hands)
    hand1, hand2 = normalize_hands(ordered)
    label = label.strip().upper()

    row = {
        "label": label,
        "label_idx": ord(label) - ord("A"),
        "filename": filename,
        "num_hands": len(ordered),
        "is_flip": int(is_flip),
    }
    row.update(zip(HAND1_COLUMNS, hand1.ravel().tolist()))
    row.update(zip(HAND2_COLUMNS, hand2.ravel().tolist()))
    row[TWO_HANDED_COLUMN] = int(len(ordered) == 2)
    return row


def mirror(hands: list[np.ndarray]) -> list[np.ndarray]:
    """Cerminkan landmark secara horizontal, setara membalik gambar."""
    mirrored = []
    for points in hands:
        flipped = points.copy()
        flipped[:, 0] = 1.0 - flipped[:, 0]
        mirrored.append(flipped)
    return mirrored


def create_detector(model_path: Path, min_confidence: float = 0.5):
    """Buat HandLandmarker MediaPipe untuk gambar diam."""
    try:
        from mediapipe.tasks.python import BaseOptions, vision
    except ImportError as error:
        raise SystemExit(
            "Paket mediapipe belum terpasang. Jalankan: pip install -r ml/requirements.txt"
        ) from error

    if not model_path.exists():
        raise SystemExit(f"Model hand landmarker tidak ditemukan: {model_path}")

    options = vision.HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(model_path)),
        running_mode=vision.RunningMode.IMAGE,
        num_hands=2,
        min_hand_detection_confidence=min_confidence,
    )
    return vision.HandLandmarker.create_from_options(options)


def detect_hands(detector, image_path: Path) -> list[np.ndarray]:
    """Deteksi tangan pada satu gambar, kembalikan daftar array (21, 3)."""
    import mediapipe as mp

    image = mp.Image.create_from_file(str(image_path))
    result = detector.detect(image)
    return [
        np.array([[point.x, point.y, point.z] for point in hand], dtype=np.float64)
        for hand in result.hand_landmarks
    ]


def iter_images(input_dir: Path):
    """Hasilkan ``(label, path)`` untuk setiap gambar di folder per huruf."""
    for class_dir in sorted(path for path in input_dir.iterdir() if path.is_dir()):
        label = class_dir.name.strip().upper()
        if len(label) != 1 or not label.isalpha():
            print(f"  lewati folder {class_dir.name}: nama folder harus satu huruf A-Z")
            continue
        for image_path in sorted(class_dir.iterdir()):
            if image_path.suffix.lower() in IMAGE_SUFFIXES:
                yield label, image_path


def extract(
    input_dir: Path,
    output_csv: Path,
    model_path: Path = DEFAULT_MODEL,
    add_flip: bool = False,
    min_confidence: float = 0.5,
) -> dict:
    """Ekstrak seluruh gambar dan tulis CSV. Kembalikan ringkasan jumlah."""
    if not input_dir.is_dir():
        raise SystemExit(f"Folder gambar tidak ditemukan: {input_dir}")

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    summary = Counter()
    per_class = Counter()

    with create_detector(model_path, min_confidence) as detector, output_csv.open(
        "w", newline="", encoding="utf-8"
    ) as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS)
        writer.writeheader()

        for label, image_path in iter_images(input_dir):
            summary["gambar"] += 1
            try:
                hands = detect_hands(detector, image_path)
            except Exception as error:  # gambar rusak atau format tidak didukung
                summary["gagal_dibaca"] += 1
                print(f"  gagal membaca {image_path.name}: {error}")
                continue

            if not hands:
                summary["tanpa_tangan"] += 1
                continue

            variants = [(hands, False)]
            if add_flip:
                variants.append((mirror(hands), True))

            for variant, is_flip in variants:
                try:
                    writer.writerow(landmarks_to_row(variant, label, image_path.name, is_flip))
                except ValueError:
                    summary["tangan_terlalu_kecil"] += 1
                    continue
                summary["baris"] += 1
                per_class[label] += 1

    return {"ringkasan": dict(summary), "per_kelas": dict(sorted(per_class.items()))}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Ekstrak landmark MediaPipe dari foto BISINDO.")
    parser.add_argument("--input", required=True, help="Folder berisi subfolder A-Z.")
    parser.add_argument("--output", required=True, help="Jalur CSV hasil.")
    parser.add_argument("--model", default=str(DEFAULT_MODEL), help="Jalur hand_landmarker.task.")
    parser.add_argument("--flip", action="store_true", help="Tambahkan versi cermin (is_flip=1).")
    parser.add_argument("--min-confidence", type=float, default=0.5)
    args = parser.parse_args(argv)

    result = extract(
        Path(args.input),
        Path(args.output),
        model_path=Path(args.model),
        add_flip=args.flip,
        min_confidence=args.min_confidence,
    )

    summary = result["ringkasan"]
    print(f"Gambar diproses : {summary.get('gambar', 0)}")
    print(f"Baris ditulis   : {summary.get('baris', 0)}")
    print(f"Tanpa tangan    : {summary.get('tanpa_tangan', 0)}")
    print(f"Gagal dibaca    : {summary.get('gagal_dibaca', 0)}")
    print(f"Per huruf       : {result['per_kelas']}")
    print(f"CSV             : {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
