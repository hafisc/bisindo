"""Augmentasi dan transformasi di ruang landmark (matriks fitur 127 kolom).

Dipakai saat melatih ulang model dari foto supaya model tahan terhadap
perbedaan antara foto dataset dan kamera HP:

- **Rasio frame.** Foto dataset berukuran persegi (640x640), sedangkan frame
  kamera HP berbentuk potret 9:16 (720x1280). MediaPipe menormalkan x dengan
  lebar dan y dengan tinggi gambar, dan aplikasi mengirim nilai itu apa adanya.
  Akibatnya tangan di HP tampak 16/9 kali lebih lebar daripada di dataset.
  ``stretch_aspect`` meniru efek ini.
- **Sudut tangan.** Rotasi kecil pada bidang gambar.
- **Getaran titik.** Noise kecil pada tiap titik dan pada skala z.

Semua fungsi menjaga kontrak fitur: pergelangan tangan 1 di titik nol, jarak
pergelangan ke titik 9 tangan 1 sama dengan 1, tangan 2 berisi nol untuk sampel
satu tangan, dan kolom 126 (``is_two_handed``) tidak berubah.
"""

from __future__ import annotations

import numpy as np

POINT_COUNT = 21
HAND_FEATURES = POINT_COUNT * 3  # 63

# Rasio lebar frame terhadap dataset persegi: 1 (persegi), 4:3, dan 16:9 potret.
PHONE_ASPECTS = (1.0, 4.0 / 3.0, 16.0 / 9.0)


def _split(features: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    features = np.asarray(features, dtype=np.float64)
    points = features[:, : HAND_FEATURES * 2].reshape(len(features), POINT_COUNT * 2, 3).copy()
    two_handed = features[:, -1] >= 0.5
    return points, two_handed


def _join(points: np.ndarray, two_handed: np.ndarray) -> np.ndarray:
    """Normalkan ulang lalu susun kembali menjadi matriks 127 kolom."""
    points = points - points[:, :1, :]
    scale = np.linalg.norm(points[:, 9, :], axis=1)
    scale = np.where(scale < 1e-6, 1.0, scale)
    points = points / scale[:, None, None]
    points[~two_handed, POINT_COUNT:, :] = 0.0
    flat = points.reshape(len(points), HAND_FEATURES * 2)
    return np.concatenate([flat, two_handed[:, None].astype(np.float64)], axis=1).astype(np.float32)


def stretch_aspect(features: np.ndarray, aspect) -> np.ndarray:
    """Tiru frame yang ``aspect`` kali lebih sempit daripada gambar persegi.

    Pada frame potret, x (dan z, yang oleh MediaPipe diskalakan seperti x)
    membesar ``aspect`` kali relatif terhadap y. ``aspect`` boleh skalar atau
    array sepanjang jumlah baris.
    """
    points, two_handed = _split(features)
    factor = np.broadcast_to(np.asarray(aspect, dtype=np.float64), (len(points),))
    points[:, :, 0] *= factor[:, None]
    points[:, :, 2] *= factor[:, None]
    return _join(points, two_handed)


def swap_hands(features: np.ndarray) -> np.ndarray:
    """Jadikan tangan 2 sebagai acuan, seperti kandidat ``swapped`` di server."""
    points, two_handed = _split(features)
    swapped = np.concatenate([points[:, POINT_COUNT:], points[:, :POINT_COUNT]], axis=1)
    swapped[~two_handed] = points[~two_handed]
    return _join(swapped, two_handed)


def mirror_x(features: np.ndarray) -> np.ndarray:
    """Cerminkan sumbu x, seperti kandidat ``mirrored`` di server."""
    mirrored = np.array(features, dtype=np.float32, copy=True)
    mirrored[:, : HAND_FEATURES * 2 : 3] *= -1
    return mirrored


def augment(
    features: np.ndarray,
    rng: np.random.Generator,
    max_rotation_deg: float = 15.0,
    point_noise: float = 0.015,
    z_jitter: float = 0.15,
    aspect_jitter: float = 0.08,
    aspects=PHONE_ASPECTS,
) -> np.ndarray:
    """Buat satu salinan acak dari setiap baris.

    Urutan: rotasi pada bentuk asli, getaran z, noise titik, lalu rasio frame.
    Rasio dipilih acak dari ``aspects`` dengan sedikit variasi.
    """
    points, two_handed = _split(features)
    count = len(points)

    angle = np.deg2rad(rng.uniform(-max_rotation_deg, max_rotation_deg, size=count))
    cos, sin = np.cos(angle)[:, None], np.sin(angle)[:, None]
    x, y = points[:, :, 0].copy(), points[:, :, 1].copy()
    points[:, :, 0] = x * cos - y * sin
    points[:, :, 1] = x * sin + y * cos

    points[:, :, 2] *= rng.uniform(1.0 - z_jitter, 1.0 + z_jitter, size=count)[:, None]
    points += rng.normal(0.0, point_noise, size=points.shape)

    aspect = rng.choice(np.asarray(aspects), size=count)
    aspect = aspect * rng.uniform(1.0 - aspect_jitter, 1.0 + aspect_jitter, size=count)
    points[:, :, 0] *= aspect[:, None]
    points[:, :, 2] *= aspect[:, None]

    return _join(points, two_handed)


def augment_dataset(
    features: np.ndarray,
    labels: np.ndarray,
    copies: int,
    seed: int = 42,
    include_original: bool = True,
    **options,
) -> tuple[np.ndarray, np.ndarray]:
    """Buat ``copies`` salinan augmentasi, dengan atau tanpa data asli.

    ``include_original=False`` dipakai bila model dikhususkan untuk rasio frame
    tertentu: data asli (rasio persegi) dibuang supaya bentuk tangan pada rasio
    lain tidak tertukar antar huruf.
    """
    if copies <= 0:
        return np.asarray(features, dtype=np.float32), np.asarray(labels)

    rng = np.random.default_rng(seed)
    parts = [np.asarray(features, dtype=np.float32)] if include_original else []
    # ``point_noise`` boleh berupa daftar: salinan ke-i memakai tingkat ke-(i mod n).
    # Goyangan besar meniru tangan yang jauh dari kamera (titik MediaPipe kurang presisi).
    noise = options.pop("point_noise", 0.015)
    levels = list(noise) if isinstance(noise, (list, tuple)) else [noise]
    parts += [
        augment(features, rng, point_noise=levels[i % len(levels)], **options)
        for i in range(copies)
    ]
    return np.concatenate(parts), np.concatenate([labels] * len(parts))
