import 'package:flutter/material.dart';

abstract class HandSkeletonConstants {
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],       // Thumb
    [0, 5], [5, 6], [6, 7], [7, 8],       // Index
    [9, 10], [10, 11], [11, 12],          // Middle
    [13, 14], [14, 15], [15, 16],         // Ring
    [0, 17], [17, 18], [18, 19], [19, 20],// Pinky
    [5, 9], [9, 13], [13, 17],            // Palm
  ];

  static const Set<int> fingertips = {4, 8, 12, 16, 20};

  static final Paint linePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint jointPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..style = PaintingStyle.fill;

  static final Paint wristPaint = Paint()
    ..color = const Color(0xFFFFD600)
    ..style = PaintingStyle.fill;

  static final Paint fingertipPaint = Paint()
    ..color = const Color(0xFFFF1744)
    ..style = PaintingStyle.fill;
}

