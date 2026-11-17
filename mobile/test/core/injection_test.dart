import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/di/injection.dart';
import 'package:bisindo_translator/core/router/app_router.dart';
import 'package:bisindo_translator/features/auth/domain/repositories/auth_repository.dart';

/// Menjalankan inisialisasi DI yang sama dengan `main.dart`.
///
/// Objek yang butuh Firebase tidak di-resolve di sini, cukup dipastikan
/// terdaftar. Test ini gagal bila ada dependensi yang dibuat terlalu awal,
/// misalnya `AppRouter` yang ditandai `@singleton` sebelum [AuthRepository]
/// terdaftar.
void main() {
  tearDown(() async => getIt.reset());

  test('configureDependencies mendaftarkan router dan repository auth', () {
    expect(configureDependencies, returnsNormally);
    expect(getIt.isRegistered<AppRouter>(), isTrue);
    expect(getIt.isRegistered<AuthRepository>(), isTrue);
  });
}
