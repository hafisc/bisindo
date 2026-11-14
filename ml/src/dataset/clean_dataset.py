"""Pembersihan dataset landmark BISINDO.

Aturan dijalankan berurutan, dan setiap baris dibuang oleh aturan pertama
yang menolaknya, sehingga jumlah per aturan tidak tumpang tindih:

1. ``nilai_tidak_terhingga``   ada NaN atau inf pada fitur.
2. ``penanda_dua_tangan``      ``is_two_handed`` tidak sesuai isi tangan 2
                               (atau ``num_hands`` bila kolom itu ada).
3. ``normalisasi_tidak_sesuai`` pergelangan tangan 1 tidak di titik nol, atau
                               jarak pergelangan ke titik 9 bukan 1. Model dan
                               server mengandalkan kedua syarat ini.
4. ``duplikat_landmark``       ke-127 fitur sama persis dengan baris
                               sebelumnya. Pada dataset asli ini satu-satunya
                               masalah yang ditemukan (1.160 baris), berasal
                               dari gambar augmentasi yang menghasilkan
                               landmark identik dengan nama berkas berbeda.
                               Duplikat seperti ini bisa jatuh ke data latih
                               dan data uji sekaligus sehingga akurasi tampak
                               lebih tinggi dari kenyataan.

``data_loader.load_dataset()`` memanggil ``clean_frame()`` secara bawaan,
jadi pelatihan selalu memakai data bersih. Skrip ini dipakai untuk membuat
laporan dan, bila perlu, mengekspor CSV bersih:

    python ml/src/dataset/clean_dataset.py
    python ml/src/dataset/clean_dataset.py --output data/bersih.csv
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.data_loader import (  # noqa: E402
    DEFAULT_CSV,
    FEATURE_COLUMNS,
    HAND2_COLUMNS,
    TWO_HANDED_COLUMN,
    read_frame,
)

REPO_ROOT = SRC_DIR.parent.parent
DEFAULT_REPORT = REPO_ROOT / "ml" / "models" / "dataset_report.json"

# Toleransi pembulatan float dari CSV.
TOLERANCE = 1e-3

RULES = (
    "nilai_tidak_terhingga",
    "penanda_dua_tangan",
    "normalisasi_tidak_sesuai",
    "duplikat_landmark",
)


def _invalid_masks(frame: pd.DataFrame) -> dict[str, np.ndarray]:
    """Kembalikan mask baris yang melanggar tiap aturan (belum eksklusif)."""
    features = frame[FEATURE_COLUMNS].to_numpy(dtype=np.float64)

    non_finite = ~np.isfinite(features).all(axis=1)

    hand2_present = np.abs(np.nan_to_num(frame[HAND2_COLUMNS].to_numpy(float))).sum(axis=1) > 0
    flag = frame[TWO_HANDED_COLUMN].to_numpy()
    flag_mismatch = ~np.isin(flag, (0, 1)) | (flag.astype(bool) != hand2_present)
    if "num_hands" in frame.columns:
        flag_mismatch |= (frame["num_hands"].to_numpy() == 2) != flag.astype(bool)

    wrist = frame[["h1_pt0_x", "h1_pt0_y", "h1_pt0_z"]].to_numpy(float)
    middle_base = frame[["h1_pt9_x", "h1_pt9_y", "h1_pt9_z"]].to_numpy(float)
    with np.errstate(invalid="ignore"):
        scale = np.linalg.norm(middle_base - wrist, axis=1)
        bad_normalization = (np.abs(wrist).max(axis=1) > TOLERANCE) | (
            np.abs(scale - 1.0) > TOLERANCE
        )

    duplicate = frame.duplicated(subset=FEATURE_COLUMNS, keep="first").to_numpy()

    return {
        "nilai_tidak_terhingga": non_finite,
        "penanda_dua_tangan": flag_mismatch,
        "normalisasi_tidak_sesuai": bad_normalization,
        "duplikat_landmark": duplicate,
    }


def clean_frame(frame: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    """Buang baris tidak valid dan kembalikan ``(frame_bersih, jumlah_per_aturan)``."""
    masks = _invalid_masks(frame)
    dropped = np.zeros(len(frame), dtype=bool)
    counts: dict[str, int] = {}

    for rule in RULES:
        newly_dropped = masks[rule] & ~dropped
        counts[rule] = int(newly_dropped.sum())
        dropped |= newly_dropped

    return frame.loc[~dropped].reset_index(drop=True), counts


def build_report(raw: pd.DataFrame, clean: pd.DataFrame, counts: dict[str, int]) -> dict:
    """Susun laporan pembersihan beserta jumlah sampel per huruf."""
    before = raw["label"].astype(str).str.upper().value_counts()
    after = clean["label"].astype(str).str.upper().value_counts()
    two_handed = clean.groupby(clean["label"].astype(str).str.upper())[TWO_HANDED_COLUMN].mean()

    per_class = {
        label: {
            "sebelum": int(before.get(label, 0)),
            "sesudah": int(after.get(label, 0)),
            "dibuang": int(before.get(label, 0) - after.get(label, 0)),
            "persen_dua_tangan": round(float(two_handed.get(label, 0.0)) * 100, 1),
        }
        for label in sorted(before.index)
    }

    return {
        "baris_sebelum": int(len(raw)),
        "baris_sesudah": int(len(clean)),
        "baris_dibuang": int(len(raw) - len(clean)),
        "dibuang_per_aturan": counts,
        "sampel_per_kelas": per_class,
        "kelas_tersedikit": min(per_class, key=lambda k: per_class[k]["sesudah"]),
        "kelas_terbanyak": max(per_class, key=lambda k: per_class[k]["sesudah"]),
    }


def format_table(report: dict) -> str:
    """Tabel Markdown jumlah sampel per huruf, siap ditempel ke README."""
    lines = [
        "| Huruf | Sebelum | Sesudah | Dibuang | Dua tangan |",
        "| :---: | ---: | ---: | ---: | ---: |",
    ]
    for label, row in report["sampel_per_kelas"].items():
        lines.append(
            f"| {label} | {row['sebelum']} | {row['sesudah']} | {row['dibuang']} "
            f"| {row['persen_dua_tangan']:.0f}% |"
        )
    lines.append(
        f"| **Total** | **{report['baris_sebelum']}** | **{report['baris_sesudah']}** "
        f"| **{report['baris_dibuang']}** | |"
    )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Bersihkan dataset landmark BISINDO.")
    parser.add_argument("--csv", default=None, help="Dataset mentah (bawaan: CSV di repo).")
    parser.add_argument("--report", default=str(DEFAULT_REPORT), help="Lokasi laporan JSON.")
    parser.add_argument("--output", default=None, help="Ekspor CSV bersih ke jalur ini.")
    args = parser.parse_args(argv)

    raw = read_frame(args.csv or DEFAULT_CSV, clean=False)
    clean, counts = clean_frame(raw)
    report = build_report(raw, clean, counts)

    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    if args.output:
        clean.to_csv(args.output, index=False)
        print(f"CSV bersih disimpan ke {args.output}")

    print(f"Baris: {report['baris_sebelum']} -> {report['baris_sesudah']}")
    for rule, total in counts.items():
        print(f"  {rule}: {total}")
    print(f"Laporan: {report_path}\n")
    print(format_table(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
