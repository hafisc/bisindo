/// Konfigurasi autentikasi Google Sign-In yang dibaca dari environment build.
///
/// Nilai Web Client ID (`client_type: 3` pada Firebase OAuth) dapat disuntikkan
/// saat build lewat `--dart-define`:
/// ```bash
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
/// ```
/// atau lewat file `.env` (lihat `mobile/.env.example`):
/// ```bash
/// flutter run --dart-define-from-file=.env
/// ```
///
/// Bila tidak diisi (`null`), plugin `google_sign_in` di Android otomatis
/// membaca `default_web_client_id` yang dihasilkan plugin Gradle
/// `com.google.gms.google-services` dari `android/app/google-services.json`.
class AuthConfig {
  const AuthConfig._();

  static const String _envServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Web Client ID untuk `GoogleSignIn.serverClientId`, atau `null` bila tidak
  /// disetel saat build.
  static String? get googleServerClientId =>
      resolveServerClientId(_envServerClientId);

  /// Mengembalikan `null` bila [raw] kosong/spasi, atau nilai yang sudah di-trim.
  static String? resolveServerClientId(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
