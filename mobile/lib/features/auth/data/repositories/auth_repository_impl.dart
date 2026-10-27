import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Concrete implementation of [AuthRepository] in the Data Layer.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  UserEntity? get currentUser => remoteDataSource.currentUser;

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.loginWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on EmailNotVerifiedException catch (e) {
      return Left(EmailNotVerifiedFailure(email: e.email));
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] loginWithEmail unexpected: $e');
      return const Left(UnexpectedFailure('Terjadi kesalahan saat masuk. Silakan coba lagi.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      // Immediately log out to enforce email verification before access
      await remoteDataSource.logout();
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] registerWithEmail unexpected: $e');
      return const Left(UnexpectedFailure('Terjadi kesalahan saat mendaftar. Silakan coba lagi.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } on GoogleSignInCancelledException {
      return const Left(GoogleSignInCancelledFailure());
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] signInWithGoogle unexpected: $e');
      return const Left(AuthFailure('Gagal masuk dengan Google. Silakan coba lagi.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      await remoteDataSource.sendVerificationEmail(
        email: email,
        password: password,
      );
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] sendVerificationEmail unexpected: $e');
      return const Left(AuthFailure('Gagal mengirim ulang email verifikasi.'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerified({
    required String email,
    required String password,
  }) async {
    try {
      final verified = await remoteDataSource.checkEmailVerified(
        email: email,
        password: password,
      );
      return Right(verified);
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] checkEmailVerified unexpected: $e');
      return const Left(AuthFailure('Gagal memeriksa status verifikasi.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordReset(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('[AUTH REPO] sendPasswordReset unexpected: $e');
      return const Left(AuthFailure('Gagal mengirim link reset password.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      debugPrint('[AUTH REPO] logout error: $e');
      return const Left(UnexpectedFailure('Gagal keluar akun.'));
    }
  }
}
