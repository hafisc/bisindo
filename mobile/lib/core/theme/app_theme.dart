import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_palette.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
      primary: AppPalette.primary,
      error: AppPalette.coral,
    ),
    scaffoldBackgroundColor: AppPalette.lightGray,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: GoogleFonts.poppins().fontFamily,
      bodyColor: AppPalette.darkBlue,
      displayColor: AppPalette.darkBlue,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.lightGray,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppPalette.darkBlue,
      ),
      iconTheme: const IconThemeData(color: AppPalette.darkBlue),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.coral, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(
        color: AppPalette.gray400,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppPalette.primary,
      unselectedItemColor: AppPalette.gray400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // ── Dark Theme ─────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.dark,
      primary: AppPalette.primary,
      error: AppPalette.coral,
    ),
    scaffoldBackgroundColor: AppPalette.navy,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: GoogleFonts.poppins().fontFamily,
      bodyColor: AppPalette.white,
      displayColor: AppPalette.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppPalette.white,
      ),
      iconTheme: const IconThemeData(color: AppPalette.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.darkBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.coral, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(
        color: AppPalette.gray400,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.darkBlue,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppPalette.darkBlue,
      selectedItemColor: AppPalette.primary,
      unselectedItemColor: AppPalette.gray400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
