import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/onboarding_data.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlideData data;

  const OnboardingSlideWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (data.textOnTop) {
      // ── Layout Slide 1: Logo → Teks → Ilustrasi
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan keseluruhan konten secara vertikal
          children: [
            // Logo
            if (data.logoPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24), // Jarak proporsional logo ke judul
                child: Image.asset(
                  data.logoPath!,
                  height: 60, // Ukuran logo yang pas
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),

            // Title
            Text(
              data.title,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              data.subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32), // Jarak fixed antara teks dan ilustrasi

            // Ilustrasi — proporsional terhadap tinggi layar
            Center(
              child: SizedBox(
                height: size.height * 0.42, 
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Layout Slide 2 & 3: Ilustrasi → Teks
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Ilustrasi
          Center(
            child: SizedBox(
              height: size.height * 0.42,
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            data.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

