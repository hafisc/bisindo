import 'package:firebase_auth/firebase_auth.dart';
import '../errors/failures.dart';

/// Maps Firebase exception codes to typed [AuthFailure] instances.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
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
    default:
      return AuthFailure(e.message ?? 'Autentikasi gagal.');
  }
}
