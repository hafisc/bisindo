import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginNotifierProvider.notifier).loginWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  void _onGoogleSignIn() {
    ref.read(loginNotifierProvider.notifier).loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginNotifierProvider);

    // ── Listen for state changes
    ref.listen<AuthState>(loginNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.success) {
        context.go(AppRoutes.home);
      }

      if (next.status == AuthStatus.emailNotVerified) {
        // Navigate to email verification page
        context.push(
          AppRoutes.emailVerification,
          extra: {
            'email': next.unverifiedEmail ?? '',
            'password': next.unverifiedPassword ?? '',
          },
        );
        // Reset state so user can try again after verifying
        ref.read(loginNotifierProvider.notifier).resetState();
      }

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next.errorMessage!,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          children: [
          // ── Dekorasi blob biru muda pojok kiri bawah
          Positioned(
            left: -60,
            bottom: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 60,
            bottom: -80,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFBFDBFE),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Dekorasi blob biru muda pojok kanan atas
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF), // warna biru sangat muda
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Konten utama
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 24,
                          ), // Kembali ke posisi normal
                          // Logo
                          Image.asset(
                            'assets/images/bisindo-logo.webp',
                            height: 50,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(
                            height: 24,
                          ), // More breathing room after logo
                          // Judul
                          Text(
                            'Selamat Datang!',
                            style: GoogleFonts.poppins(
                              fontSize: 28, // Slightly larger title
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk untuk melanjutkan\nke aplikasi BISINDO Translator.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 48), // Big gap before inputs
                          // Email field
                          AuthTextField(
                            hintText: 'Email',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ), // Increased spacing between fields
                          // Password field
                          AuthTextField(
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ), // Increased spacing before options
                          // Ingat saya + Lupa password
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ingat saya',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    context.push(AppRoutes.forgotPassword),
                                child: Text(
                                  'Lupa password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Tombol Masuk
                          AuthPrimaryButton(
                            label: 'Masuk',
                            onPressed: _onLogin,
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Google button
                          GoogleSignInButton(
                            label: 'Lanjut dengan Google',
                            onPressed: isLoading ? () {} : _onGoogleSignIn,
                          ),

                          const SizedBox(height: 20),

                          // Footer: Daftar di sini
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                                children: [
                                  const TextSpan(text: 'Belum punya akun? '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () =>
                                          context.push(AppRoutes.register),
                                      child: Text(
                                        'Daftar di sini',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
