import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../dictionary/presentation/widgets/gesture_thumbnail.dart';
import '../../domain/models/history_item.dart';
import '../providers/history_provider.dart';
import '../widgets/delete_confirm_dialog.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        // Panah back hanya saat dibuka dari menu Beranda (context.push),
        // bukan dari tab bottom nav.
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppPalette.navy),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          'Riwayat Translasi',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPalette.navy,
          ),
        ),
        actions: [
          if (historyState.items.isNotEmpty)
            IconButton(
              tooltip: 'Hapus Semua Riwayat',
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: AppPalette.coral,
                size: 26,
              ),
              onPressed: () {
                DeleteConfirmDialog.show(
                  context: context,
                  title: 'Hapus Semua Riwayat',
                  message:
                      'Apakah Anda yakin ingin menghapus seluruh riwayat translasi?',
                  onConfirm: () async {
                    final ok = await historyNotifier.clearAll();
                    if (!context.mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua riwayat berhasil dihapus'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sebagian riwayat di server belum terhapus'),
                          backgroundColor: AppPalette.coral,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description, Search Bar & Filter Pills
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
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        historyNotifier.setSearchQuery(val);
                        setState(() {});
                      },
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppPalette.navy,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari hasil terjemahan...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  historyNotifier.setSearchQuery('');
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Pills Row (Semua, Teks, Suara)
                  _buildFilterPills(context, historyState, historyNotifier),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            if (historyState.syncError != null)
              const _SyncBanner(),

            // History List or Empty State. Tarik ke bawah untuk sinkron ulang.
            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      color: AppPalette.primary,
                      onRefresh: historyNotifier.loadHistory,
                      child: filteredItems.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.paddingOf(context).bottom,
                              ),
                              children: [
                                const SizedBox(height: 40),
                                _buildEmptyState(
                                  historyState.activeFilter,
                                  historyState.searchQuery,
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                8 + MediaQuery.paddingOf(context).bottom,
                              ),
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
        children: filters.map((filter) {
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
    final confPercent = item.confidence > 1
        ? item.confidence.round()
        : (item.confidence * 100).round();

    final Color confColor = confPercent >= 80
        ? AppPalette.teal
        : confPercent >= 60
            ? AppPalette.warning
            : AppPalette.coral;

    void copyToClipboard() {
      Clipboard.setData(ClipboardData(text: item.title));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teks "${item.title}" disalin ke clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: copyToClipboard,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Avatar
                  // Ilustrasi tangan sama seperti kartu Kamus.
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: GestureThumbnail.backgroundFor(
                        isLetter: item.type == 'Huruf',
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: GestureThumbnail(
                      title: item.title,
                      isLetter: item.type == 'Huruf',
                      iconSize: 28,
                      strokeRatio: 0.035,
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
                            const SizedBox(width: 6),

                            // Confidence Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: confColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$confPercent%',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: confColor,
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
                      if (value == 'copy') {
                        copyToClipboard();
                      } else if (value == 'delete' && item.id != null) {
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
                        value: 'copy',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              color: AppPalette.navy,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Salin Teks',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppPalette.navy,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter, String searchQuery) {
    final String message;
    if (searchQuery.isNotEmpty) {
      message = 'Tidak ada riwayat terjemahan yang cocok dengan "$searchQuery".';
    } else if (filter == 'Semua') {
      message = 'Riwayat hasil deteksi bahasa isyarat kamu akan tampil di sini.';
    } else {
      message = 'Tidak ada riwayat terjemahan untuk kategori "$filter".';
    }

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
              child: Icon(
                searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.history_rounded,
                size: 48,
                color: AppPalette.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              searchQuery.isNotEmpty ? 'Tidak Ditemukan' : 'Belum Ada Riwayat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppPalette.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

/// Pemberitahuan bahwa riwayat belum tersinkron dengan server.
class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE2A7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: Color(0xFFB7791F),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server belum terhubung. Riwayat tetap tersimpan di HP dan '
              'dikirim otomatis nanti. Tarik ke bawah untuk mencoba lagi.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: const Color(0xFF8A5A12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
