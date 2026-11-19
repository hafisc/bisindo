# BISINDO Translator: Aplikasi Mobile

Aplikasi Flutter untuk scan, belajar, dan kamus BISINDO. Petunjuk umum proyek ada di [README utama](../README.md).

## Menjalankan

```bash
flutter pub get
flutter run
```

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

## Firestore untuk Profil

Data profil (nama, NIM, peran, tanggal bergabung, dan foto) disimpan di dokumen `users/{uid}`. Foto dikecilkan ke 256 px lalu disimpan di dokumen yang sama, jadi Cloud Storage dan paket Blaze tidak diperlukan.

Satu kali per project Firebase:

1. Firebase Console, **Build > Firestore Database > Create database**, pilih lokasi `asia-southeast2` (Jakarta), mode production.
2. Buka tab **Rules**, ganti isinya dengan aturan berikut, lalu **Publish**:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```

Selama Firestore belum aktif, nama dan email tetap tampil dari Firebase Auth, tetapi NIM, peran, dan foto tidak bisa disimpan, dan halaman Profil menampilkan pesan "Gagal memuat profil dari server."

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
   flutter build apk --release
   ```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`. Bila `key.properties` tidak ada, Gradle memakai kunci debug, dan APK seperti itu jangan dirilis.

### Login Google dan sidik jari sertifikat

Google menolak login dengan `ApiException: 10` bila sertifikat APK yang sedang berjalan belum terdaftar di Firebase. Yang diperiksa adalah **sertifikat APK**, bukan isi `google-services.json`. Karena itu APK debug juga butuh pendaftaran sendiri, dan tiap komputer punya kunci debug berbeda.

Cek sidik jari APK yang benar-benar terpasang:

```bash
# Windows, ganti versi build-tools sesuai yang terpasang
%LOCALAPPDATA%\Android\Sdk\build-tools\36.0.0\apksigner.bat verify --print-certs ^
  build\app\outputs\flutter-apk\app-debug.apk
```

Untuk keystore, sidik jari bisa dilihat dengan:

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey
```

Langkah pendaftaran:

1. Firebase Console, **Project settings**, tab **Your apps**, pilih aplikasi Android `com.bisindo.bisindo_translator`.
2. **Add fingerprint**, tempel SHA-1 hasil perintah di atas. Tambahkan juga SHA-256 bila perlu.
3. Tunggu sekitar lima menit. Perubahan ini berlaku di sisi Google, jadi APK yang sudah terpasang tidak perlu dibangun ulang.
4. Bila masih gagal, unduh ulang `google-services.json` dari halaman yang sama, timpa `android/app/google-services.json`, lalu build ulang.

Satu aplikasi Android boleh punya beberapa sidik jari, jadi sidik jari debug tiap anggota tim dan sidik jari keystore release bisa terdaftar bersamaan. Untuk rilis lewat Play Store dengan Play App Signing, yang didaftarkan adalah SHA-1 dari Play Console, bukan keystore lokal.

### Login Google saat bekerja dalam tim

Yang diperiksa Google adalah sertifikat **berkas APK**, bukan akun Google yang dipakai login. Jadi akun Google siapa pun bisa masuk tanpa didaftarkan, asalkan APK-nya bertanda tangan kunci yang sudah terdaftar.

Setiap komputer membuat `~/.android/debug.keystore` sendiri saat build pertama, dan isinya acak. Karena itu teman yang menjalankan `flutter run` di laptopnya akan terkena `ApiException: 10` walaupun di laptop lain login berjalan normal.

| Cara teman memakai aplikasi | Perlu tambah sidik jari? |
| :--- | :--- |
| Menerima berkas APK lalu memasangnya sendiri | Tidak, sertifikat ikut di dalam APK |
| Memakai HP atau emulator milik orang lain | Tidak |
| `flutter run` atau build sendiri di laptopnya | Ya, sidik jari laptopnya harus didaftarkan |

Tiga cara bekerja bersama:

**Bagikan berkas APK.** Cara tercepat untuk demo. Build sekali, kirim `build/app/outputs/flutter-apk/app-debug.apk`, lalu mereka pasang. Setiap kode berubah, APK harus dibagikan ulang.

**Daftarkan sidik jari tiap anggota.** Cocok saat beberapa orang mengembangkan aplikasi bersamaan. Tiap anggota menjalankan perintah `keytool` di atas, lalu hasilnya ditambahkan lewat **Add fingerprint**. Firebase tidak membatasi jumlah sidik jari, jadi 5 anggota berarti 5 baris SHA-1. Bila `debug.keystore` belum ada, jalankan `flutter build apk --debug` sekali supaya berkasnya terbentuk.

**Satu keystore release bersama.** Paling rapi untuk jangka panjang. Buat satu keystore, simpan di luar repo, bagikan lewat kanal privat, lalu tiap anggota menaruh `key.properties` di `android/`. Daftarkan SHA-1 keystore itu sekali, dan semua build release menghasilkan sertifikat identik. Jangan commit `key.properties`, `*.jks`, atau `*.keystore`; ketiganya sudah diblokir `android/.gitignore`.

**R8.** Build release memakai R8. Aturan keep MediaPipe ada di `android/app/proguard-rules.pro`. Tanpa aturan itu, layar Scan crash karena nama kelas MediaPipe ikut diubah.
