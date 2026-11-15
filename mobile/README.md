# BISINDO Translator: Aplikasi Mobile

Aplikasi Flutter untuk scan, belajar, dan kamus BISINDO. Petunjuk umum proyek ada di [README utama](../README.md).

## Menjalankan

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

- `build_runner` membuat `lib/core/di/injection.config.dart`. File ini tidak masuk git, jadi wajib dijalankan ulang setiap selesai pull.
- `google-services.json` harus ada di `android/app/`.
- Fitur Scan dan Mode Belajar butuh HP Android asli, karena emulator x86_64 tidak punya MediaPipe native.

## Struktur Kode

```
lib/
├── core/              Konfigurasi bersama: router, tema, DI, konstanta, database lokal
└── features/
    ├── auth/          Onboarding, login, register, verifikasi email, syarat dan privasi
    ├── home/          Beranda, bottom navigation, notifikasi
    ├── scan/          Kamera, MediaPipe, kirim landmark ke server, TTS
    ├── learn/         Mode Belajar
    ├── dictionary/    Kamus, ilustrasi pose, favorit
    ├── history/       Riwayat deteksi
    └── profile/       Profil, avatar, ganti password, hapus akun
```

Isi tiap fitur dibagi ke tiga lapisan: `data/` untuk sumber data dan repository, `domain/` untuk model dan use case, serta `presentation/` untuk halaman, widget, dan provider Riverpod. Fitur yang sederhana, seperti `home/`, cukup memakai `presentation/` saja. Susunan folder di `test/` mengikuti susunan yang sama.

## Alamat Server

Alamat server tidak ditulis di dalam kode. Ada dua cara mengaturnya:

| Cara | Contoh |
| :--- | :--- |
| Lewat kabel USB (bawaan `http://127.0.0.1:5000`) | `adb reverse tcp:5000 tcp:5000`. Ulangi setiap kabel dicabut atau HP di-reboot |
| Saat build | `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000` |
| Saat aplikasi berjalan | Ikon gerigi di kanan atas layar Scan, lalu isi alamat yang dicetak `python web/run.py` |

Semua build, termasuk release, mengizinkan HTTP polos lewat `android/app/src/main/res/xml/network_security_config.xml`, karena server demo berjalan di laptop tanpa HTTPS. Setelah server memakai HTTPS, ubah `cleartextTrafficPermitted` menjadi `false`.

## Build APK Release

APK release ditandatangani dengan keystore tim. Keystore dan password-nya tidak masuk repo, jadi minta file `.jks` dan isi `key.properties` ke anggota yang memegangnya.

1. Simpan keystore di luar folder repo, misalnya `C:\Users\<nama>\keystores\bisindo-release.jks`.
2. Buat `android/key.properties` (sudah di-ignore git):

   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=bisindo
   storeFile=C:/Users/<nama>/keystores/bisindo-release.jks
   ```

3. Build dari awal supaya tidak memakai hasil build lama:

   ```bash
   flutter clean
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter build apk --release
   ```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`. Bila `key.properties` tidak ada, Gradle memakai kunci debug, dan APK seperti itu jangan dirilis.

**Login Google** di APK release baru berjalan setelah SHA-1 keystore didaftarkan di Firebase Console (Project settings, aplikasi Android, Add fingerprint), lalu `google-services.json` diunduh ulang. SHA-1 bisa dilihat dengan:

```bash
keytool -list -v -keystore <path-keystore> -alias bisindo
```

**R8.** Build release memakai R8. Aturan keep MediaPipe ada di `android/app/proguard-rules.pro`. Tanpa aturan itu, layar Scan crash karena nama kelas MediaPipe ikut diubah.
