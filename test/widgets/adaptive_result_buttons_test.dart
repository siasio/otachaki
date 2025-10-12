import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/widgets/adaptive_result_buttons.dart';
import 'package:otachaki/models/auto_advance_mode.dart';
import 'package:otachaki/models/app_skin.dart';
import 'package:otachaki/models/layout_type.dart';

void main() {
  group('ButtonStateManager', () {
    test('should return correct display mode for always auto-advance', () {
      final manager = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: false,
      );
      expect(manager.getDisplayMode(), ButtonDisplayMode.choices);
      expect(manager.shouldAutoAdvance(), false); // hasn't answered yet

      final managerAnswered = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
      );
      expect(managerAnswered.getDisplayMode(), ButtonDisplayMode.choices);
      expect(managerAnswered.shouldAutoAdvance(), true);
    });

    test('should return correct display mode for never auto-advance', () {
      final manager = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.never,
        isAnswerCorrect: true,
        hasAnswered: false,
      );
      expect(manager.getDisplayMode(), ButtonDisplayMode.choices);
      expect(manager.shouldAutoAdvance(), false);

      final managerAnswered = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.never,
        isAnswerCorrect: true,
        hasAnswered: true,
      );
      expect(managerAnswered.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerAnswered.shouldAutoAdvance(), false);
    });

    test('should return correct display mode for on-correct-only auto-advance', () {
      final managerCorrect = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: true,
        hasAnswered: true,
      );
      expect(managerCorrect.getDisplayMode(), ButtonDisplayMode.choices);
      expect(managerCorrect.shouldAutoAdvance(), true);

      final managerIncorrect = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: false,
        hasAnswered: true,
      );
      expect(managerIncorrect.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerIncorrect.shouldAutoAdvance(), false);
    });

    test('should handle pause state correctly', () {
      // When pause is pressed, should always show scores regardless of auto-advance mode
      final managerAlwaysPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerAlwaysPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerAlwaysPaused.shouldAutoAdvance(), true); // auto-advance logic unchanged

      final managerCorrectOnlyPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerCorrectOnlyPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerCorrectOnlyPaused.shouldAutoAdvance(), true);

      final managerNeverPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.never,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerNeverPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerNeverPaused.shouldAutoAdvance(), false);
    });

    test('should not auto-advance when pause is not pressed', () {
      final manager = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(manager.getDisplayMode(), ButtonDisplayMode.choices);
      expect(manager.shouldAutoAdvance(), true);
    });
  });

  group('AdaptiveResultButtons', () {
    testWidgets('should create factory for choices', (WidgetTester tester) async {
      final widget = AdaptiveResultButtons.forChoices(
        onResultSelected: (_) {},
        appSkin: AppSkin.classic,
        layoutType: LayoutType.vertical,
      );

      expect(widget.displayMode, ButtonDisplayMode.choices);
      expect(widget.appSkin, AppSkin.classic);
      expect(widget.layoutType, LayoutType.vertical);
    });

    testWidgets('should create factory for scores', (WidgetTester tester) async {
      final widget = AdaptiveResultButtons.forScores(
        resultString: 'W+5.5',
        onNextPressed: () {},
        appSkin: AppSkin.modern,
        layoutType: LayoutType.horizontal,
        useColoredBackgroundForScores: true,
      );

      expect(widget.displayMode, ButtonDisplayMode.scores);
      expect(widget.resultString, 'W+5.5');
      expect(widget.appSkin, AppSkin.modern);
      expect(widget.layoutType, LayoutType.horizontal);
    });

    testWidgets('should render when in scores mode', (WidgetTester tester) async {
      final widget = AdaptiveResultButtons.forScores(
        resultString: 'B+12.5',
        onNextPressed: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('B+12.5'), findsOneWidget);
    });
  });
}