// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beat_cinema/main.dart';

void main() {
  testWidgets('App boots and renders a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pump();

    // App may be loading or ready, but must render the app shell without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
