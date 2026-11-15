import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/history_item.dart';

/// Riwayat di SQLite lokal. Semua query dibatasi pada satu akun lewat kolom
/// `userId`. String kosong dipakai untuk pemakaian tanpa login.
abstract class HistoryLocalDataSource {
  /// Riwayat yang tampil di layar, terbaru lebih dulu.
  Future<List<HistoryItem>> getHistory(String userId);

  /// Riwayat yang belum terkirim ke server.
  Future<List<HistoryItem>> getUnsynced(String userId);

  /// Riwayat yang sudah dihapus pengguna tetapi belum terhapus di server.
  Future<List<HistoryItem>> getPendingDeletes(String userId);

  Future<HistoryItem> insert(String userId, HistoryItem item);

  Future<void> markSynced(int id, int remoteId);

  /// Sembunyikan dari layar dan tunggu sampai server bisa dihubungi.
  Future<void> markPendingDelete(int id);

  Future<void> delete(int id);

  Future<void> clear(String userId);

  /// Ganti semua riwayat yang sudah tersinkron dengan isi server. Riwayat
  /// yang belum terkirim tidak disentuh.
  Future<void> replaceSynced(String userId, List<HistoryItem> remoteItems);
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl({Future<Database> Function()? database})
      : _database = database ?? (() => DatabaseHelper.instance.database);

  final Future<Database> Function() _database;

  static const String _table = 'history';
  static const String _order = 'timestamp DESC, id DESC';

  Future<List<HistoryItem>> _query(String where, List<Object?> args) async {
    final db = await _database();
    final rows = await db.query(
      _table,
      where: where,
      whereArgs: args,
      orderBy: _order,
    );
    return rows.map(HistoryItem.fromMap).toList();
  }

  @override
  Future<List<HistoryItem>> getHistory(String userId) =>
      _query('userId = ? AND pendingDelete = 0', [userId]);

  @override
  Future<List<HistoryItem>> getUnsynced(String userId) =>
      _query('userId = ? AND pendingDelete = 0 AND remoteId IS NULL', [userId]);

  @override
  Future<List<HistoryItem>> getPendingDeletes(String userId) =>
      _query('userId = ? AND pendingDelete = 1', [userId]);

  @override
  Future<HistoryItem> insert(String userId, HistoryItem item) async {
    final db = await _database();
    final row = item.toMap()
      ..remove('id')
      ..['userId'] = userId;
    final id = await db.insert(_table, row);
    return item.copyWith(id: id);
  }

  @override
  Future<void> markSynced(int id, int remoteId) async {
    final db = await _database();
    await db.update(
      _table,
      {'remoteId': remoteId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markPendingDelete(int id) async {
    final db = await _database();
    await db.update(
      _table,
      {'pendingDelete': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear(String userId) async {
    final db = await _database();
    await db.delete(_table, where: 'userId = ?', whereArgs: [userId]);
  }

  @override
  Future<void> replaceSynced(
    String userId,
    List<HistoryItem> remoteItems,
  ) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete(
        _table,
        where: 'userId = ? AND remoteId IS NOT NULL AND pendingDelete = 0',
        whereArgs: [userId],
      );
      for (final item in remoteItems) {
        final row = item.toMap()
          ..remove('id')
          ..['userId'] = userId;
        await txn.insert(_table, row);
      }
    });
  }
}
