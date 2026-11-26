import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_palette.dart';

/// Satu item notifikasi di halaman Notifikasi.
class AppNotification extends Equatable {
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

  @override
  List<Object?> get props => [id, title, body, timeLabel, icon, color, isRead];
}

const List<AppNotification> defaultNotifications = [
  AppNotification(
    id: 'welcome',
    title: 'Selamat datang di BISINDO Translator',
    body: 'Arahkan kamera ke tangan dan mulai terjemahkan bahasa isyarat.',
    timeLabel: 'Hari ini',
    icon: Icons.waving_hand_rounded,
    color: AppPalette.primary,
  ),
  AppNotification(
    id: 'tips',
    title: 'Tips latihan',
    body: 'Latih gesture setiap hari untuk meningkatkan akurasi deteksi.',
    timeLabel: 'Hari ini',
    icon: Icons.lightbulb_outline_rounded,
    color: AppPalette.yellow,
  ),
  AppNotification(
    id: 'dictionary',
    title: 'Kamus BISINDO tersedia',
    body: 'Pelajari gestur huruf A-Z lewat menu Kamus.',
    timeLabel: 'Hari ini',
    icon: Icons.menu_book_rounded,
    color: AppPalette.info,
  ),
];

/// Daftar notifikasi awal; bisa di-override di test.
final initialNotificationsProvider = Provider<List<AppNotification>>(
  (ref) => defaultNotifications,
);

/// Pengelola notifikasi berbasis Riverpod `Notifier`.
class NotificationNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    return List.unmodifiable(ref.watch(initialNotificationsProvider));
  }

  void markRead(String id) {
    final index = state.indexWhere((n) => n.id == id);
    if (index == -1 || state[index].isRead) return;
    final next = List<AppNotification>.from(state);
    next[index] = next[index].copyWith(isRead: true);
    state = List.unmodifiable(next);
  }

  void markAllRead() {
    if (!state.any((n) => !n.isRead)) return;
    state = List.unmodifiable([
      for (final item in state) item.copyWith(isRead: true),
    ]);
  }

  void remove(String id) {
    state = List.unmodifiable(state.where((n) => n.id != id));
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(
    notificationProvider.select(
      (items) => items.where((n) => !n.isRead).length,
    ),
  );
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(
    notificationProvider.select((items) => items.any((n) => !n.isRead)),
  );
});
