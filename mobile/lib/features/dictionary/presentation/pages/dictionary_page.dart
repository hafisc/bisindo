import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/dictionary_item.dart';
import '../providers/dictionary_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/dictionary_card.dart';

class DictionaryPage extends ConsumerStatefulWidget {
  const DictionaryPage({super.key});

  @override
  ConsumerState<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends ConsumerState<DictionaryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(dictionaryProvider).searchQuery;
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dictionaryState = ref.watch(dictionaryProvider);
    final notifier = ref.read(dictionaryProvider.notifier);
    final filteredItems = dictionaryState.filteredItems;
    final letterItems = dictionaryState.itemsByCategory(DictionaryCategory.huruf);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kamus BISINDO'),
        centerTitle: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.sync,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                      onChanged: notifier.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Cari huruf...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: dictionaryState.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'Semua',
                            null,
                            dictionaryState.selectedCategory,
                            notifier,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Huruf',
                            DictionaryCategory.huruf,
                            dictionaryState.selectedCategory,
                            notifier,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (dictionaryState.isLoading && dictionaryState.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dictionaryState.searchQuery.isEmpty &&
                dictionaryState.selectedCategory == null) ...[
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
                        onPressed: () =>
                            notifier.setCategory(DictionaryCategory.huruf),
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
              _buildGridSection(items: letterItems.take(26).toList()),
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
              const SliverToBoxAdapter(child: SizedBox(height: 250)),
            ],
            // Ruang untuk bar bawah dan tombol scan.
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    DictionaryCategory? category,
    DictionaryCategory? selectedCategory,
    DictionaryNotifier notifier,
  ) {
    final isSelected = selectedCategory == category;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        notifier.setCategory(selected ? category : null);
      },
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
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
