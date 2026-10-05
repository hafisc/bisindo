import 'package:flutter/material.dart';

/// Design system color palette for BISINDO Translator app.
/// Matches the official color palette specs:
/// - Primary: #2563EB, Light Blue: #60A5FA, Soft Blue: #E0F2FE, Dark Blue: #0F172A, Navy: #0B1220
/// - Secondary: Purple #8B5CF6, Teal #10B981, Yellow #F59E0B, Coral #EF4444
/// - Neutral: White #FFFFFF, Light Gray #F8FAFC, Gray 200 #E2E8F0, Gray 400 #94A3B8, Gray 600 #475569, Gray 800 #1E293B
/// - Status: Success #22C55E, Info #3B82F6, Warning #F59E0B, Error #EF4444
class AppPalette {
  AppPalette._();

  // ── Primary Colors ─────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color softBlue = Color(0xFFE0F2FE);
  static const Color darkBlue = Color(0xFF0F172A);
  static const Color navy = Color(0xFF0B1220);

  // ── Secondary Colors ───────────────────────────────────────────
  static const Color purple = Color(0xFF8B5CF6);
  static const Color teal = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEF4444);

  // ── Neutral Colors ─────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray800 = Color(0xFF1E293B);

  // ── Status Colors ──────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Gradients ──────────────────────────────────────────────────
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primary, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purple, Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [teal, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
