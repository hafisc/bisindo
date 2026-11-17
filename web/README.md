# BISINDO Translator: Server Web

Server Flask yang menyediakan REST API untuk aplikasi mobile dan panel admin. Petunjuk umum proyek ada di [README utama](../README.md).

## Menjalankan

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env      # opsional, isi nilai sesuai kebutuhan
python run.py
```

Server mendengarkan di `0.0.0.0:5000`, dan saat start mencetak alamat IP laptop yang bisa diisi di aplikasi mobile.

| Variabel | Bawaan | Keterangan |
| :--- | :--- | :--- |
| `SECRET_KEY` | acak, disimpan di `instance/secret_key` | Isi sendiri di cloud agar sesi admin tetap sama setelah redeploy |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | `admin` / `admin123` | Akun login `/admin`. Ganti sebelum demo di WiFi umum; `run.py` memberi peringatan selama masih bawaan. Login dikunci 10 menit setelah 5 kali salah |
| `DATABASE_URL` | SQLite di `web/instance/bisindo.db` | Connection string Postgres untuk produksi |
| `MODEL_PATH` | `ml/models/svm_rbf_bisindo.joblib` | Lokasi model SVM |
| `INSTANCE_DIR` | `web/instance` | Folder unggahan dataset dan model |

Test dijalankan dengan `pip install -r requirements-dev.txt` lalu `pytest`.

## REST API

Endpoint riwayat dan profil membaca Firebase UID dari token di header `Authorization` (lihat [Keamanan](#keamanan)). Di server lokal tanpa verifikasi wajib, UID juga boleh dikirim lewat header `X-User-Id`, query `user_id`, atau field `user_id` di body.

| Method | Endpoint | Keterangan |
| :--- | :--- | :--- |
| GET | `/api/status` | Status layanan dan kesiapan model |
| GET | `/api/model` | Info model aktif: jumlah fitur, kelas, akurasi |
| POST | `/api/predict` | Prediksi huruf dari 21 atau 42 titik landmark |
| GET | `/api/dictionary` | Daftar huruf kamus |
| GET | `/api/dictionary/<huruf>` | Detail satu huruf |
| GET | `/api/history` | Riwayat pengguna, terbaru lebih dulu |
| POST | `/api/history` | Simpan satu riwayat |
| DELETE | `/api/history/<id>` | Hapus satu riwayat |
| DELETE | `/api/history` | Hapus semua riwayat pengguna |
| GET | `/api/profile` | Ambil profil |
| PUT | `/api/profile` | Buat atau perbarui profil |

### Prediksi

```bash
curl -X POST http://127.0.0.1:5000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"landmarks": [{"x": 0.1, "y": 0.2, "z": 0.0}, "... 21 titik"]}'
```

Respons berisi `prediction`, `confidence`, `class_index`, `hand_order`, dan `mirrored`.

Landmark mentah MediaPipe (koordinat gambar 0 sampai 1) boleh dikirim apa adanya, karena server yang menyusun 127 fitur:

1. **Normalisasi**, sama seperti saat dataset dibuat: posisi pergelangan tangan pertama dikurangkan, lalu hasilnya dibagi jarak pergelangan ke titik 9. Untuk satu tangan, 63 nilai tangan kedua diisi nol.
2. **Urutan tangan.** MediaPipe tidak menjamin urutan tangan. Tanpa penanganan ini, akurasi dua tangan jatuh dari 99,58% menjadi 9,92%.
3. **Pencerminan.** Kamera depan bisa mencerminkan gambar. Tanpa penanganan ini, data yang tercermin hanya dikenali 51,34%.

Untuk urutan tangan dan pencerminan, server mencoba semua kemungkinan, yaitu 4 kandidat untuk dua tangan dan 2 kandidat untuk satu tangan, lalu memilih yang confidence-nya paling tinggi. Satu prediksi selesai dalam sekitar 2 sampai 3 ms.

### Riwayat

```bash
curl -X POST http://127.0.0.1:5000/api/history \
  -H "Content-Type: application/json" \
  -H "X-User-Id: <firebase-uid>" \
  -d '{"title": "Halo", "type": "Kata", "category": "Teks",
       "mode": "BISINDO -> Teks", "confidence": 0.95}'
```

- `type`: `Kata` atau `Huruf`.
- `category`: `Teks` atau `Suara`.
- `confidence`: 0.0 sampai 1.0.
- `timestamp` opsional. Bila tidak dikirim, server memakai waktu saat request diterima.

### Profil

`PUT /api/profile` membuat profil bila belum ada (membalas 201) dan memperbarui field yang dikirim bila sudah ada (membalas 200). Field `name` dan `email` wajib diisi pada panggilan pertama. Mengirim string kosong untuk `student_id`, `role`, atau `avatar_url` akan mengosongkan nilai field tersebut.

### Keamanan

Aplikasi mobile mengirim `Authorization: Bearer <Firebase ID token>`. Server memeriksa tanda tangan token dengan kunci publik Google, lalu memakai UID di dalamnya, sehingga UID tidak bisa dipalsukan.

| Variabel | Bawaan | Keterangan |
| :--- | :--- | :--- |
| `FIREBASE_PROJECT_ID` | `bisindo-translator-5b185` | Project Firebase yang menerbitkan token |
| `REQUIRE_FIREBASE_AUTH` | `0` | `1` berarti request tanpa token ditolak. Wajib `1` di server publik |

Selama `REQUIRE_FIREBASE_AUTH=0`, header `X-User-Id` tanpa token masih diterima supaya pengembangan lokal tetap mudah. Header ini tidak diverifikasi.

## Panel Admin

Panel admin ada di `/admin` dan berisi halaman dashboard, pengguna, log deteksi, dataset, dan model.

| Halaman | Endpoint | Keterangan |
| :--- | :--- | :--- |
| Dataset | `GET /admin/dataset` | Snapshot CSV, statistik baris dan kelas |
| Unggah dataset | `POST /admin/dataset/upload` | CSV landmark 127 kolom. Kolom kurang atau berkas ganda ditolak |
| Model | `GET /admin/model` | Versi model dan model yang sedang dipakai |
| Unggah model | `POST /admin/model/upload` | `.joblib`, ditambah `label_map.json` dan `metrics.json` opsional |

Aturan pengelolaan model:

- Model yang jumlah fiturnya bukan 127, atau yang tidak punya `predict_proba`, ditolak.
- Mengaktifkan versi model langsung memuat ulang model tanpa restart, dan pilihan itu tetap dipakai setelah server dijalankan ulang.
- Model yang sedang aktif tidak bisa dihapus.

Training tetap dijalankan dari terminal, karena melatih model di dalam request akan memblokir server:

```bash
python ml/src/training/train_svm.py
```

Setelah training selesai, unggah `svm_rbf_bisindo.joblib` di halaman Model, lalu tekan Aktifkan.

## Deploy

### Render dan Neon (gratis)

`render.yaml` di akar repo berisi pengaturan service: Docker, region Singapura, paket gratis, health check `/api/status`, dan variabel lingkungan.

1. Buat database di [Neon](https://console.neon.tech) dengan region Singapura, lalu salin connection string-nya.
2. Di [Render](https://dashboard.render.com/blueprints), pilih **New Blueprint Instance**, lalu pilih repo ini.
3. Isi `DATABASE_URL` dengan connection string Neon dan `ADMIN_PASSWORD` dengan password baru, lalu klik **Apply**.
4. Setelah deploy selesai, buka `https://<nama-service>.onrender.com/api/status`.

Paket gratis Render tertidur setelah 15 menit tanpa request dan butuh sekitar satu menit untuk bangun. Buka `/api/status` sebelum demo. Berkas yang diunggah lewat panel admin hilang setiap restart, jadi ganti model lewat commit ke `ml/models/`.

### Docker

```bash
docker build -t bisindo-api .
docker run -p 8000:8000 bisindo-api
```

`Procfile` disediakan untuk platform seperti Heroku. Docker maupun Procfile menjalankan `gunicorn` dengan satu worker, supaya model yang diaktifkan lewat panel admin sama di semua request.

Filesystem container dihapus setiap kali redeploy, jadi siapkan:

1. **`DATABASE_URL`** yang mengarah ke Postgres. Awalan `postgres://` otomatis diubah menjadi `postgresql://`. Tanpa variabel ini, riwayat ikut hilang setiap redeploy.
2. **Volume persisten** untuk `INSTANCE_DIR`, atau pasang volume ke `/app/web/instance`, supaya dataset dan model hasil unggahan tidak hilang.
3. **Nilai acak** untuk `SECRET_KEY` dan `ADMIN_PASSWORD`, serta `REQUIRE_FIREBASE_AUTH=1`.
