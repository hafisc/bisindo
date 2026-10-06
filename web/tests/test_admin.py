from datetime import datetime, timedelta, timezone

import pytest

from app import create_app
from app.extensions import db
from app.models import DetectionLog, User, utcnow


@pytest.fixture()
def app(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{(tmp_path / 'test.db').as_posix()}",
            "SECRET_KEY": "test-secret",
            "ADMIN_USERNAME": "admin",
            "ADMIN_PASSWORD": "rahasia123",
            "ADMIN_PER_PAGE": 3,
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
    """Ambil token CSRF dari session setelah membuka halaman form."""
    client.get(path)
    with client.session_transaction() as sess:
        return sess["_csrf"]


def login(client, username="admin", password="rahasia123"):
    token = _csrf(client)
    return client.post(
        "/admin/login",
        data={"username": username, "password": password, "csrf_token": token},
    )


@pytest.fixture()
def seeded(app):
    """3 pengguna dan 6 log. Huruf A paling sering."""
    with app.app_context():
        budi = User(name="Budi Santoso", email="budi@mail.com")
        sari = User(name="Sari Dewi", email="sari@mail.com")
        tono = User(name="Tono", email="tono@mail.com")
        db.session.add_all([budi, sari, tono])
        db.session.flush()
        now = utcnow()
        db.session.add_all(
            [
                DetectionLog(user_id=budi.id, letter="A", confidence=0.95, created_at=now),
                DetectionLog(user_id=budi.id, letter="A", confidence=0.85, created_at=now),
                DetectionLog(user_id=sari.id, letter="A", confidence=0.75, created_at=now),
                DetectionLog(user_id=sari.id, letter="B", confidence=0.9, created_at=now),
                DetectionLog(user_id=None, letter="C", confidence=0.8, created_at=now),
                DetectionLog(
                    user_id=budi.id,
                    letter="B",
                    confidence=0.9,
                    created_at=now - timedelta(days=3),
                ),
            ]
        )
        db.session.commit()


# ── Akses dan login ───────────────────────────────────────────────

@pytest.mark.parametrize("path", ["/admin/dashboard", "/admin/users", "/admin/logs"])
def test_halaman_admin_butuh_login(client, path):
    response = client.get(path)
    assert response.status_code == 302
    assert "/admin/login" in response.headers["Location"]


def test_root_mengarah_ke_dashboard(client):
    response = client.get("/")
    assert response.status_code == 302
    assert response.headers["Location"].endswith("/admin/dashboard")


def test_login_salah_ditolak(client):
    response = login(client, password="salah")
    assert response.status_code == 200
    assert "Username atau password salah" in response.get_data(as_text=True)
    assert client.get("/admin/dashboard").status_code == 302


def test_login_tanpa_csrf_ditolak(client):
    client.get("/admin/login")
    response = client.post(
        "/admin/login", data={"username": "admin", "password": "rahasia123"}
    )
    assert response.status_code == 400


def test_login_benar_masuk_dashboard(client):
    response = login(client)
    assert response.status_code == 302
    assert response.headers["Location"].endswith("/admin/dashboard")
    assert client.get("/admin/dashboard").status_code == 200


def test_login_redirect_next_hanya_ke_admin(client):
    token = _csrf(client)
    response = client.post(
        "/admin/login?next=https://situs-lain.com",
        data={"username": "admin", "password": "rahasia123", "csrf_token": token},
    )
    assert response.headers["Location"].endswith("/admin/dashboard")


def test_logout_menghapus_sesi(client):
    login(client)
    with client.session_transaction() as sess:
        token = sess["_csrf"] if "_csrf" in sess else ""
    token = token or _csrf(client, "/admin/dashboard")
    response = client.post("/admin/logout", data={"csrf_token": token})
    assert response.status_code == 302
    assert client.get("/admin/dashboard").status_code == 302


# ── Dashboard ─────────────────────────────────────────────────────

def test_dashboard_kosong(client):
    login(client)
    html = client.get("/admin/dashboard").get_data(as_text=True)
    assert 'id="stat-users">0<' in html
    assert 'id="stat-logs">0<' in html
    assert 'id="stat-confidence">-<' in html
    assert "Belum ada log deteksi" in html


def test_dashboard_berisi_statistik(client, seeded):
    login(client)
    html = client.get("/admin/dashboard").get_data(as_text=True)
    assert 'id="stat-users">3<' in html
    assert 'id="stat-logs">6<' in html
    assert 'id="stat-today">5<' in html  # 1 log lain dibuat 3 hari lalu
    assert 'id="top-letters"' in html
    assert 'id="table-latest"' in html
    assert "Budi Santoso" in html
    assert "Tanpa akun" in html


def test_dashboard_huruf_teratas_urut(app, seeded):
    from app.admin import queries

    with app.app_context():
        top = queries.get_top_letters()
        assert [item["letter"] for item in top] == ["A", "B", "C"]
        assert top[0]["total"] == 3 and top[0]["percent"] == 100


def test_dashboard_grafik_7_hari(app, seeded):
    from app.admin import queries

    with app.app_context():
        series = queries.get_daily_counts(7)
        assert len(series) == 7
        assert series[-1]["is_today"] is True and series[-1]["total"] == 5
        assert series[-4]["total"] == 1  # 3 hari lalu
        assert sum(item["total"] for item in series) == 6


# ── Pengguna ──────────────────────────────────────────────────────

def test_users_kosong(client):
    login(client)
    html = client.get("/admin/users").get_data(as_text=True)
    assert "Belum ada pengguna terdaftar" in html


def test_users_menampilkan_jumlah_deteksi(client, seeded):
    login(client)
    html = client.get("/admin/users").get_data(as_text=True)
    assert "Budi Santoso" in html and "budi@mail.com" in html
    assert 'id="table-users"' in html


def test_users_pencarian(client, seeded):
    login(client)
    html = client.get("/admin/users?q=sari").get_data(as_text=True)
    assert "Sari Dewi" in html
    assert "Budi Santoso" not in html


def test_users_pencarian_tanpa_hasil(client, seeded):
    login(client)
    html = client.get("/admin/users?q=zzz").get_data(as_text=True)
    assert "Tidak ada pengguna yang cocok" in html


def test_users_pencarian_karakter_wildcard_tidak_cocok_semua(client, seeded):
    login(client)
    html = client.get("/admin/users?q=%25").get_data(as_text=True)
    assert "Tidak ada pengguna yang cocok" in html


def test_users_pagination(client, seeded):
    login(client)
    page1 = client.get("/admin/users").get_data(as_text=True)
    page2 = client.get("/admin/users?page=2").get_data(as_text=True)
    # per_page = 3 dan ada 3 pengguna, jadi halaman 2 kosong, tidak error
    assert "Budi Santoso" in page1
    assert client.get("/admin/users?page=99").status_code == 200
    assert client.get("/admin/users?page=abc").status_code == 200
    assert page2


# ── Log ───────────────────────────────────────────────────────────

def test_logs_kosong(client):
    login(client)
    html = client.get("/admin/logs").get_data(as_text=True)
    assert "Belum ada log deteksi" in html


def test_logs_pagination_dan_isi(client, seeded):
    login(client)
    page1 = client.get("/admin/logs").get_data(as_text=True)
    page2 = client.get("/admin/logs?page=2").get_data(as_text=True)
    assert page1.count('class="letter-chip"') == 3
    assert page2.count('class="letter-chip"') == 3
    assert "Menampilkan 1-3 dari 6 data" in page1


def test_logs_filter_huruf(client, seeded):
    login(client)
    html = client.get("/admin/logs?letter=b").get_data(as_text=True)  # huruf kecil ikut dikenali
    assert html.count('class="letter-chip"') == 2
    assert "Menampilkan 1-2 dari 2 data" in html


def test_logs_filter_pengguna(client, seeded):
    login(client)
    html = client.get("/admin/logs?q=budi").get_data(as_text=True)
    assert "dari 3 data" in html


def test_logs_filter_tanpa_hasil(client, seeded):
    login(client)
    html = client.get("/admin/logs?letter=Z").get_data(as_text=True)
    assert "Tidak ada log yang cocok" in html


def test_badge_confidence(client, seeded):
    login(client)
    html = client.get("/admin/logs").get_data(as_text=True)
    page2 = client.get("/admin/logs?page=2").get_data(as_text=True)
    combined = html + page2
    assert "badge high" in combined and "badge mid" in combined and "badge low" in combined


def test_waktu_ditampilkan_dalam_wib(app):
    from app.admin import queries

    utc_value = datetime(2026, 10, 3, 20, 30)  # 20:30 UTC = 03:30 WIB tanggal 4
    local = queries.to_wib(utc_value)
    assert (local.day, local.hour, local.minute) == (4, 3, 30)
    assert local.utcoffset() == timedelta(hours=7)
    assert utc_value.replace(tzinfo=timezone.utc) == local
