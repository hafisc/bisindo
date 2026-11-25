import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Legacy color tokens bridge — now mapped directly to [AppPalette]
/// to maintain a single source of truth across the app.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────
  static const Color primary = AppPalette.primary;
  static const Color primaryLight = AppPalette.lightBlue;
  static const Color primaryDark = AppPalette.navy;
  static const Color secondary = AppPalette.teal;
  static const Color accent = AppPalette.yellow;

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = AppPalette.success;
  static const Color warning = AppPalette.warning;
  static const Color error = AppPalette.error;
  static const Color info = AppPalette.info;

  // ── Backgrounds & Surfaces ─────────────────────────────────────
  static const Color backgroundLight = AppPalette.lightGray;
  static const Color surfaceLight = AppPalette.white;
  static const Color backgroundDark = AppPalette.darkBlue;
  static const Color surfaceDark = AppPalette.navy;

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimaryLight = AppPalette.darkBlue;
  static const Color textSecondaryLight = AppPalette.gray600;
  static const Color textHintLight = AppPalette.gray400;
  static const Color textPrimaryDark = AppPalette.white;
  static const Color textSecondaryDark = AppPalette.gray400;
}
