# Pembagian Scope Pengerjaan — BisindoVision

Setiap anggota mengerjakan tiga bagian sekaligus: aplikasi mobile (Flutter), backend web (Flask), dan machine learning (ML). Pembagian ini dibuat supaya tidak ada yang kerjanya sama atau tabrakan.

---

## Aryaputra Ferdiananta

**Mobile**
Mengerjakan halaman Kamus BISINDO. Isinya daftar 26 huruf alfabet beserta foto atau ilustrasi cara memperagakannya. Ada juga halaman detail untuk tiap huruf. Halaman ini bisa dibuka tanpa koneksi internet.

**Web Flask**
Membuat endpoint untuk data kamus.
- `GET /api/dictionary` untuk mengambil seluruh daftar huruf
- `GET /api/dictionary/<huruf>` untuk mengambil detail satu huruf tertentu

**ML**
Mengurus konversi model yang sudah selesai dilatih ke format TFLite. Setelah dikonversi, diuji dulu apakah hasil prediksinya masih sama dengan model aslinya.

---

## Fadhil Taufiqurrachman

**Mobile**
Mengerjakan halaman Onboarding, Login, dan Register. Termasuk form login dengan validasi, form register lengkap, dan koneksi ke Firebase Auth supaya sesi pengguna bisa tersimpan.

**Web Flask**
Membuat endpoint untuk autentikasi.
- `POST /api/auth/register` untuk mendaftarkan pengguna baru
- `POST /api/auth/login` untuk login dan mendapatkan token
- `GET /api/auth/me` untuk mengambil data pengguna yang sedang aktif

**ML**
Menjalankan MediaPipe Hand Landmarker ke seluruh foto di dataset. Hasilnya berupa 21 titik koordinat per foto yang sudah dinormalisasi, lalu disimpan ke file CSV atau NPY sebagai bahan training model.

---

## M. Aldyth Rafiansyah Fauzi

**Mobile**
Mengerjakan halaman Scan atau kamera deteksi. Preview kamera berjalan langsung, MediaPipe dan model TFLite diintegrasikan ke Flutter, dan huruf hasil deteksi beserta nilai confidence-nya tampil di layar. Ada juga tombol spasi, hapus, dan reset teks.

**Web Flask**
Membuat endpoint untuk prediksi model.
- `POST /api/predict` menerima data 21 titik landmark, lalu mengembalikan huruf yang diprediksi beserta nilai confidence-nya. Endpoint ini berguna untuk menguji model tanpa harus buka aplikasi.

**ML**
Merancang dan melatih model classifier menggunakan data landmark yang sudah diekstrak. Menyimpan model hasil training dan mencatat grafik loss serta akurasi selama proses training.

---

## Mohammad Al Hafis Hidayatulloh

**Mobile**
Mengerjakan halaman Beranda dan keseluruhan sistem navigasi. Termasuk setup go_router untuk routing 7 layar, bottom navigation bar, dan proses build serta rilis file APK.

**Web Flask**
Membuat halaman admin sederhana berbasis web.
- `/admin/dashboard` menampilkan statistik singkat
- `/admin/users` menampilkan daftar pengguna yang terdaftar
- `/admin/logs` menampilkan log aktivitas deteksi

**ML**
Mengevaluasi model yang sudah dilatih. Menghitung accuracy, precision, recall, dan F1-score untuk setiap kelas huruf, membuat confusion matrix 26x26, dan menganalisis huruf mana yang paling sering salah terdeteksi. Hasilnya didokumentasikan lengkap dengan grafik.

---

## Mokhamad Rizki Hadiono Singgih

**Mobile**
Mengerjakan halaman Riwayat dan Profil. Di halaman Riwayat ada tampilan daftar hasil deteksi beserta waktu, fitur hapus satu item, dan hapus semua. Di halaman Profil ada data pengguna dan tombol logout. Selain itu juga mengurus setup Riverpod untuk state management dan sqflite untuk database lokal.

**Web Flask**
Membuat endpoint untuk riwayat dan profil pengguna.
- `GET /api/history` dan `POST /api/history` untuk membaca dan menyimpan riwayat
- `DELETE /api/history/<id>` untuk menghapus satu entri
- `DELETE /api/history` untuk menghapus semua riwayat
- `GET /api/profile` dan `PUT /api/profile` untuk membaca dan mengubah data profil

**ML**
Mencari dan mengunduh dataset BISINDO dari Kaggle yang berisi foto tangan 26 kelas alfabet. Setelah diunduh, dicek kelengkapan dan kualitasnya, foto yang tidak layak dibuang, lalu dataset dibagi ke folder train dan test dengan rasio 80:20. Jumlah sampel per kelas sebelum dan sesudah pembersihan dicatat.

---

## Ringkasan

| Anggota | Mobile | Flask | ML |
|---|---|---|---|
| Aryaputra | Kamus BISINDO | /api/dictionary | Konversi model ke TFLite |
| Fadhil | Login, Register, Onboarding | /api/auth | Ekstraksi landmark MediaPipe |
| Aldyth | Scan, Kamera, Deteksi | /api/predict | Training model classifier |
| Hafis | Beranda, Router, APK | Admin Dashboard | Evaluasi model dan confusion matrix |
| Rizki | Riwayat, Profil, Riverpod, sqflite | /api/history, /api/profile | Download dan cleaning dataset |
