import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/history/domain/models/history_item.dart';

/// SQLite Database Helper for local storage of history and dictionary entries.
/// Implements Singgih's scope: sqflite setup for local database.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bisindo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';

    // ── History Table ─────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE history (
        id $idType,
        title $textType,
        type $textType,
        category $textType,
        mode $textType,
        timestamp $textType,
        confidence $realType,
        imagePath $textNullable
      )
    ''');

    // ── Dictionary Table ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE dictionary (
        id $idType,
        word $textType,
        category $textType,
        description $textNullable,
        imagePath $textNullable,
        videoUrl $textNullable
      )
    ''');

    // Seed initial mock history data to populate history list nicely
    await _seedInitialHistory(db);
  }

  Future<void> _seedInitialHistory(Database db) async {
    final now = DateTime.now();
    final sampleItems = [
      {
        'title': 'Halo',
        'type': 'Kata',
        'category': 'Teks',
        'mode': 'BISINDO → Teks',
        'timestamp': now.subtract(const Duration(minutes: 5)).toIso8601String(),
        'confidence': 0.95,
        'imagePath': null,
      },
      {
        'title': 'Terima kasih',
        'type': 'Kata',
        'category': 'Teks',
        'mode': 'BISINDO → Teks',
        'timestamp': now.subtract(const Duration(hours: 1, minutes: 15)).toIso8601String(),
        'confidence': 0.92,
        'imagePath': null,
      },
      {
        'title': 'A',
        'type': 'Huruf',
        'category': 'Teks',
        'mode': 'BISINDO → Teks',
        'timestamp': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        'confidence': 0.98,
        'imagePath': null,
      },
      {
        'title': 'Tolong',
        'type': 'Kata',
        'category': 'Suara',
        'mode': 'BISINDO → Suara',
        'timestamp': now.subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
        'confidence': 0.89,
        'imagePath': null,
      },
      {
        'title': 'B',
        'type': 'Huruf',
        'category': 'Suara',
        'mode': 'BISINDO → Suara',
        'timestamp': now.subtract(const Duration(days: 1, hours: 6)).toIso8601String(),
        'confidence': 0.94,
        'imagePath': null,
      },
    ];

    for (final item in sampleItems) {
      await db.insert('history', item);
    }
  }

  // ── History CRUD ───────────────────────────────────────────────

  Future<List<HistoryItem>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'id DESC');
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<HistoryItem> insertHistory(HistoryItem item) async {
    final db = await instance.database;
    final id = await db.insert('history', item.toMap());
    return item.copyWith(id: id);
  }

  Future<int> deleteHistoryItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllHistory() async {
    final db = await instance.database;
    return await db.delete('history');
  }

  Future<int> getHistoryCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM history');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
