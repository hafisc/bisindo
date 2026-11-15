import 'package:flutter/foundation.dart';

import '../../domain/models/history_item.dart';
import '../datasources/history_local_data_source.dart';
import '../datasources/history_remote_data_source.dart';

/// Hasil memuat riwayat: daftar yang ditampilkan dan status sinkronisasi.
class HistoryLoadResult {
  const HistoryLoadResult(this.items, {this.syncError});

  final List<HistoryItem> items;

  /// Terisi bila server tidak bisa dihubungi. Daftar tetap berisi riwayat
  /// yang tersimpan di HP.
  final String? syncError;
}

/// Riwayat disimpan di HP lebih dulu supaya Scan tetap jalan tanpa server,
/// lalu disamakan dengan server `/api/history` setiap kali bisa terhubung.
///
/// Server adalah sumber utama untuk riwayat yang sudah terkirim, sehingga
/// riwayat yang dihapus dari perangkat lain ikut hilang saat sinkronisasi.
/// Tanpa login ([HistoryOwner] `null`) riwayat hanya disimpan di HP.
class HistoryRepository {
  HistoryRepository({
    required HistoryLocalDataSource local,
    required HistoryRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final HistoryLocalDataSource _local;
  final HistoryRemoteDataSource _remote;

  static String _keyOf(HistoryOwner? owner) => owner?.uid ?? '';

  Future<List<HistoryItem>> getLocal(HistoryOwner? owner) =>
      _local.getHistory(_keyOf(owner));

  /// Urutan sinkronisasi: kirim penghapusan yang tertunda, kirim riwayat
  /// baru, lalu ambil isi server.
  Future<HistoryLoadResult> sync(HistoryOwner? owner) async {
    final key = _keyOf(owner);
    if (owner == null) return HistoryLoadResult(await _local.getHistory(key));

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
      return HistoryLoadResult(await _local.getHistory(key));
    } on HistorySyncException catch (error) {
      debugPrint('[HISTORY] Sinkronisasi gagal: ${error.message}');
      return HistoryLoadResult(
        await _local.getHistory(key),
        syncError: error.message,
      );
    }
  }

  /// Simpan ke HP, lalu coba kirim ke server. Bila gagal, riwayat dikirim
  /// pada sinkronisasi berikutnya.
  Future<HistoryItem> add(HistoryOwner? owner, HistoryItem item) async {
    final saved = await _local.insert(_keyOf(owner), item);
    if (owner == null) return saved;

    try {
      final remoteId = await _remote.create(owner, saved);
      await _local.markSynced(saved.id!, remoteId);
      return saved.copyWith(remoteId: remoteId);
    } on HistorySyncException catch (error) {
      debugPrint('[HISTORY] Riwayat belum terkirim: ${error.message}');
      return saved;
    }
  }

  /// Hapus dari layar seketika. Bila server gagal dihubungi, penghapusan
  /// dikirim ulang pada sinkronisasi berikutnya.
  Future<void> delete(HistoryOwner? owner, HistoryItem item) async {
    final id = item.id;
    if (id == null) return;

    if (owner == null || item.remoteId == null) {
      await _local.delete(id);
      return;
    }

    try {
      await _remote.delete(owner, item.remoteId!);
      await _local.delete(id);
    } on HistorySyncException catch (error) {
      debugPrint('[HISTORY] Hapus di server tertunda: ${error.message}');
      await _local.markPendingDelete(id);
    }
  }

  /// Hapus semua riwayat akun. Server dihapus lebih dulu agar riwayat tidak
  /// muncul lagi saat sinkronisasi; bila gagal, melempar
  /// [HistorySyncException] dan data di HP tidak disentuh.
  Future<void> clear(HistoryOwner? owner) async {
    if (owner != null) await _remote.clear(owner);
    await _local.clear(_keyOf(owner));
  }
}
