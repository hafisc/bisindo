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
      extendBody: true, // Allows body background to flow under the notch
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppPalette.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2, context),
          backgroundColor: AppPalette.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.crop_free_rounded, // Camera/scan box
                color: Colors.white,
                size: 30,
              ),
              Icon(
                Icons.back_hand_rounded, // Small hand inside
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppPalette.white,
        elevation: 0, // We'll rely on the crisp border instead of unreliable shadow
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: CustomPaint(
          painter: _NotchBorderPainter(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
                  const SizedBox(width: 56), // Empty space for the docked FAB
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
      child: Transform.translate(
        offset: const Offset(0, -10), // Lift the button up so it aligns better with other icons
        child: Container(
          width: 56, // Slightly larger to emphasize it's the primary action
          height: 56,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.white, width: 4), // Add a white border to make it pop out of the nav bar
            boxShadow: [
              BoxShadow(
                color: AppPalette.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.back_hand_rounded, // Hand icon to indicate sign language scanning
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _NotchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0) // Subtle gray border (AppPalette.gray200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // The BottomAppBar is horizontal.
    // FloatingActionButton radius is 28 (56/2), notch margin is 8.
    // So the cutout radius is roughly 36.
    final center = size.width / 2;
    final notchRadius = 36.0;

    // Left line
    canvas.drawLine(const Offset(0, 0), Offset(center - notchRadius, 0), paint);

    // Right line
    canvas.drawLine(Offset(center + notchRadius, 0), Offset(size.width, 0), paint);

    // Draw the notch arc (a semi-circle dipping down)
    final rect = Rect.fromCircle(center: Offset(center, 0), radius: notchRadius);
    // Sweep angle is PI (half circle). We start from 0 (right) and go to PI (left).
    // Actually, in Flutter, 0 is 3 o'clock. PI is 9 o'clock.
    canvas.drawArc(rect, 0, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
