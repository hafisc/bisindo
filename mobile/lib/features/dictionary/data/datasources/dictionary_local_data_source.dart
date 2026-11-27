import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/dictionary_item.dart';
import '../../domain/models/letter_pose.dart';

/// Cache lokal kamus huruf BISINDO di SQLite (`dictionary_items`) beserta
/// seed dari berkas aset `assets/data/bisindo_poses.json`.
abstract class DictionaryLocalDataSource {
  Future<List<DictionaryItem>> getItems({DictionaryCategory? category});
  Future<DictionaryItem?> getItemById(String id);
  Future<void> saveItems(List<DictionaryItem> items);
  Future<void> upsertItem(DictionaryItem item, {int? sortOrder});
  Future<List<DictionaryItem>> loadBundledSeed();
}

class DictionaryLocalDataSourceImpl implements DictionaryLocalDataSource {
  DictionaryLocalDataSourceImpl({
    Future<Database> Function()? database,
    AssetBundle? bundle,
  })  : _database = database ?? (() => DatabaseHelper.instance.database),
        _bundle = bundle ?? rootBundle;

  static const String _posesAsset = 'assets/data/bisindo_poses.json';
  static const String _table = 'dictionary_items';

  final Future<Database> Function() _database;
  final AssetBundle _bundle;

  /// Fallback di memori khusus ketika plugin platform SQLite/path_provider
  /// tidak tersedia (mis. pada widget test VM).
  List<DictionaryItem>? _memoryFallback;

  Future<Database?> _tryDatabase() async {
    if (_memoryFallback != null) return null;
    try {
      return await _database();
    } on MissingPluginException {
      _memoryFallback ??= <DictionaryItem>[];
      return null;
    }
  }

  @override
  Future<List<DictionaryItem>> getItems({DictionaryCategory? category}) async {
    final db = await _tryDatabase();
    if (db == null) {
      final list = _memoryFallback ?? const <DictionaryItem>[];
      if (category == null) return List.unmodifiable(list);
      return list.where((e) => e.category == category).toList(growable: false);
    }

    final rows = await db.query(
      _table,
      where: category == null ? null : 'category = ?',
      whereArgs: category == null ? null : [category.key],
      orderBy: 'sortOrder ASC, title ASC',
    );
    return rows.map(DictionaryItem.fromMap).toList(growable: false);
  }

  @override
  Future<DictionaryItem?> getItemById(String id) async {
    final db = await _tryDatabase();
    if (db == null) {
      for (final item in _memoryFallback ?? const <DictionaryItem>[]) {
        if (item.id == id) return item;
      }
      return null;
    }

    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DictionaryItem.fromMap(rows.first);
  }

  @override
  Future<void> saveItems(List<DictionaryItem> items) async {
    final db = await _tryDatabase();
    if (db == null) {
      _memoryFallback = List<DictionaryItem>.from(items);
      return;
    }

    await db.transaction((txn) async {
      await txn.delete(_table);
      for (var i = 0; i < items.length; i++) {
        await txn.insert(
          _table,
          items[i].toMap(sortOrder: i),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> upsertItem(DictionaryItem item, {int? sortOrder}) async {
    final db = await _tryDatabase();
    if (db == null) {
      final list = _memoryFallback ??= <DictionaryItem>[];
      final index = list.indexWhere((e) => e.id == item.id);
      if (index == -1) {
        list.add(item);
      } else {
        list[index] = item;
      }
      return;
    }

    var resolvedOrder = sortOrder;
    if (resolvedOrder == null) {
      final existing = await db.query(
        _table,
        columns: ['sortOrder'],
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        resolvedOrder = existing.first['sortOrder'] as int? ?? 0;
      } else {
        final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
        resolvedOrder = (countRes.first['cnt'] as int?) ?? 0;
      }
    }

    await db.insert(
      _table,
      item.toMap(sortOrder: resolvedOrder),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DictionaryItem>> loadBundledSeed() async {
    final items = <DictionaryItem>[];

    try {
      final posesRaw = await _bundle.loadString(_posesAsset);
      final decoded = jsonDecode(posesRaw) as Map<String, dynamic>;
      final letters = decoded['letters'] as Map<String, dynamic>? ?? const {};
      final sortedKeys = letters.keys.toList()..sort();

      for (final key in sortedKeys) {
        final poseJson = letters[key];
        if (poseJson is! Map<String, dynamic>) continue;
        final pose = LetterPose.fromJson(poseJson);
        final letter = pose.letter.toUpperCase();
        items.add(
          DictionaryItem(
            id: 'letter_$letter',
            title: letter,
            category: DictionaryCategory.huruf,
            imageUrl: '',
            instructions: pose.instructions,
            tips: pose.tips,
          ),
        );
      }
    } catch (_) {
      // Abaikan bila aset pose tidak tersedia.
    }

    return items;
  }
}
