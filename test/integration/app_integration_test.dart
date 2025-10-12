import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otachaki/main.dart';

void main() {
  setUp(() async {
    // Initialize SharedPreferences with empty values for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('App Integration Tests', () {
    testWidgets('app should start without errors and render basic structure', (WidgetTester tester) async {
      // Build the app widget directly instead of calling main()
      await tester.pumpWidget(const GoCountingApp());

      // Pump several frames to allow for initialization
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify app starts without exceptions
      expect(tester.takeException(), isNull);

      // Verify main components are present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app should handle multiple initializations without errors', (WidgetTester tester) async {
      // Test multiple app instances
      await tester.pumpWidget(const GoCountingApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test that we can rebuild the app
      await tester.pumpWidget(const GoCountingApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('app should maintain basic structure stability', (WidgetTester tester) async {
      await tester.pumpWidget(const GoCountingApp());

      // Pump several frames to test stability
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }

      // Should maintain basic structure
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app should handle theme initialization', (WidgetTester tester) async {
      await tester.pumpWidget(const GoCountingApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should initialize without crashing
      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);

      // Look for theme-related widgets without strict requirements
      final hasThemeData = find.byType(MaterialApp).evaluate().first.widget as MaterialApp;
      expect(hasThemeData.theme, isNotNull);
    });
  });
}