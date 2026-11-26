import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../data/repositories/letter_pose_repository.dart';
import '../../domain/models/dictionary_item.dart';
import '../../domain/models/letter_pose.dart';
import '../providers/dictionary_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/hand_pose_view.dart';

class DictionaryDetailPage extends ConsumerStatefulWidget {
  final String id;
  const DictionaryDetailPage({super.key, required this.id});

  @override
  ConsumerState<DictionaryDetailPage> createState() =>
      _DictionaryDetailPageState();
}

class _DictionaryDetailPageState extends ConsumerState<DictionaryDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dictionaryProvider.notifier).refreshItemDetail(widget.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dictionaryState = ref.watch(dictionaryProvider);

    if (dictionaryState.isLoading && dictionaryState.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Gesture')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = dictionaryState.itemById(widget.id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Gesture')),
        body: const Center(child: Text('Item tidak ditemukan.')),
      );
    }

    final theme = Theme.of(context);
    final isLetter = item.category == DictionaryCategory.huruf;
    final badgeColor = isLetter ? AppPalette.orange : AppPalette.primary;
    final posesAsync = isLetter ? ref.watch(letterPosesProvider) : null;
    final poses = posesAsync?.valueOrNull;
    final LetterPose? pose = poses == null
        ? null
        : poses[item.title.toUpperCase()];

    final instructions =
        pose?.instructions ??
        (item.instructions.isNotEmpty
            ? item.instructions
            : (item.description.isNotEmpty ? [item.description] : null));
    final tips = (pose?.tips.isNotEmpty == true) ? pose!.tips : item.tips;
    final confusedWith = pose?.confusedWith;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Gesture'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        surfaceTintColor: AppPalette.transparent,
        elevation: 0,
      ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IllustrationBox(
                isLetter: isLetter,
                pose: pose,
                isLoading: posesAsync?.isLoading ?? false,
              ),
              if (pose != null) ...[
                const SizedBox(height: 10),
                _IllustrationCaption(pose: pose),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPalette.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
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
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppPalette.gray600,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Cara Melakukan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (instructions == null)
                Text(
                  posesAsync?.hasError == true
                      ? 'Panduan peragaan gagal dimuat. Tutup lalu buka lagi halaman ini.'
                      : 'Memuat panduan peragaan...',
                  style: const TextStyle(color: AppPalette.gray500, height: 1.5),
                )
              else
                ...instructions.asMap().entries.map(
                  (entry) =>
                      _InstructionRow(number: entry.key + 1, text: entry.value),
                ),
              const SizedBox(height: 24),
              if (tips.isNotEmpty) _TipsBox(text: tips),
              if (confusedWith != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(
                    GoRouterState.of(
                          context,
                        ).uri.path.startsWith(AppRoutes.favorites)
                        ? 'favoriteDetail'
                        : 'dictionaryDetail',
                    pathParameters: {'id': 'letter_$confusedWith'},
                  ),
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: Text('Bandingkan dengan huruf $confusedWith'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _FavoriteButton(itemId: item.id),
          ),
        ),
      );
  }
}

class _IllustrationBox extends StatelessWidget {
  final bool isLetter;
  final LetterPose? pose;
  final bool isLoading;

  const _IllustrationBox({
    required this.isLetter,
    required this.pose,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (pose != null) {
      content = HandPoseView(pose: pose!);
    } else if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = Center(
        child: Icon(
          isLetter ? Icons.back_hand : Icons.sign_language,
          size: 100,
          color: isLetter ? AppPalette.orangeLight : AppPalette.blue300,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: AppPalette.gray100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: content,
    );
  }
}

class _IllustrationCaption extends StatelessWidget {
  final LetterPose pose;
  const _IllustrationCaption({required this.pose});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: AppPalette.gray500, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pose.twoHanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 16,
              children: [
                _LegendDot(
                  color: HandPosePainter.skinColors[0],
                  label: 'Tangan kiri (lebih gelap)',
                ),
                _LegendDot(
                  color: HandPosePainter.skinColors[1],
                  label: 'Tangan kanan (lebih terang)',
                ),
              ],
            ),
          ),
        Text(
          'Ilustrasi diambil dari peragaan asli di dataset model '
          '(${pose.samples} contoh huruf ${pose.letter}), seperti terlihat dari kamera.',
          style: style,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: HandPosePainter.outlineColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppPalette.gray600)),
      ],
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final int number;
  final String text;
  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsBox extends StatelessWidget {
  final String text;
  const _TipsBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.blue50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.blue100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppPalette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppPalette.blue800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: AppPalette.blue900, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String itemId;
  const _FavoriteButton({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(itemId);
    final color = isFavorite ? AppPalette.error : Theme.of(context).primaryColor;

    return OutlinedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        String message;
        try {
          final added = await ref
              .read(favoritesProvider.notifier)
              .toggle(itemId);
          message = added ? 'Ditambahkan ke Favorit' : 'Dihapus dari Favorit';
        } catch (_) {
          message = 'Favorit gagal disimpan. Coba lagi.';
        }
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: color,
      ),
      label: Text(
        isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
