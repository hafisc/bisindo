import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/errors/failures.dart';
import 'package:bisindo_translator/features/auth/domain/entities/user_entity.dart';
import 'package:bisindo_translator/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisindo_translator/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  Either<Failure, UserEntity> loginResult = const Right(
    UserEntity(
      id: 'uid-1',
      email: 'user@example.com',
      displayName: 'User',
      isEmailVerified: true,
      hasPassword: true,
    ),
  );
  Either<Failure, UserEntity> registerResult = const Right(
    UserEntity(
      id: 'uid-2',
      email: 'new@example.com',
      displayName: 'New User',
      hasPassword: true,
    ),
  );
  Either<Failure, UserEntity> googleResult = const Right(
    UserEntity(
      id: 'uid-g',
      email: 'google@example.com',
      displayName: 'Google User',
      isEmailVerified: true,
      isGoogleUser: true,
    ),
  );
  Either<Failure, void> resendResult = const Right(null);
  Either<Failure, bool> checkVerifiedResult = const Right(true);
  Either<Failure, void> resetPasswordResult = const Right(null);
  Either<Failure, void> reauthResult = const Right(null);
  Either<Failure, void> changePasswordResult = const Right(null);
  Either<Failure, void> deleteAccountResult = const Right(null);
  Either<Failure, void> logoutResult = const Right(null);

  @override
  Stream<UserEntity?> get authStateChanges => const Stream<UserEntity?>.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async =>
      loginResult;

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async =>
      registerResult;

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async => googleResult;

  @override
  Future<Either<Failure, void>> sendVerificationEmail({
    required String email,
    required String password,
  }) async =>
      resendResult;

  @override
  Future<Either<Failure, bool>> checkEmailVerified({
    required String email,
    required String password,
  }) async =>
      checkVerifiedResult;

  @override
  Future<Either<Failure, void>> sendPasswordReset({required String email}) async =>
      resetPasswordResult;

  @override
  Future<Either<Failure, void>> reauthenticate({required String password}) async =>
      reauthResult;

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      changePasswordResult;

  @override
  Future<Either<Failure, void>> deleteAccount({String? password}) async =>
      deleteAccountResult;

  @override
  Future<Either<Failure, void>> logout() async => logoutResult;
}

ProviderContainer _createContainer(_FakeAuthRepository repo) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late _FakeAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeAuthRepository();
    container = _createContainer(repo);
  });

  tearDown(() => container.dispose());

  group('LoginNotifier', () {
    test('loginWithEmail berhasil mengubah status menjadi success dengan user', () async {
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.loginWithEmail(
        email: 'user@example.com',
        password: 'password123',
      );

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.success);
      expect(state.user?.id, 'uid-1');
      expect(state.errorMessage, isNull);
    });

    test('loginWithEmail email belum terverifikasi menyimpan unverifiedEmail dan password', () async {
      repo.loginResult = const Left(EmailNotVerifiedFailure(email: 'belum@example.com'));
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.loginWithEmail(
        email: '  belum@example.com  ',
        password: 'secret',
      );

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.emailNotVerified);
      expect(state.unverifiedEmail, 'belum@example.com');
      expect(state.unverifiedPassword, 'secret');
    });

    test('loginWithEmail gagal menghasilkan status error dengan pesan failure', () async {
      repo.loginResult = const Left(WrongPasswordFailure());
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.loginWithEmail(
        email: 'user@example.com',
        password: 'salah',
      );

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, const WrongPasswordFailure().message);
    });

    test('loginWithGoogle batal mengembalikan status ke idle tanpa pesan error', () async {
      repo.googleResult = const Left(GoogleSignInCancelledFailure());
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.loginWithGoogle();

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.idle);
      expect(state.errorMessage, isNull);
    });

    test('loginWithGoogle berhasil mengubah status menjadi success', () async {
      final notifier = container.read(loginNotifierProvider.notifier);

      await notifier.loginWithGoogle();

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.success);
      expect(state.user?.isGoogleUser, isTrue);
    });

    test('resetState mengembalikan state ke kondisi awal', () async {
      repo.loginResult = const Left(WrongPasswordFailure());
      final notifier = container.read(loginNotifierProvider.notifier);
      await notifier.loginWithEmail(email: 'a@b.c', password: '123');

      notifier.resetState();

      final state = container.read(loginNotifierProvider);
      expect(state.status, AuthStatus.idle);
      expect(state.errorMessage, isNull);
    });
  });

  group('RegisterNotifier', () {
    test('registerWithEmail berhasil mengarahkan ke emailNotVerified dan trim email', () async {
      final notifier = container.read(registerNotifierProvider.notifier);

      await notifier.registerWithEmail(
        name: 'Budi',
        email: '  new@example.com ',
        password: 'password123',
      );

      final state = container.read(registerNotifierProvider);
      expect(state.status, AuthStatus.emailNotVerified);
      expect(state.unverifiedEmail, 'new@example.com');
      expect(state.unverifiedPassword, 'password123');
    });

    test('registerWithEmail gagal mengubah status ke error', () async {
      repo.registerResult = const Left(EmailAlreadyInUseFailure());
      final notifier = container.read(registerNotifierProvider.notifier);

      await notifier.registerWithEmail(
        name: 'Budi',
        email: 'dup@example.com',
        password: 'password123',
      );

      final state = container.read(registerNotifierProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, const EmailAlreadyInUseFailure().message);
    });

    test('registerWithGoogle berhasil dan batal ditangani dengan tepat', () async {
      final notifier = container.read(registerNotifierProvider.notifier);

      repo.googleResult = const Left(GoogleSignInCancelledFailure());
      await notifier.registerWithGoogle();
      expect(container.read(registerNotifierProvider).status, AuthStatus.idle);

      repo.googleResult = const Right(
        UserEntity(id: 'g1', email: 'g@x.com', displayName: 'G'),
      );
      await notifier.registerWithGoogle();
      expect(container.read(registerNotifierProvider).status, AuthStatus.success);

      notifier.resetState();
      expect(container.read(registerNotifierProvider).status, AuthStatus.idle);
    });
  });

  group('EmailVerificationNotifier', () {
    test('resendEmail berhasil dan gagal mengisi message sesuai hasil', () async {
      final notifier = container.read(emailVerificationProvider.notifier);

      await notifier.resendEmail(email: 'a@x.com', password: 'p');
      expect(container.read(emailVerificationProvider).isSending, isFalse);
      expect(
        container.read(emailVerificationProvider).message,
        'Email verifikasi telah dikirim ulang.',
      );

      repo.resendResult = const Left(TooManyRequestsFailure());
      await notifier.resendEmail(email: 'a@x.com', password: 'p');
      expect(
        container.read(emailVerificationProvider).message,
        const TooManyRequestsFailure().message,
      );
    });

    test('checkVerification menangani verified true, false, dan failure', () async {
      final notifier = container.read(emailVerificationProvider.notifier);

      repo.checkVerifiedResult = const Right(true);
      expect(await notifier.checkVerification(email: 'a@x.com', password: 'p'), isTrue);
      expect(container.read(emailVerificationProvider).isVerified, isTrue);

      repo.checkVerifiedResult = const Right(false);
      expect(await notifier.checkVerification(email: 'a@x.com', password: 'p'), isFalse);
      expect(container.read(emailVerificationProvider).isVerified, isFalse);

      repo.checkVerifiedResult = const Left(NetworkAuthFailure());
      expect(await notifier.checkVerification(email: 'a@x.com', password: 'p'), isFalse);
      expect(
        container.read(emailVerificationProvider).message,
        const NetworkAuthFailure().message,
      );

      notifier.reset();
      expect(container.read(emailVerificationProvider).message, isNull);
    });
  });

  group('PasswordResetNotifier', () {
    test('sendReset berhasil, gagal, dan reset bekerja dengan benar', () async {
      final notifier = container.read(passwordResetProvider.notifier);

      await notifier.sendReset(email: 'a@x.com');
      expect(container.read(passwordResetProvider).isSent, isTrue);
      expect(container.read(passwordResetProvider).errorMessage, isNull);

      repo.resetPasswordResult = const Left(UserNotFoundFailure());
      await notifier.sendReset(email: 'missing@x.com');
      expect(container.read(passwordResetProvider).isSent, isFalse);
      expect(
        container.read(passwordResetProvider).errorMessage,
        const UserNotFoundFailure().message,
      );

      notifier.reset();
      expect(container.read(passwordResetProvider).errorMessage, isNull);
    });
  });

  group('AccountSecurityNotifier', () {
    test('changePassword, reauthenticate, dan deleteAccount mengembalikan hasil dan state tepat', () async {
      final notifier = container.read(accountSecurityProvider.notifier);

      expect(
        await notifier.changePassword(
          currentPassword: 'old',
          newPassword: 'newpassword',
        ),
        isTrue,
      );
      expect(
        container.read(accountSecurityProvider).successMessage,
        'Password berhasil diperbarui.',
      );

      repo.changePasswordResult = const Left(WrongPasswordFailure());
      expect(
        await notifier.changePassword(
          currentPassword: 'bad',
          newPassword: 'newpassword',
        ),
        isFalse,
      );
      expect(
        container.read(accountSecurityProvider).errorMessage,
        const WrongPasswordFailure().message,
      );

      expect(await notifier.reauthenticate('old'), isTrue);
      expect(container.read(accountSecurityProvider).errorMessage, isNull);

      repo.reauthResult = const Left(PasswordNotSetFailure());
      expect(await notifier.reauthenticate('old'), isFalse);
      expect(
        container.read(accountSecurityProvider).errorMessage,
        const PasswordNotSetFailure().message,
      );

      expect(await notifier.deleteAccount(password: 'old'), isTrue);
      expect(
        container.read(accountSecurityProvider).successMessage,
        'Akun berhasil dihapus.',
      );

      repo.deleteAccountResult = const Left(RequiresRecentLoginFailure());
      expect(await notifier.deleteAccount(), isFalse);
      expect(
        container.read(accountSecurityProvider).errorMessage,
        const RequiresRecentLoginFailure().message,
      );

      notifier.reset();
      expect(container.read(accountSecurityProvider).errorMessage, isNull);
      expect(container.read(accountSecurityProvider).successMessage, isNull);
    });
  });
}
