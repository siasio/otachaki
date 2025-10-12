import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/training_state.dart';

void main() {
  group('TrainingState', () {
    test('displayName returns correct values', () {
      expect(TrainingState.loading.displayName, 'Loading');
      expect(TrainingState.solving.displayName, 'Solving');
      expect(TrainingState.feedback.displayName, 'Feedback');
      expect(TrainingState.review.displayName, 'Review');
      expect(TrainingState.paused.displayName, 'Paused');
    });

    test('shouldRunTimer returns correct values', () {
      expect(TrainingState.loading.shouldRunTimer, false);
      expect(TrainingState.solving.shouldRunTimer, true);
      expect(TrainingState.feedback.shouldRunTimer, false);
      expect(TrainingState.review.shouldRunTimer, false);
      expect(TrainingState.paused.shouldRunTimer, false);
    });

    test('shouldShowFeedbackOverlay returns correct values', () {
      expect(TrainingState.loading.shouldShowFeedbackOverlay, false);
      expect(TrainingState.solving.shouldShowFeedbackOverlay, false);
      expect(TrainingState.feedback.shouldShowFeedbackOverlay, true);
      expect(TrainingState.review.shouldShowFeedbackOverlay, false);
      expect(TrainingState.paused.shouldShowFeedbackOverlay, false);
    });

    test('hasAnswered returns correct values', () {
      expect(TrainingState.loading.hasAnswered, false);
      expect(TrainingState.solving.hasAnswered, false);
      expect(TrainingState.feedback.hasAnswered, true);
      expect(TrainingState.review.hasAnswered, true);
      expect(TrainingState.paused.hasAnswered, true);
    });

    test('isWaitingForNext returns correct values', () {
      expect(TrainingState.loading.isWaitingForNext, false);
      expect(TrainingState.solving.isWaitingForNext, false);
      expect(TrainingState.feedback.isWaitingForNext, false);
      expect(TrainingState.review.isWaitingForNext, true);
      expect(TrainingState.paused.isWaitingForNext, true);
    });

    test('validTransitions returns correct sets', () {
      expect(TrainingState.loading.validTransitions, {TrainingState.solving, TrainingState.loading});
      expect(TrainingState.solving.validTransitions, {
        TrainingState.feedback,
        TrainingState.review,
        TrainingState.loading
      });
      expect(TrainingState.feedback.validTransitions, {
        TrainingState.review,
        TrainingState.paused,
        TrainingState.loading
      });
      expect(TrainingState.review.validTransitions, {TrainingState.loading});
      expect(TrainingState.paused.validTransitions, {TrainingState.loading});
    });

    test('canTransitionTo validates transitions correctly', () {
      // Valid transitions
      expect(TrainingState.loading.canTransitionTo(TrainingState.solving), true);
      expect(TrainingState.loading.canTransitionTo(TrainingState.loading), true); // Allow reentrant loading
      expect(TrainingState.solving.canTransitionTo(TrainingState.feedback), true);
      expect(TrainingState.feedback.canTransitionTo(TrainingState.review), true);
      expect(TrainingState.feedback.canTransitionTo(TrainingState.paused), true);

      // Invalid transitions
      expect(TrainingState.loading.canTransitionTo(TrainingState.feedback), false);
      expect(TrainingState.solving.canTransitionTo(TrainingState.paused), false);
      expect(TrainingState.review.canTransitionTo(TrainingState.feedback), false);
    });
  });

  group('TrainingStateData', () {
    test('answer factory creates correct data', () {
      final data = TrainingStateData.answer(isCorrect: true);
      expect(data.isCorrect, true);
      expect(data.wasTimeout, false);
      expect(data.errorMessage, null);

      final timeoutData = TrainingStateData.answer(isCorrect: false, wasTimeout: true);
      expect(timeoutData.isCorrect, false);
      expect(timeoutData.wasTimeout, true);
    });

    test('error factory creates correct data', () {
      final data = TrainingStateData.error('Test error');
      expect(data.errorMessage, 'Test error');
      expect(data.isCorrect, null);
      expect(data.wasTimeout, null);
    });

    test('empty factory creates empty data', () {
      final data = TrainingStateData.empty();
      expect(data.isCorrect, null);
      expect(data.wasTimeout, null);
      expect(data.errorMessage, null);
      expect(data.additionalData, null);
    });
  });
}