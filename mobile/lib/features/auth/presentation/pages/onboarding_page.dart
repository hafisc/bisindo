import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/onboarding_slide_widget.dart';
import 'onboarding_data.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _dotInactive = Color(0xFFCBD5E1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _nextPage() {
    if (_currentIndex < onboardingSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(AppRoutes.login);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == onboardingSlides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: tombol "Lewati" ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: isLastPage ? null : _finishOnboarding,
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── PageView — konten slide ─────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingSlides.length,
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index),
                itemBuilder: (context, index) => OnboardingSlideWidget(
                  data: onboardingSlides[index],
                ),
              ),
            ),

            // ── Dot indicator ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingSlides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? _primaryBlue
                          : _dotInactive,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // ── Tombol Selanjutnya / Mulai Sekarang ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'Mulai Sekarang' : 'Selanjutnya',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
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
