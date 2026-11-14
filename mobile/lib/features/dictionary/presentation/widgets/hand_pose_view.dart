import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../scan/presentation/widgets/hand_skeleton_constants.dart';
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

class HandPosePainter extends CustomPainter {
  static const List<Color> handColors = [AppPalette.primary, AppPalette.yellow];

  final List<List<Offset>> hands;
  final double strokeRatio;
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

    // Skala seragam supaya bentuk tangan tidak gepeng, dengan sedikit ruang
    // di tepi agar ujung jari tidak terpotong.
    const padding = 0.12;
    final available = Size(
      size.width * (1 - 2 * padding),
      size.height * (1 - 2 * padding),
    );
    final spanX = math.max(maxX - minX, 1e-6);
    final spanY = math.max(maxY - minY, 1e-6);
    final scale = math.min(available.width / spanX, available.height / spanY);
    final offset = Offset(
      (size.width - spanX * scale) / 2 - minX * scale,
      (size.height - spanY * scale) / 2 - minY * scale,
    );
    Offset toCanvas(Offset point) => point * scale + offset;

    final stroke = math.max(1.5, size.shortestSide * strokeRatio);

    for (var index = 0; index < hands.length; index++) {
      final hand = hands[index];
      final color = handColors[index % handColors.length];
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final connection in HandSkeletonConstants.connections) {
        canvas.drawLine(
          toCanvas(hand[connection[0]]),
          toCanvas(hand[connection[1]]),
          linePaint,
        );
      }

      if (!showJoints) continue;
      final jointPaint = Paint()..color = color;
      final tipPaint = Paint()..color = AppPalette.coral;
      for (var point = 0; point < hand.length; point++) {
        final isTip = HandSkeletonConstants.fingertips.contains(point);
        canvas.drawCircle(
          toCanvas(hand[point]),
          stroke * (isTip ? 1.0 : 0.75),
          isTip ? tipPaint : jointPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(HandPosePainter oldDelegate) =>
      oldDelegate.hands != hands ||
      oldDelegate.strokeRatio != strokeRatio ||
      oldDelegate.showJoints != showJoints;
}
