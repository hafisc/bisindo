from flask import jsonify, request

from ..extensions import db
from ..models import DetectionLog
from . import bp
from .identity import resolve_user_id
from .services import (
    FEATURE_COUNT,
    get_classes,
    get_model,
    get_model_info,
    predict_landmarks,
    preprocess_landmarks,
)


@bp.get("/status")
def status():
    """Cek status layanan API prediksi."""
    model = get_model()
    return jsonify({
        "status": "online",
        "service": "BISINDO Sign Language Prediction API",
        "model_loaded": model is not None,
        "feature_count": FEATURE_COUNT,
        "class_count": len(get_classes()),
    })


@bp.get("/model")
def model_info():
    """Informasi model aktif, dipakai mobile untuk cek kompatibilitas.

    Berisi jumlah fitur, daftar kelas, dan akurasi model. Aplikasi bisa
    membandingkan ``feature_count`` dengan yang dikirimnya sebelum memanggil
    ``/api/predict``, sehingga kesalahan format terdeteksi lebih awal.
    """
    info = get_model_info()
    return jsonify(info), 200 if info.get("loaded") else 503


@bp.post("/predict")
def predict():
    """
    Endpoint utama prediksi huruf BISINDO dari landmark tangan.

    Menerima 21 titik (satu tangan) atau 42 titik (dua tangan), dalam bentuk
    list koordinat, dict ``{x, y, z}``, maupun flat array 63/126 nilai.
    Mengembalikan prediksi huruf dan confidence score.
    """
    if not request.is_json:
        return jsonify({"error": "Request Content-Type harus application/json."}), 400

    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify({"error": "JSON body tidak valid atau kosong."}), 400

    try:
        features = preprocess_landmarks(payload)
    except ValueError as val_err:
        return jsonify({"error": f"Validasi data landmark gagal: {str(val_err)}"}), 400
    except Exception as e:
        return jsonify({"error": f"Terjadi kesalahan saat memproses data: {str(e)}"}), 400

    result, err = predict_landmarks(features)
    if err:
        return jsonify({"error": err}), 503

    # Simpan hasil deteksi ke riwayat database (DetectionLog)
    # Ini otomatis memberi makan dashboard admin tim
    try:
        # Mobile mengirim Firebase UID, bukan primary key. Helper ini
        # menerjemahkannya supaya log terhubung ke profil yang benar.
        raw_user = payload.get("user_id") if isinstance(payload, dict) else None
        log = DetectionLog(
            user_id=resolve_user_id(raw_user),
            letter=result["prediction"],
            confidence=result["confidence"],
        )
        db.session.add(log)
        db.session.commit()
    except Exception:
        db.session.rollback()

    return jsonify(result), 200

