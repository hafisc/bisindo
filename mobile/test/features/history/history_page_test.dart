import 'package:bisindo_translator/features/history/domain/models/history_item.dart';
import 'package:bisindo_translator/features/history/presentation/pages/history_page.dart';
import 'package:bisindo_translator/features/history/presentation/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHistoryNotifier extends HistoryNotifier {
  _FakeHistoryNotifier(this._initialItems);

  final List<HistoryItem> _initialItems;

  @override
  HistoryState build() => HistoryState(
    items: _initialItems,
    isLoading: false,
  );

  @override
  Future<void> loadHistory() async {}
}

void main() {
  final sampleItems = [
    const HistoryItem(
      id: 1,
      remoteId: 101,
      title: 'HALO',
      type: 'Kata',
      category: 'Teks',
      mode: 'BISINDO → Teks',
      timestamp: '2026-11-16T10:00:00',
      confidence: 0.95,
    ),
    const HistoryItem(
      id: 2,
      remoteId: 102,
      title: 'A',
      type: 'Huruf',
      category: 'Teks',
      mode: 'BISINDO → Teks',
      timestamp: '2026-11-16T09:30:00',
      confidence: 0.88,
    ),
  ];

  Widget createWidget(List<HistoryItem> items) {
    return ProviderScope(
      overrides: [
        historyNotifierProvider.overrideWith(
          () => _FakeHistoryNotifier(items),
        ),
      ],
      child: const MaterialApp(
        home: HistoryPage(),
      ),
    );
  }

  testWidgets('menampilkan search bar, badge confidence, dan item riwayat', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget(sampleItems));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Translasi'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('HALO'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
  });

  testWidgets('fitur pencarian memfilter hasil riwayat', (tester) async {
    await tester.pumpWidget(createWidget(sampleItems));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'HALO');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Dismissible, 'HALO'), findsOneWidget);
    expect(find.widgetWithText(Dismissible, 'A'), findsNothing);

    // Cari teks yang tidak ada
    await tester.enterText(searchField, 'XYZ');
    await tester.pumpAndSettle();

    expect(find.text('Tidak Ditemukan'), findsOneWidget);
    expect(
      find.text('Tidak ada riwayat terjemahan yang cocok dengan "XYZ".'),
      findsOneWidget,
    );
  });
}
