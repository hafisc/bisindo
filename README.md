# BISINDO Translator

Aplikasi mobile untuk menerjemahkan Bahasa Isyarat Indonesia (BISINDO) secara real-time melalui kamera smartphone.

Aplikasi ini dikembangkan sebagai proyek mata kuliah (Project Based Learning) untuk memfasilitasi komunikasi bagi komunitas tunarungu.

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
- Bahasa: Python 3.10
- Framework: TensorFlow
- Ekstraksi Fitur: MediaPipe
- Inferensi Mobile: TFLite Flutter

Web Dashboard:
- Framework: Flask (Python)

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
1. `collect_data.py`: Pengumpulan gambar tangan per kelas.
2. `augment.py`: Proses augmentasi dataset (rotasi, flip, potong).
3. `train.py`: Pelatihan model CNN memanfaatkan landmark dari MediaPipe.
4. `evaluate.py`: Pengujian akurasi model.
5. `export_tflite.py`: Konversi model menjadi format `.tflite` untuk digunakan pada aplikasi mobile.

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
pip install -r requirements.txt
python src/dataset/collect_data.py
python src/training/train.py
python src/export/export_tflite.py
```
