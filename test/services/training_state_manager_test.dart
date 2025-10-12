import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/training_state.dart';
import 'package:otachaki/services/training_state_manager.dart';

void main() {
  group('TrainingStateManager', () {
    late TrainingStateManager stateManager;

    setUp(() {
      stateManager = TrainingStateManager();
    });

    tearDown(() {
      stateManager.dispose();
    });

    test('initial state is loading', () {
      expect(stateManager.currentState, TrainingState.loading);
      expect(stateManager.currentData.isCorrect, null);
      expect(stateManager.currentData.wasTimeout, null);
      expect(stateManager.currentData.errorMessage, null);
    });

    test('valid transition succeeds', () {
      bool stateChangedCalled = false;
      stateManager.onStateChanged = () => stateChangedCalled = true;

      stateManager.transitionTo(TrainingState.solving);

      expect(stateManager.currentState, TrainingState.solving);
      expect(stateChangedCalled, true);
    });

    test('invalid transition throws StateError', () {
      expect(
        () => stateManager.transitionTo(TrainingState.feedback),
        throwsA(isA<StateError>()),
      );
    });

    test('transition with data preserves data', () {
      final data = TrainingStateData.answer(isCorrect: true);

      stateManager.transitionTo(TrainingState.solving);
      stateManager.transitionTo(TrainingState.feedback, data);

      expect(stateManager.currentState, TrainingState.feedback);
      expect(stateManager.currentData.isCorrect, true);
      expect(stateManager.isCorrectAnswer, true);
    });

    test('canTransitionTo returns correct values', () {
      expect(stateManager.canTransitionTo(TrainingState.solving), true);
      expect(stateManager.canTransitionTo(TrainingState.feedback), false);

      stateManager.transitionTo(TrainingState.solving);
      expect(stateManager.canTransitionTo(TrainingState.feedback), true);
      expect(stateManager.canTransitionTo(TrainingState.review), true);
    });

    test('derived properties reflect current state', () {
      // Loading state
      expect(stateManager.shouldRunTimer, false);
      expect(stateManager.shouldShowFeedbackOverlay, false);
      expect(stateManager.hasAnswered, false);
      expect(stateManager.isWaitingForNext, false);

      // Solving state
      stateManager.transitionTo(TrainingState.solving);
      expect(stateManager.shouldRunTimer, true);
      expect(stateManager.shouldShowFeedbackOverlay, false);
      expect(stateManager.hasAnswered, false);
      expect(stateManager.isWaitingForNext, false);

      // Feedback state
      final data = TrainingStateData.answer(isCorrect: true);
      stateManager.transitionTo(TrainingState.feedback, data);
      expect(stateManager.shouldRunTimer, false);
      expect(stateManager.shouldShowFeedbackOverlay, true);
      expect(stateManager.hasAnswered, true);
      expect(stateManager.isWaitingForNext, false);

      // Review state
      stateManager.transitionTo(TrainingState.review);
      expect(stateManager.shouldRunTimer, false);
      expect(stateManager.shouldShowFeedbackOverlay, false);
      expect(stateManager.hasAnswered, true);
      expect(stateManager.isWaitingForNext, true);
    });

    test('forceTransitionTo bypasses validation', () {
      // This would normally be invalid
      stateManager.forceTransitionTo(TrainingState.feedback);
      expect(stateManager.currentState, TrainingState.feedback);
    });

    test('transition cancels pending timers', () {
      stateManager.transitionTo(TrainingState.solving);

      // Schedule a transition
      stateManager.scheduleTransition(
        TrainingState.feedback,
        const Duration(milliseconds: 100),
      );

      expect(stateManager.timerManager.hasActiveTimers, true);

      // Transitioning should cancel the scheduled transition
      stateManager.transitionTo(TrainingState.review);

      expect(stateManager.timerManager.hasActiveTimers, false);
    });

    test('scheduleTransition executes after delay', () async {
      stateManager.transitionTo(TrainingState.solving);

      stateManager.scheduleTransition(
        TrainingState.feedback,
        const Duration(milliseconds: 50),
        TrainingStateData.answer(isCorrect: true),
      );

      expect(stateManager.currentState, TrainingState.solving);

      // Wait for scheduled transition
      await Future.delayed(const Duration(milliseconds: 100));

      expect(stateManager.currentState, TrainingState.feedback);
      expect(stateManager.isCorrectAnswer, true);
    });

    test('scheduleTransition respects validation', () async {
      // Try to schedule invalid transition
      stateManager.scheduleTransition(
        TrainingState.feedback,
        const Duration(milliseconds: 50),
      );

      // Wait for timer
      await Future.delayed(const Duration(milliseconds: 100));

      // Should still be in loading state
      expect(stateManager.currentState, TrainingState.loading);
    });

    test('cancelScheduledTransitions stops pending transitions', () async {
      stateManager.transitionTo(TrainingState.solving);

      stateManager.scheduleTransition(
        TrainingState.feedback,
        const Duration(milliseconds: 50),
      );

      stateManager.cancelScheduledTransitions();

      // Wait to ensure transition would have happened
      await Future.delayed(const Duration(milliseconds: 100));

      expect(stateManager.currentState, TrainingState.solving);
    });

    test('reset returns to initial state', () {
      stateManager.transitionTo(TrainingState.solving);
      stateManager.transitionTo(TrainingState.feedback, TrainingStateData.answer(isCorrect: true));

      bool stateChangedCalled = false;
      stateManager.onStateChanged = () => stateChangedCalled = true;

      stateManager.reset();

      expect(stateManager.currentState, TrainingState.loading);
      expect(stateManager.currentData.isCorrect, null);
      expect(stateChangedCalled, true);
    });

    test('timeout data is preserved correctly', () {
      final timeoutData = TrainingStateData.answer(isCorrect: false, wasTimeout: true);

      stateManager.transitionTo(TrainingState.solving);
      stateManager.transitionTo(TrainingState.feedback, timeoutData);

      expect(stateManager.isCorrectAnswer, false);
      expect(stateManager.wasTimeout, true);
    });

    test('error data is preserved correctly', () {
      final errorData = TrainingStateData.error('Test error');

      stateManager.forceTransitionTo(TrainingState.loading, errorData);

      expect(stateManager.errorMessage, 'Test error');
    });

    test('multiple onStateChanged calls work correctly', () {
      int callCount = 0;
      stateManager.onStateChanged = () => callCount++;

      stateManager.transitionTo(TrainingState.solving);
      stateManager.transitionTo(TrainingState.feedback);
      stateManager.reset();

      expect(callCount, 3);
    });

    test('dispose cleans up resources', () {
      stateManager.scheduleTransition(
        TrainingState.solving,
        const Duration(milliseconds: 100),
      );

      expect(stateManager.timerManager.hasActiveTimers, true);

      stateManager.dispose();

      expect(stateManager.timerManager.hasActiveTimers, false);
      expect(stateManager.onStateChanged, null);
    });
  });
}