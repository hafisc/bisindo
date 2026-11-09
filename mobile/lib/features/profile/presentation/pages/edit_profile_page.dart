import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_actions.dart';
import '../widgets/profile_avatar.dart';

/// Pilihan peran pengguna yang tersedia di form edit profil.
const List<String> _roleOptions = <String>[
  'Mahasiswa',
  'Dosen',
  'Umum',
];

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _studentIdController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();

    final profile = ref.read(profileNotifierProvider).profile;
    _nameController = TextEditingController(text: profile.name);
    _studentIdController = TextEditingController(text: profile.studentId);
    _selectedRole = _resolveRole(profile);
  }

  /// Pastikan peran yang tersimpan selalu ada di daftar pilihan dropdown.
  String _resolveRole(UserProfile profile) {
    final role = profile.role.trim();

    if (_roleOptions.contains(role)) return role;
    if (role.isEmpty || role == '-') return _roleOptions.first;

    // Peran lama di luar daftar (mis. "Pengguna BISINDO") tetap ditampilkan.
    return role;
  }

  List<String> get _availableRoles {
    if (_roleOptions.contains(_selectedRole)) return _roleOptions;
    return [_selectedRole, ..._roleOptions];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .saveProfile(
          name: _nameController.text,
          studentId: _studentIdController.text,
          role: _selectedRole,
        );

    if (!mounted) return;

    final message = success
        ? 'Profil berhasil diperbarui.'
        : (ref.read(profileNotifierProvider).errorMessage ??
            'Gagal memperbarui profil.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor:
              success ? AppPalette.success : AppPalette.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

    if (success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppPalette.darkBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        avatarUrl: profile.avatarUrl,
                        size: 104,
                        isLoading: state.isUploadingAvatar,
                        onTap: () => showAvatarPicker(context, ref),
                        badge: const ProfileAvatarEditBadge(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketuk foto untuk mengganti',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppPalette.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Informasi Pribadi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.darkBlue,
                  ),
                ),
                const SizedBox(height: 12),

                _ProfileTextField(
                  label: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length < 3) {
                      return 'Nama minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _ProfileTextField(
                  label: 'NIM / Nomor Identitas',
                  hintText: 'Masukkan NIM',
                  icon: Icons.badge_outlined,
                  controller: _studentIdController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null; // opsional
                    if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
                      return 'NIM hanya boleh berisi angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _ProfileTextField(
                  label: 'Email',
                  hintText: 'Email tidak dapat diubah',
                  icon: Icons.mail_outline_rounded,
                  initialValue: profile.email.isEmpty ? '-' : profile.email,
                  enabled: false,
                ),
                const SizedBox(height: 14),

                Text(
                  'Peran',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: _inputDecoration(
                    icon: Icons.groups_outlined,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                  items: _availableRoles
                      .map(
                        (role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        ),
                      )
                      .toList(),
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: state.isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required IconData icon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF94A3B8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF94A3B8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
      ),
    );
  }
}

/// Field teks dengan label di atas, mengikuti gaya form aplikasi.
class _ProfileTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF94A3B8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF94A3B8)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppPalette.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppPalette.coral),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppPalette.coral, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
