import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';

/// Kartu "Tips Hari Ini" di bagian bawah Beranda.
class HomeTipsCard extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeTipsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFEFC2)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFAD27A), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26F59E0B),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_tips_bulb.svg',
                width: 42,
                height: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.homeTipsTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.homeTipsBody,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.65,
                        color: AppPalette.gray800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
