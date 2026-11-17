import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/history/data/datasources/history_local_data_source.dart';
import 'package:bisindo_translator/features/history/data/datasources/history_remote_data_source.dart';
import 'package:bisindo_translator/features/history/data/repositories/history_repository.dart';
import 'package:bisindo_translator/features/history/domain/models/history_item.dart';

/// SQLite tiruan di memori dengan aturan yang sama seperti tabel `history`.
class _MemoryLocal implements HistoryLocalDataSource {
  final rows = <({String userId, HistoryItem item, bool pendingDelete})>[];
  int _nextId = 1;

  List<HistoryItem> _where(bool Function(dynamic row) test) =>
      rows.where(test).map((row) => row.item).toList().reversed.toList();

  @override
  Future<List<HistoryItem>> getHistory(String userId) async =>
      _where((r) => r.userId == userId && !r.pendingDelete);

  @override
  Future<List<HistoryItem>> getUnsynced(String userId) async => _where(
        (r) => r.userId == userId && !r.pendingDelete && r.item.remoteId == null,
      );

  @override
  Future<List<HistoryItem>> getPendingDeletes(String userId) async =>
      _where((r) => r.userId == userId && r.pendingDelete);

  @override
  Future<HistoryItem> insert(String userId, HistoryItem item) async {
    final saved = item.copyWith(id: _nextId++);
    rows.add((userId: userId, item: saved, pendingDelete: false));
    return saved;
  }

  void _update(int id, HistoryItem Function(HistoryItem) change,
      {bool? pendingDelete}) {
    final index = rows.indexWhere((r) => r.item.id == id);
    final row = rows[index];
    rows[index] = (
      userId: row.userId,
      item: change(row.item),
      pendingDelete: pendingDelete ?? row.pendingDelete,
    );
  }

  @override
  Future<void> markSynced(int id, int remoteId) async =>
      _update(id, (item) => item.copyWith(remoteId: remoteId));

  @override
  Future<void> markPendingDelete(int id) async =>
      _update(id, (item) => item, pendingDelete: true);

  @override
  Future<void> delete(int id) async => rows.removeWhere((r) => r.item.id == id);

  @override
  Future<void> clear(String userId) async =>
      rows.removeWhere((r) => r.userId == userId);

  @override
  Future<void> replaceSynced(String userId, List<HistoryItem> remote) async {
    rows.removeWhere(
      (r) => r.userId == userId && r.item.remoteId != null && !r.pendingDelete,
    );
    for (final item in remote) {
      await insert(userId, item);
    }
  }
}

/// Server tiruan. [online] false meniru server yang tidak bisa dihubungi.
class _FakeServer implements HistoryRemoteDataSource {
  final entries = <int, HistoryItem>{};
  bool online = true;
  int _nextId = 100;

  void _check() {
    if (!online) throw const HistorySyncException('Server tidak bisa dihubungi.');
  }

  @override
  Future<List<HistoryItem>> fetch(HistoryOwner owner) async {
    _check();
    return entries.entries
        .map((e) => e.value.copyWith(remoteId: e.key))
        .toList();
  }

  @override
  Future<int> create(HistoryOwner owner, HistoryItem item) async {
    _check();
    final id = _nextId++;
    entries[id] = item;
    return id;
  }

  @override
  Future<void> delete(HistoryOwner owner, int remoteId) async {
    _check();
    entries.remove(remoteId);
  }

  @override
  Future<void> clear(HistoryOwner owner) async {
    _check();
    entries.clear();
  }
}

HistoryItem _letter(String title, {String time = '2026-11-15T10:00:00.000'}) =>
    HistoryItem(
      title: title,
      type: 'Huruf',
      category: 'Teks',
      mode: 'BISINDO → Teks',
      timestamp: time,
      confidence: 0.9,
    );

void main() {
  const owner = HistoryOwner(uid: 'uid-a', name: 'A', email: 'a@x.id');
  late _MemoryLocal local;
  late _FakeServer server;
  late HistoryRepository repository;

  setUp(() {
    local = _MemoryLocal();
    server = _FakeServer();
    repository = HistoryRepository(local: local, remote: server);
  });

  test('riwayat baru tersimpan di HP dan terkirim ke server', () async {
    final saved = await repository.add(owner, _letter('A'));

    expect(saved.remoteId, isNotNull);
    expect(server.entries.values.single.title, 'A');
    expect((await repository.getLocal(owner)).single.isSynced, isTrue);
  });

  test('saat server mati riwayat tetap tersimpan lalu terkirim saat sinkron',
      () async {
    server.online = false;
    await repository.add(owner, _letter('B'));
    final offline = await repository.sync(owner);

    expect(offline.items.single.title, 'B');
    expect(offline.syncError, isNotNull);
    expect(server.entries, isEmpty);

    server.online = true;
    final online = await repository.sync(owner);

    expect(online.syncError, isNull);
    expect(server.entries.values.single.title, 'B');
    expect(online.items.single.isSynced, isTrue);
  });

  test('sinkron mengambil riwayat yang ada di server', () async {
    server.entries[7] = _letter('C');

    final result = await repository.sync(owner);

    expect(result.items.map((e) => e.title), ['C']);
    expect(result.items.single.remoteId, 7);
  });

  test('riwayat yang dihapus di server ikut hilang dari HP', () async {
    final saved = await repository.add(owner, _letter('D'));
    server.entries.remove(saved.remoteId);

    final result = await repository.sync(owner);

    expect(result.items, isEmpty);
  });

  test('hapus saat server mati ditunda lalu dikirim saat sinkron', () async {
    final saved = await repository.add(owner, _letter('E'));
    server.online = false;

    await repository.delete(owner, saved);
    expect(await repository.getLocal(owner), isEmpty);
    expect(server.entries, isNotEmpty);

    server.online = true;
    await repository.sync(owner);
    expect(server.entries, isEmpty);
    expect(local.rows, isEmpty);
  });

  test('riwayat satu akun tidak tampil di akun lain', () async {
    await repository.add(owner, _letter('F'));
    await repository.add(null, _letter('G'));

    expect((await repository.getLocal(owner)).map((e) => e.title), ['F']);
    expect((await repository.getLocal(null)).map((e) => e.title), ['G']);
    expect(
      await repository.getLocal(const HistoryOwner(uid: 'uid-b')),
      isEmpty,
    );
  });

  test('tanpa login riwayat hanya disimpan di HP', () async {
    await repository.add(null, _letter('H'));
    final result = await repository.sync(null);

    expect(server.entries, isEmpty);
    expect(result.syncError, isNull);
    expect(result.items.single.title, 'H');
  });

  test('hapus semua gagal saat server mati dan data HP tidak disentuh',
      () async {
    await repository.add(owner, _letter('I'));
    server.online = false;

    await expectLater(
      repository.clear(owner),
      throwsA(isA<HistorySyncException>()),
    );
    expect(await repository.getLocal(owner), isNotEmpty);
  });

  group('HistoryItem dari dan ke server', () {
    test('waktu UTC dari server diubah ke waktu lokal', () {
      final item = HistoryItem.fromServerJson({
        'id': 5,
        'title': 'A',
        'type': 'Huruf',
        'category': 'Suara',
        'mode': 'BISINDO → Suara',
        'confidence': 0.8,
        'timestamp': '2026-11-15T03:00:00',
      });

      expect(item.remoteId, 5);
      expect(item.category, 'Suara');
      expect(
        DateTime.parse(item.timestamp),
        DateTime.utc(2026, 11, 15, 3).toLocal(),
      );
    });

    test('entri lama tanpa title memakai huruf hasil prediksi', () {
      final item = HistoryItem.fromServerJson({
        'id': 6,
        'title': null,
        'type': null,
        'category': null,
        'mode': null,
        'letter': 'K',
        'confidence': 0.7,
        'timestamp': '2026-11-15T03:00:00',
      });

      expect(item.title, 'K');
      expect(item.type, 'Huruf');
      expect(item.mode, 'BISINDO → Teks');
    });

    test('waktu dikirim ke server dalam UTC', () {
      final local = DateTime(2026, 11, 15, 10, 30);
      final json = _letter('A', time: local.toIso8601String()).toServerJson();

      expect(DateTime.parse(json['timestamp'] as String), local.toUtc());
      expect(json['timestamp'], endsWith('Z'));
    });
  });
}
