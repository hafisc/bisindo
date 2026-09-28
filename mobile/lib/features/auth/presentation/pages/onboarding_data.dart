/// Data model untuk tiap slide onboarding.
class OnboardingSlideData {
  final String imagePath;
  final String? logoPath;
  final bool textOnTop;
  final String title;
  final String subtitle;

  const OnboardingSlideData({
    required this.imagePath,
    this.logoPath,
    this.textOnTop = false,
    required this.title,
    required this.subtitle,
  });
}

/// Daftar konten 3 slide onboarding.
const List<OnboardingSlideData> onboardingSlides = [
  OnboardingSlideData(
    imagePath: 'assets/images/onboarding_1.png',
    logoPath: 'assets/images/bisindo-logo.webp',
    textOnTop: true,
    title: 'Jembatan komunikasi\nuntuk semua.',
    subtitle:
        'Aplikasi penerjemah Bahasa Isyarat Indonesia (BISINDO) yang membantu kamu berkomunikasi dengan lebih mudah dan inklusif.',
  ),
  OnboardingSlideData(
    imagePath: 'assets/images/onboarding_2.jpg',
    title: 'Deteksi Gesture\nSecara Real-Time',
    subtitle:
        'Arahkan kamera ke tangan kamu, biarkan aplikasi mendeteksi gesture secara langsung dan menampilkan teks serta suara.',
  ),
  OnboardingSlideData(
    imagePath: 'assets/images/onboarding_3.jpg',
    title: 'Lebih dari Sekadar\nPenerjemah',
    subtitle:
        'Jelajahi kamus BISINDO, latihan gesture, dan simpan riwayat terjemahan. Belajar jadi lebih mudah dan menyenangkan.',
  ),
];
