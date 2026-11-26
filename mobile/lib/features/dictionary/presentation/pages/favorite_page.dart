import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/dictionary_item.dart';
import '../providers/dictionary_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/dictionary_card.dart';

/// Daftar gesture kamus yang ditandai favorit, terbaru di atas.
class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final dictionaryState = ref.watch(dictionaryProvider);

    final byId = {for (final item in dictionaryState.items) item.id: item};
    // Id yang sudah tidak ada di kamus (data lama) diabaikan.
    final items = favoriteIds
        .map((id) => byId[id])
        .whereType<DictionaryItem>()
        .toList();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Favorit'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: AppPalette.transparent,
        elevation: 0,
      ),
      body: dictionaryState.isLoading && dictionaryState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const _EmptyFavorites()
              : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      '${items.length} gesture tersimpan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return DictionaryCard(
                          item: item,
                          isFavorite: true,
                          onTap: () => context.pushNamed(
                            'favoriteDetail',
                            pathParameters: {'id': item.id},
                          ),
                        );
                      }, childCount: items.length),
                    ),
                  ),
                ],
              ),
      );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppPalette.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: AppPalette.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada favorit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Buka gesture di Kamus lalu ketuk "Tambah ke Favorit" '
              'supaya mudah ditemukan saat latihan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppPalette.gray500, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.dictionary),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Buka Kamus'),
            ),
          ],
        ),
      ),
    );
  }
}
