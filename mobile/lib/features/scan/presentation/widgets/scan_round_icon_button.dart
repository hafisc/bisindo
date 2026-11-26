import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';

/// Tombol ikon melingkar dengan latar semi-transparan untuk layar kamera.
class ScanRoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ScanRoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.scanOverlay,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppPalette.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
