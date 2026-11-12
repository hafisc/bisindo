"""Layanan inferensi model SVM BISINDO.

Model dimuat dari artefak joblib hasil ``ml/src/training/train_svm.py``.
Artefak berisi ``Pipeline(StandardScaler, SVC)``, sehingga data mentah tidak
perlu distandardisasi manual di sini: scaler ikut tersimpan bersama model.

Kontrak fitur: 127 nilai, dengan urutan
- 0 sampai 62   : 21 titik tangan 1 (x, y, z per titik)
- 63 sampai 125 : 21 titik tangan 2 (x, y, z per titik)
- 126           : ``is_two_handed`` (1 atau 0)

Seluruh koordinat sudah dinormalkan terhadap pergelangan tangan 1 dan dibagi
dengan jarak pergelangan ke titik 9 tangan 1 (pangkal jari tengah), sehingga
jarak tersebut selalu 1. Bila hanya satu tangan terdeteksi, 63 nilai tangan 2
diisi nol.

Dua normalisasi itu wajib. Landmark mentah MediaPipe memakai koordinat gambar
0-1, sedangkan dataset latih memakai satuan panjang tangan. Tanpa pembagian
skala, akurasi pada data yang diperkecil 0,1 kali jatuh ke 3,69% (lihat
``web/tests/test_predict.py``).
"""

import json
import logging
from pathlib import Path

import joblib
import numpy as np
from flask import current_app

logger = logging.getLogger(__name__)

# Daftar label kelas alfabet BISINDO (Index 0 = A, ..., 25 = Z).
CLASSES = [chr(i) for i in range(ord("A"), ord("Z") + 1)]

POINT_COUNT = 21
AXES = 3
HAND_FEATURES = POINT_COUNT * AXES  # 63
FEATURE_COUNT = HAND_FEATURES * 2 + 1  # 127

_model = None
_classes = None
_model_info = {}


def _model_path() -> Path | None:
    model_path_str = current_app.config.get("MODEL_PATH")
    if not model_path_str:
        logger.warning("[API] MODEL_PATH belum dikonfigurasi.")
        return None
    return Path(model_path_str)


def _load_classes(model_path: Path, model) -> list[str]:
    """Ambil urutan kelas dari label_map.json, dengan cadangan dari model."""
    label_map_path = model_path.parent / "label_map.json"

    if label_map_path.exists():
        try:
            data = json.loads(label_map_path.read_text(encoding="utf-8"))
            classes = [str(name) for name in data["classes"]]
            if classes:
                return classes
        except Exception as error:  # pragma: no cover - jalur jarang
            logger.warning(f"[API] label_map.json tidak terbaca: {error}")

    # Pipeline menyimpan kelas pada langkah terakhir.
    try:
        estimator = model.steps[-1][1]
        classes = list(estimator.classes_)
    except Exception:  # pragma: no cover - jalur jarang
        return list(CLASSES)

    if not classes:
        return list(CLASSES)

    # LabelEncoder menghasilkan 0..25, bukan huruf. Tanpa pemetaan ini server
    # akan membalas angka padahal aplikasi mobile mengharapkan huruf.
    if all(isinstance(item, (int, np.integer)) for item in classes):
        return [
            CLASSES[int(item)] if 0 <= int(item) < len(CLASSES) else str(item)
            for item in classes
        ]

    return [str(item) for item in classes]


def _load_metrics(model_path: Path) -> dict:
    """Baca metrics.json di samping model, bila ada."""
    metrics_path = model_path.parent / "metrics.json"
    if not metrics_path.exists():
        return {}
    try:
        return json.loads(metrics_path.read_text(encoding="utf-8"))
    except Exception as error:  # pragma: no cover - jalur jarang
        logger.warning(f"[API] metrics.json tidak terbaca: {error}")
        return {}


def get_model():
    """Memuat model SVM dari artefak joblib saat pertama kali dipanggil."""
    global _model, _classes, _model_info

    if _model is not None:
        return _model

    model_path = _model_path()
    if model_path is None:
        return None

    if not model_path.exists():
        logger.warning(f"[API] File model tidak ditemukan di: {model_path}")
        return None

    try:
        logger.info(f"[API] Memuat model BISINDO dari: {model_path}")
        model = joblib.load(model_path)

        _model = model
        _classes = _load_classes(model_path, model)

        metrics = _load_metrics(model_path)
        _model_info = {
            "model_file": model_path.name,
            "algorithm": metrics.get("algorithm", "SVM"),
            "variant": metrics.get("variant"),
            "kernel": metrics.get("kernel"),
            "accuracy": metrics.get("accuracy"),
            "f1_score": metrics.get("f1_score"),
            "feature_count": int(getattr(model, "n_features_in_", FEATURE_COUNT)),
            "class_count": len(_classes),
            "trained_at": _last_modified(model_path),
            "dataset_warning": metrics.get("dataset_warning"),
        }

        logger.info(
            "[API] Model BISINDO dimuat. Fitur: %s, kelas: %s, akurasi: %s",
            _model_info["feature_count"],
            _model_info["class_count"],
            _model_info["accuracy"],
        )
        return _model
    except Exception as error:
        logger.error(f"[API] Gagal memuat model joblib: {error}")
        return None


def _last_modified(path: Path) -> str | None:
    try:
        from datetime import datetime, timezone

        stamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
        return stamp.isoformat(timespec="seconds")
    except Exception:  # pragma: no cover - jalur jarang
        return None


def get_model_info() -> dict:
    """Ringkasan model aktif, dipakai endpoint ``GET /api/model``.

    Aplikasi mobile bisa memakai ini untuk memastikan jumlah fitur dan
    daftar kelas masih cocok sebelum mengirim data.
    """
    model = get_model()
    if model is None:
        return {"loaded": False}

    info = dict(_model_info)
    info["loaded"] = True
    info["classes"] = list(_classes or CLASSES)
    return info


def get_classes() -> list[str]:
    """Daftar kelas sesuai urutan keluaran model."""
    get_model()
    return list(_classes or CLASSES)


def reload_model() -> bool:
    """Buang model dari cache lalu muat ulang.

    Dipanggil setelah admin mengaktifkan versi model lain. Tanpa ini, server
    tetap memakai model lama sampai proses dijalankan ulang.
    """
    global _model, _classes, _model_info

    _model = None
    _classes = None
    _model_info = {}

    return get_model() is not None


def _expected_feature_count() -> int:
    model = get_model()
    if model is None:
        return FEATURE_COUNT
    return int(getattr(model, "n_features_in_", FEATURE_COUNT))


def _parse_points(data) -> list[list[float]]:
    """Ubah list titik menjadi ``[[x, y, z], ...]``."""
    points = []
    for index, point in enumerate(data):
        if isinstance(point, dict):
            if "x" not in point or "y" not in point:
                raise ValueError(
                    f"Titik ke-{index} tidak memiliki koordinat 'x' atau 'y'."
                )
            points.append(
                [float(point["x"]), float(point["y"]), float(point.get("z", 0.0))]
            )
        elif isinstance(point, (list, tuple)):
            if len(point) >= 3:
                points.append([float(point[0]), float(point[1]), float(point[2])])
            elif len(point) == 2:
                points.append([float(point[0]), float(point[1]), 0.0])
            else:
                raise ValueError(f"Titik ke-{index} memiliki dimensi tidak valid: {point}")
        else:
            raise ValueError(
                f"Elemen ke-{index} bukan format koordinat yang valid (dict/list)."
            )
    return points


def _landmark_input(data):
    """Baca payload menjadi ``(points_array, features_lengkap)``.

    Salah satu hasil selalu ``None``. ``features_lengkap`` terisi bila payload
    sudah berupa vektor fitur 127 kolom yang siap dipakai model.
    """
    if data is None:
        raise ValueError("Payload tidak boleh kosong.")

    # Payload boleh dibungkus dalam key "landmarks" atau "points".
    if isinstance(data, dict):
        if "landmarks" in data:
            data = data["landmarks"]
        elif "points" in data:
            data = data["points"]
        else:
            raise ValueError(
                "JSON harus memiliki key 'landmarks' atau langsung berupa array titik landmark."
            )

    if not isinstance(data, (list, tuple)):
        raise ValueError("Data landmark harus berupa list / array.")

    is_flat = all(isinstance(value, (int, float)) for value in data)

    if is_flat:
        values = [float(value) for value in data]

        # Vektor fitur lengkap, sudah termasuk is_two_handed.
        if len(values) == FEATURE_COUNT:
            features = np.asarray(values, dtype=np.float32).reshape(1, -1)
            expected = _expected_feature_count()
            if features.shape[1] != expected:
                raise ValueError(
                    f"Jumlah fitur tidak sesuai: {features.shape[1]}, "
                    f"model membutuhkan {expected}."
                )
            return None, features

        if len(values) == HAND_FEATURES:
            points = [values[i : i + 3] for i in range(0, HAND_FEATURES, 3)]
        elif len(values) == HAND_FEATURES * 2:
            points = [values[i : i + 3] for i in range(0, HAND_FEATURES * 2, 3)]
        else:
            raise ValueError(
                f"Jumlah nilai tidak sesuai: menerima {len(values)} angka. "
                "Diharapkan 63 (satu tangan), 126 (dua tangan), atau 127 (fitur lengkap)."
            )
    else:
        points = _parse_points(data)

    if len(points) not in (POINT_COUNT, POINT_COUNT * 2):
        raise ValueError(
            f"Jumlah titik tidak sesuai: menerima {len(points)} titik. "
            "Diharapkan 21 titik (satu tangan) atau 42 titik (dua tangan)."
        )

    return np.asarray(points, dtype=np.float32), None


def _normalized_features(points_array, reference_index):
    """Bentuk 127 fitur dengan tangan ke-``reference_index`` sebagai acuan.

    ``reference_index`` 0 berarti tangan pertama, 21 berarti tangan kedua.
    Dataset latih mengurangi posisi pergelangan tangan acuan dari semua titik,
    lalu membagi dengan jarak pergelangan ke titik 9 tangan acuan (pangkal jari
    tengah). Kedua langkah itu wajib agar landmark mentah MediaPipe, yang masih
    memakai satuan gambar 0-1, cocok dengan data latih.
    """
    reference = points_array[reference_index]
    shifted = points_array - reference
    two_handed = len(points_array) > POINT_COUNT

    if reference_index == 0:
        hand1 = shifted[:POINT_COUNT]
        if two_handed:
            hand2 = shifted[POINT_COUNT:]
        else:
            # Satu tangan: tangan 2 diisi nol, sama seperti di dataset latih.
            hand2 = np.zeros((POINT_COUNT, AXES), dtype=np.float32)
    else:
        hand1 = shifted[POINT_COUNT:]
        hand2 = shifted[:POINT_COUNT]

    scale = float(np.linalg.norm(hand1[9]))
    if not np.isfinite(scale) or scale < 1e-6:
        raise ValueError(
            "Landmark tangan terlalu kecil untuk diproses. Pastikan tangan "
            "terlihat jelas oleh kamera."
        )

    hand1 = hand1 / scale
    hand2 = hand2 / scale

    return np.concatenate(
        [
            hand1.ravel(),
            hand2.ravel(),
            np.array([1.0 if two_handed else 0.0], dtype=np.float32),
        ]
    ).astype(np.float32).reshape(1, -1)


def _mirror_x(matrix):
    """Cerminkan sumbu x pada matriks fitur 127 kolom.

    Kolom x berada di indeks 0, 3, 6, dan seterusnya. Kolom ``is_two_handed``
    di indeks 126 tidak ikut diubah.
    """
    mirrored = np.array(matrix, dtype=np.float32, copy=True)
    mirrored[:, : HAND_FEATURES * 2 : 3] *= -1
    return mirrored


def preprocess_landmarks_variants(data):
    """Ubah payload menjadi daftar kandidat fitur beserta keterangannya.

    Setiap kandidat berupa ``(matriks_fitur, urutan_tangan, dicerminkan)``.

    Ada dua sumbu ketidakpastian yang tidak bisa diketahui server:

    1. **Urutan tangan.** MediaPipe mengembalikan tangan sesuai urutan deteksi,
       sedangkan dataset latih selalu menaruh tangan pertama di kolom awal.
       Kandidat ``as_is`` dan ``swapped`` menutup kemungkinan ini.
    2. **Pencerminan.** Kamera depan dan konvensi koordinat berbeda-beda antar
       perangkat. Dataset yang dicerminkan hanya dikenali 51,34% bila kandidat
       cermin tidak disediakan, dan 98,10% bila disediakan.

    Keduanya harus dinormalkan sendiri-sendiri, karena pergelangan dan skala
    acuannya berbeda. Menukar blok fitur setelah normalisasi tidak cukup:
    hasilnya bukan kebalikan yang benar.
    """
    points_array, full_features = _landmark_input(data)

    if full_features is not None:
        variants = [(full_features, "as_is", False)]
        if full_features.shape[1] == FEATURE_COUNT and float(full_features[0, -1]) == 1.0:
            variants.append((swap_hands(full_features), "swapped", False))
        return variants + [
            (_mirror_x(candidate), order, True) for candidate, order, _ in variants
        ]

    two_handed = points_array.shape[0] == POINT_COUNT * 2

    def build(points):
        candidates = [(_normalized_features(points, 0), "as_is", False)]
        if two_handed:
            candidates.append((_normalized_features(points, POINT_COUNT), "swapped", False))
        return candidates

    variants = build(points_array)

    # Cermin dihitung dari landmark mentah: membalik tanda x sebelum atau
    # sesudah normalisasi memberi hasil yang sama, karena normalisasi hanya
    # menggeser dan membagi dengan bilangan positif.
    mirrored_points = points_array.copy()
    mirrored_points[:, 0] *= -1
    variants += [(features, order, True) for features, order, _ in build(mirrored_points)]

    return variants


def preprocess_landmarks(data):
    """Ubah payload landmark menjadi matriks fitur 127 kolom.

    Format yang diterima:
    1. 21 titik (satu tangan), dict ``{x, y, z}`` atau list ``[x, y, z]``
    2. 42 titik (dua tangan)
    3. Flat list 63 nilai (satu tangan), 126 nilai (dua tangan),
       atau 127 nilai (vektor fitur lengkap)
    """
    return preprocess_landmarks_variants(data)[0][0]


def swap_hands(matrix):
    """Tukar blok fitur tangan 1 dan tangan 2 pada matriks fitur.

    Dataset latih selalu menyimpan tangan pertama di kolom 0-62 dan tangan
    kedua di kolom 63-125. MediaPipe di aplikasi mobile mengembalikan tangan
    sesuai urutan deteksi, yang bisa terbalik. Fungsi ini membuat versi
    alternatif dari vektor fitur untuk diuji ulang oleh model.
    """
    swapped = np.array(matrix, dtype=np.float32, copy=True)
    swapped[:, :HAND_FEATURES] = matrix[:, HAND_FEATURES : HAND_FEATURES * 2]
    swapped[:, HAND_FEATURES : HAND_FEATURES * 2] = matrix[:, :HAND_FEATURES]
    return swapped


def predict_variants(variants):
    """Jalankan model pada beberapa kandidat fitur, pilih yang paling yakin.

    ``variants`` berisi ``(matriks_fitur, urutan_tangan, dicerminkan)``. Setiap
    kandidat dihitung probabilitasnya, lalu hasil dengan confidence tertinggi
    yang dipakai. Bila nilainya sama, kandidat yang lebih dulu menang, sehingga
    orientasi asli selalu dipilih saat semuanya setara.

    Mengembalikan ``(dict_result, None)`` saat berhasil, atau
    ``(None, error_message)`` saat gagal.
    """
    model = get_model()
    if model is None:
        return (
            None,
            "Model machine learning belum tersedia di server. "
            "Pastikan svm_rbf_bisindo.joblib ada di folder ml/models.",
        )

    try:
        best_probabilities = None
        best_order = "as_is"
        best_mirrored = False

        for candidate, hand_order, mirrored in variants:
            matrix = np.asarray(candidate, dtype=np.float32)
            if matrix.ndim == 1:
                matrix = matrix.reshape(1, -1)

            expected = _expected_feature_count()
            if matrix.shape[1] != expected:
                raise ValueError(
                    f"Jumlah fitur tidak sesuai: {matrix.shape[1]}, "
                    f"model membutuhkan {expected}."
                )

            probabilities = model.predict_proba(matrix)[0]
            if best_probabilities is None or float(probabilities.max()) > float(
                best_probabilities.max()
            ):
                best_probabilities = probabilities
                best_order = hand_order
                best_mirrored = bool(mirrored)

        predicted_idx = int(np.argmax(best_probabilities))
        confidence = float(best_probabilities[predicted_idx])

        classes = get_classes()
        predicted_letter = (
            classes[predicted_idx]
            if predicted_idx < len(classes)
            else CLASSES[predicted_idx]
        )

        return {
            "prediction": predicted_letter,
            "confidence": round(confidence, 4),
            "class_index": predicted_idx,
            "hand_order": best_order,
            "mirrored": best_mirrored,
        }, None
    except Exception as error:
        return None, f"Gagal menjalankan inferensi model: {str(error)}"


def predict_landmarks(features):
    """Jalankan inferensi model terhadap matriks fitur yang sudah jadi.

    Untuk sampel dua tangan, model diuji pada dua kemungkinan urutan tangan,
    masing-masing dengan versi cermin, lalu dipilih hasil dengan confidence
    tertinggi. Bila yang dikirim adalah landmark mentah, gunakan
    :func:`predict_variants` dengan hasil :func:`preprocess_landmarks_variants`,
    karena normalisasi harus diulang untuk masing-masing urutan.
    """
    matrix = np.asarray(features, dtype=np.float32)
    if matrix.ndim == 1:
        matrix = matrix.reshape(1, -1)

    variants = [(matrix, "as_is", False)]

    # Hanya sampel dua tangan yang punya masalah urutan. Sampel satu tangan
    # tidak perlu diuji ulang karena tangan kedua berisi nol.
    is_two_handed = (
        matrix.shape[1] == FEATURE_COUNT and float(matrix[0, -1]) == 1.0
    )
    if is_two_handed:
        variants.append((swap_hands(matrix), "swapped", False))

    variants += [
        (_mirror_x(candidate), order, True) for candidate, order, _ in list(variants)
    ]

    return predict_variants(variants)

