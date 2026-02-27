// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:surivion/main.dart';

void main() {
  testWidgets('Home screen renders scanner CTA', (WidgetTester tester) async {
    await tester.pumpWidget(SuriVionApp());

    expect(find.text('SuriVion'), findsOneWidget);
    expect(find.text('Offline Waste Scanner'), findsOneWidget);
    expect(find.text('Scan Waste'), findsOneWidget);
    expect(find.byIcon(Icons.recycling), findsOneWidget);
  });
}
