import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_palette.dart';
import '../../domain/models/history_item.dart';
import '../providers/history_provider.dart';
import '../widgets/delete_confirm_dialog.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyNotifierProvider);
    final historyNotifier = ref.read(historyNotifierProvider.notifier);
    final filteredItems = historyState.filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // AppPalette.lightGray
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Riwayat Translasi',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description & Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lihat kembali hasil terjemahan\nyang pernah kamu lakukan.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B), // Slightly darker gray for better readability
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filter Pills Row (Semua, Teks, Suara)
                  _buildFilterPills(context, historyState, historyNotifier),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // History List or Empty State
            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                      ? _buildEmptyState(historyState.activeFilter)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildHistoryCard(
                              context,
                              item,
                              historyNotifier,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills(
    BuildContext context,
    HistoryState state,
    HistoryNotifier notifier,
  ) {
    final filters = ['Semua', 'Teks', 'Suara'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1), // AppPalette.gray200
      ),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = state.activeFilter == filter;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppPalette.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItem item,
    HistoryNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Dismissible(
        key: Key('history_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppPalette.coral,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        confirmDismiss: (direction) async {
          return await DeleteConfirmDialog.show(
            context: context,
            title: 'Hapus Item Riwayat',
            message: 'Apakah Anda yakin ingin menghapus "${item.title}" dari riwayat?',
            onConfirm: () {
              if (item.id != null) {
                notifier.deleteItem(item.id!);
              }
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Avatar
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.type == 'Huruf' ? '✋🏽' : '☝🏽',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A), // AppPalette.darkBlue
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Type Pill Badge (Kata / Huruf)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.softBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.type,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Timestamp
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8), // AppPalette.gray400
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Mode Subtitle
                    Text(
                      item.mode,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFCBD5E1), // Very faint text
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Options
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF64748B), // AppPalette.gray600
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete' && item.id != null) {
                    DeleteConfirmDialog.show(
                      context: context,
                      title: 'Hapus Item',
                      message:
                          'Apakah Anda yakin ingin menghapus "${item.title}" dari riwayat?',
                      onConfirm: () => notifier.deleteItem(item.id!),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: AppPalette.coral,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppPalette.coral,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppPalette.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: AppPalette.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Riwayat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'Semua'
                  ? 'Riwayat hasil deteksi bahasa isyarat kamu akan tampil di sini.'
                  : 'Tidak ada riwayat terjemahan untuk kategori "$filter".',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestampStr) {
    try {
      final dt = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 60) {
        return DateFormat('HH:mm').format(dt);
      } else if (difference.inDays == 0 && dt.day == now.day) {
        return DateFormat('HH:mm').format(dt);
      } else if (difference.inDays == 1 || (now.day - dt.day == 1)) {
        return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
      } else {
        return DateFormat('dd MMM, HH:mm').format(dt);
      }
    } catch (_) {
      return timestampStr;
    }
  }
}
