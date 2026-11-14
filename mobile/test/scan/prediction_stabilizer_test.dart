import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/features/scan/data/models/prediction_result.dart';
import 'package:bisindo_translator/features/scan/domain/prediction_stabilizer.dart';

PredictionResult _result(String letter, {double confidence = 0.95}) {
  return PredictionResult(prediction: letter, confidence: confidence);
}

void main() {
  group('PredictionStabilizer', () {
    test('belum mengunci sebelum suara cukup', () {
      final stabilizer = PredictionStabilizer();

      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
    });

    test('mengunci setelah tiga suara sama', () {
      final stabilizer = PredictionStabilizer();

      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), 'A');
    });

    test('prediksi berubah-ubah tidak dikunci', () {
      final stabilizer = PredictionStabilizer();

      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('B')), isNull);
      expect(stabilizer.add(_result('C')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('B')), isNull);
    });

    test('confidence rendah diabaikan', () {
      final stabilizer = PredictionStabilizer(minConfidence: 0.8);

      expect(stabilizer.add(_result('A', confidence: 0.5)), isNull);
      expect(stabilizer.add(_result('A', confidence: 0.5)), isNull);
      expect(stabilizer.add(_result('A', confidence: 0.5)), isNull);
      expect(stabilizer.lastCommitted, isNull);
    });

    test('huruf sama tidak diulang selama tangan dipertahankan', () {
      final stabilizer = PredictionStabilizer();

      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), 'A');

      // Tangan masih menunjukkan A: jangan tambahkan A lagi.
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
    });

    test('huruf sama boleh lagi setelah tangan diangkat', () {
      final stabilizer = PredictionStabilizer();

      stabilizer.add(_result('A'));
      stabilizer.add(_result('A'));
      expect(stabilizer.add(_result('A')), 'A');

      stabilizer.markHandsLost();

      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), isNull);
      expect(stabilizer.add(_result('A')), 'A');
    });

    test('huruf berbeda tetap bisa dikunci berurutan', () {
      final stabilizer = PredictionStabilizer();

      stabilizer.add(_result('A'));
      stabilizer.add(_result('A'));
      expect(stabilizer.add(_result('A')), 'A');

      expect(stabilizer.add(_result('B')), isNull);
      expect(stabilizer.add(_result('B')), isNull);
      expect(stabilizer.add(_result('B')), 'B');
    });

    test('reset melupakan huruf terakhir', () {
      final stabilizer = PredictionStabilizer();

      stabilizer.add(_result('A'));
      stabilizer.add(_result('A'));
      expect(stabilizer.add(_result('A')), 'A');

      stabilizer.reset();

      expect(stabilizer.lastCommitted, isNull);
      expect(stabilizer.add(_result('A')), isNull);
    });
  });
}
