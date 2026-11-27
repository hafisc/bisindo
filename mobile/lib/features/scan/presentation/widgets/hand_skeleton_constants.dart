import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';

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
    ..color = AppPalette.skeletonLine
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint jointPaint = Paint()
    ..color = AppPalette.skeletonJoint
    ..style = PaintingStyle.fill;

  static final Paint wristPaint = Paint()
    ..color = AppPalette.skeletonWrist
    ..style = PaintingStyle.fill;

  static final Paint fingertipPaint = Paint()
    ..color = AppPalette.skeletonFingertip
    ..style = PaintingStyle.fill;
}

