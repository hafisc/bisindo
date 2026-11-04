import logging
from pathlib import Path
from flask import current_app
import numpy as np

logger = logging.getLogger(__name__)

# Daftar label kelas alfabet BISINDO (Index 0 = A, ..., 25 = Z)
CLASSES = [chr(i) for i in range(ord("A"), ord("Z") + 1)]

_model = None


def get_model():
    """Memuat model Keras/TensorFlow sesuai konfigurasi saat pertama kali dipanggil."""
    global _model
    if _model is not None:
        return _model

    model_path_str = current_app.config.get("MODEL_PATH")
    if not model_path_str:
        logger.warning("[API] MODEL_PATH belum dikonfigurasi.")
        return None

    model_path = Path(model_path_str)
    if not model_path.exists():
        logger.warning(f"[API] File model tidak ditemukan di: {model_path}")
        return None

    try:
        import tensorflow as tf

        logger.info(f"[API] Memuat model BISINDO dari: {model_path}")
        _model = tf.keras.models.load_model(str(model_path))
        logger.info(f"[API] Model BISINDO berhasil dimuat. Expected input shape: {_model.input_shape}")
        return _model
    except Exception as e:
        logger.error(f"[API] Gagal memuat model Keras: {e}")
        return None


def preprocess_landmarks(data):
    """
    Memvalidasi dan memproses data landmark menjadi array NumPy siap inferensi.
    Mendukung format:
    1. 21 titik (1 tangan) -> 63 fitur
    2. 42 titik (2 tangan: 63 kiri + 63 kanan) -> 126 fitur (disesuaikan dengan arsitektur model)
    3. Flat list: 63 atau 126 floats
    """
    if data is None:
        raise ValueError("Payload tidak boleh kosong.")

    # Jika payload dibungkus dalam key "landmarks" atau "points"
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

    # Deteksi format input
    points = []

    # Kasus 1: Flat list (63 atau 126 floats)
    if len(data) in (63, 126) and all(isinstance(v, (int, float)) for v in data):
        # Ambil per 3 koordinat [x, y, z]
        points = [[data[i], data[i + 1], data[i + 2]] for i in range(0, len(data), 3)]

    # Kasus 2: List of points (21 titik untuk 1 tangan, atau 42 titik untuk 2 tangan)
    elif len(data) in (21, 42):
        for idx, pt in enumerate(data):
            if isinstance(pt, dict):
                if "x" not in pt or "y" not in pt:
                    raise ValueError(
                        f"Titik ke-{idx} tidak memiliki koordinat 'x' atau 'y'."
                    )
                x = float(pt["x"])
                y = float(pt["y"])
                z = float(pt.get("z", 0.0))
                points.append([x, y, z])
            elif isinstance(pt, (list, tuple)):
                if len(pt) >= 3:
                    points.append([float(pt[0]), float(pt[1]), float(pt[2])])
                elif len(pt) == 2:
                    points.append([float(pt[0]), float(pt[1]), 0.0])
                else:
                    raise ValueError(
                        f"Titik ke-{idx} memiliki dimensi tidak valid: {pt}"
                    )
            else:
                raise ValueError(
                    f"Elemen ke-{idx} bukan format koordinat yang valid (dict/list)."
                )
    else:
        raise ValueError(
            f"Jumlah titik tidak sesuai: menerima {len(data)} elemen. "
            "Diharapkan 21 titik (1 tangan) / 42 titik (2 tangan), atau flat array 63 / 126 float."
        )

    # Cek input shape yang diharapkan oleh model yang terpasang
    model = get_model()
    expected_dim = 63
    if model is not None and len(model.input_shape) >= 2 and model.input_shape[1] is not None:
        expected_dim = model.input_shape[1]

    # Jika model mengharapkan 63 fitur (1 tangan), tetapi input memberi 42 titik / 126 nilai (2 tangan):
    # Gunakan 21 titik tangan pertama (Hand 1)
    if expected_dim == 63 and len(points) == 42:
        points = points[:21]

    points_arr = np.array(points, dtype=np.float32)  # Shape: (21, 3) atau (42, 3)

    # Normalisasi translasi relatif terhadap wrist tangan pertama (titik 0)
    wrist = points_arr[0].copy()
    if not np.allclose(wrist, 0.0):
        points_arr = points_arr - wrist

    features = points_arr.flatten().reshape(1, -1)
    return features


def predict_landmarks(features):
    """
    Menjalankan inferensi model terhadap matriks fitur.
    Mengembalikan (dict_result, None) atau (None, error_message).
    """
    model = get_model()
    if model is None:
        return None, "Model machine learning belum tersedia di server. Pastikan bisindo_mlp_best.h5 ada."

    try:
        predictions = model.predict(features, verbose=0)
        probabilities = predictions[0]

        predicted_idx = int(np.argmax(probabilities))
        confidence = float(probabilities[predicted_idx])
        predicted_letter = CLASSES[predicted_idx]

        return {
            "prediction": predicted_letter,
            "confidence": round(confidence, 4),
            "class_index": predicted_idx,
        }, None
    except Exception as e:
        return None, f"Gagal menjalankan inferensi model: {str(e)}"
