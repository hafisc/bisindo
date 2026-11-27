import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/history/data/datasources/history_local_data_source.dart';
import 'package:bisindo_translator/features/history/data/datasources/history_remote_data_source.dart';
import 'package:bisindo_translator/features/history/domain/models/history_item.dart';
import 'package:bisindo_translator/features/history/presentation/providers/history_provider.dart';

class _InMemoryLocal implements HistoryLocalDataSource {
  final List<HistoryItem> items = [];
  int _nextId = 1;

  @override
  Future<List<HistoryItem>> getHistory(String userId) async =>
      List.of(items.reversed);

  @override
  Future<List<HistoryItem>> getUnsynced(String userId) async => const [];

  @override
  Future<List<HistoryItem>> getPendingDeletes(String userId) async => const [];

  @override
  Future<HistoryItem> insert(String userId, HistoryItem item) async {
    final saved = item.copyWith(id: _nextId++);
    items.add(saved);
    return saved;
  }

  @override
  Future<void> markSynced(int id, int remoteId) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx != -1) items[idx] = items[idx].copyWith(remoteId: remoteId);
  }

  @override
  Future<void> markPendingDelete(int id) async {}

  @override
  Future<void> delete(int id) async => items.removeWhere((e) => e.id == id);

  @override
  Future<void> clear(String userId) async => items.clear();

  @override
  Future<void> replaceSynced(String userId, List<HistoryItem> remote) async {}
}

class _FakeRemote implements HistoryRemoteDataSource {
  bool online = true;
  int nextRemoteId = 50;

  @override
  Future<List<HistoryItem>> fetch(HistoryOwner owner) async {
    if (!online) throw const HistorySyncException('Offline');
    return const [];
  }

  @override
  Future<int> create(HistoryOwner owner, HistoryItem item) async {
    if (!online) throw const HistorySyncException('Offline');
    return nextRemoteId++;
  }

  @override
  Future<void> delete(HistoryOwner owner, int remoteId) async {
    if (!online) throw const HistorySyncException('Offline');
  }

  @override
  Future<void> clear(HistoryOwner owner) async {
    if (!online) throw const HistorySyncException('Server sedang sibuk');
  }
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

HistoryItem _sampleLetter(String letter) => HistoryItem(
      title: letter,
      type: 'Huruf',
      category: 'Teks',
      mode: 'BISINDO → Teks',
      timestamp: '2026-11-26T09:00:00.000',
      confidence: 0.91,
    );

void main() {
  const owner = HistoryOwner(uid: 'uid-test', name: 'Tester');

  late _InMemoryLocal local;
  late _FakeRemote remote;

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        historyLocalDataSourceProvider.overrideWithValue(local),
        historyRemoteDataSourceProvider.overrideWithValue(remote),
        historyOwnerProvider.overrideWithValue(owner),
      ],
    );
  }

  setUp(() {
    local = _InMemoryLocal();
    remote = _FakeRemote();
  });

  test('loadHistory menampilkan data lokal terlebih dahulu lalu sync server', () async {
    await local.insert(owner.uid, _sampleLetter('A'));

    final container = createContainer();
    addTearDown(container.dispose);

    container.read(historyNotifierProvider);
    await _flush();

    final state = container.read(historyNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.items.map((e) => e.title), ['A']);
    expect(state.syncError, isNull);
  });

  test('addHistoryItem dan deleteItem memperbarui state via use case', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(historyNotifierProvider.notifier);
    await _flush();

    await notifier.addHistoryItem(_sampleLetter('B'));
    var state = container.read(historyNotifierProvider);
    expect(state.items, hasLength(1));
    expect(state.items.single.title, 'B');
    expect(state.items.single.remoteId, 50);

    await notifier.deleteItem(state.items.single.id!);
    state = container.read(historyNotifierProvider);
    expect(state.items, isEmpty);
  });

  test('clearAll mengembalikan false dan menyimpan errorMessage bila server gagal', () async {
    await local.insert(owner.uid, _sampleLetter('C'));
    final container = createContainer();
    addTearDown(container.dispose);

    final notifier = container.read(historyNotifierProvider.notifier);
    await _flush();

    remote.online = false;
    final cleared = await notifier.clearAll();
    var state = container.read(historyNotifierProvider);
    expect(cleared, isFalse);
    expect(state.items, hasLength(1));
    expect(state.errorMessage, contains('Server sedang sibuk'));

    remote.online = true;
    final clearedOnline = await notifier.clearAll();
    state = container.read(historyNotifierProvider);
    expect(clearedOnline, isTrue);
    expect(state.items, isEmpty);
  });
}
