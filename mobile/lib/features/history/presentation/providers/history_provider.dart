import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/history_item.dart';

class HistoryState {
  final List<HistoryItem> items;
  final String activeFilter; // 'Semua' | 'Teks' | 'Suara'
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const HistoryState({
    this.items = const [],
    this.activeFilter = 'Semua',
    this.searchQuery = '',
    this.isLoading = false,
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
    String? errorMessage,
  }) {
    return HistoryState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final DatabaseHelper _dbHelper;

  HistoryNotifier({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _dbHelper.getAllHistory();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
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
      final insertedItem = await _dbHelper.insertHistory(item);
      state = state.copyWith(items: [insertedItem, ...state.items]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal menyimpan riwayat: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dbHelper.deleteHistoryItem(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal menghapus item: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _dbHelper.clearAllHistory();
      state = state.copyWith(items: []);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal menghapus riwayat: $e');
    }
  }
}

final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
