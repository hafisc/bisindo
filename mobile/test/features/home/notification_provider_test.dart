import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/core/constants/app_strings.dart';
import 'package:bisindo_translator/features/home/presentation/pages/notification_page.dart';
import 'package:bisindo_translator/features/home/presentation/providers/notification_provider.dart';

void main() {
  group('NotificationNotifier', () {
    test('memuat notifikasi default yang seluruhnya belum dibaca', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(notificationProvider);
      expect(items, hasLength(defaultNotifications.length));
      expect(container.read(hasUnreadNotificationsProvider), isTrue);
      expect(container.read(unreadNotificationCountProvider), 3);
      expect(items.every((n) => !n.isRead), isTrue);
    });

    test('markRead dan markAllRead memperbarui status serta hitungan belum dibaca', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(notificationProvider.notifier);
      notifier.markRead('welcome');

      expect(container.read(unreadNotificationCountProvider), 2);
      expect(
        container.read(notificationProvider).firstWhere((n) => n.id == 'welcome').isRead,
        isTrue,
      );

      notifier.markAllRead();
      expect(container.read(unreadNotificationCountProvider), 0);
      expect(container.read(hasUnreadNotificationsProvider), isFalse);
    });

    test('remove menghapus notifikasi sesuai id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationProvider.notifier).remove('tips');
      final items = container.read(notificationProvider);

      expect(items.any((n) => n.id == 'tips'), isFalse);
      expect(items, hasLength(2));
    });
  });

  testWidgets('NotificationPage menampilkan daftar dan bisa menandai semua dibaca', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NotificationPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(defaultNotifications.first.title), findsOneWidget);
    expect(find.text(AppStrings.notificationMarkAllRead), findsOneWidget);

    await tester.tap(find.text(AppStrings.notificationMarkAllRead));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotificationPage)),
    );
    expect(container.read(hasUnreadNotificationsProvider), isFalse);
  });
}
