import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daftar id item kamus yang ditandai favorit, disimpan di perangkat.
///
/// Urutan dipertahankan sesuai waktu ditambahkan, sehingga halaman Favorit
/// menampilkan yang terbaru di atas.
class FavoritesNotifier extends StateNotifier<List<String>> {
  static const String storageKey = 'favorite_dictionary_ids';

  final Future<SharedPreferences> Function() _prefs;

  FavoritesNotifier({Future<SharedPreferences> Function()? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance,
      super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await _prefs();
      final stored = prefs.getStringList(storageKey);
      if (stored != null && mounted) state = List.unmodifiable(stored);
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
      if (mounted) state = previous;
      rethrow;
    }
    return nowFavorite;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>(
      (ref) => FavoritesNotifier(),
    );
