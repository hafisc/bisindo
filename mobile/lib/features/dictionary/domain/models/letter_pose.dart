import 'dart:ui';

/// Pose referensi satu huruf BISINDO untuk ilustrasi Kamus.
///
/// Data berasal dari `assets/data/bisindo_poses.json`, hasil
/// `ml/src/dataset/export_dictionary_poses.py`: satu sampel asli dari dataset
/// latih yang paling mewakili huruf tersebut. Koordinat sudah dinormalkan
/// terhadap pergelangan tangan pertama, jadi bisa bernilai negatif.
class LetterPose {
  final String letter;
  final bool twoHanded;
  final int twoHandedPercent;
  final int samples;

  /// Satu atau dua tangan, masing-masing 21 titik landmark MediaPipe.
  final List<List<Offset>> hands;
  final List<String> instructions;
  final String tips;

  /// Huruf yang paling sering tertukar menurut confusion matrix model.
  final String? confusedWith;

  const LetterPose({
    required this.letter,
    required this.twoHanded,
    required this.twoHandedPercent,
    required this.samples,
    required this.hands,
    required this.instructions,
    required this.tips,
    this.confusedWith,
  });

  factory LetterPose.fromJson(Map<String, dynamic> json) {
    final hands = (json['hands'] as List)
        .map(
          (hand) => (hand as List)
              .map((point) {
                final xy = point as List;
                return Offset(
                  (xy[0] as num).toDouble(),
                  (xy[1] as num).toDouble(),
                );
              })
              .toList(growable: false),
        )
        .toList(growable: false);

    for (final hand in hands) {
      if (hand.length != 21) {
        throw FormatException(
          'Pose ${json['letter']} memiliki ${hand.length} titik, seharusnya 21.',
        );
      }
    }

    return LetterPose(
      letter: json['letter'] as String,
      twoHanded: json['twoHanded'] as bool,
      twoHandedPercent: (json['twoHandedPercent'] as num).toInt(),
      samples: (json['samples'] as num).toInt(),
      hands: hands,
      instructions: List<String>.from(json['instructions'] as List),
      tips: json['tips'] as String? ?? '',
      confusedWith: json['confusedWith'] as String?,
    );
  }
}
