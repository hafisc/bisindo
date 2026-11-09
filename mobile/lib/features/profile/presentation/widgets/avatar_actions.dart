import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_palette.dart';
import '../providers/profile_provider.dart';

enum _AvatarAction { gallery, camera, remove }

/// Menampilkan pilihan sumber foto profil, lalu mengunggah hasilnya ke
/// Cloud Storage dan menyimpan URL-nya ke Firestore.
Future<void> showAvatarPicker(BuildContext context, WidgetRef ref) async {
  final currentUrl =
      (ref.read(profileNotifierProvider).profile.avatarUrl ?? '').trim();
  final hasPhoto = currentUrl.isNotEmpty;

  final action = await showModalBottomSheet<_AvatarAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AvatarSourceSheet(hasPhoto: hasPhoto),
  );

  if (action == null || !context.mounted) return;

  if (action == _AvatarAction.remove) {
    final success =
        await ref.read(profileNotifierProvider.notifier).removeAvatar();
    if (!context.mounted) return;
    _showResult(
      context,
      success ? 'Foto profil berhasil dihapus.' : _errorOf(ref),
      success,
    );
    return;
  }

  final picker = ImagePicker();
  final XFile? picked = await picker.pickImage(
    source: action == _AvatarAction.gallery
        ? ImageSource.gallery
        : ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (picked == null || !context.mounted) return;

  final success = await ref
      .read(profileNotifierProvider.notifier)
      .uploadAvatar(picked.path);

  if (!context.mounted) return;
  _showResult(
    context,
    success ? 'Foto profil berhasil diperbarui.' : _errorOf(ref),
    success,
  );
}

String _errorOf(WidgetRef ref) =>
    ref.read(profileNotifierProvider).errorMessage ??
    'Gagal memperbarui foto profil.';

void _showResult(BuildContext context, String message, bool success) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: success ? AppPalette.success : AppPalette.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
}

class _AvatarSourceSheet extends StatelessWidget {
  final bool hasPhoto;

  const _AvatarSourceSheet({required this.hasPhoto});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Foto Profil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.darkBlue,
                ),
              ),
            ),
            _SheetTile(
              icon: Icons.photo_library_outlined,
              label: 'Pilih dari Galeri',
              onTap: () =>
                  Navigator.pop(context, _AvatarAction.gallery),
            ),
            _SheetTile(
              icon: Icons.photo_camera_outlined,
              label: 'Ambil dari Kamera',
              onTap: () => Navigator.pop(context, _AvatarAction.camera),
            ),
            if (hasPhoto)
              _SheetTile(
                icon: Icons.delete_outline_rounded,
                label: 'Hapus Foto',
                color: AppPalette.coral,
                onTap: () => Navigator.pop(context, _AvatarAction.remove),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF334155);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: effectiveColor,
        ),
      ),
    );
  }
}
