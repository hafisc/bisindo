import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisindo_translator/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BisindoApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
