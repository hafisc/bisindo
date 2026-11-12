import csv
from pathlib import Path

import numpy as np
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


def test_predict_with_dict_landmarks(client):
    """Memastikan POST /api/predict bekerja dengan 21 titik dict."""
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


def test_predict_menyimpan_log_bila_diminta(client, app):
    """Payload dengan ``"log": true`` harus menambah satu DetectionLog."""
    landmarks = [{"x": float(i * 0.01), "y": float(i * 0.02), "z": 0.0} for i in range(21)]

    res = client.post("/api/predict", json={"landmarks": landmarks, "log": True})
    assert res.status_code == 200
    data = res.get_json()

    with app.app_context():
        log = db.session.query(DetectionLog).first()
        assert log is not None
        assert log.letter == data["prediction"]


def test_predict_tanpa_log_tidak_menyimpan_riwayat(client, app):
    """Mobile memanggil prediksi sekitar lima kali per detik.

    Tanpa flag ``log``, setiap panggilan tidak boleh menulis ke tabel riwayat,
    karena riwayat sebenarnya dikirim sekali per huruf ke ``POST /api/history``.
    """
    landmarks = [{"x": float(i * 0.01), "y": float(i * 0.02), "z": 0.0} for i in range(21)]

    for _ in range(3):
        res = client.post("/api/predict", json={"landmarks": landmarks})
        assert res.status_code == 200

    with app.app_context():
        assert db.session.query(DetectionLog).count() == 0


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


# ── Orientasi tangan ─────────────────────────────────────────────────────────
#
# MediaPipe di aplikasi mobile mengembalikan dua tangan sesuai urutan deteksi,
# bukan urutan yang dipakai saat dataset dibuat. Bila urutannya terbalik tanpa
# penanganan, akurasi dua tangan jatuh dari 99,58% menjadi 9,92%. Server
# menguji dua orientasi lalu memilih confidence tertinggi.

DATASET_PATH = (
    Path(__file__).resolve().parents[2]
    / "ml"
    / "src"
    / "dataset"
    / "dataset_bisindo_landmarks.csv"
)

_AXES = ("x", "y", "z")
_FEATURE_COLUMNS = (
    [f"h1_pt{point}_{axis}" for point in range(21) for axis in _AXES]
    + [f"h2_pt{point}_{axis}" for point in range(21) for axis in _AXES]
    + ["is_two_handed"]
)


def _two_handed_samples(limit: int = 6) -> list[tuple[str, list[float]]]:
    """Ambil beberapa baris dua tangan asli dari dataset sebagai vektor 127.

    CSV dibaca dengan modul ``csv`` bawaan supaya test web tidak butuh pandas.
    """
    if not DATASET_PATH.exists():
        pytest.skip(f"Dataset landmark tidak tersedia: {DATASET_PATH}")

    samples: list[tuple[str, list[float]]] = []
    with open(DATASET_PATH, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if (row.get("is_two_handed") or "").strip() not in ("1", "1.0"):
                continue
            samples.append(
                (
                    (row["label"] or "").strip().upper(),
                    [float(row[column]) for column in _FEATURE_COLUMNS],
                )
            )
            if len(samples) >= limit:
                break

    return samples


def test_swap_hands_bolak_balik_mengembalikan_nilai_asli():
    """Menukar tangan dua kali harus kembali ke vektor semula."""
    from app.api.services import swap_hands

    values = np.arange(127, dtype=np.float32).reshape(1, -1)
    kembali = swap_hands(swap_hands(values))

    assert np.array_equal(kembali, values)


def test_swap_hands_tidak_menyentuh_penanda_dua_tangan():
    """Kolom is_two_handed tidak boleh ikut tertukar."""
    from app.api.services import swap_hands

    values = np.zeros((1, 127), dtype=np.float32)
    values[0, 126] = 1.0

    assert swap_hands(values)[0, 126] == 1.0


def test_swap_hands_menukar_blok_63_kolom():
    """Blok tangan 1 dan tangan 2 harus bertukar posisi."""
    from app.api.services import swap_hands

    values = np.zeros((1, 127), dtype=np.float32)
    values[0, 0] = 11.0  # titik pertama tangan 1
    values[0, 63] = 22.0  # titik pertama tangan 2

    swapped = swap_hands(values)
    assert swapped[0, 0] == 22.0
    assert swapped[0, 63] == 11.0


def test_predict_urutan_tangan_terbalik_tetap_benar(client):
    """Prediksi harus sama walau dua tangan dikirim dengan urutan terbalik.

    Ini meniru MediaPipe yang bisa mendeteksi tangan kanan lebih dulu.
    """
    from app.api.services import swap_hands

    samples = _two_handed_samples(6)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    for label, values in samples:
        as_is = client.post("/api/predict", json={"landmarks": values})
        assert as_is.status_code == 200
        hasil_as_is = as_is.get_json()

        terbalik = swap_hands(np.array([values], dtype=np.float32))[0].tolist()
        swapped = client.post("/api/predict", json={"landmarks": terbalik})
        assert swapped.status_code == 200
        hasil_terbalik = swapped.get_json()

        assert hasil_terbalik["prediction"] == hasil_as_is["prediction"], (
            f"huruf berubah saat urutan tangan dibalik untuk label {label}"
        )
        assert hasil_as_is["prediction"] == label


def test_predict_melaporkan_orientasi_tangan(client):
    """Respons harus menyebut orientasi mana yang dipakai."""
    from app.api.services import swap_hands

    samples = _two_handed_samples(1)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    _, values = samples[0]
    terbalik = swap_hands(np.array([values], dtype=np.float32))[0].tolist()

    as_is = client.post("/api/predict", json={"landmarks": values}).get_json()
    swapped = client.post("/api/predict", json={"landmarks": terbalik}).get_json()

    assert as_is["hand_order"] == "as_is"
    assert swapped["hand_order"] == "swapped"


def test_predict_landmark_tercermin_tetap_dikenali(client):
    """Landmark yang tercermin horizontal harus tetap dikenali.

    Kamera depan dan konvensi koordinat berbeda antar perangkat. Tanpa kandidat
    cermin, data yang tercermin hanya benar sekitar 51%. Dengan kandidat cermin,
    akurasinya kembali di atas 95%.
    """
    samples = _two_handed_samples(6)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    for label, values in samples:
        points = _points_from_values(values, 42)
        tercermin = [{"x": -point["x"], "y": point["y"], "z": point["z"]} for point in points]

        hasil = client.post("/api/predict", json={"landmarks": tercermin}).get_json()

        assert hasil["prediction"] == label, (
            f"huruf berubah saat landmark dicerminkan untuk label {label}"
        )


def test_predict_menyertakan_keterangan_cermin(client):
    """Respons selalu menyebut apakah kandidat cermin yang dipakai."""
    samples = _two_handed_samples(1)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    _, values = samples[0]
    data = client.post("/api/predict", json={"landmarks": values}).get_json()

    assert isinstance(data["mirrored"], bool)
    assert data["hand_order"] in ("as_is", "swapped")


def test_predict_satu_tangan_tidak_diuji_dua_orientasi(client):
    """Sampel satu tangan tidak perlu diuji ulang, jadi selalu 'as_is'."""
    landmarks = [{"x": float(i * 0.01), "y": float(i * 0.02), "z": 0.0} for i in range(21)]

    data = client.post("/api/predict", json={"landmarks": landmarks}).get_json()

    assert data["hand_order"] == "as_is"


# ── Normalisasi skala ────────────────────────────────────────────────────────
#
# Dataset latih membagi semua koordinat dengan jarak pergelangan ke titik 9
# tangan 1 (pangkal jari tengah), sehingga jarak itu selalu 1. Landmark mentah
# MediaPipe masih dalam satuan gambar 0-1. Tanpa pembagian skala, akurasi pada
# data yang diperkecil 0,1 kali hanya 3,69%.


def test_preprocess_menormalkan_skala_ke_satu():
    """Setelah preprocessing, jarak pergelangan ke titik 9 harus 1."""
    from app.api.services import preprocess_landmarks

    # Landmark kecil, meniru koordinat gambar dari MediaPipe.
    points = [[0.0, 0.0, 0.0]] + [
        [0.01 * index, 0.005 * index, 0.0] for index in range(1, 21)
    ]

    features = preprocess_landmarks(points)[0]
    hand1 = features[:63].reshape(21, 3)

    assert np.linalg.norm(hand1[9]) == pytest.approx(1.0, abs=1e-4)


def test_preprocess_menolak_landmark_nol():
    """Landmark yang semuanya nol tidak punya skala, harus ditolak jelas."""
    from app.api.services import preprocess_landmarks

    with pytest.raises(ValueError, match="terlalu kecil"):
        preprocess_landmarks([[0.0, 0.0, 0.0] for _ in range(21)])


def test_predict_tahan_perubahan_skala_landmark(client):
    """Memperkecil semua koordinat tidak boleh mengubah huruf prediksi.

    Ini meniru selisih satuan antara MediaPipe (koordinat gambar) dan dataset
    latih (satuan panjang tangan).
    """
    samples = _two_handed_samples(4)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    for label, values in samples:
        asli = client.post("/api/predict", json={"landmarks": values}).get_json()

        # Kirim 126 nilai (tanpa penanda is_two_handed) supaya server
        # menjalankan normalisasi, lalu perkecil 0,1 kali seperti koordinat
        # gambar MediaPipe.
        diperkecil = [value * 0.1 for value in values[:126]]
        hasil = client.post(
            "/api/predict", json={"landmarks": diperkecil}
        ).get_json()

        assert hasil["prediction"] == asli["prediction"], (
            f"huruf berubah saat skala landmark diperkecil untuk label {label}"
        )
        assert asli["prediction"] == label


# ── Orientasi tangan pada landmark mentah ───────────────────────────────────
#
# Mobile mengirim landmark mentah, bukan fitur yang sudah dinormalkan. Karena
# normalisasi memakai pergelangan dan skala tangan pertama, menukar urutan
# tangan harus diikuti normalisasi ulang, bukan sekadar menukar blok fitur.


def _points_from_values(values, point_count):
    return [
        {"x": values[index * 3], "y": values[index * 3 + 1], "z": values[index * 3 + 2]}
        for index in range(point_count)
    ]


def _swap_point_blocks(points):
    """Tukar blok 21 titik pertama dan 21 titik kedua."""
    return points[21:] + points[:21]


def test_preprocess_variants_satu_tangan_menghasilkan_asli_dan_cermin():
    from app.api.services import preprocess_landmarks_variants

    points = [[0.0, 0.0, 0.0]] + [
        [0.01 * index, 0.005 * index, 0.0] for index in range(1, 21)
    ]

    variants = preprocess_landmarks_variants(points)

    assert [(order, mirrored) for _, order, mirrored in variants] == [
        ("as_is", False),
        ("as_is", True),
    ]


def test_preprocess_variants_dua_tangan_menghasilkan_empat_kandidat():
    from app.api.services import preprocess_landmarks_variants

    points = [[0.01 * index, 0.005 * index, 0.0] for index in range(42)]

    variants = preprocess_landmarks_variants(points)

    assert [(order, mirrored) for _, order, mirrored in variants] == [
        ("as_is", False),
        ("swapped", False),
        ("as_is", True),
        ("swapped", True),
    ]
    for features, _, _ in variants:
        assert features.shape == (1, 127)
        # Penanda dua tangan harus tetap 1 pada semua kandidat.
        assert features[0, 126] == 1.0


def test_kandidat_cermin_membalik_sumbu_x_saja():
    """Varian cermin hanya membalik x, bukan y, z, atau penanda dua tangan."""
    from app.api.services import preprocess_landmarks_variants

    points = [[0.01 * index, 0.005 * index, 0.0] for index in range(21)]

    asli, cermin = preprocess_landmarks_variants(points)

    assert asli[2] is False
    assert cermin[2] is True
    np.testing.assert_allclose(cermin[0][0, 0::3], -asli[0][0, 0::3])
    np.testing.assert_allclose(cermin[0][0, 1::3], asli[0][0, 1::3])
    assert cermin[0][0, 126] == asli[0][0, 126]


def test_predict_dua_tangan_mentah_urutan_terbalik_tetap_benar(client):
    """Landmark mentah yang urutan tangannya terbalik harus tetap dikenali."""
    samples = _two_handed_samples(6)
    if not samples:
        pytest.skip("Tidak ada baris dua tangan pada dataset")

    for label, values in samples:
        normal = _points_from_values(values, 42)
        terbalik = _swap_point_blocks(normal)

        hasil_normal = client.post(
            "/api/predict", json={"landmarks": normal}
        ).get_json()
        hasil_terbalik = client.post(
            "/api/predict", json={"landmarks": terbalik}
        ).get_json()

        assert hasil_normal["prediction"] == label
        assert hasil_terbalik["prediction"] == label, (
            f"huruf berubah saat urutan tangan dibalik untuk label {label}"
        )


# ── Akurasi ujung ke ujung ───────────────────────────────────────────────────
#
# Test di atas memeriksa satu per satu perilaku preprocessing. Test berikut
# memeriksa hasil akhirnya: landmark mentah dikirim lewat HTTP, lalu huruf yang
# keluar dibandingkan dengan label dataset. Ini yang menjaga agar perubahan
# normalisasi tidak menurunkan akurasi tanpa disadari.


def _spread_samples(two_handed: bool, limit: int) -> list[tuple[str, list[float]]]:
    """Ambil baris dataset yang tersebar merata, bukan hanya baris pertama.

    Baris awal CSV didominasi huruf A dan B, jadi sampel berjarak dipakai agar
    semua huruf terwakili.
    """
    if not DATASET_PATH.exists():
        pytest.skip(f"Dataset landmark tidak tersedia: {DATASET_PATH}")

    rows: list[tuple[str, list[float]]] = []
    with open(DATASET_PATH, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            is_two = (row.get("is_two_handed") or "").strip() in ("1", "1.0")
            if is_two != two_handed:
                continue
            rows.append(
                (
                    (row["label"] or "").strip().upper(),
                    [float(row[column]) for column in _FEATURE_COLUMNS],
                )
            )

    if not rows:
        pytest.skip("Tidak ada baris dataset yang cocok")

    step = max(1, len(rows) // limit)
    return rows[::step][:limit]


def _accuracy(client, samples, point_count: int) -> float:
    correct = 0
    for label, values in samples:
        points = _points_from_values(values, point_count)
        data = client.post("/api/predict", json={"landmarks": points}).get_json()
        correct += data["prediction"] == label
    return correct / len(samples)


def test_akurasi_satu_tangan_lewat_endpoint(client):
    """Landmark mentah satu tangan harus dikenali minimal 90 persen."""
    samples = _spread_samples(two_handed=False, limit=60)

    accuracy = _accuracy(client, samples, 21)

    assert accuracy >= 0.90, f"akurasi satu tangan hanya {accuracy * 100:.1f}%"


def test_akurasi_dua_tangan_lewat_endpoint(client):
    """Landmark mentah dua tangan harus dikenali minimal 90 persen."""
    samples = _spread_samples(two_handed=True, limit=60)

    accuracy = _accuracy(client, samples, 42)

    assert accuracy >= 0.90, f"akurasi dua tangan hanya {accuracy * 100:.1f}%"


def test_akurasi_dua_tangan_tetap_tinggi_saat_urutan_dibalik(client):
    """Urutan tangan terbalik tidak boleh menurunkan akurasi dua tangan."""
    samples = _spread_samples(two_handed=True, limit=40)

    correct = 0
    for label, values in samples:
        points = _swap_point_blocks(_points_from_values(values, 42))
        data = client.post("/api/predict", json={"landmarks": points}).get_json()
        correct += data["prediction"] == label

    accuracy = correct / len(samples)
    assert accuracy >= 0.90, f"akurasi urutan terbalik hanya {accuracy * 100:.1f}%"


def test_akurasi_landmark_tercermin(client):
    """Landmark tercermin horizontal harus dikenali minimal 90 persen."""
    samples = _spread_samples(two_handed=True, limit=40)

    correct = 0
    for label, values in samples:
        points = _points_from_values(values, 42)
        tercermin = [{"x": -point["x"], "y": point["y"], "z": point["z"]} for point in points]
        data = client.post("/api/predict", json={"landmarks": tercermin}).get_json()
        correct += data["prediction"] == label

    accuracy = correct / len(samples)
    assert accuracy >= 0.90, f"akurasi landmark tercermin hanya {accuracy * 100:.1f}%"


def test_akurasi_satu_tangan_tercermin(client):
    """Satu tangan yang tercermin juga harus tetap dikenali."""
    samples = _spread_samples(two_handed=False, limit=40)

    correct = 0
    for label, values in samples:
        points = _points_from_values(values, 21)
        tercermin = [{"x": -point["x"], "y": point["y"], "z": point["z"]} for point in points]
        data = client.post("/api/predict", json={"landmarks": tercermin}).get_json()
        correct += data["prediction"] == label

    accuracy = correct / len(samples)
    assert accuracy >= 0.85, f"akurasi satu tangan tercermin hanya {accuracy * 100:.1f}%"



