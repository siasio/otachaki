import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/services/training_timer_manager.dart';

void main() {
  group('TrainingTimerManager', () {
    late TrainingTimerManager timerManager;

    setUp(() {
      timerManager = TrainingTimerManager();
    });

    tearDown(() {
      timerManager.dispose();
    });

    test('initial state has no active timers', () {
      expect(timerManager.hasActiveAutoAdvanceTimer, false);
      expect(timerManager.hasActiveFeedbackTimer, false);
      expect(timerManager.hasActiveTimers, false);
    });

    test('scheduleAutoAdvance creates active timer', () {
      bool callbackCalled = false;

      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveAutoAdvanceTimer, true);
      expect(timerManager.hasActiveTimers, true);
      expect(callbackCalled, false);
    });

    test('scheduleFeedback creates active timer', () {
      bool callbackCalled = false;

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 100),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveFeedbackTimer, true);
      expect(timerManager.hasActiveTimers, true);
      expect(callbackCalled, false);
    });

    test('autoAdvance timer executes callback and cleans up', () async {
      bool callbackCalled = false;

      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveAutoAdvanceTimer, true);

      // Wait for timer to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackCalled, true);
      expect(timerManager.hasActiveAutoAdvanceTimer, false);
    });

    test('feedback timer executes callback and cleans up', () async {
      bool callbackCalled = false;

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 50),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveFeedbackTimer, true);

      // Wait for timer to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackCalled, true);
      expect(timerManager.hasActiveFeedbackTimer, false);
    });

    test('cancelAutoAdvance stops timer and prevents callback', () async {
      bool callbackCalled = false;

      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveAutoAdvanceTimer, true);

      timerManager.cancelAutoAdvance();

      expect(timerManager.hasActiveAutoAdvanceTimer, false);

      // Wait to ensure callback would have been called
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackCalled, false);
    });

    test('cancelFeedback stops timer and prevents callback', () async {
      bool callbackCalled = false;

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 50),
        () => callbackCalled = true,
      );

      expect(timerManager.hasActiveFeedbackTimer, true);

      timerManager.cancelFeedback();

      expect(timerManager.hasActiveFeedbackTimer, false);

      // Wait to ensure callback would have been called
      await Future.delayed(const Duration(milliseconds: 100));

      expect(callbackCalled, false);
    });

    test('multiple scheduleAutoAdvance calls cancel previous timer', () async {
      bool firstCallbackCalled = false;
      bool secondCallbackCalled = false;

      // Schedule first timer
      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () => firstCallbackCalled = true,
      );

      // Schedule second timer (should cancel first)
      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 50),
        () => secondCallbackCalled = true,
      );

      // Wait for second timer to complete
      await Future.delayed(const Duration(milliseconds: 80));

      expect(firstCallbackCalled, false);
      expect(secondCallbackCalled, true);
    });

    test('cancelAllTimers cancels both timer types', () {
      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () {},
      );

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 100),
        () {},
      );

      expect(timerManager.hasActiveAutoAdvanceTimer, true);
      expect(timerManager.hasActiveFeedbackTimer, true);

      timerManager.cancelAllTimers();

      expect(timerManager.hasActiveAutoAdvanceTimer, false);
      expect(timerManager.hasActiveFeedbackTimer, false);
      expect(timerManager.hasActiveTimers, false);
    });

    test('dispose cancels all timers', () {
      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () {},
      );

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 100),
        () {},
      );

      expect(timerManager.hasActiveTimers, true);

      timerManager.dispose();

      expect(timerManager.hasActiveTimers, false);
    });

    test('both timer types can run simultaneously', () {
      timerManager.scheduleAutoAdvance(
        const Duration(milliseconds: 100),
        () {},
      );

      timerManager.scheduleFeedback(
        const Duration(milliseconds: 100),
        () {},
      );

      expect(timerManager.hasActiveAutoAdvanceTimer, true);
      expect(timerManager.hasActiveFeedbackTimer, true);
      expect(timerManager.hasActiveTimers, true);
    });
  });
}