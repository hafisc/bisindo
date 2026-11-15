import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/dictionary_item.dart';
import '../../data/repositories/dummy_dictionary_repository.dart';
import '../providers/favorites_provider.dart';
import '../widgets/dictionary_card.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DictionaryCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter and search
    List<DictionaryItem> filteredItems =
        DummyDictionaryRepository.getItemsByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filteredItems = filteredItems
          .where((item) => item.title.toLowerCase().contains(lowerQuery))
          .toList();
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Light blue-ish grey background
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
                        _buildFilterChip(
                          'Kata Umum',
                          DictionaryCategory.kataUmum,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (_searchQuery.isEmpty && _selectedCategory == null) ...[
            // Section for Huruf A-Z
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
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
                          Text(
                            'Lihat Semua',
                            style: TextStyle(color: theme.primaryColor),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildGridSection(
              items: DummyDictionaryRepository.getItemsByCategory(
                DictionaryCategory.huruf,
              ).take(12).toList(),
            ),

            // Section for Kata Umum
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
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
                          Text(
                            'Lihat Semua',
                            style: TextStyle(color: theme.primaryColor),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildGridSection(
              items: DummyDictionaryRepository.getItemsByCategory(
                DictionaryCategory.kataUmum,
              ).take(4).toList(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Hasil Pencarian (${filteredItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildGridSection(items: filteredItems),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
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
    final favorites = ref.watch(favoritesProvider);
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('Tidak ada data.')),
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return DictionaryCard(
            item: item,
            isFavorite: favorites.contains(item.id),
            onTap: () {
              context.pushNamed(
                'dictionaryDetail',
                pathParameters: {'id': item.id},
              );
            },
          );
        }, childCount: items.length),
      ),
    );
  }
}
