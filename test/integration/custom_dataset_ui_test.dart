import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countingapp/widgets/enhanced_dataset_selector.dart';
import 'package:countingapp/models/app_skin.dart';

void main() {
  group('Custom Dataset UI Integration', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Enhanced dataset selector should show built-in datasets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDatasetSelector(
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Wait for the widget to initialize
      await tester.pumpAndSettle();

      // Should show loading initially, then dataset sections
      expect(find.byType(EnhancedDatasetSelector), findsOneWidget);

      // Should show built-in dataset sections
      expect(find.text('9x9 Final Positions'), findsOneWidget);
      expect(find.text('19x19 Final Positions'), findsOneWidget);
      expect(find.text('19x19 Midgame Estimation'), findsOneWidget);
    });

    testWidgets('Enhanced dataset selector should show create buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDatasetSelector(
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Wait for the widget to initialize
      await tester.pumpAndSettle();

      // Should show add buttons for creating custom datasets
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsAtLeastNWidgets(3)); // At least 3 base types should have add buttons
    });

    testWidgets('Dataset creation dialog should open when add button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDatasetSelector(
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Wait for the widget to initialize
      await tester.pumpAndSettle();

      // Tap the first add button
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsAtLeastNWidgets(1));

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Should show the dataset creation dialog
      expect(find.text('Create Custom Dataset'), findsOneWidget);
      expect(find.text('Base Dataset Type'), findsOneWidget);
      expect(find.text('Dataset Name'), findsOneWidget);
    });

    testWidgets('Should be able to create a custom dataset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedDatasetSelector(
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Wait for the widget to initialize
      await tester.pumpAndSettle();

      // Tap the first add button
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Enter a name for the custom dataset
      final nameField = find.byType(TextFormField);
      await tester.enterText(nameField, 'My Test Dataset');

      // Tap the create button
      await tester.tap(find.text('Create Dataset'));
      await tester.pumpAndSettle(Duration(seconds: 2)); // Give time for creation

      // Should show success message
      expect(find.textContaining('created successfully'), findsOneWidget);
    });
  });
}