import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/dictionary_item.dart';

/// Kontrak repository Kamus BISINDO di domain layer.
abstract class DictionaryRepository {
  /// Memuat daftar gesture kamus dari cache lokal (di-seed dari aset bila kosong).
  Future<Either<Failure, List<DictionaryItem>>> getItems({
    DictionaryCategory? category,
  });

  /// Mengambil satu gesture berdasarkan [id].
  ///
  /// Bila [refreshRemote] true dan item bertipe huruf, repository mencoba
  /// mengambil deskripsi terbaru dari server `/api/dictionary/<huruf>` lalu
  /// menyimpannya ke cache lokal.
  Future<Either<Failure, DictionaryItem?>> getItemById(
    String id, {
    bool refreshRemote = true,
  });

  /// Menyinkronkan daftar kamus dari server `/api/dictionary` ke cache lokal.
  Future<Either<Failure, List<DictionaryItem>>> syncFromRemote();
}
