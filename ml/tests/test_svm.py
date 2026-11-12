"""Test pipeline pelatihan dan evaluasi model SVM BISINDO."""

import json
from pathlib import Path

import joblib
import numpy as np
import pytest

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


def test_dataset_asli_terbaca():
    features, labels = load_dataset()

    assert features.shape == (7893, 127)
    assert features.dtype == np.float32
    assert set(labels) == set(ALPHABET)
    assert not np.isnan(features).any()
    assert not np.isinf(features).any()


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
    assert len(y_train) + len(y_test) == 7893

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
    assert overlap["train_rows"] + overlap["test_rows"] == 7893


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
    assert (output_dir / "classification_report.txt").exists()
    assert (output_dir / "evaluation.json").exists()


def test_evaluasi_tanpa_model_memberi_pesan_jelas(tmp_path):
    from evaluation.evaluate_svm import load_artifacts

    with pytest.raises(FileNotFoundError) as error:
        load_artifacts(tmp_path)

    assert "train_svm.py" in str(error.value)
