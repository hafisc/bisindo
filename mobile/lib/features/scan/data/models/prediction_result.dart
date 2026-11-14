/// Hasil satu permintaan prediksi ke server.
class PredictionResult {
  const PredictionResult({
    required this.prediction,
    required this.confidence,
    this.handOrder = 'as_is',
  });

  /// Huruf hasil prediksi, misalnya `A`.
  final String prediction;

  /// Tingkat keyakinan model, 0.0 sampai 1.0.
  final double confidence;

  /// Urutan tangan yang dipakai server: `as_is` atau `swapped`.
  ///
  /// Berguna untuk diagnosis: bila sering `swapped`, berarti MediaPipe di
  /// perangkat mengembalikan tangan dalam urutan terbalik.
  final String handOrder;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: (json['prediction'] as String?)?.trim() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      handOrder: json['hand_order'] as String? ?? 'as_is',
    );
  }

  @override
  String toString() =>
      'PredictionResult($prediction, ${(confidence * 100).toStringAsFixed(1)}%, $handOrder)';
}

/// Galat yang bisa ditampilkan langsung ke pengguna.
class PredictionException implements Exception {
  const PredictionException(this.message, {this.statusCode});

  final String message;

  /// Kode HTTP bila server menjawab. `null` berarti server tidak terjangkau.
  final int? statusCode;

  /// True bila server menjawab, tetapi menolak data yang dikirim.
  bool get isRejected => statusCode != null && statusCode! < 500;

  @override
  String toString() => message;
}
