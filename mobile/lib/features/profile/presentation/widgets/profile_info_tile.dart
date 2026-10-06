import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppPalette.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.darkBlue,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.gray400,
                ),
              ),
            ?trailing,
            if (onTap != null && value == null && trailing == null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppPalette.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
