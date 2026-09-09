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
