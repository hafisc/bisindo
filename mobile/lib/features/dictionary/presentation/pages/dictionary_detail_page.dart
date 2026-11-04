import 'package:flutter/material.dart';

import '../../../../core/constants/app_palette.dart';
import '../../data/dictionary_data.dart';
import '../../domain/models/dictionary_item.dart';

class DictionaryDetailPage extends StatelessWidget {
  final String letter;

  const DictionaryDetailPage({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final DictionaryItem? item = DictionaryData.getByLetter(letter);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kamus')),
        body: Center(
          child: Text(
            'Huruf "$letter" tidak ditemukan dalam kamus.',
            style: const TextStyle(fontSize: 16, color: AppPalette.gray600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.lightGray,
      appBar: AppBar(
        title: Text(
          'Detail Huruf ${item.letter}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppPalette.darkBlue),
        ),
        backgroundColor: AppPalette.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Letter Hero Badge & Illustration Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.gray200.withOpacity(0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppPalette.blueGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.letter,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Illustration / Graphic Representation box
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppPalette.softBlue.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.primary.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.back_hand_rounded,
                          size: 56,
                          color: AppPalette.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ilustrasi Peragaan Huruf ${item.letter}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tersedia offline di perangkat Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppPalette.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.gray200.withOpacity(0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppPalette.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cara Peragaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppPalette.gray800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tips Card
            if (item.tips.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.gray200.withOpacity(0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: AppPalette.warning, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tips & Catatan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPalette.darkBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...item.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppPalette.primary)),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppPalette.gray700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
