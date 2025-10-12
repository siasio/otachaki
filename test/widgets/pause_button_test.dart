import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/widgets/pause_button.dart';
import 'package:otachaki/models/app_skin.dart';

void main() {
  group('PauseButton', () {
    testWidgets('should render pause icon correctly', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButton(
              onPressed: () {
                pressed = true;
              },
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Find the pause button container
      final buttonFinder = find.byType(Container);
      expect(buttonFinder, findsAtLeastNWidgets(1));

      // Find the pause icon containers (two vertical bars)
      final pauseIconRow = find.descendant(
        of: find.byType(PauseButton),
        matching: find.byType(Row),
      );
      expect(pauseIconRow, findsOneWidget);

      // The pause icon should be represented by Row with two containers
      final rowWidget = tester.widget<Row>(pauseIconRow);
      expect(rowWidget.children.length, 3); // 2 containers + 1 SizedBox spacer
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButton(
              onPressed: () {
                pressed = true;
              },
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(InkWell));
      expect(pressed, true);
    });

    testWidgets('should apply correct styling for different skins', (WidgetTester tester) async {
      for (final skin in AppSkin.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PauseButton(
                onPressed: () {},
                appSkin: skin,
              ),
            ),
          ),
        );

        // Button should always be rendered
        expect(find.byType(PauseButton), findsOneWidget);

        // Should have circular container
        final circularContainers = find.descendant(
          of: find.byType(InkWell),
          matching: find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle),
        );
        expect(circularContainers, findsAtLeastNWidgets(1));

        final containerWidget = tester.widget<Container>(circularContainers.first);
        final decoration = containerWidget.decoration as BoxDecoration;

        // E-ink skin should have border
        if (skin == AppSkin.eink) {
          expect(decoration.border, isNotNull);
        }
      }
    });

    testWidgets('should animate on classic and dark skins', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButton(
              onPressed: () {},
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Should have TweenAnimationBuilder for animated skins
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('should not animate on eink skin', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButton(
              onPressed: () {},
              appSkin: AppSkin.eink,
            ),
          ),
        ),
      );

      // Should not have TweenAnimationBuilder for non-animated skins
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });
  });
}