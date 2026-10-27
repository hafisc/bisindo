import 'package:firebase_auth/firebase_auth.dart';
import '../errors/failures.dart';

/// Maps Firebase exception codes to typed [AuthFailure] instances.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class EmailNotVerifiedException implements Exception {
  final String email;
  const EmailNotVerifiedException({required this.email});
  @override
  String toString() => 'EmailNotVerifiedException: $email belum diverifikasi.';
}

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
  @override
  String toString() => 'GoogleSignInCancelledException: User membatalkan login.';
}

/// Converts a [FirebaseAuthException] to the appropriate [AuthFailure].
AuthFailure mapFirebaseAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return const InvalidEmailFailure();
    case 'wrong-password':
    case 'invalid-credential':
      return const WrongPasswordFailure();
    case 'user-not-found':
      return const UserNotFoundFailure();
    case 'email-already-in-use':
      return const EmailAlreadyInUseFailure();
    case 'weak-password':
      return const WeakPasswordFailure();
    case 'too-many-requests':
      return const TooManyRequestsFailure();
    case 'network-request-failed':
      return const NetworkAuthFailure();
    case 'user-disabled':
      return const AuthFailure('Akun ini telah dinonaktifkan.');
    case 'operation-not-allowed':
      return const AuthFailure('Metode autentikasi ini belum diaktifkan.');
    default:
      return AuthFailure(e.message ?? 'Autentikasi gagal.');
  }
}
