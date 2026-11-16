import 'package:flutter/material.dart';

import '../../domain/models/dictionary_item.dart';
import 'gesture_thumbnail.dart';

/// Kartu item kamus. Huruf menampilkan ilustrasi pose dari dataset, kata
/// menampilkan ikon karena belum ada data pose untuk kata.
class DictionaryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isLetter = item.category == DictionaryCategory.huruf;
    final background = GestureThumbnail.backgroundFor(isLetter: isLetter);

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
                      child: GestureThumbnail(
                        title: item.title,
                        isLetter: isLetter,
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
