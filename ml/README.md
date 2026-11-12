# ML Pipeline BISINDO

Pipeline pelatihan model klasifikasi huruf BISINDO A-Z dari koordinat
landmark tangan MediaPipe. Model yang dipakai adalah **SVM kernel RBF**,
bukan jaringan saraf.

## Hasil

| Metrik | Nilai |
| :--- | :--- |
| Algoritma | SVM RBF (`C=10.0`, `gamma='scale'`) |
| Akurasi data uji | **97,91%** |
| F1 weighted | 0,9791 |
| Macro F1 | 0,9785 |
| Validasi silang 5 lipat (F1) | 0,9664 +/- 0,0050 |
| Waktu latih | sekitar 3 detik |
| Jumlah fitur | 127 |
| Jumlah kelas | 26 |

Angka lengkap ada di `models/metrics.json`. Kelas terlemah adalah Y (F1 0,92),
B (0,94), dan C (0,96).

## Perbandingan kernel

| Kernel | C | Akurasi | F1 weighted |
| :--- | :---: | :---: | :---: |
| RBF | 10.0 | **97,91%** | **0,9791** |
| Linear | 1.0 | 97,02% | 0,9702 |
| Polynomial (degree 3) | 1.0 | 92,08% | 0,9223 |

Angka di atas sama persis dengan notebook eksperimen `Klasifikasi_Kelompok_1`.
Setiap kernel memakai nilai C terbaiknya sendiri. Bila `--C` diisi manual,
nilai itu berlaku untuk ketiga kernel.

## Peringatan validitas dataset

Akurasi 97,91% berasal dari pembagian data **per baris**, bukan per gambar asal.
Dataset tidak menyimpan penanda gambar asal, dan nama berkas hasil augmentasi
dipakai ulang di banyak kelas. Contohnya `augmented_image_10.jpg` muncul pada
12 kelas berbeda, sehingga dari 7.893 baris hanya ada 668 nama berkas unik.

Akibatnya, 436 nama berkas muncul di data latih sekaligus data uji. Model bisa
mengenali versi augmentasi dari gambar yang sama. Angka ini sah sebagai hasil
eksperimen dengan protokol tersebut, tetapi performa di dunia nyata kemungkinan
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
      data_loader.py                  # baca CSV, susun 127 fitur, split
      dataset_bisindo_landmarks.csv   # dataset latih (7.893 baris, 26 kelas)
    training/
      train_svm.py                    # latih SVM dan simpan artefak
    evaluation/
      evaluate_svm.py                 # laporan, confusion matrix, banding kernel
  tests/
    test_svm.py                       # 14 test pipeline
  notebooks/
    model_evaluation.ipynb            # evaluasi model SVM yang sama dengan server
  models/
    svm_rbf_bisindo.joblib            # Pipeline(StandardScaler, SVC)
    label_map.json                    # urutan kelas A-Z
    metrics.json                      # metrik dan peringatan dataset
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
1.11. Karena itu versi dipin ke `>=1.4,<1.11` agar model dan angka 97,91% tetap
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
