import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../landmark_payload.dart';
import '../models/detected_hand.dart';
import '../models/prediction_result.dart';

/// Client HTTP ke server prediksi BISINDO.
///
/// Alamat server dibaca dari [ApiConfig] setiap kali request dibuat, sehingga
/// pengguna bisa mengganti alamat di layar Scan tanpa build ulang aplikasi.
class PredictionApiClient {
  PredictionApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrlOverride = baseUrl {
    _dio.options.connectTimeout ??= const Duration(seconds: 3);
    _dio.options.receiveTimeout ??= const Duration(seconds: 3);
  }

  final Dio _dio;
  final String? _baseUrlOverride;

  /// UID yang profilnya sudah disinkronkan pada sesi ini.
  String? _profileSyncedFor;

  String get baseUrl => _baseUrlOverride ?? ApiConfig.baseUrl;

  /// Pastikan server hidup dan modelnya termuat.
  ///
  /// Melempar [PredictionException] dengan pesan yang bisa ditampilkan ke
  /// pengguna bila server tidak bisa dihubungi.
  Future<void> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/status',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );

      final data = response.data ?? const <String, dynamic>{};
      if (data['model_loaded'] != true) {
        throw const PredictionException(
          'Server hidup, tetapi model belum termuat. Hubungi pengelola server.',
        );
      }
    } on DioException catch (error) {
      throw PredictionException(_messageFor(error));
    }
  }

  /// Kirim landmark dan kembalikan huruf hasil prediksi.
  Future<PredictionResult> predict({
    required List<DetectedHand> hands,
    String? userId,
  }) async {
    final landmarks = buildLandmarkPayload(hands);
    if (landmarks.isEmpty) {
      throw const PredictionException('Tangan belum terdeteksi.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/predict',
        data: {
          'landmarks': landmarks,
          if (userId != null && userId.isNotEmpty) 'user_id': userId,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      final data = response.data;
      if (data == null || (data['prediction'] as String?) == null) {
        throw const PredictionException('Server mengirim jawaban yang tidak dikenali.');
      }

      return PredictionResult.fromJson(data);
    } on DioException catch (error) {
      throw PredictionException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  /// Simpan satu entri riwayat ke server.
  ///
  /// Best-effort: kegagalan tidak boleh mengganggu proses scan. Riwayat lokal
  /// di perangkat tetap tersimpan lewat `HistoryNotifier`.
  Future<bool> syncHistory({
    required String uid,
    required Map<String, dynamic> entry,
    String? name,
    String? email,
  }) async {
    if (uid.isEmpty) return false;

    try {
      await _ensureProfile(uid: uid, name: name, email: email);

      await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/history',
        data: entry,
        options: Options(
          headers: {'X-User-Id': uid},
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return true;
    } on DioException catch (error) {
      debugPrint('[PredictionApiClient] Riwayat tidak tersinkron: ${_messageFor(error)}');
      return false;
    } catch (error) {
      debugPrint('[PredictionApiClient] Riwayat tidak tersinkron: $error');
      return false;
    }
  }

  /// Buat profil di server sekali per sesi.
  ///
  /// Endpoint riwayat membutuhkan baris `users` yang cocok dengan Firebase UID.
  /// Profil di aplikasi disimpan di Firestore, jadi baris di server ini perlu
  /// dibuat lebih dulu lewat `PUT /api/profile`.
  Future<void> _ensureProfile({
    required String uid,
    String? name,
    String? email,
  }) async {
    if (_profileSyncedFor == uid) return;

    final safeName = (name == null || name.trim().isEmpty)
        ? 'Pengguna BISINDO'
        : name.trim();
    final safeEmail = (email == null || email.trim().isEmpty)
        ? 'pengguna-$uid@bisindo.local'
        : email.trim();

    try {
      await _dio.put<Map<String, dynamic>>(
        '$baseUrl/api/profile',
        data: {'name': safeName, 'email': safeEmail},
        options: Options(
          headers: {'X-User-Id': uid},
          contentType: Headers.jsonContentType,
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      _profileSyncedFor = uid;
    } on DioException catch (error) {
      // 409 berarti email sudah dipakai UID lain, profil tetap ada. Selain itu
      // biarkan riwayat gagal dengan tenang.
      if (error.response?.statusCode == 409) {
        _profileSyncedFor = uid;
        return;
      }
      rethrow;
    }
  }

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server tidak menjawab dalam 3 detik. Periksa alamat server dan WiFi.';
      case DioExceptionType.connectionError:
        return 'Server tidak bisa dihubungi. Pastikan alamat benar dan HP satu WiFi dengan laptop.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final body = error.response?.data;
        if (body is Map && body['error'] is String) {
          return body['error'] as String;
        }
        if (status == 404) {
          return 'Endpoint tidak ditemukan. Pastikan alamat menunjuk ke server BISINDO.';
        }
        return 'Server menolak permintaan (HTTP $status).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.transformTimeout:
        return 'Server terlalu lambat mengirim data. Coba lagi.';
      case DioExceptionType.unknown:
        return 'Gagal menghubungi server: ${error.message ?? 'penyebab tidak diketahui'}.';
    }
  }
}
