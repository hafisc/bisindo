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
