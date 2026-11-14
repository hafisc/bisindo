import '../data/models/prediction_result.dart';

/// Menstabilkan hasil prediksi sebelum huruf dikunci ke teks.
///
/// Model SVM bisa berubah-ubah antar frame walau tangan tidak bergerak. Tanpa
/// penyaringan, satu huruf bisa masuk berkali-kali atau berganti-ganti. Aturan
/// di sini:
///
/// - prediksi dengan confidence di bawah [minConfidence] dibuang;
/// - huruf harus muncul minimal [minVotes] kali dalam [windowSize] prediksi
///   terakhir;
/// - huruf yang sama tidak dikunci lagi selama tanda itu masih dipertahankan.
///   Panggil [markHandsLost] saat tangan tidak terlihat, supaya tanda yang sama
///   bisa dikunci ulang setelah tangan diangkat.
class PredictionStabilizer {
  PredictionStabilizer({
    this.windowSize = 5,
    this.minVotes = 3,
    this.minConfidence = 0.70,
  }) : assert(minVotes > 0 && minVotes <= windowSize);

  final int windowSize;
  final int minVotes;
  final double minConfidence;

  final List<PredictionResult> _buffer = [];

  String? _lastCommitted;

  /// Huruf terakhir yang dikunci, atau `null` bila belum ada.
  String? get lastCommitted => _lastCommitted;

  /// Masukkan satu hasil prediksi. Kembalikan huruf yang siap dikunci, atau
  /// `null` bila belum cukup bukti.
  String? add(PredictionResult result) {
    if (result.prediction.isEmpty || result.confidence < minConfidence) {
      return null;
    }

    _buffer.add(result);
    if (_buffer.length > windowSize) {
      _buffer.removeAt(0);
    }

    final counts = <String, int>{};
    for (final item in _buffer) {
      counts[item.prediction] = (counts[item.prediction] ?? 0) + 1;
    }

    final winner = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    if (winner.value < minVotes) return null;

    // Tanda yang sama sedang dipertahankan: jangan ulangi hurufnya.
    if (winner.key == _lastCommitted) {
      _buffer.clear();
      return null;
    }

    _lastCommitted = winner.key;
    _buffer.clear();
    return winner.key;
  }

  /// Tangan tidak terlihat lagi, jadi tanda berikutnya boleh sama.
  void markHandsLost() {
    _buffer.clear();
    _lastCommitted = null;
  }

  /// Lupakan riwayat sementara, misalnya setelah kamera diganti.
  void reset() {
    _buffer.clear();
    _lastCommitted = null;
  }
}
