# BISINDO Sign Language Translator — ML Pipeline

## Overview
Python pipeline untuk training model deteksi gestur BISINDO menggunakan MediaPipe + TensorFlow/Keras.

## Setup

```bash
cd ml/
pip install -r requirements.txt
```

## Struktur

```
ml/
├── data/
│   ├── raw/          # Dataset mentah per kelas (A-Z, kata)
│   │   ├── A/        # 100+ gambar per kelas
│   │   ├── B/
│   │   └── ...
│   └── processed/    # Setelah augmentasi & preprocessing
├── notebooks/        # Jupyter untuk eksplorasi & analisis
├── src/
│   ├── dataset/      # Kumpul & augment data
│   ├── training/     # Pipeline training
│   ├── evaluation/   # Metrics & confusion matrix
│   └── export/       # Convert ke TFLite
└── models/
    ├── *.h5          # Saved Keras models
    └── *.tflite      # Exported TFLite models
```

## Flow

1. `src/dataset/collect_data.py` — capture gambar dari kamera
2. `src/dataset/augment.py` — augmentasi dataset
3. `notebooks/01_explore.ipynb` — eksplorasi data
4. `src/training/train.py` — training model
5. `src/evaluation/evaluate.py` — evaluasi performa
6. `src/export/export_tflite.py` — export ke TFLite
7. Copy `.tflite` ke `mobile/assets/models/`
