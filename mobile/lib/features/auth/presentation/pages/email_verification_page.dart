import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_primary_button.dart';

/// Page yang ditampilkan setelah user register dengan email/password.
/// User harus membuka email dan klik link verifikasi, lalu tekan tombol
/// "Sudah Verifikasi" di halaman ini.
class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String password;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final verifyState = ref.watch(emailVerificationProvider);

        ref.listen<EmailVerificationState>(emailVerificationProvider,
            (prev, next) {
          if (next.isVerified) {
            // Email verified! Navigate to login
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Email berhasil diverifikasi! Silakan masuk.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF22C55E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            context.go(AppRoutes.login);
          }

          if (next.message != null && !next.isVerified) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    next.message!,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  backgroundColor: next.isSending
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
          }
        });

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ── Dekorasi blob
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ── Icon envelope
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Verifikasi Email',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Kami telah mengirimkan link verifikasi ke:',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Email address chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Silakan buka email dan klik link verifikasi, '
                        'lalu tekan tombol di bawah.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Tombol "Sudah Verifikasi"
                      AuthPrimaryButton(
                        label: 'Sudah Verifikasi',
                        isLoading: verifyState.isChecking,
                        onPressed: () async {
                          final notifier = ref.read(
                            emailVerificationProvider.notifier,
                          );
                          await notifier.checkVerification(
                            email: widget.email,
                            password: widget.password,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Kirim ulang email
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: (_cooldownSeconds > 0 ||
                                  verifyState.isSending)
                              ? null
                              : () async {
                                  final notifier = ref.read(
                                    emailVerificationProvider.notifier,
                                  );
                                  await notifier.resendEmail(
                                    email: widget.email,
                                    password: widget.password,
                                  );
                                  _startCooldown();
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: verifyState.isSending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _cooldownSeconds > 0
                                      ? 'Kirim Ulang ($_cooldownSeconds s)'
                                      : 'Kirim Ulang Email',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const Spacer(),

                      // ── Kembali ke login
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(
                          'Kembali ke halaman masuk',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
