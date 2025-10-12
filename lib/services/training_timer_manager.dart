import 'dart:async';
import 'package:flutter/foundation.dart';

/// Centralized timer management for training sessions
/// Prevents race conditions and ensures proper cleanup
class TrainingTimerManager {
  Timer? _autoAdvanceTimer;
  Timer? _feedbackTimer;

  /// Whether an auto-advance timer is currently active
  bool get hasActiveAutoAdvanceTimer => _autoAdvanceTimer?.isActive ?? false;

  /// Whether a feedback timer is currently active
  bool get hasActiveFeedbackTimer => _feedbackTimer?.isActive ?? false;

  /// Whether any timer is currently active
  bool get hasActiveTimers => hasActiveAutoAdvanceTimer || hasActiveFeedbackTimer;

  /// Schedule an auto-advance timer that will call [onComplete] after [delay]
  /// Cancels any existing auto-advance timer first
  void scheduleAutoAdvance(Duration delay, VoidCallback onComplete) {
    cancelAutoAdvance();
    _autoAdvanceTimer = Timer(delay, () {
      _autoAdvanceTimer = null;
      onComplete();
    });
  }

  /// Schedule a feedback timer that will call [onComplete] after [delay]
  /// Cancels any existing feedback timer first
  void scheduleFeedback(Duration delay, VoidCallback onComplete) {
    cancelFeedback();
    _feedbackTimer = Timer(delay, () {
      _feedbackTimer = null;
      onComplete();
    });
  }

  /// Cancel the auto-advance timer if it's running
  void cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  /// Cancel the feedback timer if it's running
  void cancelFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
  }

  /// Cancel all active timers
  void cancelAllTimers() {
    cancelAutoAdvance();
    cancelFeedback();
  }

  /// Dispose of all timers and clean up resources
  void dispose() {
    cancelAllTimers();
  }
}