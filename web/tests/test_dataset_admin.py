"""Test halaman admin untuk unggah dan pengelolaan dataset CSV."""

import io
import secrets
from pathlib import Path

import pytest

from app import create_app
from app.admin import storage
from app.extensions import db
from app.models import DatasetSnapshot

# Kredensial admin khusus test, dibuat acak saat modul dimuat supaya tidak ada
# kata sandi yang tertulis di berkas.
ADMIN_USERNAME = "admin-uji"
ADMIN_PASSWORD = secrets.token_hex(16)


@pytest.fixture()
def app(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
            "SECRET_KEY": "test-secret",
            "ADMIN_USERNAME": ADMIN_USERNAME,
            "ADMIN_PASSWORD": ADMIN_PASSWORD,
            "DATASET_DIR": (tmp_path / "datasets").as_posix(),
            "MODEL_UPLOAD_DIR": (tmp_path / "models").as_posix(),
        }
    )
    yield app
    with app.app_context():
        db.session.remove()
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


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


def build_csv(rows, columns=None):
    """Susun CSV landmark: kolom label, filename, lalu 127 kolom fitur."""
    header = columns or ["label", "filename", *storage.FEATURE_COLUMNS]
    lines = [",".join(header)]
    for label, filename in rows:
        values = [label, filename] + ["0"] * storage.FEATURE_COUNT
        lines.append(",".join(values))
    return ("\n".join(lines) + "\n").encode("utf-8")


def upload(client, content, filename="landmarks.csv", note=""):
    token = _csrf(client, "/admin/dataset")
    return client.post(
        "/admin/dataset/upload",
        data={
            "dataset_file": (io.BytesIO(content), filename),
            "note": note,
            "csrf_token": token,
        },
        content_type="multipart/form-data",
        follow_redirects=True,
    )


# ── Akses ─────────────────────────────────────────────────────────


def test_halaman_dataset_butuh_login(client):
    response = client.get("/admin/dataset")
    assert response.status_code == 302
    assert "/admin/login" in response.headers["Location"]


def test_unggah_dataset_butuh_login(client):
    response = client.post("/admin/dataset/upload", data={})
    assert response.status_code == 302
    assert "/admin/login" in response.headers["Location"]


def test_halaman_dataset_kosong(client):
    login(client)
    html = client.get("/admin/dataset").get_data(as_text=True)
    assert "Belum ada dataset aktif" in html
    assert "Belum ada dataset yang diunggah" in html


# ── Unggah ────────────────────────────────────────────────────────


def test_unggah_dataset_valid_menyimpan_snapshot(app, client):
    login(client)
    content = build_csv(
        [
            ("A", "a1.jpg"),
            ("A", "a2.jpg"),
            ("B", "b1.jpg"),
            ("C", "c1.jpg"),
        ]
    )
    html = upload(client, content, note="uji unggah").get_data(as_text=True)

    assert "Dataset tersimpan: 4 baris, 3 kelas" in html

    with app.app_context():
        snapshot = db.session.query(DatasetSnapshot).one()
        assert snapshot.row_count == 4
        assert snapshot.class_count == 3
        assert snapshot.feature_count == 127
        assert snapshot.note == "uji unggah"
        assert snapshot.uploaded_by == ADMIN_USERNAME
        assert snapshot.is_active is False
        assert snapshot.distribution() == {"A": 2, "B": 1, "C": 1}
        assert snapshot.size_bytes > 0
        assert snapshot.size_label

        path = Path(app.config["DATASET_DIR"]) / snapshot.stored_name
        assert path.exists()


def test_unggah_dataset_mendeteksi_nama_berkas_lintas_kelas(app, client):
    login(client)
    # Nama berkas sama dipakai dua kelas: tanda augmentasi sebelum split.
    content = build_csv([("A", "augmented_image_0.jpg"), ("B", "augmented_image_0.jpg")])
    upload(client, content)

    with app.app_context():
        snapshot = db.session.query(DatasetSnapshot).one()
        assert snapshot.shared_filename_count == 1


def test_unggah_dataset_kolom_kurang_ditolak(app, client):
    login(client)
    content = build_csv([("A", "a1.jpg")], columns=["label", "filename", "h1_pt0_x"])
    html = upload(client, content).get_data(as_text=True)

    assert "Kolom wajib tidak ditemukan" in html
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 0


def test_unggah_dataset_tanpa_baris_ditolak(app, client):
    login(client)
    content = build_csv([])
    html = upload(client, content).get_data(as_text=True)

    assert "tidak memiliki baris data" in html
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 0


def test_unggah_dataset_ekstensi_salah_ditolak(app, client):
    login(client)
    html = upload(client, b"bukan csv", filename="data.txt").get_data(as_text=True)

    assert "tidak diterima" in html
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 0


def test_unggah_dataset_tanpa_berkas_ditolak(app, client):
    login(client)
    token = _csrf(client, "/admin/dataset")
    html = client.post(
        "/admin/dataset/upload",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Pilih berkas CSV terlebih dahulu" in html


def test_unggah_dataset_ganda_tidak_menggandakan_snapshot(app, client):
    login(client)
    content = build_csv([("A", "a1.jpg"), ("B", "b1.jpg")])

    upload(client, content)
    html = upload(client, content, filename="salinan.csv").get_data(as_text=True)

    assert "sudah pernah diunggah sebagai snapshot #1" in html
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 1
        # Berkas duplikat dibersihkan dari disk.
        folder = Path(app.config["DATASET_DIR"])
        assert len(list(folder.glob("*.csv"))) == 1


# ── Aktifkan dan hapus ────────────────────────────────────────────


def test_aktifkan_dataset_menggeser_snapshot_aktif(app, client):
    login(client)
    upload(client, build_csv([("A", "a1.jpg")]))
    upload(client, build_csv([("A", "a1.jpg"), ("B", "b1.jpg")]))

    token = _csrf(client, "/admin/dataset")
    response = client.post(
        "/admin/dataset/1/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    )
    assert response.status_code == 200
    assert "ditandai sebagai acuan aktif" in response.get_data(as_text=True)

    token = _csrf(client, "/admin/dataset")
    client.post(
        "/admin/dataset/2/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    )

    with app.app_context():
        active = db.session.query(DatasetSnapshot).filter_by(is_active=True).all()
        assert len(active) == 1
        assert active[0].id == 2


def test_aktifkan_dataset_tidak_ada(app, client):
    login(client)
    token = _csrf(client, "/admin/dataset")
    html = client.post(
        "/admin/dataset/99/activate",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Snapshot dataset tidak ditemukan" in html


def test_hapus_dataset_aktif_ditolak(app, client):
    login(client)
    upload(client, build_csv([("A", "a1.jpg")]))
    token = _csrf(client, "/admin/dataset")
    client.post("/admin/dataset/1/activate", data={"csrf_token": token})

    token = _csrf(client, "/admin/dataset")
    html = client.post(
        "/admin/dataset/1/delete",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "Dataset aktif tidak bisa dihapus" in html
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 1


def test_hapus_dataset_arsip_menghapus_berkas(app, client):
    login(client)
    upload(client, build_csv([("A", "a1.jpg")]))

    with app.app_context():
        stored_name = db.session.query(DatasetSnapshot).one().stored_name
    path = Path(app.config["DATASET_DIR"]) / stored_name
    assert path.exists()

    token = _csrf(client, "/admin/dataset")
    html = client.post(
        "/admin/dataset/1/delete",
        data={"csrf_token": token},
        follow_redirects=True,
    ).get_data(as_text=True)

    assert "dihapus" in html
    assert not path.exists()
    with app.app_context():
        assert db.session.query(DatasetSnapshot).count() == 0


def test_tombol_aktifkan_dan_hapus_tampil(client):
    login(client)
    upload(client, build_csv([("A", "a1.jpg")]))
    html = client.get("/admin/dataset").get_data(as_text=True)

    assert 'id="table-datasets"' in html
    assert "Aktifkan" in html
    assert "Hapus" in html


def test_halaman_dataset_menampilkan_sebaran_kelas(client):
    login(client)
    upload(client, build_csv([("A", "a1.jpg"), ("A", "a2.jpg"), ("B", "b1.jpg")]))

    token = _csrf(client, "/admin/dataset")
    client.post("/admin/dataset/1/activate", data={"csrf_token": token})

    html = client.get("/admin/dataset").get_data(as_text=True)

    assert "Dataset aktif" in html
    assert 'class="dist"' in html
    assert "dist-count" in html
    assert "Belum ada dataset aktif" not in html


def test_unggah_melebihi_batas_ukuran_diberi_pesan(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
            "SECRET_KEY": "test-secret",
            "ADMIN_USERNAME": ADMIN_USERNAME,
            "ADMIN_PASSWORD": ADMIN_PASSWORD,
            "DATASET_DIR": (tmp_path / "datasets").as_posix(),
            "MODEL_UPLOAD_DIR": (tmp_path / "models").as_posix(),
            "MAX_CONTENT_LENGTH": 2048,
        }
    )
    client = app.test_client()

    try:
        login(client)
        content = build_csv([("A", f"a{index}.jpg") for index in range(10)])
        assert len(content) > 2048

        html = upload(client, content).get_data(as_text=True)

        assert "Berkas terlalu besar" in html
        with app.app_context():
            assert db.session.query(DatasetSnapshot).count() == 0
    finally:
        with app.app_context():
            db.session.remove()
            db.drop_all()
