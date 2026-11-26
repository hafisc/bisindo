import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/use_case.dart';
import '../../data/datasources/dictionary_local_data_source.dart';
import '../../data/datasources/dictionary_remote_data_source.dart';
import '../../data/repositories/dictionary_repository_impl.dart';
import '../../domain/models/dictionary_item.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../../domain/usecases/get_dictionary_item_by_id_usecase.dart';
import '../../domain/usecases/get_dictionary_items_usecase.dart';
import '../../domain/usecases/sync_dictionary_usecase.dart';

// ── Dependency Injection Providers ───────────────────────────────────────────

final dictionaryRemoteDataSourceProvider =
    Provider<DictionaryRemoteDataSource>((ref) {
  return DictionaryRemoteDataSourceImpl();
});

final dictionaryLocalDataSourceProvider =
    Provider<DictionaryLocalDataSource>((ref) {
  return DictionaryLocalDataSourceImpl();
});

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return DictionaryRepositoryImpl(
    local: ref.watch(dictionaryLocalDataSourceProvider),
    remote: ref.watch(dictionaryRemoteDataSourceProvider),
  );
});

final getDictionaryItemsUseCaseProvider =
    Provider<GetDictionaryItemsUseCase>((ref) {
  return GetDictionaryItemsUseCase(ref.watch(dictionaryRepositoryProvider));
});

final getDictionaryItemByIdUseCaseProvider =
    Provider<GetDictionaryItemByIdUseCase>((ref) {
  return GetDictionaryItemByIdUseCase(ref.watch(dictionaryRepositoryProvider));
});

final syncDictionaryUseCaseProvider = Provider<SyncDictionaryUseCase>((ref) {
  return SyncDictionaryUseCase(ref.watch(dictionaryRepositoryProvider));
});

// ── State ────────────────────────────────────────────────────────────────────

class DictionaryState extends Equatable {
  final List<DictionaryItem> items;
  final String searchQuery;
  final DictionaryCategory? selectedCategory;
  final bool isLoading;
  final bool isSyncing;
  final String? syncError;
  final String? errorMessage;

  const DictionaryState({
    this.items = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.isLoading = false,
    this.isSyncing = false,
    this.syncError,
    this.errorMessage,
  });

  List<DictionaryItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    return items.where((item) {
      final matchesCategory =
          selectedCategory == null || item.category == selectedCategory;
      final matchesQuery =
          query.isEmpty || item.title.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList(growable: false);
  }

  List<DictionaryItem> itemsByCategory(DictionaryCategory category) =>
      items.where((item) => item.category == category).toList(growable: false);

  DictionaryItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  DictionaryState copyWith({
    List<DictionaryItem>? items,
    String? searchQuery,
    DictionaryCategory? Function()? selectedCategory,
    bool? isLoading,
    bool? isSyncing,
    String? Function()? syncError,
    String? Function()? errorMessage,
  }) {
    return DictionaryState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          selectedCategory != null ? selectedCategory() : this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: syncError != null ? syncError() : this.syncError,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    items,
    searchQuery,
    selectedCategory,
    isLoading,
    isSyncing,
    syncError,
    errorMessage,
  ];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DictionaryNotifier extends Notifier<DictionaryState> {
  late GetDictionaryItemsUseCase _getItems;
  late GetDictionaryItemByIdUseCase _getItemById;
  late SyncDictionaryUseCase _syncDictionary;
  bool _isDisposed = false;

  @override
  DictionaryState build() {
    _isDisposed = false;
    ref.onDispose(() => _isDisposed = true);

    _getItems = ref.watch(getDictionaryItemsUseCaseProvider);
    _getItemById = ref.watch(getDictionaryItemByIdUseCaseProvider);
    _syncDictionary = ref.watch(syncDictionaryUseCaseProvider);

    Future.microtask(load);
    return const DictionaryState(isLoading: true);
  }

  Future<void> load() async {
    final localResult = await _getItems(const GetDictionaryItemsParams());
    if (_isDisposed) return;

    localResult.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () => failure.message,
        );
      },
      (items) {
        state = state.copyWith(
          items: items,
          isLoading: false,
          errorMessage: () => null,
        );
      },
    );

    await sync();
  }

  Future<void> sync() async {
    if (_isDisposed) return;
    state = state.copyWith(isSyncing: true);

    final result = await _syncDictionary(const NoParams());
    if (_isDisposed) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isSyncing: false,
          syncError: () => failure.message,
        );
      },
      (items) {
        state = state.copyWith(
          items: items,
          isSyncing: false,
          syncError: () => null,
        );
      },
    );
  }

  /// Memperbarui detail satu huruf dari server bila tersedia (offline-safe).
  Future<void> refreshItemDetail(String id) async {
    final result = await _getItemById(GetDictionaryItemByIdParams(id: id));
    if (_isDisposed) return;

    result.fold((_) {}, (updated) {
      if (updated == null) return;
      final index = state.items.indexWhere((e) => e.id == updated.id);
      if (index == -1) return;
      if (state.items[index] == updated) return;

      final next = List<DictionaryItem>.from(state.items);
      next[index] = updated;
      state = state.copyWith(items: List.unmodifiable(next));
    });
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(DictionaryCategory? category) {
    state = state.copyWith(selectedCategory: () => category);
  }
}

final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(DictionaryNotifier.new);
