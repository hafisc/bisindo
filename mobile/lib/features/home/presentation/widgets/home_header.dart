import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/constants/app_strings.dart';
import '../notification_store.dart';

/// Baris atas Beranda: sapaan pengguna di kiri, lonceng notifikasi dan avatar di kanan.
class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    required this.userName,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${AppStrings.homeGreeting}$userName \u{1F44B}',
                style: GoogleFonts.poppins(
                  fontSize: 20, // Agak dikecilkan biar pas
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppPalette.darkBlue,
                ),
              ),
            ),
            _NotificationButton(onTap: onNotificationTap),
            const SizedBox(width: 11),
            _Avatar(onTap: onAvatarTap),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.homeSubtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.5,
            color: AppPalette.gray600,
          ),
        ),
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
              ListenableBuilder(
                listenable: NotificationStore.instance,
                builder: (context, _) {
                  if (!NotificationStore.instance.hasUnread) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
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
                  );
                },
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
