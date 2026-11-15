import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/letter_pose.dart';

/// Memuat pose referensi huruf dari aset. Data dibaca sekali lalu disimpan,
/// karena isinya tetap selama aplikasi berjalan.
class LetterPoseRepository {
  static const String assetPath = 'assets/data/bisindo_poses.json';

  final AssetBundle _bundle;
  Map<String, LetterPose>? _cache;

  LetterPoseRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<Map<String, LetterPose>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(assetPath);
    final letters =
        (jsonDecode(raw) as Map<String, dynamic>)['letters']
            as Map<String, dynamic>;

    final poses = letters.map(
      (key, value) => MapEntry(
        key.toUpperCase(),
        LetterPose.fromJson(value as Map<String, dynamic>),
      ),
    );
    return _cache = Map.unmodifiable(poses);
  }
}

final letterPoseRepositoryProvider = Provider<LetterPoseRepository>(
  (ref) => LetterPoseRepository(),
);

/// Semua pose huruf A-Z, dengan kunci huruf kapital.
final letterPosesProvider = FutureProvider<Map<String, LetterPose>>(
  (ref) => ref.watch(letterPoseRepositoryProvider).loadAll(),
);
