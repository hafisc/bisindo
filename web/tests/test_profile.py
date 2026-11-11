import pytest

from app import create_app
from app.extensions import db
from app.models import User


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


def headers(uid="uid-budi"):
    return {"X-User-Id": uid}


def profile_payload(**overrides):
    data = {
        "name": "Budi Santoso",
        "email": "budi@mail.com",
        "student_id": "2210512001",
        "role": "Mahasiswa",
        "avatar_url": "https://cdn.example.com/budi.png",
    }
    data.update(overrides)
    return data


# ── Identitas ────────────────────────────────────────────────────────────────


def test_profil_tanpa_header_ditolak(client):
    response = client.get("/api/profile")
    assert response.status_code == 401
    assert "X-User-Id" in response.get_json()["error"]


def test_profil_belum_sinkron_ditolak(client):
    response = client.get("/api/profile", headers=headers())
    assert response.status_code == 404
    assert "belum tersinkron" in response.get_json()["error"]


# ── Membuat profil ───────────────────────────────────────────────────────────


def test_put_membuat_profil_baru(app, client):
    response = client.put("/api/profile", json=profile_payload(), headers=headers())
    assert response.status_code == 201

    data = response.get_json()
    assert data["firebase_uid"] == "uid-budi"
    assert data["name"] == "Budi Santoso"
    assert data["email"] == "budi@mail.com"
    assert data["student_id"] == "2210512001"
    assert data["role"] == "Mahasiswa"
    assert data["avatar_url"] == "https://cdn.example.com/budi.png"
    assert data["created_at"] is not None

    with app.app_context():
        assert db.session.query(User).count() == 1


def test_put_tanpa_nama_ditolak_saat_membuat(client):
    data = profile_payload()
    data.pop("name")

    response = client.put("/api/profile", json=data, headers=headers())
    assert response.status_code == 400
    assert "name" in response.get_json()["error"]


def test_put_tanpa_email_ditolak_saat_membuat(client):
    data = profile_payload()
    data.pop("email")

    response = client.put("/api/profile", json=data, headers=headers())
    assert response.status_code == 400
    assert "email" in response.get_json()["error"]


def test_put_body_bukan_json_ditolak(client):
    response = client.put("/api/profile", data="bukan json", headers=headers())
    assert response.status_code == 400
    assert "JSON" in response.get_json()["error"]


# ── Memperbarui profil ───────────────────────────────────────────────────────


def test_put_kedua_hanya_mengubah_field_yang_dikirim(app, client):
    client.put("/api/profile", json=profile_payload(), headers=headers())

    response = client.put(
        "/api/profile", json={"name": "Budi Santoso Putra"}, headers=headers()
    )
    assert response.status_code == 200

    data = response.get_json()
    assert data["name"] == "Budi Santoso Putra"
    # Field lain tetap seperti sebelumnya.
    assert data["email"] == "budi@mail.com"
    assert data["student_id"] == "2210512001"
    assert data["role"] == "Mahasiswa"

    with app.app_context():
        assert db.session.query(User).count() == 1


def test_put_bisa_mengosongkan_avatar(client):
    client.put("/api/profile", json=profile_payload(), headers=headers())

    response = client.put(
        "/api/profile", json={"avatar_url": ""}, headers=headers()
    )
    assert response.status_code == 200
    assert response.get_json()["avatar_url"] is None


def test_put_bisa_mengosongkan_student_id_dan_role(client):
    client.put("/api/profile", json=profile_payload(), headers=headers())

    response = client.put(
        "/api/profile", json={"student_id": "", "role": ""}, headers=headers()
    )
    assert response.status_code == 200

    data = response.get_json()
    assert data["student_id"] is None
    assert data["role"] is None


def test_put_email_dinormalkan_menjadi_huruf_kecil(client):
    response = client.put(
        "/api/profile",
        json=profile_payload(email="Budi@Mail.COM"),
        headers=headers(),
    )
    assert response.status_code == 201
    assert response.get_json()["email"] == "budi@mail.com"


def test_get_mengembalikan_profil_terbaru(client):
    client.put("/api/profile", json=profile_payload(), headers=headers())
    client.put("/api/profile", json={"name": "Budi Baru"}, headers=headers())

    data = client.get("/api/profile", headers=headers()).get_json()
    assert data["name"] == "Budi Baru"


# ── Validasi ─────────────────────────────────────────────────────────────────


@pytest.mark.parametrize("email", ["bukan-email", "budi@mail", "budi@.com", "@mail.com"])
def test_email_tidak_valid_ditolak(client, email):
    response = client.put(
        "/api/profile", json=profile_payload(email=email), headers=headers()
    )
    assert response.status_code == 400
    assert "email" in response.get_json()["error"]


def test_nama_terlalu_panjang_ditolak(client):
    response = client.put(
        "/api/profile", json=profile_payload(name="x" * 200), headers=headers()
    )
    assert response.status_code == 400
    assert "name" in response.get_json()["error"]


def test_email_sudah_dipakai_pengguna_lain_ditolak(client):
    client.put("/api/profile", json=profile_payload(), headers=headers("uid-budi"))

    response = client.put(
        "/api/profile",
        json=profile_payload(name="Sari", email="budi@mail.com"),
        headers=headers("uid-sari"),
    )
    assert response.status_code == 409
    assert "Email" in response.get_json()["error"]


# ── Isolasi antar pengguna ───────────────────────────────────────────────────


def test_profil_terisolasi_antar_pengguna(client):
    client.put(
        "/api/profile",
        json=profile_payload(name="Budi", email="budi@mail.com"),
        headers=headers("uid-budi"),
    )
    client.put(
        "/api/profile",
        json=profile_payload(name="Sari", email="sari@mail.com"),
        headers=headers("uid-sari"),
    )

    budi = client.get("/api/profile", headers=headers("uid-budi")).get_json()
    sari = client.get("/api/profile", headers=headers("uid-sari")).get_json()

    assert budi["name"] == "Budi"
    assert sari["name"] == "Sari"
    assert budi["id"] != sari["id"]


def test_put_pengguna_lain_tidak_mengubah_profil_budi(client):
    client.put(
        "/api/profile",
        json=profile_payload(name="Budi", email="budi@mail.com"),
        headers=headers("uid-budi"),
    )
    client.put(
        "/api/profile",
        json=profile_payload(name="Sari", email="sari@mail.com"),
        headers=headers("uid-sari"),
    )

    budi = client.get("/api/profile", headers=headers("uid-budi")).get_json()
    assert budi["name"] == "Budi"
    assert budi["email"] == "budi@mail.com"


# ── Integrasi dengan riwayat ─────────────────────────────────────────────────


def test_riwayat_milik_profil_bisa_dibaca_setelah_put_profil(client):
    client.put("/api/profile", json=profile_payload(), headers=headers())

    created = client.post(
        "/api/history",
        json={
            "title": "Halo",
            "type": "Kata",
            "category": "Teks",
            "confidence": 0.9,
        },
        headers=headers(),
    )
    assert created.status_code == 201

    data = client.get("/api/history", headers=headers()).get_json()
    assert data["total"] == 1


def test_resolve_user_id_menerjemahkan_uid_dan_integer(app):
    from app.api.identity import resolve_user_id

    with app.app_context():
        user = User(firebase_uid="uid-budi", name="Budi", email="budi@mail.com")
        db.session.add(user)
        db.session.commit()
        user_id = user.id

    with app.app_context():
        assert resolve_user_id("uid-budi") == user_id
        assert resolve_user_id(user_id) == user_id
        assert resolve_user_id(str(user_id)) == user_id
        assert resolve_user_id("uid-tidak-ada") is None
        assert resolve_user_id(None) is None
        assert resolve_user_id("") is None
        assert resolve_user_id(True) is None
