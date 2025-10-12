// Flutter widget test for Go Territory Trainer app.
//
// Tests basic app functionality and widget structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:otachaki/main.dart';

void main() {
  setUp(() async {
    // Ensure Flutter test binding is initialized
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize SharedPreferences with empty values for testing
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    // Clean up SharedPreferences after each test to prevent state leakage
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and shows MaterialApp', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GoCountingApp());

    // Instead of pumpAndSettle which can timeout, just pump a few frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the app loads (look for key UI elements)
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has basic structure without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GoCountingApp());

    // Pump a few frames to allow for initial rendering
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // App should have a basic structure - just verify it doesn't crash
    expect(tester.takeException(), isNull);

    // Should have at least a MaterialApp and likely a Scaffold
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
