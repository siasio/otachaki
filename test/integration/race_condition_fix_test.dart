import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/training_state.dart';
import '../../lib/services/training_state_manager.dart';

void main() {
  group('Race Condition Fix Integration Tests', () {
    late TrainingStateManager stateManager;

    setUp(() {
      stateManager = TrainingStateManager();
    });

    tearDown(() {
      stateManager.dispose();
    });

    test('pause button prevents auto-advance transition race condition', () async {
      // Start in solving state
      stateManager.transitionTo(TrainingState.solving);

      // User answers question, goes to feedback state
      final answerData = TrainingStateData.answer(isCorrect: true);
      stateManager.transitionTo(TrainingState.feedback, answerData);

      // Schedule auto-advance (simulating mark display timeout)
      stateManager.timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () {
          // This should NOT execute if pause was pressed
          if (stateManager.currentState == TrainingState.feedback) {
            stateManager.transitionTo(TrainingState.loading);
          }
        },
      );

      // User presses pause at the last moment (simulating the race condition)
      await Future.delayed(const Duration(milliseconds: 50));
      stateManager.transitionTo(TrainingState.paused, answerData);

      // Wait for the originally scheduled auto-advance callback
      await Future.delayed(const Duration(milliseconds: 100));

      // The state should be paused, NOT loading (bug fixed!)
      expect(stateManager.currentState, TrainingState.paused);
      expect(stateManager.isCorrectAnswer, true);
      expect(stateManager.timerManager.hasActiveTimers, false);
    });

    test('state machine prevents partial state transitions', () {
      // Start in solving state
      stateManager.transitionTo(TrainingState.solving);

      bool stateChangeCalled = false;
      stateManager.onStateChanged = () => stateChangeCalled = true;

      // Try to create an invalid transition (this would represent the bug scenario)
      expect(
        () => stateManager.transitionTo(TrainingState.paused),
        throwsA(isA<StateError>()),
      );

      // State should remain consistent
      expect(stateManager.currentState, TrainingState.solving);
      expect(stateChangeCalled, false);
    });

    test('timer cancellation prevents delayed state changes', () async {
      stateManager.transitionTo(TrainingState.solving);

      // Schedule multiple conflicting state changes
      bool firstCallbackExecuted = false;
      bool secondCallbackExecuted = false;

      stateManager.timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () {
          firstCallbackExecuted = true;
          if (stateManager.currentState == TrainingState.feedback) {
            stateManager.transitionTo(TrainingState.review);
          }
        },
      );

      // Transition to feedback (this cancels the first timer)
      stateManager.transitionTo(TrainingState.feedback, TrainingStateData.answer(isCorrect: true));

      // Schedule a new timer
      stateManager.timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () {
          secondCallbackExecuted = true;
          if (stateManager.currentState == TrainingState.feedback) {
            stateManager.transitionTo(TrainingState.review);
          }
        },
      );

      // Wait for both timers to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Only the second callback should have executed
      expect(firstCallbackExecuted, false);
      expect(secondCallbackExecuted, true);
      expect(stateManager.currentState, TrainingState.review);
    });

    test('atomic state transitions maintain consistency', () {
      int stateChangeCount = 0;
      TrainingState? lastObservedState;

      stateManager.onStateChanged = () {
        stateChangeCount++;
        lastObservedState = stateManager.currentState;
      };

      // Perform multiple rapid state transitions
      stateManager.transitionTo(TrainingState.solving);
      stateManager.transitionTo(TrainingState.feedback, TrainingStateData.answer(isCorrect: false));
      stateManager.transitionTo(TrainingState.review);

      // Each transition should trigger exactly one state change notification
      expect(stateChangeCount, 3);
      expect(lastObservedState, TrainingState.review);
      expect(stateManager.isCorrectAnswer, false);
    });

    test('state guards prevent execution of stale callbacks', () async {
      stateManager.transitionTo(TrainingState.solving);

      bool staleCallbackExecuted = false;

      // Schedule a state change
      stateManager.timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () {
          // This callback includes a state guard
          if (stateManager.currentState == TrainingState.feedback) {
            staleCallbackExecuted = true;
            stateManager.transitionTo(TrainingState.review);
          }
        },
      );

      // Immediately transition to a different state (need to go through feedback first for valid transition)
      stateManager.transitionTo(TrainingState.feedback, TrainingStateData.answer(isCorrect: true));
      stateManager.transitionTo(TrainingState.paused);

      // Wait for the timer
      await Future.delayed(const Duration(milliseconds: 100));

      // The stale callback should not have executed due to state guard
      expect(staleCallbackExecuted, false);
      expect(stateManager.currentState, TrainingState.paused);
    });

    test('loading state is reentrant for navigation scenarios', () {
      // Start in loading state (initial app state)
      expect(stateManager.currentState, TrainingState.loading);

      // Transition to solving (position loaded)
      stateManager.transitionTo(TrainingState.solving);

      // User goes to config screen - app resets state
      stateManager.reset();
      expect(stateManager.currentState, TrainingState.loading);

      // User returns from config - app tries to load position again
      // This should NOT throw an error (fixing the reported bug)
      expect(() => stateManager.transitionTo(TrainingState.loading), returnsNormally);
      expect(stateManager.currentState, TrainingState.loading);

      // Position loads successfully
      stateManager.transitionTo(TrainingState.solving);
      expect(stateManager.currentState, TrainingState.solving);
    });
  });
}