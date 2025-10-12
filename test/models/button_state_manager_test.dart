import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/widgets/adaptive_result_buttons.dart';
import 'package:otachaki/models/auto_advance_mode.dart';

void main() {
  group('ButtonStateManager Pause Functionality', () {
    test('should show scores when pause is pressed regardless of auto-advance mode', () {
      // Test with always auto-advance + pause
      final managerAlwaysPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerAlwaysPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerAlwaysPaused.shouldAutoAdvance(), true); // auto-advance logic unchanged

      // Test with never auto-advance + pause
      final managerNeverPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.never,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerNeverPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerNeverPaused.shouldAutoAdvance(), false);

      // Test with onCorrectOnly auto-advance + pause + correct answer
      final managerCorrectOnlyPaused = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerCorrectOnlyPaused.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerCorrectOnlyPaused.shouldAutoAdvance(), true);
    });

    test('should follow normal logic when pause is not pressed', () {
      // Test with always auto-advance, no pause
      final managerAlways = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(managerAlways.getDisplayMode(), ButtonDisplayMode.choices);
      expect(managerAlways.shouldAutoAdvance(), true);

      // Test with never auto-advance, no pause
      final managerNever = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.never,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(managerNever.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerNever.shouldAutoAdvance(), false);

      // Test with onCorrectOnly auto-advance, correct answer, no pause
      final managerCorrectOnly = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(managerCorrectOnly.getDisplayMode(), ButtonDisplayMode.choices);
      expect(managerCorrectOnly.shouldAutoAdvance(), true);

      // Test with onCorrectOnly auto-advance, incorrect answer, no pause
      final managerIncorrectOnly = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        isAnswerCorrect: false,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(managerIncorrectOnly.getDisplayMode(), ButtonDisplayMode.scores);
      expect(managerIncorrectOnly.shouldAutoAdvance(), false);
    });

    test('should work with default pausePressed value', () {
      // Test that default constructor works as before
      final manager = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
      );
      expect(manager.getDisplayMode(), ButtonDisplayMode.choices);
      expect(manager.shouldAutoAdvance(), true);
    });

    test('should handle pause state transitions correctly', () {
      // Test that pause can be activated during auto-advance
      final managerBeforePause = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: false,
      );
      expect(managerBeforePause.shouldAutoAdvance(), true);
      expect(managerBeforePause.getDisplayMode(), ButtonDisplayMode.choices);

      // After pause is pressed, display mode changes but auto-advance logic unchanged
      final managerAfterPause = ButtonStateManager(
        autoAdvanceMode: AutoAdvanceMode.always,
        isAnswerCorrect: true,
        hasAnswered: true,
        pausePressed: true,
      );
      expect(managerAfterPause.shouldAutoAdvance(), true); // Logic unchanged
      expect(managerAfterPause.getDisplayMode(), ButtonDisplayMode.scores); // But shows Next button
    });
  });
}