import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract for Authentication operations in the domain layer.
///
/// Implemented by [AuthRepositoryImpl] in the data layer.
abstract class AuthRepository {
  /// Emits whenever auth state changes (e.g. login, logout, token refresh).
  Stream<UserEntity?> get authStateChanges;

  /// The currently authenticated user, or null if unauthenticated.
  UserEntity? get currentUser;

  /// Logs in a user using email and password.
  /// Returns [EmailNotVerifiedFailure] if the account email is not yet verified.
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with name, email, and password.
  /// Sends verification email and returns the created [UserEntity].
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Signs in or registers the user using Google Sign-In.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Re-sends verification email to the user.
  Future<Either<Failure, void>> sendVerificationEmail({
    required String email,
    required String password,
  });

  /// Checks if the user's email has been verified.
  Future<Either<Failure, bool>> checkEmailVerified({
    required String email,
    required String password,
  });

  /// Sends a password reset link to [email].
  Future<Either<Failure, void>> sendPasswordReset({
    required String email,
  });

  /// Signs the user out from both Firebase and Google.
  Future<Either<Failure, void>> logout();
}
