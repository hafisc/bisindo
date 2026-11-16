import 'package:dio/dio.dart';

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

  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server di $baseUrl tidak menjawab dalam 3 detik. Periksa alamat '
            'server dan pastikan HP tersambung ke laptop.';
      case DioExceptionType.connectionError:
        return 'Server tidak bisa dihubungi di $baseUrl. Lewat kabel USB, '
            'jalankan "adb reverse tcp:5000 tcp:5000" lalu coba lagi. Lewat '
            'WiFi, pastikan HP dan laptop satu jaringan dan alamatnya benar.';
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
