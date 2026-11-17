"""Verifikasi Firebase ID token pada /api/history dan /api/profile.

Token ditandatangani dengan kunci RSA buatan test, dan pengambil kunci publik
Google diganti agar test tidak butuh internet.
"""

import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

from app import create_app
from app.api import identity
from app.extensions import db
from app.models import User

PROJECT_ID = "proyek-uji"
PRIVATE_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
OTHER_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)


def make_token(uid="uid-budi", key=PRIVATE_KEY, **overrides):
    now = int(time.time())
    claims = {
        "iss": f"https://securetoken.google.com/{PROJECT_ID}",
        "aud": PROJECT_ID,
        "sub": uid,
        "iat": now,
        "exp": now + 3600,
    }
    claims.update(overrides)
    return jwt.encode(claims, key, algorithm="RS256", headers={"kid": "uji"})


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def app(tmp_path, monkeypatch):
    monkeypatch.setattr(identity, "_signing_key", lambda token: PRIVATE_KEY.public_key())
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
            "SECRET_KEY": "test-secret",
            "FIREBASE_PROJECT_ID": PROJECT_ID,
            "REQUIRE_FIREBASE_AUTH": True,
        }
    )
    with app.app_context():
        db.session.add(User(firebase_uid="uid-budi", name="Budi", email="budi@mail.com"))
        db.session.commit()
    yield app
    with app.app_context():
        db.session.remove()
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()


def test_token_valid_membuka_riwayat_pemiliknya(client):
    response = client.get("/api/history", headers=bearer(make_token()))
    assert response.status_code == 200
    assert response.get_json()["items"] == []


def test_uid_diambil_dari_token_bukan_dari_header(client):
    # X-User-Id milik orang lain diabaikan bila ada token.
    headers = {**bearer(make_token()), "X-User-Id": "uid-orang-lain"}
    created = client.post(
        "/api/history",
        json={"title": "A", "type": "Huruf", "category": "Teks", "confidence": 0.9},
        headers=headers,
    )
    assert created.status_code == 201

    items = client.get("/api/history", headers=bearer(make_token())).get_json()["items"]
    assert [item["title"] for item in items] == ["A"]


def test_tanpa_token_ditolak_saat_verifikasi_wajib(client):
    response = client.get("/api/history", headers={"X-User-Id": "uid-budi"})
    assert response.status_code == 401
    assert "Authorization" in response.get_json()["error"]


@pytest.mark.parametrize(
    "token",
    [
        make_token(key=OTHER_KEY),
        make_token(aud="proyek-lain"),
        make_token(iss="https://securetoken.google.com/proyek-lain"),
        make_token(exp=int(time.time()) - 3600, iat=int(time.time()) - 7200),
        "bukan-token",
    ],
    ids=["tanda-tangan-palsu", "audience-salah", "issuer-salah", "kedaluwarsa", "rusak"],
)
def test_token_tidak_sah_ditolak(client, token):
    response = client.get("/api/history", headers=bearer(token))
    assert response.status_code == 401
    assert "tidak valid" in response.get_json()["error"]


def test_profil_dibuat_dengan_uid_dari_token(client):
    response = client.put(
        "/api/profile",
        json={"name": "Sari", "email": "sari@mail.com"},
        headers=bearer(make_token(uid="uid-sari")),
    )
    assert response.status_code == 201
    assert response.get_json()["firebase_uid"] == "uid-sari"


def test_x_user_id_tetap_bisa_saat_verifikasi_tidak_wajib(app, client):
    app.config["REQUIRE_FIREBASE_AUTH"] = False
    response = client.get("/api/history", headers={"X-User-Id": "uid-budi"})
    assert response.status_code == 200


def test_project_id_kosong_memberi_pesan_konfigurasi(app, client):
    app.config["FIREBASE_PROJECT_ID"] = ""
    response = client.get("/api/history", headers=bearer(make_token()))
    assert response.status_code == 500
    assert "FIREBASE_PROJECT_ID" in response.get_json()["error"]
