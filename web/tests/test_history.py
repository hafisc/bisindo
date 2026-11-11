import pytest

from app import create_app
from app.extensions import db
from app.models import DetectionLog, User


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


def make_user(app, uid="uid-budi", name="Budi Santoso", email="budi@mail.com"):
    """Buat pengguna tersinkron dan kembalikan id-nya."""
    with app.app_context():
        user = User(firebase_uid=uid, name=name, email=email)
        db.session.add(user)
        db.session.commit()
        return user.id


def headers(uid="uid-budi"):
    return {"X-User-Id": uid}


def payload(**overrides):
    data = {
        "title": "Halo",
        "type": "Kata",
        "category": "Teks",
        "mode": "BISINDO -> Teks",
        "confidence": 0.95,
        "timestamp": "2026-11-11T10:20:00",
    }
    data.update(overrides)
    return data


# ── Identitas ────────────────────────────────────────────────────────────────


def test_history_tanpa_header_ditolak(client):
    response = client.get("/api/history")
    assert response.status_code == 401
    assert "X-User-Id" in response.get_json()["error"]


def test_history_user_belum_sinkron_ditolak(client):
    response = client.get("/api/history", headers=headers("uid-belum-ada"))
    assert response.status_code == 404
    assert "belum tersinkron" in response.get_json()["error"]


def test_uid_bisa_lewat_query_string(app, client):
    make_user(app)
    response = client.get("/api/history?user_id=uid-budi")
    assert response.status_code == 200
    assert response.get_json()["total"] == 0


# ── Simpan dan baca ──────────────────────────────────────────────────────────


def test_simpan_riwayat(app, client):
    make_user(app)

    response = client.post("/api/history", json=payload(), headers=headers())
    assert response.status_code == 201

    data = response.get_json()
    assert data["id"] > 0
    assert data["title"] == "Halo"
    assert data["type"] == "Kata"
    assert data["category"] == "Teks"
    assert data["confidence"] == 0.95
    assert data["timestamp"].startswith("2026-11-11T10:20:00")


def test_riwayat_tersimpan_di_database(app, client):
    user_id = make_user(app)
    client.post("/api/history", json=payload(), headers=headers())

    with app.app_context():
        log = db.session.query(DetectionLog).one()
        assert log.user_id == user_id
        assert log.title == "Halo"
        assert log.letter is None


def test_daftar_riwayat_urut_terbaru(app, client):
    make_user(app)
    client.post(
        "/api/history",
        json=payload(title="Lama", timestamp="2026-11-01T08:00:00"),
        headers=headers(),
    )
    client.post(
        "/api/history",
        json=payload(title="Baru", timestamp="2026-11-10T08:00:00"),
        headers=headers(),
    )

    data = client.get("/api/history", headers=headers()).get_json()
    assert data["total"] == 2
    assert [item["title"] for item in data["items"]] == ["Baru", "Lama"]


def test_riwayat_bisa_dibatasi(app, client):
    make_user(app)
    for index in range(5):
        client.post(
            "/api/history",
            json=payload(title=f"Kata {index}", timestamp=f"2026-11-0{index + 1}T08:00:00"),
            headers=headers(),
        )

    data = client.get("/api/history?limit=2&offset=1", headers=headers()).get_json()
    assert data["total"] == 5
    assert data["limit"] == 2
    assert data["offset"] == 1
    assert len(data["items"]) == 2


def test_riwayat_terisolasi_antar_pengguna(app, client):
    make_user(app, uid="uid-budi", email="budi@mail.com")
    make_user(app, uid="uid-sari", name="Sari", email="sari@mail.com")

    client.post("/api/history", json=payload(title="Punya Budi"), headers=headers("uid-budi"))

    data = client.get("/api/history", headers=headers("uid-sari")).get_json()
    assert data["total"] == 0
    assert data["items"] == []


# ── Hapus ────────────────────────────────────────────────────────────────────


def test_hapus_satu_riwayat(app, client):
    make_user(app)
    created = client.post("/api/history", json=payload(), headers=headers()).get_json()

    response = client.delete(f"/api/history/{created['id']}", headers=headers())
    assert response.status_code == 200
    assert response.get_json()["deleted"] == 1

    assert client.get("/api/history", headers=headers()).get_json()["total"] == 0


def test_hapus_riwayat_id_tidak_ada(app, client):
    make_user(app)
    response = client.delete("/api/history/9999", headers=headers())
    assert response.status_code == 404


def test_tidak_bisa_hapus_riwayat_pengguna_lain(app, client):
    make_user(app, uid="uid-budi", email="budi@mail.com")
    make_user(app, uid="uid-sari", name="Sari", email="sari@mail.com")

    created = client.post("/api/history", json=payload(), headers=headers("uid-budi")).get_json()

    response = client.delete(f"/api/history/{created['id']}", headers=headers("uid-sari"))
    assert response.status_code == 404

    # Entri tetap ada untuk pemiliknya.
    assert client.get("/api/history", headers=headers("uid-budi")).get_json()["total"] == 1


def test_hapus_semua_riwayat(app, client):
    make_user(app)
    for index in range(3):
        client.post("/api/history", json=payload(title=f"Kata {index}"), headers=headers())

    response = client.delete("/api/history", headers=headers())
    assert response.status_code == 200
    assert response.get_json()["deleted"] == 3
    assert client.get("/api/history", headers=headers()).get_json()["total"] == 0


def test_hapus_semua_tidak_menyentuh_pengguna_lain(app, client):
    make_user(app, uid="uid-budi", email="budi@mail.com")
    make_user(app, uid="uid-sari", name="Sari", email="sari@mail.com")

    client.post("/api/history", json=payload(), headers=headers("uid-budi"))
    client.post("/api/history", json=payload(), headers=headers("uid-sari"))

    client.delete("/api/history", headers=headers("uid-budi"))

    assert client.get("/api/history", headers=headers("uid-budi")).get_json()["total"] == 0
    assert client.get("/api/history", headers=headers("uid-sari")).get_json()["total"] == 1


# ── Validasi payload ─────────────────────────────────────────────────────────


def test_body_bukan_json_ditolak(app, client):
    make_user(app)
    response = client.post("/api/history", data="bukan json", headers=headers())
    assert response.status_code == 400
    assert "JSON" in response.get_json()["error"]


@pytest.mark.parametrize("field", ["title", "type", "category", "confidence"])
def test_field_wajib(app, client, field):
    make_user(app)
    data = payload()
    data.pop(field)

    response = client.post("/api/history", json=data, headers=headers())
    assert response.status_code == 400
    assert field in response.get_json()["error"]


def test_type_tidak_dikenal_ditolak(app, client):
    make_user(app)
    response = client.post("/api/history", json=payload(type="Kalimat"), headers=headers())
    assert response.status_code == 400
    assert "type" in response.get_json()["error"]


def test_category_tidak_dikenal_ditolak(app, client):
    make_user(app)
    response = client.post("/api/history", json=payload(category="Gambar"), headers=headers())
    assert response.status_code == 400
    assert "category" in response.get_json()["error"]


@pytest.mark.parametrize("confidence", [-0.1, 1.5, "tinggi", True])
def test_confidence_tidak_valid_ditolak(app, client, confidence):
    make_user(app)
    response = client.post("/api/history", json=payload(confidence=confidence), headers=headers())
    assert response.status_code == 400
    assert "confidence" in response.get_json()["error"]


def test_timestamp_tidak_valid_ditolak(app, client):
    make_user(app)
    response = client.post(
        "/api/history", json=payload(timestamp="kemarin sore"), headers=headers()
    )
    assert response.status_code == 400
    assert "timestamp" in response.get_json()["error"]


def test_timestamp_dengan_zona_waktu_dinormalkan(app, client):
    make_user(app)
    response = client.post(
        "/api/history",
        json=payload(timestamp="2026-11-11T17:20:00+07:00"),
        headers=headers(),
    )
    assert response.status_code == 201
    # 17:20 WIB = 10:20 UTC
    assert response.get_json()["timestamp"].startswith("2026-11-11T10:20:00")


def test_title_terlalu_panjang_ditolak(app, client):
    make_user(app)
    response = client.post("/api/history", json=payload(title="x" * 200), headers=headers())
    assert response.status_code == 400
    assert "title" in response.get_json()["error"]


def test_timestamp_kosong_memakai_waktu_sekarang(app, client):
    make_user(app)
    response = client.post("/api/history", json=payload(timestamp=None), headers=headers())
    assert response.status_code == 201
    assert response.get_json()["timestamp"] is not None


# ── Integrasi dengan panel admin ─────────────────────────────────────────────


def test_entri_kata_muncul_di_log_admin(app, client):
    from app.admin import queries

    make_user(app)
    client.post("/api/history", json=payload(title="Terima kasih"), headers=headers())

    with app.app_context():
        latest = queries.get_latest_logs(5)
        assert latest[0].display_label == "Terima kasih"

        # Entri kata tidak masuk peringkat huruf.
        assert queries.get_top_letters() == []
