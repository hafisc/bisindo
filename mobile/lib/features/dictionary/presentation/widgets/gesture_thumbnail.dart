import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/letter_pose_repository.dart';
import 'hand_pose_view.dart';

/// Ilustrasi kecil sebuah gesture. Huruf memakai kerangka tangan dari dataset,
/// kata memakai ikon karena belum ada data pose untuk kata. Latar ditentukan
/// pemanggil (lihat [GestureThumbnail.backgroundFor]).
class GestureThumbnail extends ConsumerWidget {
  final String title;
  final bool isLetter;
  final double iconSize;
  final double strokeRatio;

  const GestureThumbnail({
    super.key,
    required this.title,
    required this.isLetter,
    this.iconSize = 40,
    this.strokeRatio = 0.028,
  });

  /// Warna latar yang dipakai Kamus: peach untuk huruf, biru muda untuk kata.
  static Color backgroundFor({required bool isLetter}) =>
      isLetter ? const Color(0xFFFDEEE8) : const Color(0xFFE8F4FD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poses = isLetter ? ref.watch(letterPosesProvider).valueOrNull : null;
    final pose = poses?[title.toUpperCase()];

    if (pose != null) {
      return HandPoseView(
        pose: pose,
        strokeRatio: strokeRatio,
        showJoints: false,
      );
    }
    return Center(
      child: Icon(
        isLetter ? Icons.back_hand : Icons.sign_language,
        size: iconSize,
        color: isLetter ? Colors.orange[300] : Colors.blue[300],
      ),
    );
  }
}
