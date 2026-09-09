<div align="center">
  <img src="design/login-register.png" alt="BISINDO Translator Logo" width="80"/>
  <h1>BISINDO Translator</h1>
  <p><strong>Jembatan komunikasi untuk semua.</strong></p>
  <p>Aplikasi mobile penerjemah Bahasa Isyarat Indonesia (BISINDO) berbasis AI secara real-time.</p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.32.x-02569B?logo=flutter)
  ![Dart](https://img.shields.io/badge/Dart-3.8.x-0175C2?logo=dart)
  ![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python)
  ![TensorFlow](https://img.shields.io/badge/TensorFlow-2.21-FF6F00?logo=tensorflow)
  ![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)
  ![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)
</div>

---

## 📖 Tentang Aplikasi

**BISINDO Translator** adalah aplikasi mobile yang memungkinkan pengguna untuk menerjemahkan gestur tangan Bahasa Isyarat Indonesia (BISINDO) menjadi teks dan suara secara real-time menggunakan kamera HP.

Aplikasi ini dikembangkan sebagai proyek PBL (Project-Based Learning) dengan tujuan meningkatkan aksesibilitas komunikasi bagi komunitas tunarungu di Indonesia.

### ✨ Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 🎯 **Real-time Scanner** | Arahkan kamera ke tangan → gestur terdeteksi otomatis |
| 🔊 **Text-to-Speech** | Hasil deteksi langsung disuarakan |
| 📚 **Kamus BISINDO** | Daftar lengkap gestur huruf A–Z dan kata umum |
| 🎓 **Mode Belajar** | Latihan gestur satu per satu dengan feedback |
| 📋 **Riwayat Translasi** | Simpan dan lihat kembali hasil terjemahan |
| 👤 **Akun Pengguna** | Login, register, dan kelola profil |

---

## 🖼️ Preview Aplikasi

### Onboarding

![Onboarding Screens](design/onboarding%201-2%20dan%203.png)

### Login & Register

![Login Register Screens](design/login-register.png)

---

## 🏗️ Struktur Monorepo

```
bisindo-translator/
├── mobile/          # 📱 Flutter App (Android-first)
│   ├── lib/
│   │   ├── core/            # Tema, router, DI, error handling
│   │   ├── features/        # Auth, Scanner, Dictionary, History, Profile
│   │   └── shared/          # Widget & service yang dipakai bersama
│   └── assets/              # Gambar, model TFLite, animasi, font
├── ml/              # 🤖 Python ML Pipeline
│   ├── data/                # Dataset raw & processed
│   ├── notebooks/           # Eksplorasi Jupyter
│   ├── src/                 # Script dataset, training, evaluasi, export
│   └── models/              # Output model (.h5 dan .tflite)
└── design/          # 🎨 Asset desain (mockup, color palette)
```

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| 📱 Mobile | Flutter 3.32 (Dart 3.8) |
| 🧠 State Management | BLoC + Equatable |
| 🗺️ Navigasi | GoRouter |
| 💉 Dependency Injection | GetIt + Injectable |
| 🔐 Auth | Firebase Authentication |
| 🗄️ Database | Cloud Firestore + Hive (lokal) |
| 📦 Storage | Firebase Storage |
| 🤖 ML Training | Python + TensorFlow + MediaPipe |
| ⚡ ML Inference | TFLite Flutter |
| 🔊 Text-to-Speech | flutter_tts |

---

## 🚀 Quick Start

### Prasyarat

Pastikan tools berikut sudah terinstall:

| Tool | Versi | Cek |
|---|---|---|
| Flutter | ≥ 3.32.x | `flutter --version` |
| Dart | ≥ 3.8.x | `dart --version` |
| Python | ≥ 3.10 | `python --version` |
| Android Studio | Hedgehog+ | — |
| Git | — | `git --version` |

### 1. Clone Repository

```bash
git clone https://github.com/<username>/bisindo-translator.git
cd bisindo-translator
```

### 2. Setup Firebase

> ⚠️ **Wajib dilakukan sebelum menjalankan app!**

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Buat project → **bisindo-translator**
3. Tambah Android app → package: `com.bisindo.bisindo_translator`
4. Download `google-services.json` → taruh di `mobile/android/app/`
5. Aktifkan **Authentication** → Email/Password + Google Sign-In
6. Aktifkan **Cloud Firestore** → mode test

### 3. Jalankan Flutter App

```bash
cd mobile/

# Install dependencies
flutter pub get

# Generate code (DI, freezed models, dll)
dart run build_runner build --delete-conflicting-outputs

# Jalankan di device/emulator
flutter run
```

### 4. Setup ML Pipeline (Tim ML)

```bash
cd ml/

# Buat virtual environment
python -m venv .venv

# Aktifkan venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Mac/Linux

# Install dependencies
pip install -r requirements.txt

# Buka notebook eksplorasi
jupyter notebook notebooks/
```

---

## 📱 Alur Aplikasi

```
Splash Screen
    ↓
Onboarding (3 slide — tampil sekali saat install)
    ↓
Login / Register ←→ Lupa Password
    ↓
Beranda (Home)
    ├── 🎯 Scan     → Real-time gesture detection + TTS
    ├── 📚 Kamus    → Daftar gestur BISINDO (A-Z + kata)
    ├── 📋 Riwayat  → History hasil terjemahan
    └── 👤 Profil   → Edit akun + pengaturan
```

---

## 🤖 ML Pipeline

```
1. collect_data.py   → Capture foto tangan per kelas (A-Z, kata)
2. augment.py        → Augmentasi: flip, rotate, crop (100 → 500+ foto)
3. train.py          → Training CNN + MediaPipe hand landmarks
4. evaluate.py       → Confusion matrix + accuracy metrics
5. export_tflite.py  → Konversi ke .tflite
6.                   → Copy ke mobile/assets/models/
```

**Target dataset:** 26 huruf × 100 foto = **2.600 data** (expandable dengan augmentasi)

---

## 👥 Pembagian Tim

| Tim | Tanggung Jawab | Folder |
|---|---|---|
| 🤖 Tim ML | Kumpul dataset, training, export model | `ml/` |
| 📱 Tim Mobile | UI Flutter, integrasi model, auth | `mobile/` |

---

## 📋 Development Commands

```bash
# Flutter
flutter pub get                                        # Install packages
dart run build_runner build --delete-conflicting-outputs  # Generate code
flutter analyze                                        # Static analysis
flutter test                                           # Run tests
flutter build apk --release                            # Build APK release

# Python ML
pip install -r requirements.txt                        # Install packages
jupyter notebook                                       # Buka Jupyter
python src/dataset/collect_data.py                     # Kumpul data
python src/training/train.py                           # Training model
python src/export/export_tflite.py                     # Export TFLite
```

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan **PBL (Project-Based Learning)**.

---

<div align="center">
  <p>Made with ❤️ for inclusive communication</p>
  <p><em>BISINDO — Bahasa Isyarat Indonesia</em></p>
</div>
