<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="design/logo-dark.png">
  <img src="design/logo-light.png" alt="BISINDO Translator" width="320">
</picture>

<h3>Penerjemah Bahasa Isyarat Indonesia secara real-time lewat kamera HP</h3>

[![Flutter](https://img.shields.io/badge/Flutter-3.32-02569B?style=flat-square&logo=flutter&logoColor=white)](mobile/README.md)
[![Flask](https://img.shields.io/badge/Flask-REST%20API-000000?style=flat-square&logo=flask&logoColor=white)](web/README.md)
[![Model](https://img.shields.io/badge/SVM%20RBF-akurasi%2086%2C6%25%20%28frame%20HP%29-F7931E?style=flat-square&logo=scikitlearn&logoColor=white)](ml/README.md)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Release](https://img.shields.io/github/v/release/hafisc/bisindo?include_prereleases&style=flat-square&label=APK&color=2563EB)](https://github.com/hafisc/bisindo/releases)

Project Based Learning Semester 5, Kelompok 1

[Fitur](#fitur) &nbsp;·&nbsp; [Cara Kerja](#cara-kerja) &nbsp;·&nbsp; [Menjalankan](#menjalankan) &nbsp;·&nbsp; [Dokumentasi](#dokumentasi) &nbsp;·&nbsp; [Tim](#tim)

<br>
</div>

## Tentang

Banyak orang ingin berkomunikasi dengan teman tuli tetapi belum menguasai bahasa isyarat. BISINDO Translator mengenali huruf BISINDO yang diperagakan di depan kamera, lalu menampilkannya sebagai teks dan membacakannya dengan suara. Aplikasi ini juga menyediakan kamus dan mode belajar untuk berlatih.

## Fitur

| Fitur | Fungsi |
| :--- | :--- |
| **Scan real-time** | Mengenali huruf A-Z dari kamera, lalu menampilkan dan membacakannya |
| **Mode Belajar** | Latihan memperagakan huruf acak dengan skor |
| **Kamus** | Ilustrasi huruf A-Z yang diambil dari peragaan asli di dataset |
| **Favorit** | Menyimpan huruf yang sering dilatih |
| **Riwayat** | Hasil terjemahan tersimpan per akun dan tersinkron ke server |
| **Akun** | Login email atau Google, verifikasi email, edit profil dan foto |
| **Panel Admin** | Web untuk mengelola pengguna, log deteksi, dataset, dan versi model |

## Cara Kerja

```mermaid
flowchart LR
    A["Kamera HP"] --> B["MediaPipe<br/>titik tangan"]
    B -- "21 atau 42 titik" --> C["Server Flask<br/>/api/predict"]
    C --> D["Model SVM"]
    D -- "huruf" --> E["Aplikasi<br/>teks dan suara"]
```

HP hanya mengirim koordinat titik tangan, bukan gambar kamera. Server menormalkan koordinat menjadi 127 fitur, lalu model SVM (kernel RBF) menebak hurufnya. Model dilatih dari 5.789 foto dan mencapai **akurasi 86,6%** pada foto uji yang belum pernah dilihat model, dinilai dalam bentuk frame kamera HP (rata-rata 5 pembagian per kelompok foto). Alur lengkap dari foto sampai model ada di [ml/README.md](ml/README.md).

| Bagian | Teknologi |
| :--- | :--- |
| Mobile | Flutter, Riverpod, GoRouter, MediaPipe Hand Landmarker, SQLite |
| Backend | Flask, SQLAlchemy, Gunicorn, Docker |
| Machine Learning | Python, scikit-learn, MediaPipe, pandas |
| Layanan | Firebase Auth dan Firestore |

## Menjalankan

Butuh Flutter 3.32 atau lebih baru, Python 3.10 atau lebih baru, dan HP Android asli. Emulator tidak bisa menjalankan MediaPipe.

**1. Jalankan server** dari folder `web/`

```bash
pip install -r requirements.txt
python run.py
```

**2. Jalankan aplikasi** dari folder `mobile/`, dengan HP tersambung lewat USB dan `google-services.json` sudah ada di `mobile/android/app/`

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
adb reverse tcp:5000 tcp:5000
flutter run
```

Pengaturan lain seperti koneksi lewat WiFi, build APK release, dan deploy server ada di [Dokumentasi](#dokumentasi).

## Struktur Repositori

```
bisindo/
├── mobile/   Aplikasi Flutter
├── web/      Server Flask: REST API dan panel admin
├── ml/       Dataset, training, dan evaluasi model
└── design/   Mockup tampilan dan logo
```

## Dokumentasi

| Dokumen | Isi |
| :--- | :--- |
| [mobile/README.md](mobile/README.md) | Struktur kode, alamat server, Firestore, build APK release |
| [web/README.md](web/README.md) | Daftar endpoint API, panel admin, variabel lingkungan, deploy |
| [ml/README.md](ml/README.md) | Dataset, pipeline training, hasil evaluasi model |

Pengujian otomatis: 85 test mobile (`flutter test`), 151 test web (`pytest`), dan 27 test ML.

## Tim

<div align="center">

![Progres](https://img.shields.io/badge/progres%20proyek-100%25-16A34A?style=for-the-badge)

**Pekerjaan dibagi rata.** Setiap anggota memegang satu bagian di aplikasi mobile, server web, dan machine learning, sehingga beban tiap orang sama besar, yaitu 20% dari keseluruhan proyek.

</div>

| Anggota | Mobile | Web | Machine Learning | Progres |
| :--- | :--- | :--- | :--- | :---: |
| Aryaputra Ferdiananta | Kamus BISINDO | API kamus | Konversi model\* | 100% |
| Fadhil Taufiqurrachman | Onboarding, login, register | API autentikasi\* | Ekstraksi landmark MediaPipe | 100% |
| M. Aldyth Rafiansyah Fauzi | Scan kamera | API prediksi | Training model | 100% |
| Mohammad Al Hafis H. | Beranda dan navigasi | Panel admin | Evaluasi model | 100% |
| Mokhamad Rizki Hadiono S. | Riwayat dan profil | API riwayat dan profil | Pengumpulan dan pembersihan dataset | 100% |

<sub>\* Disesuaikan selama pengerjaan: model SVM tidak bisa dikonversi ke TFLite sehingga prediksi dijalankan di server, dan login ditangani langsung oleh Firebase Auth. Progres per 15 November 2026.</sub>
