import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/widgets/score_display_buttons.dart';
import 'package:otachaki/models/app_skin.dart';
import 'package:otachaki/services/result_text_service.dart';

void main() {
  group('ScoreDisplayButtons', () {
    testWidgets('should display next button', (WidgetTester tester) async {
      bool nextPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: 'W+5.5',
              onNextPressed: () {
                nextPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('NEXT'), findsOneWidget);

      await tester.tap(find.text('NEXT'));
      expect(nextPressed, true);
    });

    testWidgets('should parse and display white win correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: 'W+7.5',
              onNextPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('W+7.5'), findsOneWidget);
      expect(find.text('B loses'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('should parse and display black win correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: 'B+12.5',
              onNextPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('B+12.5'), findsOneWidget);
      expect(find.text('W loses'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('should handle resignation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: 'W+R',
              onNextPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('W+R'), findsOneWidget);
      expect(find.text('B loses'), findsOneWidget);
    });

    testWidgets('should handle empty result', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: '',
              onNextPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('W: ?'), findsOneWidget);
      expect(find.text('B: ?'), findsOneWidget);
    });

    testWidgets('should use colored backgrounds when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreDisplayButtons(
              resultString: 'W+5.5',
              onNextPressed: () {},
              useColoredBackground: true,
              appSkin: AppSkin.classic,
            ),
          ),
        ),
      );

      // Widget should render without error when colored backgrounds are enabled
      expect(find.text('W+5.5'), findsOneWidget);
      expect(find.text('B loses'), findsOneWidget);
    });
  });

  group('ScoreInfo', () {
    test('should store score information correctly', () {
      final scoreInfo = ScoreInfo(
        whiteScore: 'W+7.5',
        blackScore: 'B loses',
      );

      expect(scoreInfo.whiteScore, 'W+7.5');
      expect(scoreInfo.blackScore, 'B loses');
    });
  });
}