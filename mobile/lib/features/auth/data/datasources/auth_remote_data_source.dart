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

  Future<void> logout();
}
