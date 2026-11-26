import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../models/history_item.dart';
import '../models/history_owner.dart';

/// Hasil memuat riwayat: daftar yang ditampilkan dan status sinkronisasi.
class HistoryLoadResult {
  const HistoryLoadResult(this.items, {this.syncError});

  final List<HistoryItem> items;

  /// Terisi bila server tidak bisa dihubungi. Daftar tetap berisi riwayat
  /// yang tersimpan di HP.
  final String? syncError;
}

/// Kontrak repository Riwayat di domain layer.
abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryItem>>> getLocal(HistoryOwner? owner);

  Future<Either<Failure, HistoryLoadResult>> sync(HistoryOwner? owner);

  Future<Either<Failure, HistoryItem>> add(
    HistoryOwner? owner,
    HistoryItem item,
  );

  Future<Either<Failure, void>> delete(
    HistoryOwner? owner,
    HistoryItem item,
  );

  Future<Either<Failure, void>> clear(HistoryOwner? owner);
}
