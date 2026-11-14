"""Ekspor pose referensi tiap huruf untuk ilustrasi Kamus di aplikasi mobile.

Untuk setiap huruf dipilih satu sampel asli dari dataset bersih yang paling
mewakili (medoid): sampel dengan jarak terkecil ke rata-rata sampel lain dengan
jumlah tangan yang sama. Sampel asli dipakai, bukan rata-rata, karena rata-rata
landmark menghasilkan bentuk tangan yang tidak pernah benar-benar diperagakan.

Teks cara memperagakan hanya memuat fakta yang konsisten di data:

- jumlah tangan (diambil dari mayoritas sampel huruf itu),
- jari yang lurus pada sedikitnya 90% sampel. Ibu jari tidak disebut karena
  sudut sendinya hampir selalu terbaca lurus walaupun terlipat,
- huruf yang paling sering tertukar menurut confusion matrix model.

Bentuk detail lainnya ditunjukkan oleh ilustrasi, bukan oleh teks, supaya
kamus tidak mengajarkan bentuk tangan yang salah.

Jalankan dari akar repositori setelah model dilatih:

    python ml/src/dataset/export_dictionary_poses.py
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.data_loader import (  # noqa: E402
    HAND1_COLUMNS,
    HAND2_COLUMNS,
    TWO_HANDED_COLUMN,
    read_frame,
)

REPO_ROOT = SRC_DIR.parent.parent
DEFAULT_METRICS = REPO_ROOT / "ml" / "models" / "metrics.json"
DEFAULT_OUTPUT = REPO_ROOT / "mobile" / "assets" / "data" / "bisindo_poses.json"

# Indeks sendi per jari (pangkal, sendi tengah, sendi ujung, ujung jari).
FINGER_JOINTS = {
    "telunjuk": (5, 6, 7, 8),
    "jari tengah": (9, 10, 11, 12),
    "jari manis": (13, 14, 15, 16),
    "kelingking": (17, 18, 19, 20),
}
STRAIGHT_COSINE = 0.8
AGREEMENT = 0.9


def _unit(vector: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(vector, axis=-1, keepdims=True)
    return vector / np.where(norm == 0, 1, norm)


def straight_fingers(hands: np.ndarray) -> list[str]:
    """Jari yang lurus pada sedikitnya 90% sampel.

    ``hands`` berbentuk (n_sampel, 21, 3). Kelurusan diukur dari rata-rata
    cosinus antar ruas di sendi tengah dan sendi ujung jari.
    """
    result = []
    for name, (base, middle, upper, tip) in FINGER_JOINTS.items():
        first = _unit(hands[:, middle] - hands[:, base])
        second = _unit(hands[:, upper] - hands[:, middle])
        third = _unit(hands[:, tip] - hands[:, upper])
        straightness = (
            np.sum(first * second, axis=1) + np.sum(second * third, axis=1)
        ) / 2
        if np.mean(straightness > STRAIGHT_COSINE) >= AGREEMENT:
            result.append(name)
    return result


def _join(names: list[str]) -> str:
    if len(names) <= 1:
        return "".join(names)
    return ", ".join(names[:-1]) + " dan " + names[-1]


def medoid_index(features: np.ndarray) -> int:
    """Indeks sampel yang paling dekat dengan rata-rata kelompoknya."""
    center = features.mean(axis=0)
    return int(np.argmin(np.linalg.norm(features - center, axis=1)))


def most_confused_with(matrix: list[list[int]], classes: list[str]) -> dict[str, str]:
    """Untuk tiap huruf, huruf lain yang paling sering tertukar dua arah."""
    errors = np.array(matrix, dtype=int)
    np.fill_diagonal(errors, 0)
    combined = errors + errors.T
    partners = {}
    for index, label in enumerate(classes):
        if combined[index].max() > 0:
            partners[label] = classes[int(np.argmax(combined[index]))]
    return partners


def build_pose(group, label: str, partner: str | None) -> dict:
    """Susun data pose dan teks instruksi untuk satu huruf."""
    two_handed_ratio = float(group[TWO_HANDED_COLUMN].mean())
    two_handed = two_handed_ratio >= 0.5
    same_hands = group[group[TWO_HANDED_COLUMN] == int(two_handed)]
    # Utamakan sampel asli (bukan hasil cermin) untuk ilustrasi.
    originals = same_hands[same_hands["is_flip"] == 0] if "is_flip" in same_hands else same_hands
    candidates = originals if len(originals) else same_hands

    columns = HAND1_COLUMNS + (HAND2_COLUMNS if two_handed else [])
    features = candidates[columns].to_numpy(dtype=float)
    sample = features[medoid_index(features)]
    hands = [sample[:63].reshape(21, 3)]
    if two_handed:
        hands.append(sample[63:].reshape(21, 3))

    instructions = [
        "Peragakan dengan dua tangan, posisinya seperti pada ilustrasi."
        if two_handed
        else "Peragakan dengan satu tangan."
    ]

    hand_columns = [HAND1_COLUMNS] + ([HAND2_COLUMNS] if two_handed else [])
    hand_names = ["kiri", "kanan"] if two_handed else [None]
    for columns_of_hand, side in zip(hand_columns, hand_names):
        stacked = same_hands[columns_of_hand].to_numpy(dtype=float).reshape(-1, 21, 3)
        fingers = straight_fingers(stacked)
        if not fingers:
            continue
        owner = f"Pada tangan {side} ilustrasi, " if side else ""
        sentence = f"{owner}{_join(fingers)} lurus."
        instructions.append(sentence[0].upper() + sentence[1:])

    instructions.append("Hadapkan tangan ke kamera dan pastikan semua jari terlihat.")

    if partner:
        tips = (
            f"Huruf {label} paling sering tertukar dengan {partner}. "
            f"Bandingkan ilustrasi keduanya dan perhatikan posisi jarinya."
        )
    else:
        tips = "Peragakan perlahan dan tahan posisi tangan sampai huruf terdeteksi."

    return {
        "letter": label,
        "twoHanded": two_handed,
        "twoHandedPercent": round(two_handed_ratio * 100),
        "samples": int(len(group)),
        "hands": [[[round(float(x), 3), round(float(y), 3)] for x, y, _ in hand] for hand in hands],
        "instructions": instructions,
        "tips": tips,
        "confusedWith": partner,
    }


def export(output: Path = DEFAULT_OUTPUT, metrics_path: Path = DEFAULT_METRICS) -> dict:
    frame = read_frame()
    frame = frame.assign(label=frame["label"].astype(str).str.upper())

    partners: dict[str, str] = {}
    if metrics_path.exists():
        metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
        classes = json.loads((metrics_path.parent / "label_map.json").read_text(encoding="utf-8"))[
            "classes"
        ]
        partners = most_confused_with(metrics["confusion_matrix"], classes)

    poses = {
        label: build_pose(group, label, partners.get(label))
        for label, group in sorted(frame.groupby("label"))
    }
    payload = {
        "source": "Sampel medoid dari ml/src/dataset/dataset_bisindo_landmarks.csv setelah pembersihan",
        "letters": poses,
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    return payload


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Ekspor pose referensi huruf untuk Kamus.")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args(argv)

    payload = export(Path(args.output))
    for label, pose in payload["letters"].items():
        hands = "2 tangan" if pose["twoHanded"] else "1 tangan"
        print(f"{label}: {hands}, {pose['samples']} sampel. " + " ".join(pose["instructions"][1:-1]))
    print(f"\nTersimpan di {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
