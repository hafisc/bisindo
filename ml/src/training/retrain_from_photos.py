"""Latih ulang SVM dari CSV landmark hasil ekstraksi foto, dengan evaluasi jujur.

Berbeda dari ``train_svm.py`` (split per baris), skrip ini:

1. Membagi data **per foto**: foto, versi cerminnya, dan foto lain yang
   bentuk tangannya nyaris sama (hasil augmentasi gambar) selalu berada di sisi
   yang sama. Dengan begitu data uji benar-benar belum pernah dilihat model.
2. Memilih ``C`` dan ``gamma`` lewat validasi silang berkelompok, dinilai pada
   rasio frame persegi, 4:3, dan 16:9 (lihat ``augment_landmarks.py``).
3. Menilai seperti server: tiap sampel uji dicoba pada kandidat asli, tangan
   ditukar, dan cermin, lalu dipakai yang paling yakin.
4. Menyimpan artefak dengan format yang sama dengan ``train_svm.py``.

Jalankan dari akar repositori:

    python ml/src/dataset/extract_landmarks.py --input <folder foto> --output ml/data/processed/landmarks_train.csv
    python ml/src/training/retrain_from_photos.py --csv ml/data/processed/landmarks_train.csv         --group-threshold 0.01 --no-original --C 30 --gamma 0.004 --copies 3         --drop-single-hand B P --point-noise 0.015 0.035 0.06

Perintah kedua mereproduksi model yang dipakai server. Langkah yang sama ada di
notebook ``ml/notebooks/01_preprocessing_dataset_foto.ipynb`` dan
``02_latih_ulang_model.ipynb``.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import joblib
import numpy as np
from joblib import Parallel, delayed
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
from sklearn.model_selection import StratifiedGroupKFold

SRC_DIR = Path(__file__).resolve().parent.parent
if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

from dataset.augment_landmarks import (  # noqa: E402
    augment_dataset,
    mirror_x,
    stretch_aspect,
    swap_hands,
)
from dataset.data_loader import FEATURE_COLUMNS, FEATURE_COUNT, read_frame  # noqa: E402
from training.train_svm import (  # noqa: E402
    DEFAULT_MODELS_DIR,
    LABEL_MAP_FILENAME,
    METRICS_FILENAME,
    MODEL_FILENAME,
    build_model,
)

PHONE_ASPECT = 16.0 / 9.0  # frame potret 720x1280 dari ResolutionPreset.high
EVAL_ASPECTS = (1.0, 4.0 / 3.0, 1.6, PHONE_ASPECT, 2.0)


def aspect_name(aspect: float) -> str:
    known = {1.0: "persegi", 4.0 / 3.0: "4:3", PHONE_ASPECT: "16:9"}
    for value, name in known.items():
        if abs(aspect - value) < 1e-6:
            return name
    return f"{aspect:.2f}"
DEFAULT_C_GRID = (1.0, 3.0, 10.0, 30.0)
DEFAULT_GAMMA_GRID = (0.004, 0.008, 0.016)  # 'scale' setara sekitar 1/127 = 0,008


# --------------------------------------------------------------------------
# Pengelompokan foto
# --------------------------------------------------------------------------
def shape_descriptor(features: np.ndarray) -> np.ndarray:
    """Jarak antar titik, tidak berubah oleh rotasi maupun pencerminan."""
    points = features[:, :126].reshape(len(features), 42, 3).astype(np.float64)
    index_a, index_b = np.triu_indices(42, k=1)
    distances = np.linalg.norm(points[:, index_a] - points[:, index_b], axis=2)
    return distances / np.maximum(distances.max(axis=1, keepdims=True), 1e-9)


def photo_groups(frame, threshold: float) -> np.ndarray:
    """Beri nomor kelompok: satu foto beserta foto yang bentuknya nyaris sama."""
    labels = frame["label"].astype(str).to_numpy()
    photos = (frame["label"].astype(str) + "/" + frame["filename"].astype(str)).to_numpy()
    features = frame[FEATURE_COLUMNS].to_numpy(dtype=np.float32)

    parent = np.arange(len(frame))

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    first_seen: dict[str, int] = {}
    for index, photo in enumerate(photos):
        if photo in first_seen:
            parent[find(index)] = find(first_seen[photo])
        else:
            first_seen[photo] = index

    if threshold > 0:
        descriptor = shape_descriptor(features)
        for label in np.unique(labels):
            rows = np.flatnonzero(labels == label)
            block = descriptor[rows]
            squared = (block**2).sum(axis=1)
            gap = squared[:, None] + squared[None, :] - 2 * block @ block.T
            gap = np.sqrt(np.maximum(gap, 0.0) / block.shape[1])
            for a, b in zip(*np.where(np.triu(gap < threshold, k=1))):
                parent[find(rows[a])] = find(rows[b])

    roots = np.array([find(i) for i in range(len(frame))])
    return np.unique(roots, return_inverse=True)[1]


# --------------------------------------------------------------------------
# Penilaian
# --------------------------------------------------------------------------
def server_predict(model, features: np.ndarray) -> np.ndarray:
    """Tiru ``predict_variants`` di server: pilih kandidat paling yakin."""
    two_handed = features[:, -1] >= 0.5
    candidates = [features, mirror_x(features)]
    swapped = swap_hands(features)
    candidates += [swapped, mirror_x(swapped)]

    best = model.predict_proba(candidates[0])
    for position, candidate in enumerate(candidates[1:], start=1):
        probabilities = model.predict_proba(candidate)
        # Kandidat tangan ditukar hanya berlaku untuk sampel dua tangan.
        allowed = two_handed if position >= 2 else np.ones(len(features), dtype=bool)
        better = allowed & (probabilities.max(axis=1) > best.max(axis=1))
        best[better] = probabilities[better]
    return best.argmax(axis=1)


def aspect_scores(predict, features, target, aspects=EVAL_ASPECTS) -> dict[str, float]:
    return {
        aspect_name(aspect): float(accuracy_score(target, predict(stretch_aspect(features, aspect))))
        for aspect in aspects
    }


def _fit_and_score(c_value, gamma, copies, x_fit, y_fit, x_val, y_val, seed, aug, score_aspects):
    x_aug, y_aug = augment_dataset(x_fit, y_fit, copies, seed=seed, **aug)
    model = build_model(c_value=c_value, gamma=gamma, random_state=seed)
    model.set_params(svm__probability=False)
    model.fit(x_aug, y_aug)
    scores = aspect_scores(model.predict, x_val, y_val, score_aspects)
    return c_value, gamma, copies, scores


def search(x, y, groups, c_grid, gamma_grid, copies_grid, folds, seed, jobs, aug, score_aspects):
    """Validasi silang berkelompok. Skor = rata-rata akurasi pada rasio sasaran."""
    splitter = StratifiedGroupKFold(n_splits=folds, shuffle=True, random_state=seed)
    splits = list(splitter.split(x, y, groups))
    tasks = [
        delayed(_fit_and_score)(c, g, k, x[fit], y[fit], x[val], y[val], seed, aug, score_aspects)
        for k in copies_grid
        for c in c_grid
        for g in gamma_grid
        for fit, val in splits
    ]
    results = Parallel(n_jobs=jobs, verbose=5)(tasks)

    table: dict[tuple, list[dict]] = {}
    for c_value, gamma, copies, scores in results:
        table.setdefault((copies, c_value, gamma), []).append(scores)

    rows = []
    for (copies, c_value, gamma), fold_scores in table.items():
        per_aspect = {
            name: float(np.mean([fold[name] for fold in fold_scores]))
            for name in fold_scores[0]
        }
        rows.append(
            {
                "copies": copies,
                "C": c_value,
                "gamma": gamma,
                **per_aspect,
                "mean": float(np.mean(list(per_aspect.values()))),
            }
        )
    return sorted(rows, key=lambda row: -row["mean"])


def pick_best(rows: list[dict], tolerance: float = 0.003) -> dict:
    """Ambil yang terbaik; bila setara, pilih C terkecil (model lebih sederhana)."""
    top = rows[0]["mean"]
    close = [row for row in rows if top - row["mean"] <= tolerance]
    return sorted(close, key=lambda row: (row["C"], row["gamma"], row["copies"]))[0]


# --------------------------------------------------------------------------
# Alur utama
# --------------------------------------------------------------------------
def run(args: argparse.Namespace) -> dict:
    aug = {
        "aspects": tuple(args.aspects),
        "aspect_jitter": args.aspect_jitter,
        "include_original": not args.no_original,
        "point_noise": tuple(args.point_noise),
    }
    score_aspects = tuple(args.score_aspects)
    primary = aspect_name(args.primary_aspect)

    frame = read_frame(args.csv, clean=True)
    if args.drop_single_hand:
        # Huruf dua tangan yang hanya terdeteksi satu tangannya. Separuh huruf
        # itu mirip huruf lain (B satu tangan mirip E, P satu tangan mirip D),
        # sehingga baris seperti ini membuat model salah belajar.
        letters = [letter.upper() for letter in args.drop_single_hand]
        partial = frame["label"].astype(str).isin(letters) & (frame["is_two_handed"] < 0.5)
        print(f"      buang {int(partial.sum())} baris satu tangan dari huruf {''.join(letters)}")
        frame = frame.loc[~partial].reset_index(drop=True)
    features = frame[FEATURE_COLUMNS].to_numpy(dtype=np.float32)
    class_names = sorted(frame["label"].astype(str).unique())
    target = frame["label"].astype(str).map({name: i for i, name in enumerate(class_names)}).to_numpy()
    groups = photo_groups(frame, args.group_threshold)
    is_flip = frame["is_flip"].to_numpy().astype(bool)
    is_original = ~frame["filename"].astype(str).str.startswith("augmented").to_numpy()

    print(f"[1/5] {len(frame)} baris bersih, {len(np.unique(groups))} kelompok foto, {len(class_names)} kelas")

    outer = StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=args.seed)
    train_index, test_index = next(outer.split(features, target, groups))
    x_train, y_train, g_train = features[train_index], target[train_index], groups[train_index]
    # Uji memakai foto apa adanya (bukan versi cermin buatan), satu baris per foto.
    test_index = test_index[~is_flip[test_index]]
    x_test, y_test = features[test_index], target[test_index]
    print(f"      latih={len(train_index)} baris, uji={len(test_index)} foto")

    if args.C is not None and args.gamma is not None and args.copies is not None:
        chosen = {"C": args.C, "gamma": args.gamma, "copies": args.copies}
        table = []
        print(f"[2/5] Pencarian dilewati, memakai {chosen}")
    else:
        print("[2/5] Validasi silang berkelompok (ini bagian paling lama)")
        table = search(
            x_train, y_train, g_train,
            args.c_grid, args.gamma_grid, args.copies_grid,
            args.folds, args.seed, args.jobs, aug, score_aspects,
        )
        for row in table[:10]:
            print("      " + " ".join(f"{k}={v:.4f}" if isinstance(v, float) else f"{k}={v}" for k, v in row.items()))
        chosen = pick_best(table)
        print(f"      dipilih: {chosen}")

    print("[3/5] Melatih pada bagian latih dan menilai pada foto uji")
    x_aug, y_aug = augment_dataset(x_train, y_train, chosen["copies"], seed=args.seed, **aug)
    model = build_model(c_value=chosen["C"], gamma=chosen["gamma"], random_state=args.seed)
    started = time.perf_counter()
    model.fit(x_aug, y_aug)
    train_time = time.perf_counter() - started

    def predict(matrix):
        return server_predict(model, matrix)

    test_scores = aspect_scores(predict, x_test, y_test)
    train_rows = ~is_flip[train_index]
    train_scores = aspect_scores(predict, x_train[train_rows], y_train[train_rows])
    original_scores = aspect_scores(predict, x_test[is_original[test_index]], y_test[is_original[test_index]])

    phone_features = stretch_aspect(x_test, args.primary_aspect)
    phone_pred = predict(phone_features)
    square_pred = predict(x_test)
    report = classification_report(
        y_test, phone_pred, target_names=class_names, output_dict=True, zero_division=0
    )
    matrix = confusion_matrix(y_test, phone_pred)

    print(f"      latih : {train_scores}")
    print(f"      uji   : {test_scores}")
    print(f"      uji (foto asli saja): {original_scores}")

    baseline = None
    if args.baseline and Path(args.baseline).exists():
        old_model = joblib.load(args.baseline)
        baseline = aspect_scores(lambda m: server_predict(old_model, m), x_test, y_test)
        print(f"      model lama pada foto uji yang sama: {baseline}")

    print("[4/5] Melatih model akhir pada seluruh data")
    x_all, y_all = augment_dataset(features, target, chosen["copies"], seed=args.seed, **aug)
    final_model = build_model(c_value=chosen["C"], gamma=chosen["gamma"], random_state=args.seed)
    final_model.fit(x_all, y_all)

    print("[5/5] Menyimpan artefak")
    models_dir = Path(args.models_dir)
    models_dir.mkdir(parents=True, exist_ok=True)
    joblib.dump(final_model, models_dir / MODEL_FILENAME, compress=3)
    (models_dir / LABEL_MAP_FILENAME).write_text(
        json.dumps({"classes": class_names, "feature_count": FEATURE_COUNT}, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    pairs = [
        {"asli": class_names[a], "terbaca": class_names[b], "jumlah": int(matrix[a, b])}
        for a in range(len(class_names))
        for b in range(len(class_names))
        if a != b and matrix[a, b] > 0
    ]
    pairs.sort(key=lambda item: -item["jumlah"])

    metrics = {
        "algorithm": "SVM",
        "variant": "SVM RBF",
        "kernel": "rbf",
        "C": chosen["C"],
        "gamma": chosen["gamma"],
        "feature_count": FEATURE_COUNT,
        "class_count": len(class_names),
        "train_rows": int(len(x_all)),
        "test_rows": int(len(x_test)),
        "random_state": args.seed,
        # Angka utama: foto uji pada rasio frame kamera HP (16:9), dinilai seperti server.
        "accuracy": test_scores[primary],
        "primary_aspect": primary,
        "train_aspects": list(args.aspects),
        "aspect_jitter": args.aspect_jitter,
        "include_original_rows": not args.no_original,
        "f1_score": float(f1_score(y_test, phone_pred, average="weighted", zero_division=0)),
        "precision": float(report["weighted avg"]["precision"]),
        "recall": float(report["weighted avg"]["recall"]),
        "accuracy_by_aspect": test_scores,
        "train_accuracy_by_aspect": train_scores,
        "original_photo_accuracy_by_aspect": original_scores,
        "square_f1_score": float(f1_score(y_test, square_pred, average="weighted", zero_division=0)),
        "baseline_accuracy_by_aspect": baseline,
        "augmentation_copies": chosen["copies"],
        "search_table": table[:15],
        "train_time": float(train_time),
        "per_class_f1": {name: float(report[name]["f1-score"]) for name in class_names},
        "confusion_matrix": matrix.tolist(),
        "top_confusions": pairs[:15],
        "evaluation_protocol": (
            "Split per kelompok foto (foto, versi cermin, dan foto yang bentuk "
            "tangannya nyaris sama selalu di sisi yang sama). Akurasi dihitung "
            "pada foto uji yang tidak ikut latihan, dengan kandidat cermin dan "
            "tukar tangan seperti server. Model tersimpan dilatih ulang pada "
            "seluruh data dengan pengaturan yang sama."
        ),
        "dataset_warning": (
            "Data uji berasal dari sumber foto yang sama dengan data latih "
            "(orang dan latar yang sama), sehingga performa di kamera HP bisa "
            "lebih rendah daripada angka ini."
        ),
        "source_csv": str(args.csv),
        "dropped_single_hand_letters": list(args.drop_single_hand),
        "point_noise_levels": list(args.point_noise),
        "model_file": MODEL_FILENAME,
        "label_map_file": LABEL_MAP_FILENAME,
    }
    (models_dir / METRICS_FILENAME).write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"      model  -> {models_dir / MODEL_FILENAME}")
    return metrics


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Latih ulang SVM BISINDO dari CSV landmark foto.")
    parser.add_argument("--csv", required=True)
    parser.add_argument("--models-dir", default=str(DEFAULT_MODELS_DIR))
    parser.add_argument("--baseline", default=None, help="Model lama untuk dibandingkan.")
    parser.add_argument("--group-threshold", type=float, default=0.02)
    parser.add_argument("--c-grid", type=float, nargs="+", default=list(DEFAULT_C_GRID))
    parser.add_argument("--gamma-grid", type=float, nargs="+", default=list(DEFAULT_GAMMA_GRID))
    parser.add_argument("--copies-grid", type=int, nargs="+", default=[3])
    parser.add_argument("--aspects", type=float, nargs="+", default=[PHONE_ASPECT],
                        help="Rasio frame yang ditiru saat augmentasi.")
    parser.add_argument("--aspect-jitter", type=float, default=0.12)
    parser.add_argument("--no-original", action="store_true",
                        help="Buang baris asli (rasio persegi) dari data latih.")
    parser.add_argument("--score-aspects", type=float, nargs="+", default=[1.6, PHONE_ASPECT, 2.0],
                        help="Rasio yang dipakai menilai saat memilih pengaturan.")
    parser.add_argument("--primary-aspect", type=float, default=PHONE_ASPECT)
    parser.add_argument("--point-noise", type=float, nargs="+", default=[0.015],
                        help="Tingkat goyangan titik per salinan augmentasi, mis. 0.015 0.035 0.06.")
    parser.add_argument("--drop-single-hand", nargs="+", default=[],
                        help="Huruf dua tangan yang baris satu-tangannya dibuang, mis. B P.")
    parser.add_argument("--C", type=float, default=None)
    parser.add_argument("--gamma", type=float, default=None)
    parser.add_argument("--copies", type=int, default=None)
    parser.add_argument("--folds", type=int, default=3)
    parser.add_argument("--jobs", type=int, default=-1)
    parser.add_argument("--seed", type=int, default=42)
    return parser.parse_args(argv)


if __name__ == "__main__":
    run(parse_args())
