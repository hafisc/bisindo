import 'package:bisindo_translator/features/dictionary/presentation/providers/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menunggu `_load()` di `build()` selesai.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

ProviderContainer _createContainer({
  Future<SharedPreferences> Function()? prefs,
}) {
  return ProviderContainer(
    overrides: [
      if (prefs != null) favoritesPrefsProvider.overrideWithValue(prefs),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('memuat favorit yang tersimpan sebelumnya', () async {
    SharedPreferences.setMockInitialValues({
      FavoritesNotifier.storageKey: ['letter_A', 'letter_B'],
    });

    final container = _createContainer();
    addTearDown(container.dispose);

    container.read(favoritesProvider);
    await _settle();

    expect(container.read(favoritesProvider), ['letter_A', 'letter_B']);
    expect(container.read(favoritesProvider.notifier).isFavorite('letter_A'), isTrue);
  });

  test('toggle menambah di urutan teratas lalu menghapus', () async {
    final container = _createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(favoritesProvider.notifier);
    await _settle();

    expect(await notifier.toggle('letter_A'), isTrue);
    expect(await notifier.toggle('letter_B'), isTrue);
    expect(container.read(favoritesProvider), ['letter_B', 'letter_A']);

    expect(await notifier.toggle('letter_A'), isFalse);
    expect(container.read(favoritesProvider), ['letter_B']);
  });

  test(
    'favorit tersimpan dan terbaca lagi setelah aplikasi dibuka ulang',
    () async {
      final first = _createContainer();
      final notifier = first.read(favoritesProvider.notifier);
      await _settle();
      await notifier.toggle('letter_K');
      first.dispose();

      final reopened = _createContainer();
      addTearDown(reopened.dispose);
      reopened.read(favoritesProvider);
      await _settle();

      expect(reopened.read(favoritesProvider), ['letter_K']);
    },
  );

  test('perubahan dibatalkan bila penyimpanan gagal', () async {
    final container = _createContainer(
      prefs: () => Future.error(StateError('penyimpanan rusak')),
    );
    addTearDown(container.dispose);

    final notifier = container.read(favoritesProvider.notifier);
    await _settle();

    await expectLater(notifier.toggle('letter_A'), throwsStateError);
    expect(container.read(favoritesProvider), isEmpty);
  });
}
