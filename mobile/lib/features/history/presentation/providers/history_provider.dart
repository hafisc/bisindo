import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/history_local_data_source.dart';
import '../../data/datasources/history_remote_data_source.dart';
import '../../data/repositories/history_repository.dart';
import '../../domain/models/history_item.dart';

class HistoryState {
  final List<HistoryItem> items;
  final String activeFilter; // 'Semua' | 'Teks' | 'Suara'
  final String searchQuery;
  final bool isLoading;

  /// Pesan bila server tidak bisa dihubungi. Riwayat di HP tetap tampil.
  final String? syncError;
  final String? errorMessage;

  const HistoryState({
    this.items = const [],
    this.activeFilter = 'Semua',
    this.searchQuery = '',
    this.isLoading = false,
    this.syncError,
    this.errorMessage,
  });

  List<HistoryItem> get filteredItems {
    return items.where((item) {
      final matchesFilter = activeFilter == 'Semua' ||
          item.category.toLowerCase() == activeFilter.toLowerCase();
      final matchesSearch = searchQuery.isEmpty ||
          item.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  HistoryState copyWith({
    List<HistoryItem>? items,
    String? activeFilter,
    String? searchQuery,
    bool? isLoading,
    String? Function()? syncError,
    String? errorMessage,
  }) {
    return HistoryState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      syncError: syncError != null ? syncError() : this.syncError,
      errorMessage: errorMessage,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  late HistoryRepository _repository;
  HistoryOwner? _owner;
  bool _isDisposed = false;

  @override
  HistoryState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _repository = ref.watch(historyRepositoryProvider);
    _owner = ref.watch(historyOwnerProvider);
    Future.microtask(loadHistory);
    return const HistoryState(isLoading: true);
  }

  /// Tampilkan riwayat di HP lebih dulu, lalu samakan dengan server.
  Future<void> loadHistory() async {
    try {
      final local = await _repository.getLocal(_owner);
      if (_isDisposed) return;
      state = state.copyWith(items: local, isLoading: false);

      final result = await _repository.sync(_owner);
      if (_isDisposed) return;
      state = state.copyWith(
        items: result.items,
        syncError: () => result.syncError,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat riwayat terjemahan: $e',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    try {
      final saved = await _repository.add(_owner, item);
      if (_isDisposed) return;
      state = state.copyWith(items: [saved, ...state.items]);
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(errorMessage: 'Gagal menyimpan riwayat: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = state.items[index];

    // Langsung hilang dari daftar karena kartu riwayat dihapus dengan geser.
    state = state.copyWith(
      items: state.items.where((entry) => entry.id != id).toList(),
    );

    try {
      await _repository.delete(_owner, item);
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(errorMessage: 'Gagal menghapus item: $e');
    }
  }

  /// Mengembalikan `false` bila server tidak bisa dihubungi.
  Future<bool> clearAll() async {
    try {
      await _repository.clear(_owner);
      if (!_isDisposed) state = state.copyWith(items: []);
      return true;
    } on HistorySyncException catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          errorMessage: 'Riwayat di server belum terhapus: ${e.message}',
        );
      }
      return false;
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(
    local: HistoryLocalDataSourceImpl(),
    remote: HistoryRemoteDataSourceImpl(),
  );
});

/// Pemilik riwayat yang sedang login, atau `null` bila belum login.
final historyOwnerProvider = Provider<HistoryOwner?>((ref) {
  final auth = ref.watch(authStateProvider);
  final UserEntity? user = auth.isLoading
      ? ref.read(currentUserProvider)
      : auth.valueOrNull;

  if (user == null || user.isEmpty) return null;
  return HistoryOwner(uid: user.id, name: user.displayName, email: user.email);
});

/// Dibuat ulang setiap kali akun berganti, sehingga riwayat satu akun tidak
/// tampil di akun lain pada HP yang sama.
final historyNotifierProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
