# ML Pipeline BISINDO

Pipeline pelatihan model klasifikasi huruf BISINDO A-Z dari koordinat
landmark tangan MediaPipe. Model yang dipakai adalah **SVM kernel RBF**,
bukan jaringan saraf.

## Hasil

| Metrik | Nilai |
| :--- | :--- |
| Algoritma | SVM RBF (`C=10.0`, `gamma='scale'`) |
| Akurasi data uji | **96,36%** |
| F1 weighted | 0,9635 |
| Macro F1 | 0,9617 |
| Validasi silang 5 lipat (F1) | 0,9623 +/- 0,0051 |
| Data latih / uji | 5.386 / 1.347 baris (80:20, stratified) |
| Waktu latih | sekitar 3 detik |
| Jumlah fitur | 127 |
| Jumlah kelas | 26 |

Angka lengkap ada di `models/metrics.json` dan `models/evaluation/`. Kelas
terlemah adalah Y (F1 0,89), B (0,90), dan C (0,94). Dari 1.347 data uji ada
49 kesalahan, dan pasangan yang paling sering tertukar adalah B dan E (saling
tertukar dua arah), A terbaca C, K terbaca B, serta M terbaca N.

Model sebelumnya mencapai 97,91% karena dilatih dan diuji pada dataset yang
masih memuat 1.160 baris duplikat (lihat bagian Pembersihan data). Selisih
sekitar 1,5 poin itu adalah efek duplikat yang jatuh ke data latih dan data uji
sekaligus, sehingga 96,36% adalah angka yang lebih jujur. Validasi silang yang
hampir sama dengan akurasi data uji menunjukkan hasilnya stabil.

## Perbandingan kernel

| Kernel | C | Akurasi | F1 weighted |
| :--- | :---: | :---: | :---: |
| RBF | 10.0 | **96,36%** | **0,9635** |
| Linear | 1.0 | 95,25% | 0,9527 |
| Polynomial (degree 3) | 1.0 | 87,68% | 0,8827 |

Setiap kernel memakai nilai C terbaiknya dari eksperimen
`Klasifikasi_Kelompok_1`. Bila `--C` diisi manual, nilai itu berlaku untuk
ketiga kernel.

## Pembersihan data

CSV di repo adalah data mentah hasil ekstraksi MediaPipe dan tidak diubah.
`src/dataset/clean_dataset.py` dijalankan otomatis setiap kali dataset dimuat
lewat `data_loader.load_dataset()`, jadi pelatihan dan evaluasi selalu memakai
data bersih. Aturannya:

| Aturan | Baris dibuang |
| :--- | ---: |
| Nilai NaN atau inf pada fitur | 0 |
| `is_two_handed` tidak sesuai isi tangan 2 | 0 |
| Pergelangan tangan 1 tidak di titik nol, atau jarak ke titik 9 bukan 1 | 0 |
| Landmark identik dengan baris lain (duplikat) | 1.160 |

Tiga aturan pertama tidak menemukan masalah pada dataset sekarang, tetapi tetap
dipasang supaya dataset tambahan yang rusak langsung tersaring. Duplikat
berasal dari gambar augmentasi yang menghasilkan landmark persis sama dengan
nama berkas berbeda.

Laporan lengkap dibuat ulang dengan:

```bash
python ml/src/dataset/clean_dataset.py
```

Hasilnya tersimpan di `models/dataset_report.json`. Jumlah sampel per huruf:

| Huruf | Sebelum | Sesudah | Dibuang | Dua tangan |
| :---: | ---: | ---: | ---: | ---: |
| A | 223 | 203 | 20 | 85% |
| B | 306 | 251 | 55 | 57% |
| C | 292 | 260 | 32 | 0% |
| D | 325 | 272 | 53 | 73% |
| E | 311 | 277 | 34 | 0% |
| F | 284 | 252 | 32 | 42% |
| G | 291 | 229 | 62 | 77% |
| H | 282 | 228 | 54 | 83% |
| I | 353 | 311 | 42 | 0% |
| J | 340 | 294 | 46 | 2% |
| K | 260 | 207 | 53 | 95% |
| L | 323 | 273 | 50 | 0% |
| M | 355 | 321 | 34 | 64% |
| N | 350 | 302 | 48 | 57% |
| O | 306 | 268 | 38 | 5% |
| P | 354 | 354 | 0 | 62% |
| Q | 258 | 203 | 55 | 92% |
| R | 342 | 293 | 49 | 0% |
| S | 339 | 285 | 54 | 82% |
| T | 271 | 224 | 47 | 96% |
| U | 293 | 228 | 65 | 1% |
| V | 351 | 315 | 36 | 0% |
| W | 280 | 239 | 41 | 90% |
| X | 291 | 234 | 57 | 97% |
| Y | 217 | 164 | 53 | 62% |
| Z | 296 | 246 | 50 | 2% |
| **Total** | **7.893** | **6.733** | **1.160** | |

Kolom "Dua tangan" adalah persentase sampel yang terdeteksi dengan dua tangan.
Huruf seperti C, E, I, L, R, dan V selalu satu tangan, sedangkan K, Q, T, W,
dan X hampir selalu dua tangan. Y memiliki sampel paling sedikit, dan itu
sejalan dengan F1-nya yang paling rendah.

## Peringatan validitas dataset

Pembagian data latih dan uji dilakukan **per baris**, bukan per gambar asal.
Dataset tidak menyimpan penanda gambar asal, dan nama berkas hasil augmentasi
dipakai ulang di banyak kelas. Contohnya `augmented_image_10.jpg` muncul pada
12 kelas berbeda, sehingga dari 7.893 baris mentah hanya ada 668 nama berkas
unik.

Setelah duplikat dibuang, masih ada 408 nama berkas yang muncul di data latih
sekaligus data uji. Karena nama berkas tidak unik per gambar, angka ini tidak
bisa dipakai untuk memisahkan gambar asal, tetapi menunjukkan bahwa versi
augmentasi dari gambar yang sama mungkin masih terbagi ke kedua bagian. Angka
96,36% sah untuk protokol ini, dan performa di dunia nyata kemungkinan sedikit
lebih rendah.

Catatan ini juga tersimpan otomatis di `models/metrics.json` pada kunci
`dataset_warning` dan `filename_overlap`, supaya tidak hilang saat laporan
dibuat ulang.

## Susunan 127 fitur

Urutan ini harus sama persis di tiga tempat: dataset CSV, model tersimpan, dan
payload yang dikirim aplikasi ke `POST /api/predict`.

| Rentang | Isi |
| :--- | :--- |
| 0 sampai 62 | 21 titik tangan 1, tiap titik `x, y, z` |
| 63 sampai 125 | 21 titik tangan 2, tiap titik `x, y, z` |
| 126 | `is_two_handed`, bernilai 1 atau 0 |

Seluruh koordinat sudah dinormalkan terhadap pergelangan tangan 1. Bila hanya
satu tangan terdeteksi, 63 nilai tangan 2 diisi nol.

## Struktur folder

```
ml/
  src/
    dataset/
      data_loader.py                  # baca CSV, bersihkan, susun 127 fitur, split
      clean_dataset.py                # aturan pembersihan dan laporan per huruf
      dataset_bisindo_landmarks.csv   # data mentah (7.893 baris, 6.733 setelah bersih)
    training/
      train_svm.py                    # latih SVM dan simpan artefak
    evaluation/
      evaluate_svm.py                 # laporan, confusion matrix, banding kernel
  tests/
    test_svm.py                       # test pipeline, pembersihan, dan evaluasi
  notebooks/
    model_evaluation.ipynb            # evaluasi model SVM yang sama dengan server
  models/
    svm_rbf_bisindo.joblib            # Pipeline(StandardScaler, SVC)
    label_map.json                    # urutan kelas A-Z
    metrics.json                      # metrik dan peringatan dataset
    dataset_report.json               # hasil pembersihan dan jumlah sampel per huruf
    evaluation/                       # keluaran evaluate_svm.py
```

## Cara pakai

Pasang dependency:

```bash
pip install -r ml/requirements.txt
```

Latih model dan simpan artefak:

```bash
python ml/src/training/train_svm.py
```

Validasi silang memakan waktu paling lama, lewati dengan `--no-cv` bila hanya
ingin artefaknya:

```bash
python ml/src/training/train_svm.py --no-cv
```

Evaluasi model tersimpan, sekaligus bandingkan kernel linear, polynomial, dan RBF:

```bash
python ml/src/evaluation/evaluate_svm.py --compare
```

Jalankan test:

```bash
python -m pytest ml/tests -q
```

Penting: jalankan dengan Python yang punya dependensi ML. Bila `web/.venv` sedang
aktif, `python` menunjuk ke venv Flask yang tidak punya scikit-learn maupun
joblib. Matikan dulu dengan `deactivate`, atau panggil Python global langsung.
Test akan berhenti dengan pesan yang menjelaskan hal ini bila interpreter-nya salah.

Membuka notebook evaluasi:

```bash
jupyter notebook ml/notebooks/model_evaluation.ipynb
```

Notebook ini memuat `svm_rbf_bisindo.joblib` yang sama dengan server, menghitung
metrik pada data uji, menggambar confusion matrix, dan memverifikasi bahwa
angkanya masih cocok dengan `metrics.json`.

## Model disimpan sebagai Pipeline

Artefak berisi `StandardScaler` dan `SVC` dalam satu `Pipeline`. Ini disengaja:
tanpa scaler, data yang masuk saat prediksi berada pada skala berbeda dengan
saat latihan, dan hasilnya salah tanpa memunculkan error.

Cara memuat di server:

```python
import joblib

model = joblib.load("ml/models/svm_rbf_bisindo.joblib")
probabilities = model.predict_proba(features)  # features berbentuk (1, 127)
```

## Catatan versi

`SVC(probability=True)` sudah deprecated di scikit-learn 1.9 dan dihapus pada
1.11. Karena itu versi dipin ke `>=1.4,<1.11` agar model dan angka 96,36% tetap
bisa direproduksi. Bila nanti naik ke 1.11 atau lebih baru, ganti dengan
`CalibratedClassifierCV(SVC(), ensemble=False)` lalu latih ulang dan perbarui
`metrics.json`.

## Catatan riwayat

Sebelumnya ada tiga skrip MLP lama (`src/training/train.py`, `model.py`, dan
`utils.py`) beserta keluaran `models/accuracy_plot.png` dan `models/loss_plot.png`.
Ketiganya sudah dihapus pada fase artefak SVM. Alasan penghapusan:

- `train.py` berlatih pada **data acak** dari `load_dummy_data()`, bukan dataset
  asli, sehingga angka akurasinya tidak bermakna.
- Model `.h5` yang dihasilkannya tidak pernah ada di repositori.
- Grafik `accuracy_plot.png` dan `loss_plot.png` berasal dari data acak itu dan
  berisiko disalahartikan sebagai hasil SVM.

Jalur produksi sekarang hanya `train_svm.py`.

Notebook `notebooks/model_evaluation.ipynb` juga sudah ditulis ulang pada fase ini.
Versi lamanya memakai TensorFlow, memuat `model.h5` yang tidak ada, dan membuat
prediksi palsu dari angka acak yang sengaja disamakan 90% dengan label asli agar
akurasinya terlihat 90%. Versi baru memakai model SVM sungguhan dan hasilnya
diverifikasi cocok dengan `metrics.json`.
