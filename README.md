# BISINDO Translator

Aplikasi mobile untuk menerjemahkan Bahasa Isyarat Indonesia (BISINDO) secara real-time melalui kamera smartphone.

Aplikasi ini dikembangkan sebagai proyek mata kuliah (Project Based Learning) untuk memfasilitasi komunikasi bagi komunitas tunarungu.

## Status Pengembangan Proyek

Proyek ini sedang dalam tahap pengembangan aktif dengan estimasi progres keseluruhan mencapai **55%**.

### Ringkasan per Komponen

| Komponen | Status | Penyelesaian | Deskripsi |
| :--- | :--- | :---: | :--- |
| Mobile (Flutter) | Dalam Pengembangan | 85% | Alur UI, sistem navigasi, autentikasi Firebase, kamus BISINDO, dan riwayat selesai. Menunggu integrasi model TFLite secara on-device. |
| Web Dashboard & API | Dalam Pengembangan | 45% | Dashboard admin, endpoint riwayat, dan endpoint profil selesai. Menunggu integrasi pemanggilan API dari aplikasi mobile. |
| Machine Learning | Dalam Pengembangan | 65% | Model SVM RBF selesai dilatih dengan akurasi 97,91% pada 127 fitur landmark dan tersimpan sebagai artefak `joblib`. Sisa pekerjaan: penyajian model lewat web API dan konversi TFLite untuk mobile. |

### Pembagian Tugas dan Status Tim

| Anggota Tim | Fokus Tugas | Referensi Task | Progres |
| :--- | :--- | :--- | :---: |
| Aryaputra Ferdiananta | Modul Kamus BISINDO & Konversi Model TFLite | [Issue #1](https://github.com/hafisc/bisindo/issues/1) | 38% |
| Fadhil Taufiqurrachman | Modul Autentikasi & Pipeline Dataset MediaPipe | [Issue #2](https://github.com/hafisc/bisindo/issues/2) | 63% |
| M. Aldyth Rafiansyah Fauzi | Antarmuka Scan Kamera & Training Model Klasifikasi | [Issue #3](https://github.com/hafisc/bisindo/issues/3) | 70% |
| Mohammad Al Hafis H. | Halaman Beranda, Dashboard Admin, & Evaluasi Model | [Issue #4](https://github.com/hafisc/bisindo/issues/4) | 64% |
| Mokhamad Rizki Hadiono S. | Riwayat Deteksi, Manajemen Profil, & Pengumpulan Data | [Issue #5](https://github.com/hafisc/bisindo/issues/5) | 75% |

## Daftar Fitur

- Scanner Real-time: Mendeteksi gestur tangan dan menerjemahkannya secara langsung.
- Text-to-Speech: Mengubah hasil deteksi teks menjadi output suara.
- Kamus BISINDO: Daftar referensi peragaan abjad (A-Z) dan kosa kata umum.
- Mode Belajar: Fasilitas latihan mandiri dengan umpan balik langsung.
- Riwayat Terjemahan: Menyimpan log hasil terjemahan sebelumnya.
- Manajemen Akun: Pendaftaran dan pengaturan profil pengguna.

## Preview Aplikasi

- Onboarding
  ![Onboarding](design/onboarding%201-2%20dan%203.png)
- Login & Register
  ![Login dan Register](design/login-register.png)

## Struktur Repositori

Proyek ini menggunakan struktur monorepo yang memisahkan bagian mobile, machine learning, dan web:

- `mobile/`: Berisi kode sumber aplikasi berbasis Flutter.
- `ml/`: Berisi pipeline Machine Learning menggunakan Python (dataset, notebook, script training).
- `design/`: Berisi aset desain dan mockup aplikasi.
- `web/`: Berisi kode sumber dashboard admin menggunakan Flask.

## Teknologi yang Digunakan

Aplikasi Mobile:
- Framework: Flutter 3.32 (Dart 3.8)
- State Management: BLoC + Equatable
- Routing: GoRouter
- Dependency Injection: GetIt + Injectable
- Layanan Cloud: Firebase (Auth, Firestore, Storage)
- Local Database: Hive
- Text-to-Speech: flutter_tts

Machine Learning:
- Bahasa: Python 3.12
- Model: SVM kernel RBF (scikit-learn), 127 fitur landmark
- Akurasi data uji: 97,91%
- Ekstraksi Fitur: MediaPipe
- Inferensi Mobile: TFLite Flutter

Web Dashboard:
- Framework: Flask (Python)

## REST API (Web)

Server Flask menyediakan endpoint JSON untuk aplikasi mobile. Semua endpoint
riwayat memakai header `X-User-Id` berisi Firebase UID pengguna yang sudah
login. Sebagai alternatif, UID boleh dikirim lewat query string `user_id` atau
field `user_id` di body JSON.

| Method | Endpoint | Keterangan |
| :--- | :--- | :--- |
| GET | `/api/status` | Status layanan dan kesiapan model prediksi |
| POST | `/api/predict` | Prediksi huruf BISINDO dari 21 titik landmark tangan |
| GET | `/api/dictionary` | Daftar seluruh huruf kamus BISINDO |
| GET | `/api/dictionary/<huruf>` | Detail satu huruf kamus |
| GET | `/api/history` | Riwayat deteksi milik pengguna, terbaru lebih dulu |
| POST | `/api/history` | Simpan satu entri riwayat baru |
| DELETE | `/api/history/<id>` | Hapus satu entri riwayat |
| DELETE | `/api/history` | Hapus seluruh riwayat pengguna |
| GET | `/api/profile` | Ambil profil pengguna |
| PUT | `/api/profile` | Buat atau perbarui profil pengguna |

Contoh menyimpan riwayat:

```bash
curl -X POST http://127.0.0.1:5000/api/history \
  -H "Content-Type: application/json" \
  -H "X-User-Id: <firebase-uid>" \
  -d '{
    "title": "Halo",
    "type": "Kata",
    "category": "Teks",
    "mode": "BISINDO -> Teks",
    "confidence": 0.95,
    "timestamp": "2026-11-11T10:20:00"
  }'
```

Nilai `type` yang diterima adalah `Kata` atau `Huruf`, sedangkan `category`
adalah `Teks` atau `Suara`. Field `confidence` harus di antara 0.0 dan 1.0.
Field `timestamp` bersifat opsional; bila kosong, server memakai waktu saat
request diterima.

Contoh sinkronisasi profil setelah login:

```bash
curl -X PUT http://127.0.0.1:5000/api/profile \
  -H "Content-Type: application/json" \
  -H "X-User-Id: <firebase-uid>" \
  -d '{
    "name": "Budi Santoso",
    "email": "budi@mail.com",
    "student_id": "2210512001",
    "role": "Mahasiswa"
  }'
```

`PUT /api/profile` bersifat upsert: panggilan pertama membuat baris pengguna
dan membalas 201, panggilan berikutnya memperbarui field yang dikirim saja dan
membalas 200. Field `name` dan `email` wajib pada panggilan pertama. Mengirim
string kosong pada `student_id`, `role`, atau `avatar_url` akan mengosongkan
nilai tersebut.

Endpoint riwayat dan profil memakai header `X-User-Id` yang belum diverifikasi
tanda tangannya. Peningkatan ke verifikasi Firebase ID token dapat ditambahkan
kemudian memakai `firebase-admin`.

### Menjalankan test web

```bash
cd web/
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
pytest
```

## Panduan Instalasi dan Penggunaan

### Persyaratan Sistem
- Flutter SDK (Minimal versi 3.32)
- Dart SDK (Minimal versi 3.8)
- Python (Minimal versi 3.10)
- Android Studio atau VSCode
- Git

### 1. Clone Repositori
```bash
git clone https://github.com/hafisc/bisindo.git
cd bisindo
```

### 2. Konfigurasi Firebase (Wajib)
Langkah ini diperlukan agar aplikasi dapat berjalan dengan normal:
1. Buat proyek baru bernama `bisindo-translator` di Firebase Console.
2. Tambahkan aplikasi Android dengan package name `com.bisindo.bisindo_translator`.
3. Unduh file `google-services.json` dan letakkan di dalam direktori `mobile/android/app/`.
4. Aktifkan layanan Authentication (Email/Password & Google Sign-In) dan Firestore Database.

### 3. Menjalankan Aplikasi Mobile
```bash
cd mobile/
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 4. Konfigurasi Environment Machine Learning
```bash
cd ml/
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Alur Navigasi Aplikasi

1. Splash Screen
2. Onboarding (Hanya muncul saat pertama kali dibuka)
3. Login / Register
4. Halaman Utama (Beranda)
   - Menu Scanner
   - Menu Kamus
   - Menu Riwayat
   - Menu Profil

## Pipeline Machine Learning

Alur kerja pelatihan model hingga siap digunakan di aplikasi:
1. `ml/src/dataset/data_loader.py`: Membaca CSV landmark, menyusun 127 fitur, lalu membagi data latih dan uji.
2. `ml/src/training/train_svm.py`: Melatih SVM RBF dan menyimpan `svm_rbf_bisindo.joblib`, `label_map.json`, serta `metrics.json`.
3. `ml/src/evaluation/evaluate_svm.py`: Menghitung akurasi, confusion matrix, F1 per kelas, dan membandingkan kernel linear, polynomial, dan RBF.
4. `ml/tests/test_svm.py`: Memastikan susunan fitur, pemuatan dataset, dan artefak model tetap konsisten.

Detail lengkap ada di [`ml/README.md`](ml/README.md).

## Daftar Perintah Penting

Perintah Flutter:
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

Perintah Python (ML):
```bash
pip install -r ml/requirements.txt
python ml/src/training/train_svm.py
python ml/src/evaluation/evaluate_svm.py --compare
python -m pytest ml/tests -q
```
