"""Konfigurasi pytest untuk modul ML.

Menambahkan ``ml/src`` ke ``sys.path`` supaya paket ``dataset``,
``training``, dan ``evaluation`` bisa diimpor langsung dari test.

Berkas ini juga memeriksa bahwa dependensi ML benar-benar tersedia. Kesalahan
yang paling sering terjadi adalah menjalankan test dengan virtual environment
web (``web/.venv``), yang hanya berisi Flask. Tanpa pemeriksaan ini, pytest
berhenti dengan pesan ``ModuleNotFoundError: No module named 'joblib'`` yang
tidak menjelaskan apa pun.
"""

import sys
from pathlib import Path

SRC_DIR = Path(__file__).resolve().parent.parent / "src"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))

REQUIRED_MODULES = ("numpy", "pandas", "sklearn", "joblib")

_missing = []
for _module in REQUIRED_MODULES:
    try:
        __import__(_module)
    except ImportError:
        _missing.append(_module)

if _missing:
    raise RuntimeError(
        "Test ML tidak bisa dijalankan dengan Python ini.\n"
        f"  Interpreter : {sys.executable}\n"
        f"  Tidak ada   : {', '.join(_missing)}\n"
        "\n"
        "Interpreter ini tidak memiliki dependensi ML. Bila virtual environment\n"
        "web (web/.venv) sedang aktif, itu memang hanya berisi dependensi Flask.\n"
        "\n"
        "Perbaiki dengan salah satu cara berikut:\n"
        "  1. deactivate\n"
        "     python -m pytest ml/tests -q\n"
        "  2. pip install -r ml/requirements.txt   (di environment yang dipakai)\n"
    )
