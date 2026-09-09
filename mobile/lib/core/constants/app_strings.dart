/// App-wide string constants — UI labels, error messages, asset paths.
class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────
  static const String appName = 'BISINDO Translator';
  static const String appTagline = 'Jembatan Komunikasi Tanpa Batas';

  // ── Onboarding ────────────────────────────────────────────────
  static const String onboarding1Title = 'Selamat Datang di BISINDO';
  static const String onboarding1Subtitle =
      'Aplikasi penerjemah Bahasa Isyarat Indonesia berbasis AI.';
  static const String onboarding2Title = 'Deteksi Real-Time';
  static const String onboarding2Subtitle =
      'Arahkan kamera ke tangan dan lihat hasil translasi secara langsung.';
  static const String onboarding3Title = 'Belajar BISINDO';
  static const String onboarding3Subtitle =
      'Pelajari gestur huruf dan kata dengan panduan interaktif.';

  // ── Auth ──────────────────────────────────────────────────────
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String confirmPassword = 'Konfirmasi Kata Sandi';
  static const String fullName = 'Nama Lengkap';
  static const String forgotPassword = 'Lupa kata sandi?';
  static const String noAccount = 'Belum punya akun? ';
  static const String haveAccount = 'Sudah punya akun? ';
  static const String loginWithGoogle = 'Masuk dengan Google';
  static const String logout = 'Keluar';

  // ── Navigation ────────────────────────────────────────────────
  static const String navHome = 'Beranda';
  static const String navScan = 'Scan';
  static const String navDictionary = 'Kamus';
  static const String navHistory = 'Riwayat';
  static const String navProfile = 'Profil';

  // ── Scanner ───────────────────────────────────────────────────
  static const String scannerTitle = 'Penerjemah';
  static const String scannerHint = 'Arahkan kamera ke tangan Anda';
  static const String scannerDetecting = 'Mendeteksi...';
  static const String modeLetter = 'Huruf';
  static const String modeWord = 'Kata';

  // ── Dictionary ────────────────────────────────────────────────
  static const String dictionaryTitle = 'Kamus BISINDO';
  static const String dictionarySearch = 'Cari gestur...';
  static const String categoryAll = 'Semua';
  static const String categoryAlphabet = 'Alfabet';
  static const String categoryWord = 'Kata Umum';

  // ── History ───────────────────────────────────────────────────
  static const String historyTitle = 'Riwayat Translasi';
  static const String historyEmpty = 'Belum ada riwayat translasi.';
  static const String historyClearAll = 'Hapus Semua';

  // ── Profile ───────────────────────────────────────────────────
  static const String profileTitle = 'Profil';
  static const String editProfile = 'Edit Profil';
  static const String settings = 'Pengaturan';
  static const String about = 'Tentang Aplikasi';

  // ── Errors ────────────────────────────────────────────────────
  static const String errorGeneral = 'Terjadi kesalahan. Coba lagi.';
  static const String errorNetwork = 'Tidak ada koneksi internet.';
  static const String errorInvalidEmail = 'Format email tidak valid.';
  static const String errorWeakPassword = 'Password minimal 8 karakter.';
  static const String errorPasswordMismatch = 'Password tidak cocok.';
  static const String errorUserNotFound = 'Akun tidak ditemukan.';
  static const String errorWrongPassword = 'Email atau password salah.';
  static const String errorEmailInUse = 'Email sudah terdaftar.';
  static const String errorCameraPermission =
      'Izin kamera diperlukan untuk fitur ini.';

  // ── Asset Paths ───────────────────────────────────────────────
  static const String logoPath = 'assets/images/logo.png';
  static const String splashLottiePath = 'assets/animations/splash.json';
  static const String emptyLottiePath = 'assets/animations/empty.json';
  static const String tfliteModelPath = 'assets/models/bisindo_model.tflite';
  static const String tfliteLabelsPath = 'assets/models/labels.txt';
}
