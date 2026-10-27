// ── Failure Base ──────────────────────────────────────────────────────────────

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure(message: $message)';
}

// ── General Failures ──────────────────────────────────────────────────────────

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error terjadi.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal membaca data lokal.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Terjadi kesalahan yang tidak terduga.']);
}

// ── Auth Failures ─────────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Format email tidak valid.');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure() : super('Email atau password salah.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('Akun tidak ditemukan.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure() : super('Email sudah terdaftar.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('Password terlalu lemah.');
}

class EmailNotVerifiedFailure extends AuthFailure {
  final String email;
  const EmailNotVerifiedFailure({this.email = ''})
      : super('Email belum diverifikasi. Silakan cek inbox kamu.');
}

class GoogleSignInCancelledFailure extends AuthFailure {
  const GoogleSignInCancelledFailure() : super('Login dengan Google dibatalkan.');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
      : super('Terlalu banyak percobaan. Silakan coba lagi nanti.');
}

class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure([super.message = 'Tidak ada koneksi internet.']);
}

// ── ML / Scanner Failures ─────────────────────────────────────────────────────

class ModelLoadFailure extends Failure {
  const ModelLoadFailure([super.message = 'Gagal memuat model AI.']);
}

class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Gagal mengakses kamera.']);
}

class InferenceFailure extends Failure {
  const InferenceFailure([super.message = 'Gagal melakukan deteksi gestur.']);
}
