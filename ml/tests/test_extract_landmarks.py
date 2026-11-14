"""Test konversi landmark MediaPipe menjadi baris dataset.

Bagian yang diuji tidak memanggil MediaPipe, sehingga test tetap berjalan di
mesin yang belum memasang paket mediapipe.
"""

import numpy as np
import pandas as pd
import pytest

from dataset.clean_dataset import clean_frame
from dataset.data_loader import DEFAULT_CSV, FEATURE_COLUMNS
from dataset.extract_landmarks import (
    CSV_COLUMNS,
    iter_images,
    landmarks_to_row,
    mirror,
    order_hands,
)


def _tangan(wrist_x, rng):
    """Satu tangan acak (21, 3) dengan pergelangan di ``wrist_x``."""
    points = rng.uniform(0.0, 0.2, (21, 3))
    points[:, 0] += wrist_x
    points[0] = [wrist_x, 0.5, 0.0]
    return points


def test_kolom_csv_sama_dengan_dataset_asli():
    asli = pd.read_csv(DEFAULT_CSV, nrows=1)

    assert CSV_COLUMNS == list(asli.columns)


def test_tangan_paling_kiri_menjadi_tangan_1():
    rng = np.random.default_rng(0)
    kanan, kiri = _tangan(0.7, rng), _tangan(0.2, rng)

    urut = order_hands([kanan, kiri])

    assert urut[0] is kiri
    assert urut[1] is kanan


def test_normalisasi_satu_tangan():
    rng = np.random.default_rng(1)
    row = landmarks_to_row([_tangan(0.4, rng)], "c", "foto.jpg")

    assert row["label"] == "C"
    assert row["label_idx"] == 2
    assert row["num_hands"] == 1
    assert row["is_two_handed"] == 0
    assert (row["h1_pt0_x"], row["h1_pt0_y"], row["h1_pt0_z"]) == (0.0, 0.0, 0.0)
    jarak = np.linalg.norm([row["h1_pt9_x"], row["h1_pt9_y"], row["h1_pt9_z"]])
    assert jarak == pytest.approx(1.0)
    assert all(row[f"h2_pt{i}_{a}"] == 0.0 for i in range(21) for a in "xyz")


def test_dua_tangan_memakai_acuan_tangan_1():
    rng = np.random.default_rng(2)
    row = landmarks_to_row([_tangan(0.2, rng), _tangan(0.6, rng)], "K", "foto.jpg")

    assert row["num_hands"] == 2
    assert row["is_two_handed"] == 1
    # Tangan 2 berada di kanan tangan 1 dan tidak ikut digeser ke titik nol.
    assert row["h2_pt0_x"] > 0


def test_cermin_membalik_urutan_tangan():
    rng = np.random.default_rng(3)
    kiri, kanan = _tangan(0.2, rng), _tangan(0.6, rng)

    asli = landmarks_to_row([kiri, kanan], "K", "f.jpg")
    cermin = landmarks_to_row(mirror([kiri, kanan]), "K", "f.jpg", is_flip=True)

    assert cermin["is_flip"] == 1
    assert cermin["h2_pt0_x"] > 0
    assert cermin["h1_pt9_x"] == pytest.approx(-_x_relatif(kanan) / _skala(kanan))
    assert asli["h1_pt9_x"] == pytest.approx(_x_relatif(kiri) / _skala(kiri))


def _x_relatif(points):
    return points[9, 0] - points[0, 0]


def _skala(points):
    return np.linalg.norm(points[9] - points[0])


def test_tangan_terlalu_kecil_ditolak():
    titik = np.zeros((21, 3))

    with pytest.raises(ValueError):
        landmarks_to_row([titik], "A", "kosong.jpg")


def test_hasil_ekstraksi_lolos_aturan_pembersihan():
    rng = np.random.default_rng(4)
    rows = [
        landmarks_to_row([_tangan(0.3, rng)], "A", "a.jpg"),
        landmarks_to_row([_tangan(0.2, rng), _tangan(0.7, rng)], "B", "b.jpg"),
    ]

    clean, counts = clean_frame(pd.DataFrame(rows, columns=CSV_COLUMNS))

    assert len(clean) == 2
    assert sum(counts.values()) == 0
    assert clean[FEATURE_COLUMNS].shape[1] == 127


def test_folder_bukan_huruf_dilewati(tmp_path):
    (tmp_path / "A").mkdir()
    (tmp_path / "A" / "satu.jpg").write_bytes(b"")
    (tmp_path / "A" / "catatan.txt").write_text("bukan gambar")
    (tmp_path / "lain").mkdir()
    (tmp_path / "lain" / "dua.jpg").write_bytes(b"")

    hasil = [(label, path.name) for label, path in iter_images(tmp_path)]

    assert hasil == [("A", "satu.jpg")]
