"""Test halaman admin untuk unggah dan pengelolaan versi model."""

import io
import json
import secrets
from pathlib import Path

import joblib
import numpy as np
import pytest
from sklearn.svm import SVC

from app import create_app
from app.api import services
from app.extensions import db
from app.models import ModelVersion

REPO_ROOT = Path(__file__).resolve().parents[2]
ARTIFACT_DIR = REPO_ROOT / "ml" / "models"
MODEL_ARTIFACT = ARTIFACT_DIR / "svm_rbf_bisindo.joblib"

# Kredensial admin khusus test, dibuat acak saat modul dimuat supaya tidak ada
# kata sandi yang tertulis di berkas.
ADMIN_USERNAME = "admin-uji"
ADMIN_PASSWORD = secrets.token_hex(16)


@pytest.fixture()
def config(tmp_path):
    return {
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
        "SECRET_KEY": "test-secret",
        "ADMIN_USERNAME": ADMIN_USERNAME,
        "ADMIN_PASSWORD": ADMIN_PASSWORD,
        "DATASET_DIR": (tmp_path / "datasets").as_posix(),
        "MODEL_UPLOAD_DIR": (tmp_path / "models").as_posix(),
    }


@pytest.fixture()
def app(config):
    application = create_app(dict(config))
    yield application
    with application.app_context():
        db.session.remove()
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


@pytest.fixture(autouse=True)
def reset_services():
    """Kembalikan cache model ke kondisi awal supaya test tidak saling bocor."""
    yield
    services._model = None
    services._classes = None
    services._model_info = {}


def _csrf(client, path="/admin/login"):
    client.get(path)
    with client.session_transaction() as sess:
        return sess["_csrf"]


def login(client):
    token = _csrf(client)
    return client.post(
        "/admin/login",
        data={"username": ADMIN_USERNAME, "password": ADMIN_PASSWORD, "csrf_token": token},
    )


def model_bytes(model) -> bytes:
    buffer = io.BytesIO()
    joblib.dump(model, buffer)
    return buffer.getvalue()


def upload_model(
    client,
    content,
    filename="model.joblib",
    label=None,
    note=None,
    label_map=None,
    metrics=None,
):
    token = _csrf(client, "/admin/model")
    data = {
        "model_file": (io.BytesIO(content), filename),
        "label": label or "",
        "note": note or "",
        "csrf_token": token,
    }
    if label_map is not None:
        data["label_map"] = (io.BytesIO(json.dumps(label_map).encode()), "label_map.json")
    if metrics is not None:
        data["metrics"] = (io.BytesIO(json.dumps(metrics).encode()), "metrics.json")

    return client.post(
        "/admin/model/upload",
        data=data,
        content_type="multipart/form-data",
        follow_redirects=True,
    )


# ── Akses ─────────────────────────────────────────────────────────


def test_halaman_model_butuh_login(client):
    response = client.get("/admin/model")
    assert response.status_code == 302
    assert "/admin/login" in response.headers["Location"]


def test_unggah_model_butuh_login(client):
    response = client.post("/admin/model/upload", data={})
    assert response.status_code == 302
    assert "/admin/login" in response.headers["Location"]


def test_halaman_model_kosong_menampilkan_model_bawaan(client):
    login(client)
    html = client.get("/admin/model").get_data(as_text=True)

    assert "Belum ada versi model yang diunggah" in html
    # Angka diambil dari metrics.json supaya test tidak perlu diubah setiap
    # kali model dilatih ulang.
    from app.admin import format_percent

    accuracy = json.loads((ARTIFACT_DIR / "metrics.json").read_text())["accuracy"]
    assert format_percent(accuracy) in html
    assert "127" in html
    assert "26" in html


def test_halaman_model_menampilkan_versi_terunggah(client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes(), label="SVM RBF C=10", note="uji tabel")

    html = client.get("/admin/model").get_data(as_text=True)

    assert 'id="table-models"' in html
    assert "SVM RBF C=10" in html
    assert "uji tabel" in html
    assert "Aktifkan" in html
    assert "Hapus" in html


# ── Unggah ────────────────────────────────────────────────────────


def test_unggah_model_valid_menyimpan_versi(app, client):
    login(client)
    html = upload_model(
        client,
        MODEL_ARTIFACT.read_bytes(),
        label="SVM RBF C=10",
        note="uji unggah",
    ).get_data(as_text=True)

    assert "tersimpan" in html

    with app.app_context():
        version = db.session.query(ModelVersion).one()
        assert version.label == "SVM RBF C=10"
        assert version.feature_count == 127
        assert version.class_count == 26
        assert version.note == "uji unggah"
        assert version.uploaded_by == ADMIN_USERNAME
        assert version.is_active is False
        assert version.size_bytes > 0

        version_dir = Path(app.config["MODEL_UPLOAD_DIR"]) / version.stored_name
        assert (version_dir / "model.joblib").exists()

        label_map = json.loads((version_dir / "label_map.json").read_text(encoding="utf-8"))
        assert label_map["classes"][0] == "A"
        assert label_map["classes"][-1] == "Z"
        assert len(label_map["classes"]) == 26
        assert label_map["feature_count"] == 127


def test_unggah_model_dengan_metrics_menyimpan_akurasi(app, client):
    login(client)
    metrics = {
        "algorithm": "SVM",
        "variant": "SVM RBF",
        "kernel": "rbf",
        "accuracy": 0.9791,
        "f1_score": 0.9791,
    }
    upload_model(client, MODEL_ARTIFACT.read_bytes(), label="dengan metrics", metrics=metrics)

    with app.app_context():
        version = db.session.query(ModelVersion).one()
        assert version.algorithm == "SVM"
        assert version.kernel == "rbf"
        assert version.accuracy == pytest.approx(0.9791)


def test_unggah_model_dengan_label_map_kiriman_admin(app, client):
    login(client)
    label_map = {"classes": ["A", "B"], "catatan": "uji"}
    upload_model(client, MODEL_ARTIFACT.read_bytes(), label_map=label_map)

    with app.app_context():
        version = db.session.query(ModelVersion).one()
        version_dir = Path(app.config["MODEL_UPLOAD_DIR"]) / version.stored_name
        stored = json.loads((version_dir / "label_map.json").read_text(encoding="utf-8"))
        assert stored["classes"] == ["A", "B"]
        assert stored["catatan"] == "uji"
        assert stored["feature_count"] == 127


@pytest.mark.filterwarnings("ignore::FutureWarning")
def test_unggah_model_fitur_salah_ditolak(app, client):
    login(client)
    # Model sah, tetapi hanya memakai 63 fitur.
    rng = np.random.default_rng(0)
    small = SVC(kernel="rbf", probability=True, random_state=0)
    small.fit(rng.random((30, 63)), np.array([i % 2 for i in range(30)]))

    html = upload_model(client, model_bytes(small)).get_data(as_text=True)

    assert "memakai 63 fitur" in html
    assert "127" in html
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 0


@pytest.mark.filterwarnings("ignore::FutureWarning")
def test_unggah_model_tanpa_predict_proba_ditolak(app, client):
    login(client)
    rng = np.random.default_rng(1)
    no_proba = SVC(kernel="rbf", probability=False)
    no_proba.fit(rng.random((30, 127)), np.array([i % 2 for i in range(30)]))

    html = upload_model(client, model_bytes(no_proba)).get_data(as_text=True)

    assert "predict_proba" in html
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 0


def test_unggah_berkas_bukan_model_ditolak(app, client):
    login(client)
    html = upload_model(client, b"ini bukan pickle", filename="model.joblib").get_data(
        as_text=True
    )

    assert "tidak bisa dibaca sebagai model joblib" in html
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 0


def test_unggah_model_ekstensi_salah_ditolak(app, client):
    login(client)
    html = upload_model(client, MODEL_ARTIFACT.read_bytes(), filename="model.txt").get_data(
        as_text=True
    )

    assert "tidak diterima" in html


def test_unggah_model_tanpa_berkas_ditolak(client):
    login(client)
    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/upload",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Pilih berkas model" in html


def test_unggah_model_ganda_tidak_menggandakan_versi(app, client):
    login(client)
    content = MODEL_ARTIFACT.read_bytes()

    upload_model(client, content, label="pertama")
    html = upload_model(client, content, label="kedua").get_data(as_text=True)

    assert "sudah pernah diunggah sebagai versi #1" in html
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 1
        folder = Path(app.config["MODEL_UPLOAD_DIR"])
        assert len([item for item in folder.iterdir() if item.is_dir()]) == 1


# ── Aktifkan dan hapus ────────────────────────────────────────────


def test_aktifkan_model_memuat_ulang_server(app, client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes(), label="kandidat")

    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/1/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "aktif dan sudah dimuat server" in html

    with app.app_context():
        version = db.session.query(ModelVersion).one()
        assert version.is_active is True
        expected = Path(app.config["MODEL_UPLOAD_DIR"]) / version.stored_name / "model.joblib"
        assert Path(app.config["MODEL_PATH"]) == expected

        info = services.get_model_info()
        assert info["loaded"] is True
        assert info["feature_count"] == 127
        assert info["class_count"] == 26


def test_aktifkan_model_berkas_hilang_ditolak(app, client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes())

    with app.app_context():
        version = db.session.query(ModelVersion).one()
        version_dir = Path(app.config["MODEL_UPLOAD_DIR"]) / version.stored_name
    (version_dir / "model.joblib").unlink()

    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/1/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "tidak ada di disk" in html
    with app.app_context():
        assert db.session.query(ModelVersion).one().is_active is False


def test_aktifkan_model_tidak_ada(client):
    login(client)
    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/99/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Versi model tidak ditemukan" in html


def test_hapus_model_aktif_ditolak(app, client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes())
    token = _csrf(client, "/admin/model")
    client.post("/admin/model/1/activate", data={"csrf_token": token})

    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/1/delete",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Model aktif tidak bisa dihapus" in html
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 1


def test_hapus_model_arsip_menghapus_direktori(app, client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes())

    with app.app_context():
        version_dir = (
            Path(app.config["MODEL_UPLOAD_DIR"])
            / db.session.query(ModelVersion).one().stored_name
        )
    assert version_dir.exists()

    token = _csrf(client, "/admin/model")
    html = client.post(
        "/admin/model/1/delete",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "dihapus" in html
    assert not version_dir.exists()
    with app.app_context():
        assert db.session.query(ModelVersion).count() == 0


# ── Pemulihan saat server mulai ───────────────────────────────────


def test_model_aktif_dipulihkan_saat_app_dibuat_ulang(config, app, client):
    login(client)
    upload_model(client, MODEL_ARTIFACT.read_bytes())
    token = _csrf(client, "/admin/model")
    client.post("/admin/model/1/activate", data={"csrf_token": token})

    with app.app_context():
        expected = Path(app.config["MODEL_PATH"])

    # Server "dijalankan ulang": instance aplikasi baru dengan konfigurasi sama.
    second = create_app(dict(config))
    try:
        assert Path(second.config["MODEL_PATH"]) == expected
    finally:
        with second.app_context():
            db.session.remove()
