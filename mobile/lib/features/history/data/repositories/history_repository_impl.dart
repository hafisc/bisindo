import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/models/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';
import '../datasources/history_remote_data_source.dart';

/// Implementasi offline-first [HistoryRepository]: riwayat disimpan di SQLite
/// lokal terlebih dahulu dan disinkronkan ke server `/api/history` saat
/// tersedia.
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({
    required HistoryLocalDataSource local,
    required HistoryRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final HistoryLocalDataSource _local;
  final HistoryRemoteDataSource _remote;

  static String _keyOf(HistoryOwner? owner) => owner?.uid ?? '';

  @override
  Future<Either<Failure, List<HistoryItem>>> getLocal(
    HistoryOwner? owner,
  ) async {
    try {
      final items = await _local.getHistory(_keyOf(owner));
      return Right(items);
    } catch (error) {
      return Left(CacheFailure('Gagal membaca riwayat lokal: $error'));
    }
  }

  /// Urutan sinkronisasi: kirim penghapusan yang tertunda, kirim riwayat
  /// baru, lalu ambil isi server.
  @override
  Future<Either<Failure, HistoryLoadResult>> sync(HistoryOwner? owner) async {
    final key = _keyOf(owner);
    try {
      if (owner == null) {
        return Right(HistoryLoadResult(await _local.getHistory(key)));
      }

      try {
        for (final item in await _local.getPendingDeletes(key)) {
          if (item.remoteId != null) {
            await _remote.delete(owner, item.remoteId!);
          }
          await _local.delete(item.id!);
        }

        for (final item in await _local.getUnsynced(key)) {
          final remoteId = await _remote.create(owner, item);
          await _local.markSynced(item.id!, remoteId);
        }

        await _local.replaceSynced(key, await _remote.fetch(owner));
        return Right(HistoryLoadResult(await _local.getHistory(key)));
      } on HistorySyncException catch (error) {
        debugPrint('[HISTORY] Sinkronisasi gagal: ${error.message}');
        return Right(
          HistoryLoadResult(
            await _local.getHistory(key),
            syncError: error.message,
          ),
        );
      }
    } catch (error) {
      return Left(CacheFailure('Gagal menyinkronkan riwayat: $error'));
    }
  }

  /// Simpan ke HP, lalu coba kirim ke server. Bila gagal, riwayat dikirim
  /// pada sinkronisasi berikutnya.
  @override
  Future<Either<Failure, HistoryItem>> add(
    HistoryOwner? owner,
    HistoryItem item,
  ) async {
    try {
      final saved = await _local.insert(_keyOf(owner), item);
      if (owner == null) return Right(saved);

      try {
        final remoteId = await _remote.create(owner, saved);
        await _local.markSynced(saved.id!, remoteId);
        return Right(saved.copyWith(remoteId: remoteId));
      } on HistorySyncException catch (error) {
        debugPrint('[HISTORY] Riwayat belum terkirim: ${error.message}');
        return Right(saved);
      }
    } catch (error) {
      return Left(CacheFailure('Gagal menyimpan riwayat: $error'));
    }
  }

  /// Hapus dari layar seketika. Bila server gagal dihubungi, penghapusan
  /// dikirim ulang pada sinkronisasi berikutnya.
  @override
  Future<Either<Failure, void>> delete(
    HistoryOwner? owner,
    HistoryItem item,
  ) async {
    final id = item.id;
    if (id == null) return const Right(null);

    try {
      if (owner == null || item.remoteId == null) {
        await _local.delete(id);
        return const Right(null);
      }

      try {
        await _remote.delete(owner, item.remoteId!);
        await _local.delete(id);
      } on HistorySyncException catch (error) {
        debugPrint('[HISTORY] Hapus di server tertunda: ${error.message}');
        await _local.markPendingDelete(id);
      }
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure('Gagal menghapus item: $error'));
    }
  }

  /// Hapus semua riwayat akun. Server dihapus lebih dulu agar riwayat tidak
  /// muncul lagi saat sinkronisasi; bila gagal, data lokal tidak disentuh.
  @override
  Future<Either<Failure, void>> clear(HistoryOwner? owner) async {
    try {
      if (owner != null) await _remote.clear(owner);
      await _local.clear(_keyOf(owner));
      return const Right(null);
    } on HistorySyncException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(CacheFailure('Gagal menghapus semua riwayat: $error'));
    }
  }
}
