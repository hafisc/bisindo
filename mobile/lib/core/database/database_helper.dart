import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Membuka database SQLite lokal `bisindo.db` dan mengurus skema serta
/// migrasinya. Query riwayat ada di `HistoryLocalDataSource`.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Versi 2: riwayat dipisah per akun (`userId`), menyimpan id dari server
  /// (`remoteId`), dan bisa ditandai menunggu dihapus di server
  /// (`pendingDelete`). Data contoh dari versi 1 dibuang.
  ///
  /// Versi 3: menambah tabel `dictionary_items` untuk cache kamus BISINDO lokal.
  static const int schemaVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bisindo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT '',
        remoteId INTEGER,
        pendingDelete INTEGER NOT NULL DEFAULT 0,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        mode TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        confidence REAL NOT NULL,
        imagePath TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_history_user ON history (userId, pendingDelete)',
    );
    await _createDictionaryTable(db);
  }

  static Future<void> _createDictionaryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dictionary_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        instructionsJson TEXT NOT NULL DEFAULT '[]',
        tips TEXT NOT NULL DEFAULT '',
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE history ADD COLUMN userId TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('ALTER TABLE history ADD COLUMN remoteId INTEGER');
      await db.execute(
        'ALTER TABLE history ADD COLUMN pendingDelete INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'CREATE INDEX idx_history_user ON history (userId, pendingDelete)',
      );

      // Versi 1 menanam lima riwayat contoh saat database dibuat. Scan hanya
      // menghasilkan huruf, jadi kata-kata ini pasti bukan hasil scan.
      await db.execute('''
        DELETE FROM history
        WHERE imagePath IS NULL AND (
          (type = 'Kata' AND title IN ('Halo', 'Terima kasih', 'Tolong'))
          OR (title = 'A' AND type = 'Huruf' AND category = 'Teks' AND confidence = 0.98)
          OR (title = 'B' AND type = 'Huruf' AND category = 'Suara' AND confidence = 0.94)
        )
      ''');
    }

    if (oldVersion < 3) {
      await _createDictionaryTable(db);
    }
  }
}
