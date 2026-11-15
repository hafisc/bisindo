import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/letter_pose.dart';

/// Ilustrasi kerangka tangan untuk satu huruf, diskalakan agar pas di kotak.
class HandPoseView extends StatelessWidget {
  final LetterPose pose;

  /// Tebal garis relatif terhadap sisi terpendek kotak.
  final double strokeRatio;
  final bool showJoints;

  const HandPoseView({
    super.key,
    required this.pose,
    this.strokeRatio = 0.018,
    this.showJoints = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Ilustrasi peragaan huruf ${pose.letter}, '
          '${pose.twoHanded ? 'dua tangan' : 'satu tangan'}',
      image: true,
      child: CustomPaint(
        painter: HandPosePainter(
          hands: pose.hands,
          strokeRatio: strokeRatio,
          showJoints: showJoints,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Menggambar tangan bergaya ilustrasi: telapak terisi dan jari tebal
/// berwarna kulit dengan garis tepi, mengikuti titik landmark sampel asli.
///
/// Titik landmark dinormalkan sehingga jarak pergelangan ke pangkal jari
/// tengah bernilai 1. Tebal jari dihitung dari satuan itu supaya proporsinya
/// sama di kartu kecil maupun di halaman detail.
class HandPosePainter extends CustomPainter {
  /// Warna kulit tangan pertama dan kedua. Tangan kedua dibuat lebih terang
  /// agar dua tangan yang bertumpuk tetap bisa dibedakan.
  static const List<Color> skinColors = [Color(0xFFE0A46E), Color(0xFFF6D2A8)];
  static const Color outlineColor = Color(0xFF7A4A2A);

  static const List<int> _palm = [0, 1, 2, 5, 9, 13, 17];

  /// Urutan digambar dari kelingking ke ibu jari agar ibu jari dan telunjuk
  /// berada di depan.
  static const List<List<int>> _fingers = [
    [17, 18, 19, 20],
    [13, 14, 15, 16],
    [9, 10, 11, 12],
    [5, 6, 7, 8],
    [1, 2, 3, 4],
  ];
  static const List<double> _fingerWidths = [0.15, 0.17, 0.18, 0.18, 0.21];

  /// Ruang ekstra (dalam satuan landmark) agar jari tebal tidak terpotong.
  static const double _bleed = 0.16;

  final List<List<Offset>> hands;

  /// Tebal garis tepi relatif terhadap tebal jari.
  final double strokeRatio;

  /// Menampilkan lipatan sendi jari. Dimatikan di kartu kecil.
  final bool showJoints;

  HandPosePainter({
    required this.hands,
    this.strokeRatio = 0.018,
    this.showJoints = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = hands.expand((hand) => hand).toList();
    if (points.isEmpty || size.isEmpty) return;

    var minX = points.first.dx, maxX = points.first.dx;
    var minY = points.first.dy, maxY = points.first.dy;
    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    minX -= _bleed;
    minY -= _bleed;
    maxX += _bleed;
    maxY += _bleed;

    // Skala seragam supaya bentuk tangan tidak gepeng.
    const padding = 0.08;
    final availableWidth = size.width * (1 - 2 * padding);
    final availableHeight = size.height * (1 - 2 * padding);
    final spanX = math.max(maxX - minX, 1e-6);
    final spanY = math.max(maxY - minY, 1e-6);
    final scale = math.min(availableWidth / spanX, availableHeight / spanY);
    final offset = Offset(
      (size.width - spanX * scale) / 2 - minX * scale,
      (size.height - spanY * scale) / 2 - minY * scale,
    );
    Offset toCanvas(Offset point) => point * scale + offset;

    // strokeRatio lama berkisar 0,018 sampai 0,028; dipetakan ke tepi
    // sekitar 12 sampai 18 persen tebal jari.
    final outlineFactor = (strokeRatio * 6.5).clamp(0.08, 0.2);

    for (var index = 0; index < hands.length; index++) {
      final hand = hands[index].map(toCanvas).toList();
      if (hand.length < 21) continue;
      _paintHand(
        canvas,
        hand,
        unit: scale,
        skin: skinColors[index % skinColors.length],
        outlineFactor: outlineFactor,
      );
    }
  }

  void _paintHand(
    Canvas canvas,
    List<Offset> hand, {
    required double unit,
    required Color skin,
    required double outlineFactor,
  }) {
    final palmWidth = 0.2 * unit;
    final outline = math.max(1.2, palmWidth * outlineFactor);

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final palm = Path()..addPolygon(_palm.map((i) => hand[i]).toList(), true);
    canvas
      ..drawPath(palm, stroke(outlineColor, palmWidth + outline * 2))
      ..drawPath(palm, Paint()..color = outlineColor)
      ..drawPath(palm, stroke(skin, palmWidth))
      ..drawPath(palm, Paint()..color = skin);

    for (var f = 0; f < _fingers.length; f++) {
      final chain = _fingers[f];
      final width = _fingerWidths[f] * unit;
      final path = Path()..moveTo(hand[chain.first].dx, hand[chain.first].dy);
      for (final i in chain.skip(1)) {
        path.lineTo(hand[i].dx, hand[i].dy);
      }
      canvas
        ..drawPath(path, stroke(outlineColor, width + outline * 2))
        ..drawPath(path, stroke(skin, width));

      if (!showJoints) continue;
      // Lipatan sendi: garis pendek tegak lurus arah ruas jari.
      final crease = stroke(outlineColor.withValues(alpha: 0.45), outline * 0.8);
      for (var j = 1; j < chain.length - 1; j++) {
        final from = hand[chain[j - 1]];
        final at = hand[chain[j]];
        final direction = at - from;
        final length = direction.distance;
        if (length < 1e-3) continue;
        final normal = Offset(-direction.dy, direction.dx) / length;
        final half = width * 0.28;
        canvas.drawLine(at - normal * half, at + normal * half, crease);
      }
    }
  }

  @override
  bool shouldRepaint(HandPosePainter oldDelegate) =>
      oldDelegate.hands != hands ||
      oldDelegate.strokeRatio != strokeRatio ||
      oldDelegate.showJoints != showJoints;
}
