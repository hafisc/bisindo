import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/letter_pose_repository.dart';
import '../../domain/models/dictionary_item.dart';
import 'hand_pose_view.dart';

/// Kartu item kamus. Huruf menampilkan ilustrasi pose dari dataset, kata
/// menampilkan ikon karena belum ada data pose untuk kata.
class DictionaryCard extends ConsumerWidget {
  final DictionaryItem item;
  final VoidCallback onTap;
  final bool isFavorite;

  const DictionaryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLetter = item.category == DictionaryCategory.huruf;
    final background = isLetter
        ? const Color(0xFFFDEEE8)
        : const Color(0xFFE8F4FD);
    final poses = isLetter ? ref.watch(letterPosesProvider).valueOrNull : null;
    final pose = poses == null ? null : poses[item.title.toUpperCase()];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: pose != null
                          ? HandPoseView(
                              pose: pose,
                              strokeRatio: 0.028,
                              showJoints: false,
                            )
                          : Center(
                              child: Icon(
                                isLetter
                                    ? Icons.back_hand
                                    : Icons.sign_language,
                                size: 40,
                                color: isLetter
                                    ? Colors.orange[300]
                                    : Colors.blue[300],
                              ),
                            ),
                    ),
                    if (isFavorite)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
