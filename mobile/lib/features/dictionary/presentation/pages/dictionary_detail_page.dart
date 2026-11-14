import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../data/repositories/dummy_dictionary_repository.dart';
import '../../data/repositories/letter_pose_repository.dart';
import '../../domain/models/dictionary_item.dart';
import '../../domain/models/letter_pose.dart';
import '../providers/favorites_provider.dart';
import '../widgets/hand_pose_view.dart';

class DictionaryDetailPage extends ConsumerWidget {
  final String id;
  const DictionaryDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = DummyDictionaryRepository.getItemById(id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Gesture')),
        body: const Center(child: Text('Item tidak ditemukan.')),
      );
    }

    final theme = Theme.of(context);
    final isLetter = item.category == DictionaryCategory.huruf;
    final badgeColor = isLetter ? Colors.orange : Colors.blue;
    final posesAsync = isLetter ? ref.watch(letterPosesProvider) : null;
    final poses = posesAsync?.valueOrNull;
    final LetterPose? pose = poses == null
        ? null
        : poses[item.title.toUpperCase()];

    final instructions =
        pose?.instructions ??
        (item.instructions.isEmpty ? null : item.instructions);
    final tips = pose?.tips ?? item.tips;
    final confusedWith = pose?.confusedWith;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Gesture'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
                      color: Colors.black87,
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
                style: TextStyle(color: Colors.grey[600], height: 1.5),
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
                  'dictionaryDetail',
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
          color: isLetter ? Colors.orange[300] : Colors.blue[300],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
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
    final style = TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pose.twoHanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 16,
              children: const [
                _LegendDot(color: AppPalette.primary, label: 'Tangan kiri'),
                _LegendDot(color: AppPalette.yellow, label: 'Tangan kanan'),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
        color: const Color(0xFFEFF6FF),
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
                  text,
                  style: TextStyle(color: Colors.blue[900], height: 1.5),
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
    final color = isFavorite ? Colors.red : Theme.of(context).primaryColor;

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
