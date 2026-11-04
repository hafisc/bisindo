import pytest

from app import create_app
from app.extensions import db


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


def test_get_all_dictionary_letters(client):
    response = client.get("/api/dictionary")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    assert len(data) == 26
    letters = [item["letter"] for item in data]
    assert "A" in letters
    assert "Z" in letters


def test_get_letter_detail_success(client):
    response = client.get("/api/dictionary/a")
    assert response.status_code == 200
    data = response.get_json()
    assert data["letter"] == "A"
    assert "description" in data
    assert "image_url" in data
    assert data["image_url"] == "/static/img/dictionary/A.png"


def test_get_letter_detail_not_found(client):
    response = client.get("/api/dictionary/1")
    assert response.status_code == 404
