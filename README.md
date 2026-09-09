# BISINDO Translator

> Aplikasi mobile penerjemah Bahasa Isyarat Indonesia (BISINDO) berbasis AI secara real-time.

---

## Struktur Monorepo

```
bisindo-translator/
├── mobile/     # Flutter app (Android-first)
├── ml/         # Python ML pipeline
└── design/     # Design assets
```

---

## Prasyarat

| Tool | Versi Minimum |
|---|---|
| Flutter | 3.32.x |
| Dart | 3.8.x |
| Python | 3.10+ |
| Android Studio | Hedgehog+ |

---

## Quick Start

### Mobile (Flutter)

```bash
cd mobile/

# Install dependencies
flutter pub get

# Generate code (DI, models, etc.)
dart run build_runner build --delete-conflicting-outputs

# Jalankan di device/emulator
flutter run
```

> ⚠️ Sebelum menjalankan, tambahkan `google-services.json` dari Firebase Console ke `mobile/android/app/`

### ML Pipeline (Python)

```bash
cd ml/

# Buat virtual environment
python -m venv .venv
.venv\Scripts\activate      # Windows
# source .venv/bin/activate  # Mac/Linux

# Install dependencies
pip install -r requirements.txt

# Jalankan notebook eksplorasi
jupyter notebook notebooks/
```

---

## Setup Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Buat project baru → `bisindo-translator`
3. Tambahkan Android app dengan package name: `com.bisindo.bisindo_translator`
4. Download `google-services.json` → taruh di `mobile/android/app/`
5. Enable **Authentication** (Email/Password)
6. Enable **Cloud Firestore**

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Mobile | Flutter 3.32 |
| State Management | BLoC + Equatable |
| Navigation | GoRouter |
| DI | GetIt + Injectable |
| Backend/Auth | Firebase (Auth, Firestore, Storage) |
| Local DB | Hive |
| ML (Training) | Python + TensorFlow + MediaPipe |
| ML (Inference) | TFLite Flutter |
| TTS | flutter_tts |

---

## Kontribusi & Pembagian Kerja

| Tim | Fokus |
|---|---|
| Tim ML | `ml/` — dataset, training, export TFLite |
| Tim Mobile | `mobile/` — UI, integrasi model, auth |

---

## Lisensi

Proyek ini dikembangkan untuk keperluan PBL (Project-Based Learning).
