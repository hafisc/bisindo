class LandmarkPoint {
  final double x;
  final double y;
  final double z;

  const LandmarkPoint({
    required this.x,
    required this.y,
    required this.z,
  });

  factory LandmarkPoint.fromMap(Map<dynamic, dynamic> map) {
    return LandmarkPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
    );
  }

  Map<String, double> toMap() => {'x': x, 'y': y, 'z': z};

  @override
  String toString() =>
      'LandmarkPoint(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)})';
}

class DetectedHand {
  final List<LandmarkPoint> landmarks;
  final String label;
  final double score;

  const DetectedHand({
    required this.landmarks,
    required this.label,
    required this.score,
  });

  factory DetectedHand.fromMap(Map<dynamic, dynamic> map) {
    final rawLandmarks = map['landmarks'] as List<dynamic>? ?? [];
    final landmarks = rawLandmarks
        .map((p) => LandmarkPoint.fromMap(p as Map<dynamic, dynamic>))
        .toList();

    return DetectedHand(
      landmarks: landmarks,
      label: map['label'] as String? ?? 'Unknown',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

