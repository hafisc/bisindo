import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/app.dart';
import 'package:bisindo_translator/features/auth/domain/entities/user_entity.dart';
import 'package:bisindo_translator/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisindo_translator/features/auth/presentation/providers/auth_provider.dart';

/// Repository palsu supaya test tidak menyentuh Firebase.
///
/// `AppRouter` hanya memakai [currentUser] saat menentukan halaman awal, dan
/// `null` berarti pengguna belum login sehingga aplikasi membuka onboarding.
class _FakeAuthRepository implements AuthRepository {
  @override
  UserEntity? get currentUser => null;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream<UserEntity?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Layar ponsel, bukan 800x600 bawaan test, supaya halaman onboarding
    // tidak overflow saat dirender.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const BisindoApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
