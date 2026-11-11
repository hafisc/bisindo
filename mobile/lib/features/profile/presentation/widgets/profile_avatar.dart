import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';

/// Avatar bulat untuk halaman profil.
///
/// Menampilkan foto dari [avatarUrl] bila tersedia, dan jatuh kembali ke
/// ilustrasi default bila URL kosong atau gagal dimuat.
class ProfileAvatar extends StatelessWidget {
  static const String defaultAsset = 'assets/images/avatar_default.png';

  final String? avatarUrl;
  final double size;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isLoading;

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.onTap,
    this.badge,
    this.isLoading = false,
  });

  bool get _hasRemotePhoto => (avatarUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.gray200,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _hasRemotePhoto
                ? Image.network(
                    avatarUrl!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _defaultImage(),
                  )
                : _defaultImage(),
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null && badge == null) return avatar;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (badge != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
        ],
      ),
    );
  }

  Widget _defaultImage() {
    return Image.asset(
      defaultAsset,
      fit: BoxFit.cover,
      width: size,
      height: size,
    );
  }
}

/// Badge kecil (ikon kamera) untuk menandakan avatar bisa diganti.
class ProfileAvatarEditBadge extends StatelessWidget {
  final double size;

  const ProfileAvatarEditBadge({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.white, width: 2),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
