import 'models/detected_hand.dart';

/// Jumlah titik yang wajib ada pada setiap tangan MediaPipe.
const int landmarkPointsPerHand = 21;

/// Ubah hasil deteksi tangan menjadi payload untuk `POST /api/predict`.
///
/// Server menerima 21 titik (satu tangan) atau 42 titik (dua tangan), masing
/// masing berupa `{x, y, z}`. Koordinat sengaja dikirim apa adanya: server yang
/// mengurangi posisi pergelangan dan membagi dengan skala tangan, sama seperti
/// saat dataset latih dibuat.
///
/// Urutan tangan tidak diubah di sini. MediaPipe bisa mengembalikan tangan
/// kiri lebih dulu atau kanan lebih dulu, dan server sudah menguji kedua
/// orientasi lalu memilih yang paling yakin.
List<Map<String, double>> buildLandmarkPayload(List<DetectedHand> hands) {
  final usable = hands
      .where((hand) => hand.landmarks.length >= landmarkPointsPerHand)
      .take(2)
      .toList();

  if (usable.isEmpty) return const [];

  return [
    for (final hand in usable)
      for (final point in hand.landmarks.take(landmarkPointsPerHand))
        point.toMap(),
  ];
}

/// Ringkasan singkat jumlah tangan, dipakai untuk pesan status.
String describeHands(List<DetectedHand> hands) {
  final count = hands
      .where((hand) => hand.landmarks.length >= landmarkPointsPerHand)
      .length;
  if (count == 0) return 'Tangan belum terdeteksi';
  if (count == 1) return '1 tangan terdeteksi';
  return '2 tangan terdeteksi';
}
