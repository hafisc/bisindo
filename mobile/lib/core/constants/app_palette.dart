import 'package:flutter/material.dart';

/// Warna sesuai `design/color palette.png`.
///
/// Dipisah dari [AppColors] karena `AppColors.primary` saat ini belum sama
/// dengan palet desain (#2563EB). Dipakai oleh layar yang mengikuti desain baru.
class AppPalette {
  AppPalette._();

  // ── Primary ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color softBlue = Color(0xFFE0F2FE);
  static const Color darkBlue = Color(0xFF0F172A);
  static const Color navy = Color(0xFF0B1220);

  // ── Secondary / status ────────────────────────────────────────
  static const Color yellow = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Neutral ───────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray800 = Color(0xFF1E293B);
}
