/// Status hubungan aplikasi dengan server prediksi.
enum PredictionStatus {
  /// Server belum diperiksa sejak layar Scan dibuka.
  idle,

  /// Sedang memeriksa apakah server bisa dihubungi.
  connecting,

  /// Server menjawab dan siap menerima landmark.
  ready,

  /// Server tidak bisa dihubungi, atau menolak permintaan.
  error,
}
