import 'package:flutter/material.dart';

/// All color tokens for the BISINDO Translator app.
/// Consistent with the design palette (color palette.png in /design).
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF4F6AF0);       // Indigo blue
  static const Color primaryLight = Color(0xFF7B93F5);
  static const Color primaryDark = Color(0xFF2D4ED8);
  static const Color secondary = Color(0xFF00C9A7);     // Teal accent
  static const Color secondaryLight = Color(0xFF4DDFC6);
  static const Color accent = Color(0xFFFFC857);        // Amber highlight

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Backgrounds (Light) ───────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2FF);

  // ── Backgrounds (Dark) ────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F1117);
  static const Color surfaceDark = Color(0xFF1A1D2E);
  static const Color surfaceVariantDark = Color(0xFF252840);

  // ── Text (Light) ──────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1D2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textHintLight = Color(0xFF9CA3AF);

  // ── Text (Dark) ───────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textHintDark = Color(0xFF6B7280);

  // ── Gradient Presets ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F6AF0), Color(0xFF00C9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
