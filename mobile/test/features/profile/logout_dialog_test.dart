import 'package:bisindo_translator/features/profile/presentation/widgets/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, void Function(bool) onResult) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  onResult(await LogoutDialog.show(context));
                },
                child: const Text('Buka dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));
    await tester.pumpAndSettle();
  }

  testWidgets('dialog keluar mengembalikan true saat dikonfirmasi',
      (tester) async {
    bool? confirmed;

    await pumpPage(tester, (value) => confirmed = value);

    expect(find.text('Konfirmasi Keluar'), findsOneWidget);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Konfirmasi Keluar'), findsNothing);
  });

  testWidgets('dialog keluar mengembalikan false saat dibatalkan',
      (tester) async {
    bool? confirmed;

    await pumpPage(tester, (value) => confirmed = value);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.text('Konfirmasi Keluar'), findsNothing);
  });
}
