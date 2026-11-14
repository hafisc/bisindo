"""Pelatihan model SVM untuk klasifikasi huruf BISINDO.

Skrip ini mereproduksi konfigurasi yang menghasilkan akurasi terbaik pada
eksperimen ``Klasifikasi_Kelompok_1``: standardisasi fitur diikuti SVM
kernel RBF dengan ``C=10.0`` dan ``gamma='scale'``.

Berbeda dari notebook eksperimen, hasil latihan di sini disimpan sebagai
artefak sehingga bisa dipakai ulang oleh server web:

- ``svm_rbf_bisindo.joblib``  model lengkap (scaler + SVM)
- ``label_map.json``          urutan kelas A-Z
- ``metrics.json``            metrik evaluasi dan konfigurasi

Jalankan dari akar repositori:

    python ml/src/training/train_svm.py

Atau dengan dataset lain:

    python ml/src/training/train_svm.py --csv jalur/dataset.csv
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import joblib
import numpy as np
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

# Agar modul ``dataset`` dan ``training`` bisa diimpor saat skrip dijalankan
# langsung sebagai berkas.
SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.data_loader import (  # noqa: E402
    DEFAULT_CSV,
    FEATURE_COUNT,
    count_filename_overlap,
    load_real_data,
)

REPO_ROOT = SRC_DIR.parent.parent
DEFAULT_MODELS_DIR = REPO_ROOT / "ml" / "models"

MODEL_FILENAME = "svm_rbf_bisindo.joblib"
LABEL_MAP_FILENAME = "label_map.json"
METRICS_FILENAME = "metrics.json"

# Konfigurasi terbaik dari eksperimen SVM (akurasi 97,91%).
DEFAULT_KERNEL = "rbf"
DEFAULT_C = 10.0
DEFAULT_GAMMA = "scale"


def build_model(
    kernel: str = DEFAULT_KERNEL,
    c_value: float = DEFAULT_C,
    gamma: str = DEFAULT_GAMMA,
    random_state: int = 42,
) -> Pipeline:
    """Bentuk pipeline standardisasi + SVM.

    Scaler harus ikut tersimpan bersama model. Tanpa itu, data yang masuk
    saat prediksi tidak berada pada skala yang sama dengan saat latihan dan
    hasilnya akan salah tanpa memunculkan error.
    """
    return Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "svm",
                SVC(
                    kernel=kernel,
                    C=c_value,
                    gamma=gamma,
                    probability=True,
                    random_state=random_state,
                ),
            ),
        ]
    )


def train(
    csv_path: str | Path | None = None,
    models_dir: str | Path = DEFAULT_MODELS_DIR,
    kernel: str = DEFAULT_KERNEL,
    c_value: float = DEFAULT_C,
    gamma: str = DEFAULT_GAMMA,
    test_size: float = 0.2,
    random_state: int = 42,
    cross_validate: bool = True,
) -> dict:
    """Latih model, simpan artefak, dan kembalikan metriknya."""
    csv_path = Path(csv_path) if csv_path else DEFAULT_CSV
    models_dir = Path(models_dir)
    models_dir.mkdir(parents=True, exist_ok=True)

    print(f"[1/5] Memuat dataset: {csv_path}")
    x_train, x_test, y_train, y_test, class_names = load_real_data(
        csv_path,
        test_size=test_size,
        random_state=random_state,
    )
    print(
        f"      latih={x_train.shape[0]} uji={x_test.shape[0]} "
        f"fitur={x_train.shape[1]} kelas={len(class_names)}"
    )

    if x_train.shape[1] != FEATURE_COUNT:
        raise ValueError(
            f"Jumlah fitur tidak sesuai: {x_train.shape[1]}, "
            f"seharusnya {FEATURE_COUNT}."
        )

    print(f"[2/5] Melatih SVM kernel={kernel} C={c_value} gamma={gamma}")
    model = build_model(kernel=kernel, c_value=c_value, gamma=gamma, random_state=random_state)

    started = time.perf_counter()
    model.fit(x_train, y_train)
    train_time = time.perf_counter() - started

    print("[3/5] Mengevaluasi pada data uji")
    started = time.perf_counter()
    y_pred = model.predict(x_test)
    predict_time = time.perf_counter() - started

    accuracy = float(accuracy_score(y_test, y_pred))
    precision = float(precision_score(y_test, y_pred, average="weighted", zero_division=0))
    recall = float(recall_score(y_test, y_pred, average="weighted", zero_division=0))
    f1 = float(f1_score(y_test, y_pred, average="weighted", zero_division=0))

    print(f"      akurasi={accuracy:.4f} f1={f1:.4f} latih={train_time:.2f}s")

    cv_mean = None
    cv_std = None
    if cross_validate:
        print("[4/5] Validasi silang 5 lipat (agak lambat, mohon tunggu)")
        folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=random_state)
        scores = cross_val_score(
            build_model(kernel=kernel, c_value=c_value, gamma=gamma, random_state=random_state),
            x_train,
            y_train,
            cv=folds,
            scoring="f1_weighted",
            n_jobs=-1,
        )
        cv_mean = float(np.mean(scores))
        cv_std = float(np.std(scores))
        print(f"      CV F1 = {cv_mean:.4f} +/- {cv_std:.4f}")

    report = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )

    print("[5/5] Menyimpan artefak")
    model_path = models_dir / MODEL_FILENAME
    joblib.dump(model, model_path, compress=3)

    label_map_path = models_dir / LABEL_MAP_FILENAME
    label_map_path.write_text(
        json.dumps(
            {"classes": class_names, "feature_count": FEATURE_COUNT},
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    overlap = count_filename_overlap(
        csv_path, test_size=test_size, random_state=random_state
    )

    metrics = {
        "algorithm": "SVM",
        "variant": f"SVM {kernel.upper()}",
        "kernel": kernel,
        "C": c_value,
        "gamma": gamma,
        "feature_count": FEATURE_COUNT,
        "class_count": len(class_names),
        "train_rows": int(x_train.shape[0]),
        "test_rows": int(x_test.shape[0]),
        "test_size": test_size,
        "random_state": random_state,
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1_score": f1,
        "cv_f1_mean": cv_mean,
        "cv_f1_std": cv_std,
        "train_time": float(train_time),
        "predict_time": float(predict_time),
        "per_class_f1": {
            name: float(report[name]["f1-score"]) for name in class_names
        },
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "dataset_warning": (
            "Dataset tidak menyimpan penanda gambar asal dan nama berkas "
            "augmentasi dipakai ulang di banyak kelas, sehingga pembagian "
            "data latih/uji dilakukan per baris. Akurasi berpotensi lebih "
            "optimistis daripada performa di dunia nyata."
        ),
        "filename_overlap": overlap,
        "model_file": MODEL_FILENAME,
        "label_map_file": LABEL_MAP_FILENAME,
    }

    metrics_path = models_dir / METRICS_FILENAME
    metrics_path.write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    print(f"      model  -> {model_path}")
    print(f"      label  -> {label_map_path}")
    print(f"      metrik -> {metrics_path}")

    return metrics


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Latih model SVM klasifikasi huruf BISINDO."
    )
    parser.add_argument("--csv", default=None, help="Jalur dataset CSV landmark.")
    parser.add_argument(
        "--models-dir", default=str(DEFAULT_MODELS_DIR), help="Folder keluaran artefak."
    )
    parser.add_argument("--kernel", default=DEFAULT_KERNEL, choices=["rbf", "linear", "poly"])
    parser.add_argument("--C", dest="c_value", type=float, default=DEFAULT_C)
    parser.add_argument("--gamma", default=DEFAULT_GAMMA)
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--no-cv", action="store_true", help="Lewati validasi silang.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    metrics = train(
        csv_path=args.csv,
        models_dir=args.models_dir,
        kernel=args.kernel,
        c_value=args.c_value,
        gamma=args.gamma,
        test_size=args.test_size,
        cross_validate=not args.no_cv,
    )

    print("\nRingkasan")
    print(f"  akurasi   : {metrics['accuracy'] * 100:.2f}%")
    print(f"  F1 weighted: {metrics['f1_score']:.4f}")
    print(f"  model     : {metrics['model_file']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
