# Image server Flask untuk API prediksi BISINDO (SVM).
#
# Build dari akar repositori, bukan dari dalam folder web:
#   docker build -t bisindo-api .
#   docker run -p 8000:8000 bisindo-api
#
# Model tidak dilatih di dalam image. Artefak joblib disalin dari ml/models,
# sesuai alur: latih lewat CLI, lalu deploy.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# scikit-learn membutuhkan libgomp untuk OpenMP.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependency dipisah agar cache Docker tidak batal saat kode berubah.
COPY web/requirements.txt /app/web/requirements.txt
RUN pip install --no-cache-dir -r /app/web/requirements.txt

COPY web /app/web

# Hanya artefak yang dibutuhkan server, bukan seluruh folder ml.
COPY ml/models/svm_rbf_bisindo.joblib /app/ml/models/svm_rbf_bisindo.joblib
COPY ml/models/label_map.json /app/ml/models/label_map.json
COPY ml/models/metrics.json /app/ml/models/metrics.json

ENV MODEL_PATH=/app/ml/models/svm_rbf_bisindo.joblib \
    PORT=8000

# Database SQLite ditulis di sini. Mount volume bila datanya harus persist.
RUN mkdir -p /app/web/instance

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/status').status == 200 else 1)"

# Satu worker: model SVM dimuat per proses, dan aktivasi model dari panel admin
# hanya berlaku pada proses yang melayani request tersebut. Satu worker juga
# menghindari dua proses membuat tabel database bersamaan saat start.
CMD ["sh", "-c", "gunicorn --chdir /app/web --bind 0.0.0.0:${PORT} --workers 1 --timeout 120 run:app"]
