import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';

class MainWrapperPage extends StatelessWidget {
  final Widget child;

  const MainWrapperPage({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.dictionary)) return 1;
    if (location.startsWith(AppRoutes.scan)) return 2;
    if (location.startsWith(AppRoutes.history)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.dictionary);
        break;
      case 2:
        context.go(AppRoutes.scan);
        break;
      case 3:
        context.go(AppRoutes.history);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppPalette.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                  isSelected: selectedIndex == 0,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: 'Kamus',
                  isSelected: selectedIndex == 1,
                ),
                _buildCenterScanItem(
                  context: context,
                  isSelected: selectedIndex == 2,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Riwayat',
                  isSelected: selectedIndex == 3,
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: selectedIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppPalette.primary : AppPalette.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppPalette.primary : AppPalette.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterScanItem({
    required BuildContext context,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(2, context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppPalette.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppPalette.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.center_focus_strong_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
