import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';

class DictionaryRemoteException implements Exception {
  const DictionaryRemoteException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DictionaryRemoteLetterDetail {
  final String letter;
  final String description;
  final String imageUrl;

  const DictionaryRemoteLetterDetail({
    required this.letter,
    required this.description,
    required this.imageUrl,
  });
}

/// Sumber data remote kamus BISINDO dari endpoint Flask `/api/dictionary`.
abstract class DictionaryRemoteDataSource {
  Future<List<String>> fetchLetters();
  Future<DictionaryRemoteLetterDetail> fetchLetterDetail(String letter);
}

class DictionaryRemoteDataSourceImpl implements DictionaryRemoteDataSource {
  DictionaryRemoteDataSourceImpl({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrlOverride = baseUrl {
    _dio.options.connectTimeout ??= const Duration(seconds: 3);
    _dio.options.receiveTimeout ??= const Duration(seconds: 5);
  }

  final Dio _dio;
  final String? _baseUrlOverride;

  String get _baseUrl => _baseUrlOverride ?? ApiConfig.baseUrl;

  @override
  Future<List<String>> fetchLetters() async {
    try {
      final response = await _dio.get<List<dynamic>>('$_baseUrl/api/dictionary');
      final data = response.data;
      if (data == null) {
        throw const DictionaryRemoteException('Jawaban server kamus kosong.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map((row) => (row['letter'] as String?)?.trim().toUpperCase() ?? '')
          .where((letter) => letter.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw DictionaryRemoteException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  @override
  Future<DictionaryRemoteLetterDetail> fetchLetterDetail(String letter) async {
    final normalized = letter.trim().toUpperCase();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/dictionary/$normalized',
      );
      final data = response.data;
      if (data == null) {
        throw const DictionaryRemoteException('Detail huruf tidak tersedia.');
      }

      final rawImage = (data['image_url'] as String?)?.trim() ?? '';
      final resolvedImage = rawImage.isEmpty
          ? ''
          : (rawImage.startsWith('http://') || rawImage.startsWith('https://'))
              ? rawImage
              : '$_baseUrl${rawImage.startsWith('/') ? '' : '/'}$rawImage';

      return DictionaryRemoteLetterDetail(
        letter: (data['letter'] as String?)?.trim().toUpperCase() ?? normalized,
        description: (data['description'] as String?)?.trim() ?? '',
        imageUrl: resolvedImage,
      );
    } on DioException catch (error) {
      throw DictionaryRemoteException(
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
      case DioExceptionType.connectionError:
        return 'Server kamus tidak dapat dihubungi.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final body = error.response?.data;
        if (body is Map && body['description'] is String) {
          return body['description'] as String;
        }
        return 'Server kamus menolak permintaan (HTTP $status).';
      default:
        return 'Gagal memuat data kamus dari server.';
    }
  }
}
