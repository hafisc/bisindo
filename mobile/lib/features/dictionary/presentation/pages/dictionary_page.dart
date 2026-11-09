import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../data/dictionary_data.dart';
import '../../domain/models/dictionary_item.dart';
=======
import '../../domain/models/dictionary_item.dart';
import '../../data/repositories/dummy_dictionary_repository.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
<<<<<<< HEAD
=======
  DictionaryCategory? _selectedCategory;
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final filteredLetters = DictionaryData.letters.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.letter.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppPalette.lightGray,
      appBar: AppBar(
        title: const Text(
          'Kamus BISINDO',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppPalette.darkBlue),
        ),
        backgroundColor: AppPalette.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'Mode Offline Aktif',
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt_rounded, size: 16, color: AppPalette.teal),
                  SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.teal,
=======
    // Filter and search
    List<DictionaryItem> filteredItems = DummyDictionaryRepository.getItemsByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filteredItems = filteredItems.where((item) => item.title.toLowerCase().contains(lowerQuery)).toList();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light blue-ish grey background
      appBar: AppBar(
        title: const Text('Kamus BISINDO'),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pelajari gesture bahasa isyarat Indonesia secara lengkap.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari huruf atau kata...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: const Icon(Icons.filter_list),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Huruf', DictionaryCategory.huruf),
                        const SizedBox(width: 8),
                        _buildFilterChip('Kata Umum', DictionaryCategory.kataUmum),
                        const SizedBox(width: 8),
                        _buildFilterChip('Frasa', DictionaryCategory.frasa),
                      ],
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d
                    ),
                  ),
                ],
              ),
            ),
          ),
<<<<<<< HEAD
        ],
      ),
      body: Column(
        children: [
          // Search & Header banner
          Container(
            color: AppPalette.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alfabet Bahasa Isyarat Indonesia (26 Huruf)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPalette.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari huruf alfabet (misal: A, B, C)...',
                    hintStyle: const TextStyle(color: AppPalette.gray400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppPalette.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppPalette.lightGray,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Grid view of alphabet letters
          Expanded(
            child: filteredLetters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppPalette.gray400),
                        const SizedBox(height: 12),
                        Text(
                          'Huruf "$_searchQuery" tidak ditemukan',
                          style: const TextStyle(
                            color: AppPalette.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: filteredLetters.length,
                    itemBuilder: (context, index) {
                      final item = filteredLetters[index];
                      return _DictionaryCard(item: item);
                    },
                  ),
          ),
        ],
=======
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          
          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
            // Section for Huruf A-Z
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Huruf A-Z',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = DictionaryCategory.huruf;
                        });
                      },
                      child: Row(
                        children: [
                          Text('Lihat Semua', style: TextStyle(color: theme.primaryColor)),
                          Icon(Icons.arrow_forward, size: 16, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildGridSection(
              items: DummyDictionaryRepository.getItemsByCategory(DictionaryCategory.huruf).take(12).toList(),
            ),
            
            // Section for Kata Umum
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kata Umum',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = DictionaryCategory.kataUmum;
                        });
                      },
                      child: Row(
                        children: [
                          Text('Lihat Semua', style: TextStyle(color: theme.primaryColor)),
                          Icon(Icons.arrow_forward, size: 16, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildGridSection(
              items: DummyDictionaryRepository.getItemsByCategory(DictionaryCategory.kataUmum).take(4).toList(),
            ),
             const SliverToBoxAdapter(
              child: SizedBox(height: 48),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  'Hasil Pencarian (${filteredItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildGridSection(items: filteredItems),
            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DictionaryCategory? category) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.grey[300]!,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildGridSection({required List<DictionaryItem> items}) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text('Tidak ada data.'),
          ),
        ),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return _DictionaryCard(
              item: item,
              onTap: () {
                context.pushNamed(
                  'dictionaryDetail',
                  pathParameters: {'id': item.id},
                );
              },
            );
          },
          childCount: items.length,
        ),
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d
      ),
    );
  }
}

class _DictionaryCard extends StatelessWidget {
  final DictionaryItem item;
<<<<<<< HEAD

  const _DictionaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppPalette.gray200.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to detail page
          context.push('/dictionary/${item.letter}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppPalette.blueGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.letter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppPalette.gray400,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOptions.ellipsized,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.gray600,
                  height: 1.3,
                ),
              ),
            ],
          ),
=======
  final VoidCallback onTap;

  const _DictionaryCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a background color based on item category
    Color bgColor;
    if (item.category == DictionaryCategory.huruf) {
      bgColor = const Color(0xFFFDEEE8); // Light peach/orange
    } else {
      bgColor = const Color(0xFFE8F4FD); // Light blue
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: bgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: item.category == DictionaryCategory.huruf
                    ? Icon(Icons.back_hand, size: 40, color: Colors.orange[300])
                    : Icon(Icons.sign_language, size: 40, color: Colors.blue[300]),
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
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d
        ),
      ),
    );
  }
<<<<<<< HEAD
}

extension on TextOverflow {
  static const TextOverflow ellipsized = TextOverflow.ellipsis;
}
=======
}
>>>>>>> 95c878a36c3a21c5d928a7cfdcb3c0f629a63d7d
