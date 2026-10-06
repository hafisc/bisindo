import 'package:flutter/material.dart';

import '../../../core/constants/app_palette.dart';

/// Satu item notifikasi di halaman Notifikasi.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    timeLabel: timeLabel,
    icon: icon,
    color: color,
    isRead: isRead ?? this.isRead,
  );
}

/// Penyimpan notifikasi sementara (lokal, di memori).
///
/// Belum terhubung ke backend atau FCM. Isinya masih info bawaan aplikasi.
/// Nanti cukup ganti sumber [items] kalau notifikasi dari server sudah ada,
/// halaman dan titik kuning di lonceng akan ikut menyesuaikan.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  final List<AppNotification> _items = [
    const AppNotification(
      id: 'welcome',
      title: 'Selamat datang di BISINDO Translator',
      body: 'Arahkan kamera ke tangan dan mulai terjemahkan bahasa isyarat.',
      timeLabel: 'Hari ini',
      icon: Icons.waving_hand_rounded,
      color: AppPalette.primary,
    ),
    const AppNotification(
      id: 'tips',
      title: 'Tips latihan',
      body: 'Latih gesture setiap hari untuk meningkatkan akurasi deteksi.',
      timeLabel: 'Hari ini',
      icon: Icons.lightbulb_outline_rounded,
      color: AppPalette.yellow,
    ),
    const AppNotification(
      id: 'dictionary',
      title: 'Kamus BISINDO tersedia',
      body: 'Pelajari gestur huruf dan kata lewat menu Kamus.',
      timeLabel: 'Hari ini',
      icon: Icons.menu_book_rounded,
      color: AppPalette.info,
    ),
  ];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  void markRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllRead() {
    if (!hasUnread) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
