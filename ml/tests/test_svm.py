"""Test pipeline pelatihan dan evaluasi model SVM BISINDO."""

import json
from pathlib import Path

import joblib
import numpy as np
import pytest

from dataset.clean_dataset import build_report, clean_frame
from dataset.data_loader import (
    FEATURE_COLUMNS,
    FEATURE_COUNT,
    HAND1_COLUMNS,
    HAND2_COLUMNS,
    TWO_HANDED_COLUMN,
    count_filename_overlap,
    encode_labels,
    load_dataset,
    load_real_data,
    read_frame,
    validate_columns,
)
from training.train_svm import (
    LABEL_MAP_FILENAME,
    METRICS_FILENAME,
    MODEL_FILENAME,
    build_model,
    train,
)

ALPHABET = [chr(code) for code in range(ord("A"), ord("Z") + 1)]


# ── Susunan fitur ────────────────────────────────────────────────────────────


def test_jumlah_fitur_127():
    assert len(HAND1_COLUMNS) == 63
    assert len(HAND2_COLUMNS) == 63
    assert FEATURE_COUNT == 127


def test_urutan_fitur_sesuai_kontrak():
    """Urutan harus sama dengan dataset_bisindo_landmarks.npz."""
    assert FEATURE_COLUMNS[0] == "h1_pt0_x"
    assert FEATURE_COLUMNS[2] == "h1_pt0_z"
    assert FEATURE_COLUMNS[63] == "h2_pt0_x"
    assert FEATURE_COLUMNS[-2] == "h2_pt20_z"
    assert FEATURE_COLUMNS[-1] == TWO_HANDED_COLUMN


# ── Pemuatan dataset ─────────────────────────────────────────────────────────


# Dataset mentah 7.893 baris; 1.160 di antaranya duplikat landmark.
RAW_ROWS = 7893
CLEAN_ROWS = 6733


def test_dataset_asli_terbaca():
    features, labels = load_dataset()

    assert features.shape == (CLEAN_ROWS, 127)
    assert features.dtype == np.float32
    assert set(labels) == set(ALPHABET)
    assert not np.isnan(features).any()
    assert not np.isinf(features).any()


def test_dataset_mentah_tetap_bisa_dimuat():
    features, _ = load_dataset(clean=False)

    assert features.shape == (RAW_ROWS, 127)


def test_data_bersih_tanpa_duplikat_landmark():
    frame = read_frame()

    assert not frame.duplicated(subset=FEATURE_COLUMNS).any()


def _contoh_baris(label="A", two_handed=False):
    """Satu baris valid: pergelangan di titik nol, titik 9 berjarak 1."""
    row = {column: 0.0 for column in FEATURE_COLUMNS}
    row["label"] = label
    row["h1_pt9_y"] = -1.0
    row["h1_pt8_y"] = -1.5
    if two_handed:
        row["h2_pt0_x"] = 2.0
        row[TWO_HANDED_COLUMN] = 1
    else:
        row[TWO_HANDED_COLUMN] = 0
    return row


def test_pembersihan_membuang_tiap_jenis_data_tidak_valid():
    import pandas as pd

    valid = _contoh_baris("A")
    duplikat = dict(valid)
    nan_row = _contoh_baris("B")
    nan_row["h1_pt4_x"] = float("nan")
    flag_salah = _contoh_baris("C", two_handed=True)
    flag_salah[TWO_HANDED_COLUMN] = 0
    skala_salah = _contoh_baris("D")
    skala_salah["h1_pt9_y"] = -2.0
    dua_tangan = _contoh_baris("E", two_handed=True)

    frame = pd.DataFrame([valid, duplikat, nan_row, flag_salah, skala_salah, dua_tangan])
    clean, counts = clean_frame(frame)

    assert list(clean["label"]) == ["A", "E"]
    assert counts == {
        "nilai_tidak_terhingga": 1,
        "penanda_dua_tangan": 1,
        "normalisasi_tidak_sesuai": 1,
        "duplikat_landmark": 1,
    }


def test_laporan_jumlah_sampel_per_kelas():
    raw = read_frame(clean=False)
    clean, counts = clean_frame(raw)
    report = build_report(raw, clean, counts)

    assert report["baris_sebelum"] == RAW_ROWS
    assert report["baris_sesudah"] == CLEAN_ROWS
    assert set(report["sampel_per_kelas"]) == set(ALPHABET)
    assert sum(row["sesudah"] for row in report["sampel_per_kelas"].values()) == CLEAN_ROWS
    assert report["kelas_tersedikit"] == "Y"


def test_label_terenkode_urut_abjad():
    _, labels = load_dataset()
    encoded, class_names = encode_labels(labels)

    assert class_names == ALPHABET
    assert encoded.min() == 0
    assert encoded.max() == 25


def test_split_stratified_seimbang():
    x_train, x_test, y_train, y_test, class_names = load_real_data()

    assert x_train.shape[1] == 127
    assert len(class_names) == 26
    assert len(y_train) + len(y_test) == CLEAN_ROWS

    # Setiap kelas harus muncul di kedua bagian.
    assert set(y_train) == set(range(26))
    assert set(y_test) == set(range(26))


def test_kolom_hilang_ditolak(tmp_path):
    import pandas as pd

    frame = pd.DataFrame({"label": ["A"], "h1_pt0_x": [0.0]})
    with pytest.raises(ValueError) as error:
        validate_columns(frame)

    assert "Kolom wajib tidak ditemukan" in str(error.value)


def test_file_dataset_tidak_ada():
    with pytest.raises(FileNotFoundError):
        load_dataset("tidak/ada/file.csv")


def test_hitungan_tumpang_tindih_nama_berkas():
    """Dataset memakai ulang nama berkas augmentasi di banyak kelas.

    Angka ini dipakai sebagai peringatan kebocoran data di metrics.json.
    """
    overlap = count_filename_overlap()

    assert overlap["shared_names"] > 0
    assert overlap["train_rows"] + overlap["test_rows"] == CLEAN_ROWS


# ── Model ────────────────────────────────────────────────────────────────────


def test_pipeline_memuat_scaler_dan_svm():
    model = build_model()

    assert list(dict(model.steps)) == ["scaler", "svm"]
    assert model.named_steps["svm"].kernel == "rbf"
    assert model.named_steps["svm"].C == 10.0


def test_latih_dan_simpan_artefak(tmp_path):
    """Latih model pada subset kecil lalu pastikan artefaknya bisa dimuat."""
    metrics = train(
        models_dir=tmp_path,
        test_size=0.2,
        cross_validate=False,
    )

    model_path = tmp_path / MODEL_FILENAME
    label_path = tmp_path / LABEL_MAP_FILENAME
    metrics_path = tmp_path / METRICS_FILENAME

    assert model_path.exists()
    assert label_path.exists()
    assert metrics_path.exists()

    model = joblib.load(model_path)
    label_map = json.loads(label_path.read_text(encoding="utf-8"))
    saved = json.loads(metrics_path.read_text(encoding="utf-8"))

    assert label_map["classes"] == ALPHABET
    assert label_map["feature_count"] == 127
    assert saved["feature_count"] == 127
    assert saved["class_count"] == 26

    # Scaler harus ikut tersimpan, kalau tidak prediksi akan salah diam-diam.
    assert hasattr(model, "named_steps")
    assert "scaler" in model.named_steps

    # Model harus menghasilkan prediksi yang valid.
    x_train, x_test, _, _, _ = load_real_data()
    predictions = model.predict(x_test[:20])
    assert len(predictions) == 20
    assert set(predictions).issubset(set(range(26)))

    # Probabilitas dipakai untuk confidence di /api/predict.
    probabilities = model.predict_proba(x_test[:5])
    assert probabilities.shape == (5, 26)
    assert np.allclose(probabilities.sum(axis=1), 1.0, atol=1e-5)

    assert 0.0 <= metrics["accuracy"] <= 1.0
    assert metrics["filename_overlap"]["shared_names"] > 0


def test_akurasi_mencapai_target(tmp_path):
    """Model harus melampaui ambang wajar untuk 26 kelas."""
    metrics = train(models_dir=tmp_path, cross_validate=False)

    # Eksperimen awal mencapai 97,91%. Ambang dibuat longgar agar test
    # tidak rapuh, tapi tetap menangkap model yang rusak.
    assert metrics["accuracy"] >= 0.90


def test_metrics_mencatat_peringatan_dataset(tmp_path):
    metrics = train(models_dir=tmp_path, cross_validate=False)

    assert "dataset_warning" in metrics
    assert "optimistis" in metrics["dataset_warning"]
    assert len(metrics["per_class_f1"]) == 26
    assert len(metrics["confusion_matrix"]) == 26


# ── Evaluasi ─────────────────────────────────────────────────────────────────


def test_evaluasi_model_tersimpan(tmp_path):
    from evaluation.evaluate_svm import evaluate

    models_dir = tmp_path / "models"
    output_dir = tmp_path / "evaluation"

    train(models_dir=models_dir, cross_validate=False)
    result = evaluate(models_dir=models_dir, output_dir=output_dir)

    assert result["accuracy"] >= 0.90
    assert 0.0 <= result["macro_f1"] <= 1.0
    assert len(result["weakest_classes"]) == 5
    assert 1 <= len(result["most_confused"]) <= 5
    assert result["total_errors"] >= sum(pair["count"] for pair in result["most_confused"])
    assert (output_dir / "classification_report.txt").exists()
    assert (output_dir / "evaluation.json").exists()


def test_pasangan_huruf_tertukar_diurutkan_dari_terbanyak():
    from evaluation.evaluate_svm import most_confused_pairs

    matrix = np.array(
        [
            [9, 1, 0],
            [3, 7, 0],
            [0, 2, 8],
        ]
    )
    pairs = most_confused_pairs(matrix, ["A", "B", "C"], top=2)

    assert pairs == [
        {"actual": "B", "predicted": "A", "count": 3},
        {"actual": "C", "predicted": "B", "count": 2},
    ]


def test_evaluasi_tanpa_model_memberi_pesan_jelas(tmp_path):
    from evaluation.evaluate_svm import load_artifacts

    with pytest.raises(FileNotFoundError) as error:
        load_artifacts(tmp_path)

    assert "train_svm.py" in str(error.value)
