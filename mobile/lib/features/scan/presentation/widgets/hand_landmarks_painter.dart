import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/models/detected_hand.dart';
import 'hand_skeleton_constants.dart';

class HandLandmarksPainter extends CustomPainter {
  final List<DetectedHand> hands;
  final bool isFrontCamera;
  final Size? imageSize;

  HandLandmarksPainter({
    required this.hands,
    this.isFrontCamera = true,
    this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double offsetX = 0.0;
    double offsetY = 0.0;
    double renderWidth = size.width;
    double renderHeight = size.height;

    if (imageSize != null && imageSize!.width > 0 && imageSize!.height > 0) {
      final camWidth = math.min(imageSize!.width, imageSize!.height);
      final camHeight = math.max(imageSize!.width, imageSize!.height);
      final scale = math.max(size.width / camWidth, size.height / camHeight);

      renderWidth = camWidth * scale;
      renderHeight = camHeight * scale;
      offsetX = (size.width - renderWidth) / 2;
      offsetY = (size.height - renderHeight) / 2;
    }

    for (final hand in hands) {
      if (hand.landmarks.length < 21) continue;

      Offset toCanvasOffset(LandmarkPoint pt) {
        final normX = isFrontCamera ? (1.0 - pt.x) : pt.x;
        return Offset(
          offsetX + (normX * renderWidth),
          offsetY + (pt.y * renderHeight),
        );
      }

      for (final conn in HandSkeletonConstants.connections) {
        final p1 = toCanvasOffset(hand.landmarks[conn[0]]);
        final p2 = toCanvasOffset(hand.landmarks[conn[1]]);
        canvas.drawLine(p1, p2, HandSkeletonConstants.linePaint);
      }

      for (var i = 0; i < hand.landmarks.length; i++) {
        final center = toCanvasOffset(hand.landmarks[i]);
        final isFingertip = HandSkeletonConstants.fingertips.contains(i);
        final paint = i == 0
            ? HandSkeletonConstants.wristPaint
            : (isFingertip ? HandSkeletonConstants.fingertipPaint : HandSkeletonConstants.jointPaint);
        final radius = i == 0 ? 6.0 : (isFingertip ? 5.5 : 4.5);

        canvas.drawCircle(center, radius, paint);
      }

      if (hand.label != 'Unknown' && hand.landmarks.isNotEmpty) {
        final wristPos = toCanvasOffset(hand.landmarks[0]);
        _drawHandLabel(canvas, wristPos, hand.label, hand.score);
      }
    }

    canvas.restore();
  }

  void _drawHandLabel(Canvas canvas, Offset pos, String label, double score) {
    final text = '${label == "Left" ? "Tangan Kiri" : "Tangan Kanan"} (${(score * 100).toInt()}%)';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + 18),
        width: painter.width + 12,
        height: painter.height + 6,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(bgRect, Paint()..color = Colors.black.withValues(alpha: 0.6));
    painter.paint(canvas, Offset(pos.dx - painter.width / 2, pos.dy + 18 - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant HandLandmarksPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.imageSize != imageSize;
  }
}
