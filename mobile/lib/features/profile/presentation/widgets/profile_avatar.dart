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

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.onTap,
    this.badge,
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
        child: _hasRemotePhoto
            ? Image.network(
                avatarUrl!.trim(),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) =>
                    _defaultImage(),
              )
            : _defaultImage(),
      ),
    );

    if (onTap == null && badge == null) return avatar;

    return GestureDetector(
      onTap: onTap,
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
