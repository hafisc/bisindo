import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bisindo_translator/core/router/app_router.dart';
import 'package:bisindo_translator/features/auth/domain/entities/user_entity.dart';
import 'package:bisindo_translator/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisindo_translator/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  UserEntity? get currentUser => null;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream<UserEntity?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Riverpod container menyediakan AppRouter dan GoRouter tanpa error', () {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appRouterProvider), isA<AppRouter>());
    expect(container.read(goRouterProvider), isA<GoRouter>());
  });
}
