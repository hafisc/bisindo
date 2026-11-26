import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/history_local_data_source.dart';
import '../../data/datasources/history_remote_data_source.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/models/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/add_history_item_usecase.dart';
import '../../domain/usecases/clear_history_usecase.dart';
import '../../domain/usecases/delete_history_item_usecase.dart';
import '../../domain/usecases/get_local_history_usecase.dart';
import '../../domain/usecases/sync_history_usecase.dart';

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
  late GetLocalHistoryUseCase _getLocalHistoryUseCase;
  late SyncHistoryUseCase _syncHistoryUseCase;
  late AddHistoryItemUseCase _addHistoryItemUseCase;
  late DeleteHistoryItemUseCase _deleteHistoryItemUseCase;
  late ClearHistoryUseCase _clearHistoryUseCase;
  HistoryOwner? _owner;
  bool _isDisposed = false;

  @override
  HistoryState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);
    _getLocalHistoryUseCase = ref.watch(getLocalHistoryUseCaseProvider);
    _syncHistoryUseCase = ref.watch(syncHistoryUseCaseProvider);
    _addHistoryItemUseCase = ref.watch(addHistoryItemUseCaseProvider);
    _deleteHistoryItemUseCase = ref.watch(deleteHistoryItemUseCaseProvider);
    _clearHistoryUseCase = ref.watch(clearHistoryUseCaseProvider);
    _owner = ref.watch(historyOwnerProvider);
    Future.microtask(loadHistory);
    return const HistoryState(isLoading: true);
  }

  /// Tampilkan riwayat di HP lebih dulu, lalu samakan dengan server.
  Future<void> loadHistory() async {
    final localResult = await _getLocalHistoryUseCase(
      GetLocalHistoryParams(owner: _owner),
    );
    if (_isDisposed) return;

    final failedLocal = localResult.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return true;
      },
      (items) {
        state = state.copyWith(items: items, isLoading: false);
        return false;
      },
    );
    if (failedLocal) return;

    final syncResult = await _syncHistoryUseCase(
      SyncHistoryParams(owner: _owner),
    );
    if (_isDisposed) return;

    syncResult.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (result) => state = state.copyWith(
        items: result.items,
        syncError: () => result.syncError,
      ),
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    final result = await _addHistoryItemUseCase(
      AddHistoryItemParams(owner: _owner, item: item),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (saved) => state = state.copyWith(items: [saved, ...state.items]),
    );
  }

  Future<void> deleteItem(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = state.items[index];

    // Langsung hilang dari daftar karena kartu riwayat dihapus dengan geser.
    state = state.copyWith(
      items: state.items.where((entry) => entry.id != id).toList(),
    );

    final result = await _deleteHistoryItemUseCase(
      DeleteHistoryItemParams(owner: _owner, item: item),
    );
    if (_isDisposed) return;

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (_) {},
    );
  }

  /// Mengembalikan `false` bila server atau penyimpanan gagal dihapus.
  Future<bool> clearAll() async {
    final result = await _clearHistoryUseCase(
      ClearHistoryParams(owner: _owner),
    );
    if (_isDisposed) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: 'Riwayat di server belum terhapus: ${failure.message}',
        );
        return false;
      },
      (_) {
        state = state.copyWith(items: []);
        return true;
      },
    );
  }
}

// ── Dependency Injection Providers ───────────────────────────────────────────

final historyLocalDataSourceProvider = Provider<HistoryLocalDataSource>((ref) {
  return HistoryLocalDataSourceImpl();
});

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return HistoryRemoteDataSourceImpl();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
    local: ref.watch(historyLocalDataSourceProvider),
    remote: ref.watch(historyRemoteDataSourceProvider),
  );
});

final getLocalHistoryUseCaseProvider = Provider<GetLocalHistoryUseCase>((ref) {
  return GetLocalHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final syncHistoryUseCaseProvider = Provider<SyncHistoryUseCase>((ref) {
  return SyncHistoryUseCase(ref.watch(historyRepositoryProvider));
});

final addHistoryItemUseCaseProvider = Provider<AddHistoryItemUseCase>((ref) {
  return AddHistoryItemUseCase(ref.watch(historyRepositoryProvider));
});

final deleteHistoryItemUseCaseProvider =
    Provider<DeleteHistoryItemUseCase>((ref) {
  return DeleteHistoryItemUseCase(ref.watch(historyRepositoryProvider));
});

final clearHistoryUseCaseProvider = Provider<ClearHistoryUseCase>((ref) {
  return ClearHistoryUseCase(ref.watch(historyRepositoryProvider));
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
