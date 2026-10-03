import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';

/// Baris atas Beranda: logo di kiri, lonceng notifikasi dan avatar di kanan.
class HomeHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const HomeHeader({super.key, this.onNotificationTap, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/bisindo-logo.webp',
          height: 50,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        _NotificationButton(onTap: onNotificationTap),
        const SizedBox(width: 11),
        _Avatar(onTap: onAvatarTap),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NotificationButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x1A0F172A),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: AppPalette.gray800,
              ),
              Positioned(
                top: 6,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppPalette.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final VoidCallback? onTap;
  const _Avatar({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppPalette.softBlue,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/avatar_default.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
