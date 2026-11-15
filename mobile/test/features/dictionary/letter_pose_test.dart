import 'dart:convert';

import 'package:bisindo_translator/features/dictionary/data/repositories/letter_pose_repository.dart';
import 'package:bisindo_translator/features/dictionary/domain/models/letter_pose.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _poseJson({int points = 21, int hands = 1}) => {
  'letter': 'V',
  'twoHanded': hands == 2,
  'twoHandedPercent': hands == 2 ? 90 : 0,
  'samples': 315,
  'hands': List.generate(
    hands,
    (_) => List.generate(points, (i) => [i * 0.1, -i * 0.05]),
  ),
  'instructions': ['Peragakan dengan satu tangan.'],
  'tips': 'Huruf V paling sering tertukar dengan U.',
  'confusedWith': 'U',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LetterPose.fromJson', () {
    test('membaca titik tangan, instruksi, dan huruf pembanding', () {
      final pose = LetterPose.fromJson(_poseJson());

      expect(pose.letter, 'V');
      expect(pose.hands, hasLength(1));
      expect(pose.hands.first, hasLength(21));
      expect(pose.hands.first[2], const Offset(0.2, -0.1));
      expect(pose.confusedWith, 'U');
    });

    test('menolak tangan yang jumlah titiknya bukan 21', () {
      expect(
        () => LetterPose.fromJson(_poseJson(points: 20)),
        throwsFormatException,
      );
    });
  });

  group('aset bisindo_poses.json', () {
    late Map<String, LetterPose> poses;

    setUpAll(() async {
      poses = await LetterPoseRepository().loadAll();
    });

    test('memuat 26 huruf A-Z', () {
      expect(
        poses.keys.toList()..sort(),
        List.generate(26, (i) => String.fromCharCode(65 + i)),
      );
    });

    test('jumlah tangan sesuai penanda twoHanded', () {
      for (final pose in poses.values) {
        expect(
          pose.hands.length,
          pose.twoHanded ? 2 : 1,
          reason: 'huruf ${pose.letter}',
        );
        expect(pose.instructions, isNotEmpty, reason: 'huruf ${pose.letter}');
      }
    });

    test('huruf pembanding selalu huruf lain yang ada di kamus', () {
      for (final pose in poses.values) {
        final partner = pose.confusedWith;
        if (partner == null) continue;
        expect(partner, isNot(pose.letter));
        expect(poses.containsKey(partner), isTrue);
      }
    });

    test('pergelangan tangan pertama berada di titik nol', () {
      for (final pose in poses.values) {
        expect(pose.hands.first.first, Offset.zero, reason: pose.letter);
      }
    });
  });

  test('repository menyimpan hasil supaya aset hanya dibaca sekali', () async {
    final bundle = _CountingBundle(
      jsonEncode({
        'letters': {'V': _poseJson()},
      }),
    );
    final repository = LetterPoseRepository(bundle: bundle);

    await repository.loadAll();
    await repository.loadAll();

    expect(bundle.reads, 1);
  });
}

class _CountingBundle extends CachingAssetBundle {
  final String content;
  int reads = 0;

  _CountingBundle(this.content);

  @override
  Future<ByteData> load(String key) async {
    reads++;
    return ByteData.sublistView(utf8.encode(content));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads++;
    return content;
  }
}
