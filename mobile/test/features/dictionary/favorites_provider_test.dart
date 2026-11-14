import 'package:bisindo_translator/features/dictionary/presentation/providers/favorites_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menunggu `_load()` di konstruktor selesai.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('memuat favorit yang tersimpan sebelumnya', () async {
    SharedPreferences.setMockInitialValues({
      FavoritesNotifier.storageKey: ['letter_A', 'word_maaf'],
    });

    final notifier = FavoritesNotifier();
    await _settle();

    expect(notifier.state, ['letter_A', 'word_maaf']);
    expect(notifier.isFavorite('letter_A'), isTrue);
    notifier.dispose();
  });

  test('toggle menambah di urutan teratas lalu menghapus', () async {
    final notifier = FavoritesNotifier();
    await _settle();

    expect(await notifier.toggle('letter_A'), isTrue);
    expect(await notifier.toggle('letter_B'), isTrue);
    expect(notifier.state, ['letter_B', 'letter_A']);

    expect(await notifier.toggle('letter_A'), isFalse);
    expect(notifier.state, ['letter_B']);
    notifier.dispose();
  });

  test(
    'favorit tersimpan dan terbaca lagi setelah aplikasi dibuka ulang',
    () async {
      final first = FavoritesNotifier();
      await _settle();
      await first.toggle('letter_K');
      first.dispose();

      final reopened = FavoritesNotifier();
      await _settle();

      expect(reopened.state, ['letter_K']);
      reopened.dispose();
    },
  );

  test('perubahan dibatalkan bila penyimpanan gagal', () async {
    final notifier = FavoritesNotifier(
      prefs: () => Future.error(StateError('penyimpanan rusak')),
    );
    await _settle();

    await expectLater(notifier.toggle('letter_A'), throwsStateError);
    expect(notifier.state, isEmpty);
    notifier.dispose();
  });
}
