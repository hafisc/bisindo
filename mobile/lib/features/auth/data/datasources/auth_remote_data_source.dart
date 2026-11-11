import '../models/user_model.dart';

/// Abstract contract for remote authentication operations.
abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> sendVerificationEmail({
    required String email,
    required String password,
  });

  Future<bool> checkEmailVerified({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});

  /// Memverifikasi ulang pengguna dengan password saat ini.
  /// Wajib dipanggil sebelum operasi sensitif (ganti password / hapus akun).
  Future<void> reauthenticate({required String password});

  /// Mengganti password pengguna setelah verifikasi password lama.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Menghapus akun pengguna yang sedang login.
  /// [password] wajib untuk akun email/password; akun Google akan
  /// direautentikasi lewat Google Sign-In.
  Future<void> deleteAccount({String? password});

  Future<void> logout();
}
