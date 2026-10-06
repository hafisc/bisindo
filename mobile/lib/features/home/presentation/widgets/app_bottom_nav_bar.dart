import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';

/// Bottom navigation 5 kolom dengan tombol Scan bulat yang menonjol di tengah.
///
/// [currentIndex] mengikuti 4 tab: 0 Beranda, 1 Kamus, 2 Riwayat, 3 Profil.
/// Nilai null berarti tidak ada tab yang aktif.
class AppBottomNavBar extends StatelessWidget {
  final int? currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanTap,
  });

  static const double _barHeight = 64;
  static const double _scanSize = 60;
  // Bagian tombol Scan yang menonjol di atas bar.
  static const double _overflow = 18;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _overflow + _barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EEF6), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A0F172A),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    _NavItem(
                      label: AppStrings.navHome,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      isActive: currentIndex == 0,
                      onTap: () => onTabSelected(0),
                    ),
                    _NavItem(
                      label: AppStrings.navDictionary,
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book_rounded,
                      isActive: currentIndex == 1,
                      onTap: () => onTabSelected(1),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                    _NavItem(
                      label: AppStrings.navHistory,
                      icon: Icons.history_rounded,
                      activeIcon: Icons.history_rounded,
                      isActive: currentIndex == 2,
                      onTap: () => onTabSelected(2),
                    ),
                    _NavItem(
                      label: AppStrings.navProfile,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      isActive: currentIndex == 3,
                      onTap: () => onTabSelected(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _ScanButton(onTap: onScanTap)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 25,
                color: isActive ? AppPalette.primary : AppPalette.gray600,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppPalette.primary : AppPalette.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.navScan,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppBottomNavBar._scanSize,
          height: AppBottomNavBar._scanSize,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x592563EB),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.crop_free_rounded, size: 32, color: Colors.white),
              Icon(Icons.back_hand_rounded, size: 15, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
