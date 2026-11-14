import 'package:bisindo_translator/features/auth/presentation/pages/legal_page.dart';
import 'package:bisindo_translator/features/dictionary/data/repositories/letter_pose_repository.dart';
import 'package:bisindo_translator/features/dictionary/domain/models/letter_pose.dart';
import 'package:bisindo_translator/features/dictionary/presentation/pages/dictionary_detail_page.dart';
import 'package:bisindo_translator/features/dictionary/presentation/pages/favorite_page.dart';
import 'package:bisindo_translator/features/dictionary/presentation/providers/favorites_provider.dart';
import 'package:bisindo_translator/features/dictionary/presentation/widgets/hand_pose_view.dart';
import 'package:bisindo_translator/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, LetterPose> _poses;

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  // Pose dimuat sekali di luar zona waktu palsu test, lalu disuntikkan ke
  // provider supaya halaman tidak menunggu pembacaan aset.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [letterPosesProvider.overrideWith((ref) async => _poses)],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    _poses = await LetterPoseRepository().loadAll();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Detail kamus huruf', () {
    testWidgets('menampilkan ilustrasi dan panduan dari data pose', (
      tester,
    ) async {
      await _pump(tester, const DictionaryDetailPage(id: 'letter_V'));

      expect(find.byType(HandPoseView), findsOneWidget);
      expect(find.text('Peragakan dengan satu tangan.'), findsOneWidget);
      expect(
        find.textContaining('Telunjuk dan jari tengah lurus'),
        findsOneWidget,
      );
      expect(find.textContaining('Bandingkan dengan huruf'), findsOneWidget);
      // Elemen palsu lama tidak boleh muncul lagi.
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('tombol favorit menyimpan dan mengubah label', (tester) async {
      await _pump(tester, const DictionaryDetailPage(id: 'letter_V'));

      await tester.tap(find.text('Tambah ke Favorit'));
      await tester.pump();

      expect(find.text('Hapus dari Favorit'), findsOneWidget);
      expect(find.text('Ditambahkan ke Favorit'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(FavoritesNotifier.storageKey), ['letter_V']);
    });

    testWidgets('item yang tidak ada menampilkan pesan', (tester) async {
      await _pump(tester, const DictionaryDetailPage(id: 'tidak_ada'));

      expect(find.text('Item tidak ditemukan.'), findsOneWidget);
    });
  });

  testWidgets('detail kata memakai panduan dari repository kamus', (
    tester,
  ) async {
    await _pump(tester, const DictionaryDetailPage(id: 'word_maaf'));

    expect(find.byType(HandPoseView), findsNothing);
    expect(find.text('Kuncupkan semua jari tangan kanan.'), findsOneWidget);
  });

  group('Halaman Favorit', () {
    testWidgets('kosong menampilkan ajakan ke Kamus', (tester) async {
      await _pump(tester, const FavoritePage());

      expect(find.text('Belum ada favorit'), findsOneWidget);
      expect(find.text('Buka Kamus'), findsOneWidget);
    });

    testWidgets('menampilkan item tersimpan dan mengabaikan id lama', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        FavoritesNotifier.storageKey: ['letter_V', 'item_sudah_dihapus'],
      });

      await _pump(tester, const FavoritePage());

      expect(find.text('1 gesture tersimpan'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
    });
  });

  testWidgets('Syarat dan Kebijakan Privasi dapat dibuka', (tester) async {
    await _pump(tester, const LegalPage(document: LegalDocument.terms));
    expect(find.text('Syarat dan Ketentuan'), findsOneWidget);

    await _pump(tester, const LegalPage(document: LegalDocument.privacy));
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(
      find.textContaining('Gambar tidak dikirim ke server'),
      findsOneWidget,
    );
  });

  test('sapaan Beranda memakai nama depan pengguna', () {
    expect(HomePage.greetingName('Mohammad Al Hafis'), 'Mohammad');
    expect(HomePage.greetingName('  Rizki  '), 'Rizki');
    expect(HomePage.greetingName(''), 'Teman');
  });
}
