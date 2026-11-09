import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../providers/profile_provider.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';

const List<String> _bulan = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _formatTanggal(DateTime? date) {
  if (date == null) return 'Belum tercatat';
  return '${date.day} ${_bulan[date.month - 1]} ${date.year}';
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Profil',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppPalette.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: state.isLoading && profile.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppPalette.primary),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar + Nama + Tombol Edit
                    Row(
                      children: [
                        ProfileAvatar(
                          avatarUrl: profile.avatarUrl,
                          size: 100,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.darkBlue,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email.isEmpty ? '-' : profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _EditProfileButton(
                                onPressed: () =>
                                    context.push(AppRoutes.editProfile),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: state.errorMessage!),
                    ],

                    const SizedBox(height: 32),

                    // ── Informasi Akun
                    _SectionTitle(title: 'Informasi Akun'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: _cardDecoration,
                      child: Column(
                        children: [
                          _InfoItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Nama Lengkap',
                            value: profile.displayName,
                          ),
                          const _ItemDivider(),
                          _InfoItem(
                            icon: Icons.mail_outline_rounded,
                            title: 'Email',
                            value: profile.email.isEmpty ? '-' : profile.email,
                          ),
                          const _ItemDivider(),
                          _InfoItem(
                            icon: Icons.badge_outlined,
                            title: 'NIM / Nomor Identitas',
                            value: profile.displayStudentId,
                          ),
                          const _ItemDivider(),
                          _InfoItem(
                            icon: Icons.groups_outlined,
                            title: 'Peran',
                            value: profile.displayRole,
                          ),
                          const _ItemDivider(),
                          _InfoItem(
                            icon: Icons.calendar_today_outlined,
                            title: 'Tanggal Bergabung',
                            value: _formatTanggal(profile.joinedAt),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Pengaturan
                    _SectionTitle(title: 'Pengaturan'),
                    const SizedBox(height: 12),
                    ProfileInfoTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifikasi',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppPalette.gray400,
                        size: 20,
                      ),
                      onTap: () => _showComingSoon(
                        context,
                        'Pengaturan notifikasi segera hadir.',
                      ),
                    ),
                    ProfileInfoTile(
                      icon: Icons.language_rounded,
                      title: 'Bahasa Aplikasi',
                      trailing: Text(
                        'Indonesia',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.gray400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppPalette.coral.withValues(alpha: 0.08),
                          foregroundColor: AppPalette.coral,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFFFECACA),
                              width: 1,
                            ),
                          ),
                        ),
                        onPressed: () => LogoutDialog.show(context),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppPalette.coral,
                        ),
                        label: Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.coral,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  static BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
}

class _EditProfileButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditProfileButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.primary,
        side: const BorderSide(color: AppPalette.gray200, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(
        'Edit Profil',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppPalette.primary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppPalette.darkBlue,
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppPalette.lightGray,
      indent: 56,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppPalette.gray400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppPalette.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppPalette.coral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
