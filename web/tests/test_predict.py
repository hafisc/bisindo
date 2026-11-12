import pytest
from app import create_app
from app.extensions import db
from app.models import DetectionLog


@pytest.fixture()
def app(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
            "SECRET_KEY": "test-secret",
        }
    )
    yield app
    with app.app_context():
        db.session.remove()
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


def test_api_status(client):
    """Memastikan endpoint /api/status dapat diakses."""
    res = client.get("/api/status")
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "online"
    assert "service" in data


def test_predict_with_dict_landmarks(client, app):
    """Memastikan POST /api/predict bekerja dengan 21 titik dict dan menyimpan DetectionLog."""
    landmarks = [{"x": float(i * 0.01), "y": float(i * 0.02), "z": 0.0} for i in range(21)]
    payload = {"landmarks": landmarks}

    res = client.post("/api/predict", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert "prediction" in data
    assert "confidence" in data
    assert "class_index" in data
    assert isinstance(data["prediction"], str)
    assert 0.0 <= data["confidence"] <= 1.0

    # Pastikan riwayat tersimpan di database DetectionLog
    with app.app_context():
        log = db.session.query(DetectionLog).first()
        assert log is not None
        assert log.letter == data["prediction"]


def test_predict_with_list_landmarks(client):
    """Memastikan POST /api/predict bekerja dengan array 21 titik [[x, y, z], ...]."""
    landmarks = [[float(i * 0.01), float(i * 0.02), 0.0] for i in range(21)]
    payload = {"landmarks": landmarks}

    res = client.post("/api/predict", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert "prediction" in data
    assert "confidence" in data


def test_predict_with_flat_array(client):
    """Memastikan POST /api/predict bekerja dengan flat array 63 angka."""
    landmarks = [float(i * 0.01) for i in range(63)]
    payload = {"landmarks": landmarks}

    res = client.post("/api/predict", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert "prediction" in data


def test_predict_with_two_hands_42_points(client):
    """Memastikan POST /api/predict mendukung 2 tangan (42 titik / 126 nilai)."""
    # 42 titik (21 kiri + 21 kanan)
    landmarks = [{"x": float(i * 0.01), "y": float(i * 0.02), "z": 0.0} for i in range(42)]
    payload = {"landmarks": landmarks}

    res = client.post("/api/predict", json=payload)
    assert res.status_code == 200
    data = res.get_json()
    assert "prediction" in data
    assert "confidence" in data


def test_predict_missing_json(client):
    """Memastikan request tanpa body json mengembalikan HTTP 400."""
    res = client.post("/api/predict", data="bukan json", content_type="text/plain")
    assert res.status_code == 400
    assert "error" in res.get_json()


def test_predict_invalid_point_count(client):
    """Memastikan input kurang dari 21 titik ditolak dengan HTTP 400."""
    landmarks = [{"x": 0.1, "y": 0.2, "z": 0.0} for _ in range(10)]
    payload = {"landmarks": landmarks}

    res = client.post("/api/predict", json=payload)
    assert res.status_code == 400
    assert "error" in res.get_json()


# ── Kontrak fitur 127 ────────────────────────────────────────────────────────


def test_preprocess_satu_tangan_mengisi_tangan_dua_dengan_nol():
    """Satu tangan harus menghasilkan 127 fitur dengan blok tangan 2 bernilai nol."""
    from app.api.services import preprocess_landmarks

    points = [[float(i * 0.01), float(i * 0.02), 0.0] for i in range(21)]
    features = preprocess_landmarks({"landmarks": points})

    assert features.shape == (1, 127)
    assert features.dtype.name == "float32"

    # Blok tangan 2 (kolom 63 sampai 125) harus nol seluruhnya.
    assert not features[0, 63:126].any()

    # Fitur terakhir menandai satu tangan.
    assert features[0, 126] == 0.0


def test_preprocess_dua_tangan_mengisi_seluruh_127_fitur():
    """Dua tangan harus mengisi blok tangan 2 dan menandai is_two_handed."""
    from app.api.services import preprocess_landmarks

    points = [[float(i * 0.01), float(i * 0.02), 0.0] for i in range(42)]
    features = preprocess_landmarks({"landmarks": points})

    assert features.shape == (1, 127)
    assert features[0, 126] == 1.0

    # Tangan 2 tidak boleh seluruhnya nol karena titiknya berbeda dari tangan 1.
    assert features[0, 63:126].any()


def test_preprocess_menormalkan_terhadap_pergelangan_tangan_satu():
    """Titik pergelangan tangan 1 harus menjadi (0, 0, 0) setelah normalisasi."""
    from app.api.services import preprocess_landmarks

    points = [[float(i * 0.01), float(i * 0.02), 0.0] for i in range(42)]
    features = preprocess_landmarks({"landmarks": points})

    assert features[0, 0] == pytest.approx(0.0, abs=1e-6)
    assert features[0, 1] == pytest.approx(0.0, abs=1e-6)
    assert features[0, 2] == pytest.approx(0.0, abs=1e-6)


def test_preprocess_menerima_vektor_127_langsung():
    """Vektor fitur lengkap 127 angka harus diteruskan tanpa diubah."""
    from app.api.services import preprocess_landmarks

    values = [float(i) / 100.0 for i in range(127)]
    features = preprocess_landmarks({"landmarks": values})

    assert features.shape == (1, 127)
    assert features[0, 126] == pytest.approx(1.26, abs=1e-6)


def test_preprocess_menolak_jumlah_nilai_aneh(client):
    """Flat array dengan jumlah nilai tidak dikenal harus ditolak."""
    res = client.post("/api/predict", json={"landmarks": [0.5] * 100})

    assert res.status_code == 400
    assert "error" in res.get_json()


# ── Endpoint informasi model ─────────────────────────────────────────────────


def test_api_model_mengembalikan_info_model(client):
    """GET /api/model harus melaporkan model aktif, fitur, dan kelas."""
    res = client.get("/api/model")

    assert res.status_code == 200
    data = res.get_json()
    assert data["loaded"] is True
    assert data["feature_count"] == 127
    assert data["class_count"] == 26
    assert data["classes"] == [chr(code) for code in range(ord("A"), ord("Z") + 1)]
    assert data["kernel"] == "rbf"
    assert 0.0 <= data["accuracy"] <= 1.0


def test_api_status_melaporkan_model_siap(client):
    """GET /api/status harus menandai model sudah termuat."""
    res = client.get("/api/status")
    data = res.get_json()

    assert data["model_loaded"] is True
    assert data["feature_count"] == 127
    assert data["class_count"] == 26
