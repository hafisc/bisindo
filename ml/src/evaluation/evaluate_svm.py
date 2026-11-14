"""Evaluasi model SVM BISINDO dan pembandingan kernel.

Skrip ini memuat artefak hasil ``train_svm.py``, lalu menghasilkan:

- laporan klasifikasi per huruf (teks dan JSON)
- confusion matrix 26x26 (PNG)
- grafik F1 per kelas (PNG)
- perbandingan kernel linear, polynomial, dan RBF (JSON dan PNG)

Jalankan dari akar repositori:

    python ml/src/evaluation/evaluate_svm.py

Tanpa opsi ``--compare``, skrip hanya mengevaluasi model yang tersimpan.
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
)

SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.data_loader import load_real_data  # noqa: E402
from training.train_svm import (  # noqa: E402
    DEFAULT_C,
    DEFAULT_GAMMA,
    DEFAULT_MODELS_DIR,
    LABEL_MAP_FILENAME,
    MODEL_FILENAME,
    build_model,
)

REPO_ROOT = SRC_DIR.parent.parent
DEFAULT_OUTPUT_DIR = REPO_ROOT / "ml" / "models" / "evaluation"

KERNELS = ("linear", "poly", "rbf")

# Nilai C terbaik per kernel pada eksperimen Klasifikasi_Kelompok_1.
# Memakai C yang sama untuk semua kernel akan membuat angka linear dan
# polynomial tidak sebanding dengan hasil eksperimen aslinya.
KERNEL_C_VALUES = {"linear": 1.0, "poly": 1.0, "rbf": DEFAULT_C}


def _import_pyplot():
    """Impor matplotlib secara malas agar skrip tetap jalan tanpa itu."""
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        return plt
    except ImportError:
        return None


def load_artifacts(models_dir: str | Path = DEFAULT_MODELS_DIR):
    """Muat model dan daftar kelas hasil pelatihan."""
    models_dir = Path(models_dir)
    model_path = models_dir / MODEL_FILENAME
    label_path = models_dir / LABEL_MAP_FILENAME

    if not model_path.exists():
        raise FileNotFoundError(
            f"Model belum ada di {model_path}. Jalankan train_svm.py lebih dulu."
        )

    model = joblib.load(model_path)

    if label_path.exists():
        label_map = json.loads(label_path.read_text(encoding="utf-8"))
        class_names = list(label_map["classes"])
    else:
        # Pipeline scikit-learn menyimpan kelas pada langkah terakhir.
        class_names = [str(c) for c in model.classes_]

    return model, class_names


def evaluate(
    models_dir: str | Path = DEFAULT_MODELS_DIR,
    output_dir: str | Path = DEFAULT_OUTPUT_DIR,
    csv_path: str | Path | None = None,
    test_size: float = 0.2,
    random_state: int = 42,
) -> dict:
    """Evaluasi model tersimpan pada data uji dan simpan hasilnya."""
    models_dir = Path(models_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    model, class_names = load_artifacts(models_dir)

    _, x_test, _, y_test, _ = load_real_data(
        csv_path, test_size=test_size, random_state=random_state
    )

    started = time.perf_counter()
    y_pred = model.predict(x_test)
    predict_time = time.perf_counter() - started

    accuracy = float(accuracy_score(y_test, y_pred))
    f1 = float(f1_score(y_test, y_pred, average="weighted", zero_division=0))

    report_dict = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        output_dict=True,
        zero_division=0,
    )
    report_text = classification_report(
        y_test,
        y_pred,
        target_names=class_names,
        zero_division=0,
    )

    (output_dir / "classification_report.txt").write_text(
        report_text, encoding="utf-8"
    )

    matrix = confusion_matrix(y_test, y_pred)

    result = {
        "accuracy": accuracy,
        "f1_score": f1,
        "predict_time": float(predict_time),
        "test_rows": int(len(y_test)),
        "per_class_f1": {
            name: float(report_dict[name]["f1-score"]) for name in class_names
        },
        "macro_f1": float(report_dict["macro avg"]["f1-score"]),
        "weighted_f1": float(report_dict["weighted avg"]["f1-score"]),
        "weakest_classes": sorted(
            (
                {"class": name, "f1": float(report_dict[name]["f1-score"])}
                for name in class_names
            ),
            key=lambda item: item["f1"],
        )[:5],
        "total_errors": int(len(y_test) - np.trace(matrix)),
        "most_confused": most_confused_pairs(matrix, class_names),
    }

    (output_dir / "evaluation.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    plt = _import_pyplot()
    if plt is not None:
        _plot_confusion_matrix(plt, matrix, class_names, accuracy, f1, output_dir)
        _plot_per_class_f1(plt, report_dict, class_names, output_dir)

    print(f"Akurasi      : {accuracy * 100:.2f}%")
    print(f"F1 weighted  : {f1:.4f}")
    print(f"Macro F1     : {result['macro_f1']:.4f}")
    print("Kelas terlemah:")
    for item in result["weakest_classes"]:
        print(f"  {item['class']}: F1={item['f1']:.4f}")
    print(f"Huruf paling sering tertukar ({result['total_errors']} kesalahan total):")
    for pair in result["most_confused"]:
        print(f"  {pair['actual']} terbaca {pair['predicted']}: {pair['count']} kali")
    print(f"Hasil disimpan di: {output_dir}")

    return result


def most_confused_pairs(matrix, class_names, top: int = 5) -> list[dict]:
    """Pasangan huruf yang paling sering tertukar, diambil dari luar diagonal.

    Dipakai untuk analisis kesalahan: pasangan dengan jumlah tertinggi biasanya
    punya bentuk tangan yang mirip, misalnya posisi jari yang hanya berbeda
    sedikit.
    """
    errors = np.array(matrix, copy=True)
    np.fill_diagonal(errors, 0)

    pairs = [
        {
            "actual": class_names[actual],
            "predicted": class_names[predicted],
            "count": int(errors[actual, predicted]),
        }
        for actual, predicted in zip(*np.nonzero(errors))
    ]
    pairs.sort(key=lambda pair: (-pair["count"], pair["actual"], pair["predicted"]))
    return pairs[:top]


def _plot_confusion_matrix(plt, matrix, class_names, accuracy, f1, output_dir):
    figure, axis = plt.subplots(figsize=(15, 13))
    image = axis.imshow(matrix, interpolation="nearest", cmap="Blues")
    figure.colorbar(image, ax=axis, fraction=0.046, pad=0.04)

    threshold = matrix.max() / 2 if matrix.size else 0
    for row in range(len(class_names)):
        for column in range(len(class_names)):
            axis.text(
                column,
                row,
                str(matrix[row, column]),
                ha="center",
                va="center",
                fontsize=7,
                color="white" if matrix[row, column] > threshold else "black",
            )

    axis.set_xticks(range(len(class_names)))
    axis.set_xticklabels(class_names, rotation=45, ha="right", fontsize=9)
    axis.set_yticks(range(len(class_names)))
    axis.set_yticklabels(class_names, fontsize=9)
    axis.set_xlabel("Prediksi")
    axis.set_ylabel("Label asli")
    axis.set_title(
        f"Confusion Matrix SVM RBF\nAkurasi {accuracy:.4f} | F1 {f1:.4f}",
        fontweight="bold",
    )
    figure.tight_layout()
    figure.savefig(output_dir / "confusion_matrix.png", dpi=150, bbox_inches="tight")
    plt.close(figure)


def _plot_per_class_f1(plt, report_dict, class_names, output_dir):
    scores = [float(report_dict[name]["f1-score"]) for name in class_names]

    figure, axis = plt.subplots(figsize=(14, 5))
    bars = axis.bar(class_names, scores, color="#3F51B5", edgecolor="black", linewidth=0.5)
    for bar, score in zip(bars, scores):
        axis.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.005,
            f"{score:.2f}",
            ha="center",
            va="bottom",
            fontsize=7,
        )

    axis.axhline(
        float(np.mean(scores)),
        color="red",
        linestyle="--",
        alpha=0.7,
        label=f"Rata-rata {np.mean(scores):.3f}",
    )
    axis.set_ylim(0, 1.08)
    axis.set_xlabel("Huruf")
    axis.set_ylabel("F1-Score")
    axis.set_title("F1-Score per Kelas", fontweight="bold")
    axis.legend()
    figure.tight_layout()
    figure.savefig(output_dir / "f1_per_class.png", dpi=150, bbox_inches="tight")
    plt.close(figure)


def compare_kernels(
    output_dir: str | Path = DEFAULT_OUTPUT_DIR,
    csv_path: str | Path | None = None,
    c_value: float | None = None,
    gamma: str = DEFAULT_GAMMA,
    test_size: float = 0.2,
    random_state: int = 42,
) -> list[dict]:
    """Latih dan bandingkan kernel linear, polynomial, dan RBF.

    Bila ``c_value`` dibiarkan ``None``, tiap kernel memakai nilai C terbaik
    dari eksperimen aslinya (``KERNEL_C_VALUES``).
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if csv_path:
        x_train, x_test, y_train, y_test, _ = load_real_data(
            csv_path, test_size=test_size, random_state=random_state
        )
    else:
        x_train, x_test, y_train, y_test, _ = load_real_data(
            test_size=test_size, random_state=random_state
        )

    results = []

    for kernel in KERNELS:
        kernel_c = c_value if c_value is not None else KERNEL_C_VALUES[kernel]
        print(f"Melatih kernel {kernel} (C={kernel_c}) ...")
        model = build_model(
            kernel=kernel, c_value=kernel_c, gamma=gamma, random_state=random_state
        )

        started = time.perf_counter()
        model.fit(x_train, y_train)
        train_time = time.perf_counter() - started

        started = time.perf_counter()
        y_pred = model.predict(x_test)
        predict_time = time.perf_counter() - started

        results.append(
            {
                "kernel": kernel,
                "C": kernel_c,
                "accuracy": float(accuracy_score(y_test, y_pred)),
                "f1_score": float(
                    f1_score(y_test, y_pred, average="weighted", zero_division=0)
                ),
                "train_time": float(train_time),
                "predict_time": float(predict_time),
            }
        )

    best = max(results, key=lambda item: item["f1_score"])

    (output_dir / "kernel_comparison.json").write_text(
        json.dumps(
            {"best_kernel": best["kernel"], "results": results},
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    plt = _import_pyplot()
    if plt is not None:
        figure, axis = plt.subplots(figsize=(8, 5))
        names = [item["kernel"] for item in results]
        scores = [item["f1_score"] for item in results]
        bars = axis.bar(names, scores, color=["#90A4AE", "#FFB74D", "#3F51B5"])
        for bar, score in zip(bars, scores):
            axis.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height() + 0.005,
                f"{score:.4f}",
                ha="center",
                va="bottom",
                fontsize=9,
            )
        axis.set_ylim(0, 1.05)
        axis.set_xlabel("Kernel")
        axis.set_ylabel("F1 weighted")
        axis.set_title("Perbandingan Kernel SVM", fontweight="bold")
        figure.tight_layout()
        figure.savefig(
            output_dir / "kernel_comparison.png", dpi=150, bbox_inches="tight"
        )
        plt.close(figure)

    for item in results:
        print(
            f"  {item['kernel']:7s} C={item['C']:<5g} akurasi={item['accuracy']:.4f} "
            f"f1={item['f1_score']:.4f}"
        )

    print(f"Kernel terbaik: {best['kernel']}")
    return results


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Evaluasi model SVM BISINDO.")
    parser.add_argument("--csv", default=None, help="Jalur dataset CSV landmark.")
    parser.add_argument("--models-dir", default=str(DEFAULT_MODELS_DIR))
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT_DIR))
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Bandingkan kernel linear, polynomial, dan RBF.",
    )
    parser.add_argument(
        "--C",
        dest="c_value",
        type=float,
        default=None,
        help=(
            "Nilai C untuk semua kernel. Bila tidak diisi, tiap kernel memakai "
            "nilai terbaiknya (linear 1.0, poly 1.0, rbf 10.0)."
        ),
    )
    parser.add_argument("--gamma", default=DEFAULT_GAMMA)
    parser.add_argument("--test-size", type=float, default=0.2)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    evaluate(
        models_dir=args.models_dir,
        output_dir=args.output_dir,
        csv_path=args.csv,
        test_size=args.test_size,
    )

    if args.compare:
        print("\nMembandingkan kernel ...")
        compare_kernels(
            output_dir=args.output_dir,
            csv_path=args.csv,
            c_value=args.c_value,
            gamma=args.gamma,
            test_size=args.test_size,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
