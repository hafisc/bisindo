import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/scan/data/landmark_payload.dart';
import 'package:bisindo_translator/features/scan/data/models/detected_hand.dart';

DetectedHand _hand({int points = 21, String label = 'Right'}) {
  return DetectedHand(
    label: label,
    score: 0.9,
    landmarks: [
      for (var index = 0; index < points; index++)
        LandmarkPoint(x: index * 0.01, y: index * 0.02, z: 0.0),
    ],
  );
}

void main() {
  group('buildLandmarkPayload', () {
    test('mengembalikan kosong bila tidak ada tangan', () {
      expect(buildLandmarkPayload(const []), isEmpty);
    });

    test('satu tangan menghasilkan 21 titik', () {
      final payload = buildLandmarkPayload([_hand()]);

      expect(payload, hasLength(21));
      expect(payload.first, {'x': 0.0, 'y': 0.0, 'z': 0.0});
    });

    test('dua tangan menghasilkan 42 titik', () {
      final payload = buildLandmarkPayload([
        _hand(label: 'Left'),
        _hand(label: 'Right'),
      ]);

      expect(payload, hasLength(42));
    });

    test('tangan dengan titik tidak lengkap dibuang', () {
      final payload = buildLandmarkPayload([
        _hand(points: 10),
        _hand(points: 21),
      ]);

      expect(payload, hasLength(21));
    });

    test('tidak mengubah urutan tangan dari MediaPipe', () {
      final payload = buildLandmarkPayload([
        _hand(label: 'Right'),
        _hand(label: 'Left'),
      ]);

      // Titik pertama blok kedua adalah titik pertama tangan kedua.
      expect(payload[21]['x'], 0.0);
      expect(payload, hasLength(42));
    });

    test('lebih dari dua tangan hanya diambil dua', () {
      final payload = buildLandmarkPayload([
        _hand(),
        _hand(),
        _hand(),
      ]);

      expect(payload, hasLength(42));
    });
  });

  group('describeHands', () {
    test('menyebut jumlah tangan yang bisa dipakai', () {
      expect(describeHands(const []), 'Tangan belum terdeteksi');
      expect(describeHands([_hand()]), '1 tangan terdeteksi');
      expect(describeHands([_hand(), _hand()]), '2 tangan terdeteksi');
    });
  });
}
