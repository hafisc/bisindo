import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';

/// Kartu biru ajakan scan: ilustrasi di kiri, teks dan tombol di kanan.
class HomeBanner extends StatelessWidget {
  final VoidCallback onScanTap;

  const HomeBanner({super.key, required this.onScanTap});

  static const double _height = 148;
  static const double _illustrationWidth = 132;
  static const double _textStart = 155;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppPalette.bannerBlue,
            AppPalette.bannerBlue,
            AppPalette.primary,
          ],
          stops: [0, 0.38, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadowPrimary,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ilustrasi, tepi kanannya dipudarkan supaya menyatu dengan gradasi.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _illustrationWidth,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppPalette.white,
                  AppPalette.white,
                  AppPalette.transparent,
                ],
                stops: [0, 0.8, 1],
              ).createShader(rect),
              child: Image.asset(
                'assets/images/home_banner_illustration.png',
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          Positioned.fill(
            left: _textStart,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.homeBannerTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                      color: AppPalette.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ScanButton(onTap: onScanTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 166),
      child: Material(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.homeScanNow,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppPalette.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
