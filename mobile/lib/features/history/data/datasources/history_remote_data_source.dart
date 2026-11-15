import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../domain/models/history_item.dart';

/// Gagal menghubungi atau ditolak server riwayat.
class HistorySyncException implements Exception {
  const HistorySyncException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Identitas pemilik riwayat yang dikirim ke server.
class HistoryOwner {
  const HistoryOwner({required this.uid, this.name, this.email});

  final String uid;
  final String? name;
  final String? email;

  // Dua owner dengan UID sama dianggap sama supaya riwayat tidak dimuat
  // ulang hanya karena nama atau email berubah.
  @override
  bool operator ==(Object other) => other is HistoryOwner && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

/// Endpoint `/api/history` di server Flask.
abstract class HistoryRemoteDataSource {
  Future<List<HistoryItem>> fetch(HistoryOwner owner);

  /// Mengembalikan id entri di server.
  Future<int> create(HistoryOwner owner, HistoryItem item);

  Future<void> delete(HistoryOwner owner, int remoteId);

  Future<void> clear(HistoryOwner owner);
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  HistoryRemoteDataSourceImpl({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrlOverride = baseUrl {
    _dio.options.connectTimeout ??= const Duration(seconds: 3);
    _dio.options.receiveTimeout ??= const Duration(seconds: 5);
  }

  final Dio _dio;
  final String? _baseUrlOverride;

  /// Jumlah maksimal yang dilayani server dalam satu permintaan.
  static const int pageLimit = 200;

  /// UID yang barisnya di tabel `users` server sudah dipastikan ada.
  String? _profileReadyFor;

  String get _baseUrl => _baseUrlOverride ?? ApiConfig.baseUrl;

  Options _options(String uid) => Options(
        headers: {'X-User-Id': uid},
        contentType: Headers.jsonContentType,
      );

  @override
  Future<List<HistoryItem>> fetch(HistoryOwner owner) {
    return _guard(owner, () async {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/history',
        queryParameters: {'limit': pageLimit},
        options: _options(owner.uid),
      );
      final items = response.data?['items'];
      if (items is! List) {
        throw const HistorySyncException('Jawaban server tidak dikenali.');
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(HistoryItem.fromServerJson)
          .toList();
    });
  }

  @override
  Future<int> create(HistoryOwner owner, HistoryItem item) {
    return _guard(owner, () async {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/history',
        data: item.toServerJson(),
        options: _options(owner.uid),
      );
      final id = response.data?['id'];
      if (id is! num) {
        throw const HistorySyncException('Server tidak mengembalikan id.');
      }
      return id.toInt();
    });
  }

  @override
  Future<void> delete(HistoryOwner owner, int remoteId) {
    return _guard(owner, () async {
      try {
        await _dio.delete<Map<String, dynamic>>(
          '$_baseUrl/api/history/$remoteId',
          options: _options(owner.uid),
        );
      } on DioException catch (error) {
        // Entri sudah tidak ada di server, misalnya dihapus dari perangkat
        // lain. 404 karena profil belum ada tetap dianggap gagal.
        final body = error.response?.data;
        final profileMissing =
            body is Map && '${body['error']}'.startsWith('Profil');
        if (error.response?.statusCode == 404 && !profileMissing) return;
        rethrow;
      }
    });
  }

  @override
  Future<void> clear(HistoryOwner owner) {
    return _guard(owner, () async {
      await _dio.delete<Map<String, dynamic>>(
        '$_baseUrl/api/history',
        options: _options(owner.uid),
      );
    });
  }

  /// Menjalankan [request] setelah profil server dipastikan ada, lalu
  /// mengubah kegagalan Dio menjadi [HistorySyncException].
  Future<T> _guard<T>(HistoryOwner owner, Future<T> Function() request) async {
    try {
      await _ensureProfile(owner);
      return await request();
    } on DioException catch (error) {
      throw HistorySyncException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Endpoint riwayat butuh baris `users` dengan Firebase UID yang sama.
  /// Profil aplikasi disimpan di Firestore, jadi baris ini dibuat sekali per
  /// sesi lewat `PUT /api/profile`.
  Future<void> _ensureProfile(HistoryOwner owner) async {
    if (_profileReadyFor == owner.uid) return;

    final name = (owner.name ?? '').trim();
    final email = (owner.email ?? '').trim();

    try {
      await _dio.put<Map<String, dynamic>>(
        '$_baseUrl/api/profile',
        data: {
          'name': name.isEmpty ? 'Pengguna BISINDO' : name,
          'email': email.isEmpty ? 'pengguna-${owner.uid}@bisindo.local' : email,
        },
        options: _options(owner.uid),
      );
    } on DioException catch (error) {
      // 409: email sudah terdaftar. Profil dengan UID ini mungkin sudah ada,
      // biarkan request riwayat yang menentukan.
      if (error.response?.statusCode != 409) rethrow;
    }
    _profileReadyFor = owner.uid;
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Server tidak bisa dihubungi.';
      case DioExceptionType.badResponse:
        final body = error.response?.data;
        if (body is Map && body['error'] is String) {
          return body['error'] as String;
        }
        return 'Server menolak permintaan (HTTP ${error.response?.statusCode}).';
      default:
        return 'Gagal menghubungi server.';
    }
  }
}
