import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/errors/failures.dart';
import 'package:bisindo_translator/features/auth/domain/entities/user_entity.dart';
import 'package:bisindo_translator/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisindo_translator/features/auth/presentation/providers/auth_provider.dart';
import 'package:bisindo_translator/features/profile/domain/models/user_profile.dart';
import 'package:bisindo_translator/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:bisindo_translator/features/profile/presentation/providers/profile_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  UserEntity? user = const UserEntity(
    id: 'uid-profile',
    email: 'budi@example.com',
    displayName: 'Budi',
    isEmailVerified: true,
    hasPassword: true,
  );
  Either<Failure, void> logoutResult = const Right(null);
  int logoutCalls = 0;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(user);

  @override
  UserEntity? get currentUser => user;

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalls++;
    return logoutResult;
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerified({
    required String email,
    required String password,
  }) async =>
      const Right(true);

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteAccount({String? password}) async =>
      const Right(null);

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> reauthenticate({required String password}) async =>
      const Right(null);

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> sendPasswordReset({required String email}) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> sendVerificationEmail({
    required String email,
    required String password,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() =>
      throw UnimplementedError();
}

class _FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? stored = const UserProfile(
    id: 'uid-profile',
    name: 'Budi Santoso',
    email: 'budi@example.com',
    studentId: '123456',
    role: 'Mahasiswa',
  );

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String uid) async =>
      Right(stored);

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async {
    stored = profile;
    return Right(profile);
  }

  @override
  Future<Either<Failure, void>> deleteProfile(String uid) async {
    stored = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String uid,
    required String filePath,
  }) async =>
      const Right('https://example.com/avatar.jpg');

  @override
  Future<Either<Failure, void>> deleteAvatar(String uid) async =>
      const Right(null);
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late _FakeAuthRepository authRepo;
  late _FakeUserProfileRepository profileRepo;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        userProfileRepositoryProvider.overrideWithValue(profileRepo),
      ],
    );
  }

  setUp(() {
    authRepo = _FakeAuthRepository();
    profileRepo = _FakeUserProfileRepository();
  });

  test('ProfileNotifier.logout berjalan tanpa BuildContext dan mereset profil saat sukses', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    await _flush();

    expect(
      container.read(profileNotifierProvider).profile.displayName,
      'Budi Santoso',
    );

    final ok = await notifier.logout();
    final state = container.read(profileNotifierProvider);

    expect(ok, isTrue);
    expect(authRepo.logoutCalls, 1);
    expect(state.profile, UserProfile.empty);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('ProfileNotifier.logout mengembalikan false dan mengisi errorMessage saat gagal', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(profileNotifierProvider.notifier);
    await _flush();

    authRepo.logoutResult = const Left(ServerFailure('Gagal logout dari server'));
    final ok = await notifier.logout();
    final state = container.read(profileNotifierProvider);

    expect(ok, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, 'Gagal logout dari server');
    expect(state.profile.displayName, 'Budi Santoso');
  });
}
