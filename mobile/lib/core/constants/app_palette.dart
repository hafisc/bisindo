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

  // ── Extended Blue Tints ────────────────────────────────────────
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color bannerBlue = Color(0xFF3384E0);
  static const Color navBorder = Color(0xFFE8EEF6);

  // ── Secondary Colors ───────────────────────────────────────────
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFEDE9FE);
  static const Color teal = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFDBA74);

  // ── Neutral Colors ─────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color lightGray = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);

  // ── Status Colors ──────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ── Feature & Surface Tints ────────────────────────────────────
  static const Color blueTile = Color(0xFFE3EEFD);
  static const Color amberTile = Color(0xFFFEF3C7);
  static const Color amber50 = Color(0xFFFFF8E1);
  static const Color amber100 = Color(0xFFFFEFC2);
  static const Color amberBorder = Color(0xFFFAD27A);
  static const Color amberDark = Color(0xFFD97706);
  static const Color redSoft = Color(0xFFFEE2E2);
  static const Color redBorder = Color(0xFFFECACA);
  static const Color redAccent = Color(0xFFF05252);
  static const Color warningBg = Color(0xFFFFF7E6);
  static const Color warningBorder = Color(0xFFFDE2A7);
  static const Color warningIcon = Color(0xFFB7791F);
  static const Color warningText = Color(0xFF8A5A12);
  static const Color peachSoft = Color(0xFFFDEEE8);
  static const Color skySoft = Color(0xFFE8F4FD);

  // ── Hand Illustration ──────────────────────────────────────────
  static const Color skinPrimary = Color(0xFFE0A46E);
  static const Color skinSecondary = Color(0xFFF6D2A8);
  static const Color skinOutline = Color(0xFF7A4A2A);

  // ── Scan & Camera Dark UI ──────────────────────────────────────
  static const Color scanSurface = Color(0xF20F1117);
  static const Color scanDialogBg = Color(0xFF161A22);
  static const Color scanActionBg = Color(0xFF2A3042);
  static const Color scanConfidenceHigh = Color(0xFF9EE7D7);
  static const Color skeletonLine = Color(0xFF00E5FF);
  static const Color skeletonJoint = Color(0xFF00E676);
  static const Color skeletonWrist = Color(0xFFFFD600);
  static const Color skeletonFingertip = Color(0xFFFF1744);
  static const Color scanOverlay = Color(0x73000000);
  static const Color scanChipOverlay = Color(0x8A000000);
  static const Color scanControlOverlay = Color(0x8C000000);
  static const Color scanPanelOverlay = Color(0xBF000000);
  static const Color scanBannerOverlay = Color(0xB8000000);
  static const Color scanStatusOverlay = Color(0x99000000);
  static const Color scanInputOverlay = Color(0x42000000);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color black87 = Color(0xDD000000);
  static const Color avatarOverlay = Color(0x59000000);
  static const Color avatarShadow = Color(0x0F000000);
  static const Color cardShadow = Color(0x0D000000);
  static const Color xsShadow = Color(0x08000000);
  static const Color subtleShadow = Color(0x05000000);
  static const Color amber = Color(0xFFFFC107);

  // ── Shadows ────────────────────────────────────────────────────
  static const Color shadowSoft = Color(0x0F0F172A);
  static const Color shadowMedium = Color(0x1A0F172A);
  static const Color shadowPrimary = Color(0x332563EB);
  static const Color shadowPrimaryStrong = Color(0x592563EB);
  static const Color shadowAmber = Color(0x26F59E0B);

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
