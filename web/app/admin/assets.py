"""Rute admin untuk mengelola dataset dan versi model.

Ini bagian "web untuk input data" pada alur kerja: berkas diunggah lewat
panel admin, disimpan di ``web/instance/``, lalu model yang aktif dipakai
server untuk melayani ``POST /api/predict``.

Training **tidak** dijalankan dari sini. Melatih SVM memakan beberapa detik
dan akan memblokir request Flask. Alurnya tetap: latih lewat CLI dengan
``ml/src/training/train_svm.py``, lalu unggah artefaknya.
"""

from __future__ import annotations

import json
import numbers
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from flask import current_app, flash, redirect, render_template, request, session, url_for
from sqlalchemy import select, update

from ..api import services
from ..extensions import db
from ..models import DatasetSnapshot, ModelVersion
from . import bp
from .auth import login_required, verify_csrf
from . import storage


def _admin_name() -> str:
    return session.get("admin_name") or "admin"


def _stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")


def _dataset_dir() -> Path:
    path = Path(current_app.config["DATASET_DIR"])
    path.mkdir(parents=True, exist_ok=True)
    return path


def _model_dir() -> Path:
    path = Path(current_app.config["MODEL_UPLOAD_DIR"])
    path.mkdir(parents=True, exist_ok=True)
    return path


# ── Dataset ──────────────────────────────────────────────────────────────────


@bp.get("/dataset")
@login_required
def dataset():
    snapshots = list(
        db.session.scalars(
            select(DatasetSnapshot).order_by(
                DatasetSnapshot.uploaded_at.desc(), DatasetSnapshot.id.desc()
            )
        )
    )
    active = next((item for item in snapshots if item.is_active), None)

    return render_template(
        "admin/dataset.html",
        snapshots=snapshots,
        active=active,
        feature_count=storage.FEATURE_COUNT,
    )


@bp.post("/dataset/upload")
@login_required
def dataset_upload():
    verify_csrf()

    upload = request.files.get("dataset_file")
    if upload is None or not upload.filename:
        flash("Pilih berkas CSV terlebih dahulu.", "error")
        return redirect(url_for("admin.dataset"))

    stored_name = f"{_stamp()}-{uuid4().hex[:8]}.csv"
    target = _dataset_dir() / stored_name

    try:
        storage.save_upload(
            upload, _dataset_dir(), stored_name, storage.ALLOWED_DATASET_SUFFIXES
        )
        stats = storage.analyze_dataset_csv(target)
    except storage.UploadError as error:
        target.unlink(missing_ok=True)
        flash(str(error), "error")
        return redirect(url_for("admin.dataset"))
    except Exception as error:  # pragma: no cover - jalur jarang
        target.unlink(missing_ok=True)
        flash(f"Gagal membaca dataset: {error}", "error")
        return redirect(url_for("admin.dataset"))

    checksum = storage.checksum_of(target)

    existing = db.session.scalar(
        select(DatasetSnapshot).where(DatasetSnapshot.checksum == checksum)
    )
    if existing is not None:
        target.unlink(missing_ok=True)
        flash(
            f"Dataset ini sudah pernah diunggah sebagai snapshot #{existing.id}. "
            "Tidak ada yang diubah.",
            "info",
        )
        return redirect(url_for("admin.dataset"))

    snapshot = DatasetSnapshot(
        filename=storage.safe_name(upload.filename),
        stored_name=stored_name,
        size_bytes=target.stat().st_size,
        checksum=checksum,
        row_count=stats["row_count"],
        class_count=stats["class_count"],
        feature_count=stats["feature_count"],
        shared_filename_count=stats["shared_filename_count"],
        class_distribution=json.dumps(stats["class_distribution"]),
        note=(request.form.get("note") or "").strip()[:255] or None,
        uploaded_by=_admin_name(),
    )
    db.session.add(snapshot)
    db.session.commit()

    flash(
        f"Dataset tersimpan: {snapshot.row_count} baris, "
        f"{snapshot.class_count} kelas, {snapshot.size_label}.",
        "success",
    )
    return redirect(url_for("admin.dataset"))


@bp.post("/dataset/<int:snapshot_id>/activate")
@login_required
def dataset_activate(snapshot_id: int):
    verify_csrf()

    snapshot = db.session.get(DatasetSnapshot, snapshot_id)
    if snapshot is None:
        flash("Snapshot dataset tidak ditemukan.", "error")
        return redirect(url_for("admin.dataset"))

    db.session.execute(update(DatasetSnapshot).values(is_active=False))
    snapshot.is_active = True
    db.session.commit()

    flash(f"Dataset #{snapshot.id} ditandai sebagai acuan aktif.", "success")
    return redirect(url_for("admin.dataset"))


@bp.post("/dataset/<int:snapshot_id>/delete")
@login_required
def dataset_delete(snapshot_id: int):
    verify_csrf()

    snapshot = db.session.get(DatasetSnapshot, snapshot_id)
    if snapshot is None:
        flash("Snapshot dataset tidak ditemukan.", "error")
        return redirect(url_for("admin.dataset"))

    if snapshot.is_active:
        flash("Dataset aktif tidak bisa dihapus. Aktifkan snapshot lain lebih dulu.", "error")
        return redirect(url_for("admin.dataset"))

    path = _dataset_dir() / snapshot.stored_name
    path.unlink(missing_ok=True)

    db.session.delete(snapshot)
    db.session.commit()

    flash(f"Snapshot dataset #{snapshot_id} dihapus.", "info")
    return redirect(url_for("admin.dataset"))


# ── Model ────────────────────────────────────────────────────────────────────


def _build_label_map(info: dict) -> dict:
    """Susun label_map.json dari kelas yang terbaca pada model.

    Model hasil LabelEncoder menyimpan kelas sebagai 0..25, bukan huruf.
    Pemetaan ke A-Z dilakukan di sini supaya server tidak pernah membalas
    angka ke aplikasi mobile.
    """
    classes = info.get("classes") or []
    letters = services.CLASSES

    if classes and all(isinstance(item, numbers.Integral) for item in classes):
        mapped = [
            letters[int(item)] if 0 <= int(item) < len(letters) else str(item)
            for item in classes
        ]
    elif classes:
        mapped = [str(item) for item in classes]
    else:
        mapped = list(letters)

    return {"classes": mapped, "feature_count": storage.FEATURE_COUNT}


@bp.get("/model")
@login_required
def model_versions():
    versions = list(
        db.session.scalars(
            select(ModelVersion).order_by(
                ModelVersion.uploaded_at.desc(), ModelVersion.id.desc()
            )
        )
    )
    active = next((item for item in versions if item.is_active), None)

    return render_template(
        "admin/model.html",
        versions=versions,
        active=active,
        live_info=services.get_model_info(),
        model_path=current_app.config.get("MODEL_PATH"),
        feature_count=storage.FEATURE_COUNT,
    )


@bp.post("/model/upload")
@login_required
def model_upload():
    verify_csrf()

    upload = request.files.get("model_file")
    if upload is None or not upload.filename:
        flash("Pilih berkas model (.joblib) terlebih dahulu.", "error")
        return redirect(url_for("admin.model_versions"))

    stored_name = f"{_stamp()}-{uuid4().hex[:8]}"
    version_dir = _model_dir() / stored_name

    try:
        storage.save_upload(
            upload, version_dir, "model.joblib", storage.ALLOWED_MODEL_SUFFIXES
        )
        info = storage.validate_model_upload(version_dir / "model.joblib")
    except storage.UploadError as error:
        _remove_dir(version_dir)
        flash(str(error), "error")
        return redirect(url_for("admin.model_versions"))
    except Exception as error:  # pragma: no cover - jalur jarang
        _remove_dir(version_dir)
        flash(f"Gagal memeriksa model: {error}", "error")
        return redirect(url_for("admin.model_versions"))

    # label_map.json: pakai kiriman admin bila ada, kalau tidak susun sendiri.
    label_upload = request.files.get("label_map")
    label_map = {}
    if label_upload is not None and label_upload.filename:
        try:
            raw = label_upload.read()
            label_map = json.loads(raw.decode("utf-8"))
            if not isinstance(label_map, dict) or not label_map.get("classes"):
                raise ValueError("label_map.json harus memuat kunci 'classes'.")
            label_map["feature_count"] = storage.FEATURE_COUNT
        except Exception as error:
            _remove_dir(version_dir)
            flash(f"label_map.json tidak valid: {error}", "error")
            return redirect(url_for("admin.model_versions"))
    else:
        label_map = _build_label_map(info)

    (version_dir / "label_map.json").write_text(
        json.dumps(label_map, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    # metrics.json: opsional, dipakai untuk menampilkan akurasi.
    metrics_upload = request.files.get("metrics")
    metrics = {}
    if metrics_upload is not None and metrics_upload.filename:
        try:
            metrics = json.loads(metrics_upload.read().decode("utf-8"))
            if not isinstance(metrics, dict):
                raise ValueError("metrics.json harus berupa objek JSON.")
            (version_dir / "metrics.json").write_text(
                json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8"
            )
        except Exception as error:
            _remove_dir(version_dir)
            flash(f"metrics.json tidak valid: {error}", "error")
            return redirect(url_for("admin.model_versions"))

    checksum = storage.checksum_of(version_dir / "model.joblib")
    existing = db.session.scalar(
        select(ModelVersion).where(ModelVersion.checksum == checksum)
    )
    if existing is not None:
        _remove_dir(version_dir)
        flash(
            f"Model ini sudah pernah diunggah sebagai versi #{existing.id}. "
            "Tidak ada yang diubah.",
            "info",
        )
        return redirect(url_for("admin.model_versions"))

    version = ModelVersion(
        label=(request.form.get("label") or "").strip()[:120]
        or f"svm-{_stamp()}",
        filename=storage.safe_name(upload.filename),
        stored_name=stored_name,
        size_bytes=(version_dir / "model.joblib").stat().st_size,
        checksum=checksum,
        algorithm=metrics.get("algorithm"),
        variant=metrics.get("variant"),
        kernel=metrics.get("kernel"),
        accuracy=metrics.get("accuracy"),
        f1_score=metrics.get("f1_score"),
        feature_count=info.get("feature_count") or storage.FEATURE_COUNT,
        class_count=info.get("class_count") or len(label_map["classes"]),
        note=(request.form.get("note") or "").strip()[:255] or None,
        uploaded_by=_admin_name(),
    )
    db.session.add(version)
    db.session.commit()

    flash(f"Model versi #{version.id} tersimpan. Aktifkan untuk mulai dipakai.", "success")
    return redirect(url_for("admin.model_versions"))


@bp.post("/model/<int:version_id>/activate")
@login_required
def model_activate(version_id: int):
    verify_csrf()

    version = db.session.get(ModelVersion, version_id)
    if version is None:
        flash("Versi model tidak ditemukan.", "error")
        return redirect(url_for("admin.model_versions"))

    model_path = _model_dir() / version.stored_name / "model.joblib"
    if not model_path.exists():
        flash(
            "Berkas model versi ini tidak ada di disk. Unggah ulang berkasnya.",
            "error",
        )
        return redirect(url_for("admin.model_versions"))

    db.session.execute(update(ModelVersion).values(is_active=False))
    version.is_active = True
    db.session.commit()

    current_app.config["MODEL_PATH"] = model_path.as_posix()
    loaded = services.reload_model()

    if loaded:
        flash(f"Model versi #{version.id} aktif dan sudah dimuat server.", "success")
    else:
        flash(
            f"Model versi #{version.id} ditandai aktif, tetapi gagal dimuat. "
            "Periksa log server.",
            "error",
        )

    return redirect(url_for("admin.model_versions"))


@bp.post("/model/<int:version_id>/delete")
@login_required
def model_delete(version_id: int):
    verify_csrf()

    version = db.session.get(ModelVersion, version_id)
    if version is None:
        flash("Versi model tidak ditemukan.", "error")
        return redirect(url_for("admin.model_versions"))

    if version.is_active:
        flash("Model aktif tidak bisa dihapus. Aktifkan versi lain lebih dulu.", "error")
        return redirect(url_for("admin.model_versions"))

    _remove_dir(_model_dir() / version.stored_name)

    db.session.delete(version)
    db.session.commit()

    flash(f"Versi model #{version_id} dihapus.", "info")
    return redirect(url_for("admin.model_versions"))


def _remove_dir(path: Path) -> None:
    """Hapus direktori versi model beserta isinya, abaikan bila tidak ada."""
    if not path.exists():
        return
    for item in path.iterdir():
        if item.is_file():
            item.unlink(missing_ok=True)
    path.rmdir()


# ── Galat unggahan ───────────────────────────────────────────────────────────


@bp.errorhandler(413)
def handle_upload_too_large(error):
    """Berkas melebihi ``MAX_CONTENT_LENGTH``: beri pesan, bukan halaman galat."""
    batas = current_app.config.get("MAX_CONTENT_LENGTH") or 0
    batas_mb = max(round(batas / (1024 * 1024)), 1)
    flash(
        f"Berkas terlalu besar. Batas unggahan {batas_mb} MB. "
        "Pecah dataset menjadi beberapa berkas lebih dulu.",
        "error",
    )
    return redirect(url_for("admin.dashboard"))


# ── Pemulihan saat server mulai ──────────────────────────────────────────────


def apply_active_assets(app) -> None:
    """Arahkan MODEL_PATH ke model yang terakhir diaktifkan lewat panel admin.

    Tanpa ini, model pilihan admin hilang setiap kali server dijalankan ulang
    dan kembali ke berkas bawaan di ``ml/models/``.
    """
    with app.app_context():
        version = db.session.scalar(
            select(ModelVersion).where(ModelVersion.is_active.is_(True))
        )
        if version is None:
            return

        model_path = Path(app.config["MODEL_UPLOAD_DIR"]) / version.stored_name / "model.joblib"
        if not model_path.exists():
            app.logger.warning(
                "[ADMIN] Model aktif #%s tidak ditemukan di %s, memakai model bawaan.",
                version.id,
                model_path,
            )
            return

        app.config["MODEL_PATH"] = model_path.as_posix()
        app.logger.info("[ADMIN] Memakai model aktif #%s dari %s", version.id, model_path)
