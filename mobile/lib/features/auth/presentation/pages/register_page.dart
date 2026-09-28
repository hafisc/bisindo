import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kamu harus menyetujui Syarat dan Ketentuan terlebih dahulu.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    // TODO: integrasikan Firebase Auth
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _onGoogleSignUp() {
    // TODO: integrasikan Google Sign-In
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Dekorasi blob biru muda pojok kanan bawah
          Positioned(
            right: -50,
            bottom: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back button
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF0F172A),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),

                // ── Form
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Judul
                          Text(
                            'Daftar Akun',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Buat akun untuk mulai menggunakan\nBISINDO Translator.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Nama lengkap
                          AuthTextField(
                            hintText: 'Nama lengkap',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Email
                          AuthTextField(
                            hintText: 'Email',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!v.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Password
                          AuthTextField(
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _passwordController,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (v.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Konfirmasi password
                          AuthTextField(
                            hintText: 'Konfirmasi password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _confirmPasswordController,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (v != _passwordController.text) {
                                return 'Password tidak sama';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Terms & Conditions checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (v) => setState(
                                      () => _agreeToTerms = v ?? false),
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      color: const Color(0xFF64748B),
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'Saya setuju dengan '),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () {
                                            // TODO: buka halaman syarat & ketentuan
                                          },
                                          child: Text(
                                            'Syarat dan Ketentuan',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' serta '),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () {
                                            // TODO: buka halaman kebijakan privasi
                                          },
                                          child: Text(
                                            'Kebijakan Privasi',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Tombol Daftar
                          AuthPrimaryButton(
                            label: 'Daftar',
                            onPressed: _onRegister,
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
                            label: 'Daftar dengan Google',
                            onPressed: _onGoogleSignUp,
                          ),

                          const SizedBox(height: 20),

                          // Footer: Sudah punya akun
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                                children: [
                                  const TextSpan(text: 'Sudah punya akun? '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => context.pop(),
                                      child: Text(
                                        'Masuk di sini',
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
