import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';
import '../../domain/avatar_data_uri.dart';

/// Avatar bulat untuk halaman profil.
///
/// [avatarUrl] bisa berupa data URI (foto yang diunggah dari aplikasi, lihat
/// [AvatarDataUri]) atau URL biasa (foto akun Google). Bila kosong atau gagal
/// dimuat, yang tampil ilustrasi default.
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

  // Hasil decode terakhir disimpan agar foto tidak di-decode ulang dan
  // berkedip setiap kali halaman di-rebuild.
  static String? _cachedUri;
  static Uint8List? _cachedBytes;

  static Uint8List? _bytesOf(String uri) {
    if (uri != _cachedUri) {
      _cachedUri = uri;
      _cachedBytes = AvatarDataUri.decode(uri);
    }
    return _cachedBytes;
  }

  /// Foto dari [url] (data URI atau URL biasa), atau ilustrasi bawaan bila
  /// kosong atau gagal dimuat. Dipakai juga oleh avatar di Beranda.
  static Widget photo(String? url, {required double size}) {
    final value = (url ?? '').trim();
    Widget fallback() => Image.asset(
          defaultAsset,
          fit: BoxFit.cover,
          width: size,
          height: size,
        );

    if (value.isEmpty) return fallback();

    if (AvatarDataUri.isDataUri(value)) {
      final bytes = _bytesOf(value);
      if (bytes == null) return fallback();
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Image.network(
      value,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }

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
            photo(avatarUrl, size: size),
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
