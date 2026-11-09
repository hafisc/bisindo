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
=======
import '../../domain/models/dictionary_item.dart';
import '../../data/repositories/dummy_dictionary_repository.dart';

class DictionaryDetailPage extends StatefulWidget {
  final String id;
  const DictionaryDetailPage({super.key, required this.id});

  @override
  State<DictionaryDetailPage> createState() => _DictionaryDetailPageState();
}

class _DictionaryDetailPageState extends State<DictionaryDetailPage> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final item = DummyDictionaryRepository.getItemById(widget.id);
    
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Gesture')),
        body: const Center(child: Text('Item tidak ditemukan.')),
      );
    }

    final theme = Theme.of(context);

    // Color based on category
    Color badgeColor;
    if (item.category == DictionaryCategory.huruf) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.blue;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Gesture'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Player / Image Placeholder
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light grey
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   item.category == DictionaryCategory.huruf
                    ? Icon(Icons.back_hand, size: 100, color: Colors.orange[300])
                    : Icon(Icons.sign_language, size: 100, color: Colors.blue[300]),
                  // Play button icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, size: 32, color: Colors.black87),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '1/1',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title and Category Tag
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.categoryName,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Cara Melakukan
            Text(
              'Cara Melakukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...item.instructions.asMap().entries.map((entry) {
              int idx = entry.key + 1;
              String text = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$idx. ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d
                        ),
                      ),
                    ),
                  ],
                ),
<<<<<<< HEAD
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
=======
              );
            }),
            
            const SizedBox(height: 24),
            
            // Tips
            if (item.tips.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Light blue info box
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.tips,
                            style: TextStyle(
                              color: Colors.blue[900],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? 'Ditambahkan ke Favorit' : 'Dihapus dari Favorit'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : theme.primaryColor,
            ),
            label: Text(
              _isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
              style: TextStyle(
                color: _isFavorite ? Colors.red : theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: _isFavorite ? Colors.red : theme.primaryColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

