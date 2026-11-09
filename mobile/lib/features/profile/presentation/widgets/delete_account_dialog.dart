import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Dialog konfirmasi penghapusan akun.
///
/// Akun email/password harus memasukkan password saat ini karena Firebase
/// mewajibkan verifikasi ulang sebelum `user.delete()`. Akun Google cukup
/// diverifikasi ulang lewat Google Sign-In.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final needsPassword = ref.read(currentUserProvider)?.hasPassword ?? false;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .deleteAccount(
          password: needsPassword ? _passwordController.text : null,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      router.go(AppRoutes.login);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Akun kamu telah dihapus.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppPalette.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    } else {
      setState(() {
        _errorMessage = ref.read(profileNotifierProvider).errorMessage ??
            'Gagal menghapus akun. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final needsPassword = user?.hasPassword ?? false;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppPalette.coral.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppPalette.coral,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Hapus Akun?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.darkBlue,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Akun dan seluruh data profilmu akan dihapus secara permanen '
                'dan tidak dapat dikembalikan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppPalette.gray600,
                  height: 1.5,
                ),
              ),
              if (needsPassword) ...[
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi untuk menghapus akun';
                    }
                    return null;
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppPalette.darkBlue,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password saat ini',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
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
                      borderSide: const BorderSide(
                        color: AppPalette.coral,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppPalette.coral,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.gray600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.coral,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Hapus Akun',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
