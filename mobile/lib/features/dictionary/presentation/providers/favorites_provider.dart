import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

final favoritesPrefsProvider = Provider<Future<SharedPreferences> Function()>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs != null) return () async => prefs;
    return SharedPreferences.getInstance;
  },
);

/// Daftar id item kamus yang ditandai favorit, disimpan di perangkat.
///
/// Urutan dipertahankan sesuai waktu ditambahkan, sehingga halaman Favorit
/// menampilkan yang terbaru di atas.
class FavoritesNotifier extends Notifier<List<String>> {
  static const String storageKey = 'favorite_dictionary_ids';

  late Future<SharedPreferences> Function() _prefs;
  bool _isDisposed = false;

  @override
  List<String> build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _prefs = ref.watch(favoritesPrefsProvider);

    final syncPrefs = ref.watch(sharedPreferencesProvider);
    if (syncPrefs != null) {
      final stored = syncPrefs.getStringList(storageKey);
      if (stored != null) return List.unmodifiable(stored);
      return const [];
    }

    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await _prefs();
      final stored = prefs.getStringList(storageKey);
      if (stored != null && !_isDisposed) state = List.unmodifiable(stored);
    } catch (_) {
      // Penyimpanan gagal dibaca: mulai dari daftar kosong.
    }
  }

  bool isFavorite(String id) => state.contains(id);

  /// Tambah atau hapus favorit. Mengembalikan status baru item tersebut.
  ///
  /// Bila penyimpanan gagal, perubahan dibatalkan supaya tampilan tidak
  /// menunjukkan status yang tidak tersimpan.
  Future<bool> toggle(String id) async {
    final previous = state;
    final nowFavorite = !previous.contains(id);
    state = List.unmodifiable(
      nowFavorite ? [id, ...previous] : previous.where((item) => item != id),
    );

    try {
      final prefs = await _prefs();
      final saved = await prefs.setStringList(storageKey, state);
      if (!saved) throw StateError('Gagal menyimpan favorit.');
    } catch (_) {
      if (!_isDisposed) state = previous;
      rethrow;
    }
    return nowFavorite;
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
