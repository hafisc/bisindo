import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';

/// Empat kartu menu cepat di bawah banner.
class HomeMenuGrid extends StatelessWidget {
  final VoidCallback onDictionaryTap;
  final VoidCallback onLearnTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onFavoriteTap;

  const HomeMenuGrid({
    super.key,
    required this.onDictionaryTap,
    required this.onLearnTap,
    required this.onHistoryTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MenuCard(
            label: AppStrings.homeMenuDictionary,
            tileColor: AppPalette.blueTile,
            icon: SvgPicture.asset(
              'assets/icons/ic_book_bisindo.svg',
              width: 38,
              height: 38,
            ),
            onTap: onDictionaryTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MenuCard(
            label: AppStrings.homeMenuLearn,
            tileColor: AppPalette.amberTile,
            icon: const Icon(
              Icons.school_rounded,
              size: 36,
              color: AppPalette.yellow,
            ),
            onTap: onLearnTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MenuCard(
            label: AppStrings.homeMenuHistory,
            tileColor: AppPalette.purpleSoft,
            icon: const Icon(
              Icons.access_time_filled_rounded,
              size: 34,
              color: AppPalette.purple,
            ),
            onTap: onHistoryTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MenuCard(
            label: AppStrings.homeMenuFavorite,
            tileColor: AppPalette.redSoft,
            icon: const Icon(
              Icons.favorite_rounded,
              size: 34,
              color: AppPalette.redAccent,
            ),
            onTap: onFavoriteTap,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String label;
  final Color tileColor;
  final Widget icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.label,
    required this.tileColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 113,
      decoration: BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.gray100),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: AppPalette.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: icon,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppPalette.gray800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
