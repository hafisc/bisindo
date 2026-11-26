import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/dictionary_item.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../datasources/dictionary_local_data_source.dart';
import '../datasources/dictionary_remote_data_source.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl({
    required DictionaryLocalDataSource local,
    required DictionaryRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final DictionaryLocalDataSource _local;
  final DictionaryRemoteDataSource _remote;

  Future<List<DictionaryItem>> _ensureSeeded() async {
    final existing = await _local.getItems();
    if (existing.isNotEmpty) return existing;

    final seed = await _local.loadBundledSeed();
    if (seed.isNotEmpty) {
      await _local.saveItems(seed);
    }
    return _local.getItems();
  }

  @override
  Future<Either<Failure, List<DictionaryItem>>> getItems({
    DictionaryCategory? category,
  }) async {
    try {
      await _ensureSeeded();
      final items = await _local.getItems(category: category);
      return Right(items);
    } catch (e) {
      debugPrint('[DICTIONARY REPO] getItems gagal: $e');
      return const Left(CacheFailure('Gagal membaca kamus dari penyimpanan lokal.'));
    }
  }

  @override
  Future<Either<Failure, DictionaryItem?>> getItemById(
    String id, {
    bool refreshRemote = true,
  }) async {
    try {
      await _ensureSeeded();
      final item = await _local.getItemById(id);
      if (item == null) return const Right(null);

      if (!refreshRemote || item.category != DictionaryCategory.huruf) {
        return Right(item);
      }

      try {
        final detail = await _remote.fetchLetterDetail(item.title);
        final updated = item.copyWith(
          description: detail.description.isNotEmpty
              ? detail.description
              : item.description,
          imageUrl:
              detail.imageUrl.isNotEmpty ? detail.imageUrl : item.imageUrl,
          instructions: item.instructions.isEmpty && detail.description.isNotEmpty
              ? [detail.description]
              : item.instructions,
        );
        await _local.upsertItem(updated);
        return Right(updated);
      } on DictionaryRemoteException {
        // Server tidak terjangkau — kembalikan data cache lokal.
        return Right(item);
      }
    } catch (e) {
      debugPrint('[DICTIONARY REPO] getItemById gagal: $e');
      return const Left(CacheFailure('Gagal memuat detail gesture.'));
    }
  }

  @override
  Future<Either<Failure, List<DictionaryItem>>> syncFromRemote() async {
    try {
      final letters = await _remote.fetchLetters();
      final localItems = await _ensureSeeded();

      final existingById = <String, DictionaryItem>{
        for (final item in localItems) item.id: item,
      };
      final merged = List<DictionaryItem>.from(localItems);

      var added = false;
      for (final rawLetter in letters) {
        final letter = rawLetter.trim().toUpperCase();
        if (letter.isEmpty) continue;
        final id = 'letter_$letter';
        if (!existingById.containsKey(id)) {
          final created = DictionaryItem(
            id: id,
            title: letter,
            category: DictionaryCategory.huruf,
          );
          merged.add(created);
          existingById[id] = created;
          added = true;
        }
      }

      if (added) {
        await _local.saveItems(merged);
      }

      return Right(await _local.getItems());
    } on DictionaryRemoteException catch (e) {
      debugPrint('[DICTIONARY REPO] syncFromRemote gagal: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[DICTIONARY REPO] syncFromRemote unexpected: $e');
      return const Left(UnexpectedFailure('Gagal menyinkronkan kamus.'));
    }
  }
}
