import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: integrasikan Firebase Auth
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _onGoogleSignIn() {
    // TODO: integrasikan Google Sign-In
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                          const SizedBox(height: 12),

                          // Logo
                          Image.asset(
                            'assets/images/bisindo-logo.webp',
                            height: 50, // sedikit lebih kecil agar pas
                            fit: BoxFit.contain,
                          ),
                          
                          const SizedBox(height: 16),

                          // Judul
                          Text(
                            'Selamat Datang!',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masuk untuk melanjutkan\nke aplikasi BISINDO Translator.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Ilustrasi
                          Center(
                            child: SizedBox(
                              height: size.height * 0.25, // ukuran sedikit dikecilkan
                              child: Image.asset(
                                'assets/images/onboarding_1.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Email field
                          AuthTextField(
                            hintText: 'Email atau nomor handphone',
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

                          const SizedBox(height: 12),

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

                          const SizedBox(height: 12),

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
                                onTap: () {
                                  // TODO: forgot password
                                },
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
                            isLoading: _isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Google button
                          GoogleSignInButton(
                            label: 'Lanjut dengan Google',
                            onPressed: _onGoogleSignIn,
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
    );
  }
}

