import 'package:flutter/foundation.dart';
import '../models/training_state.dart';
import 'training_timer_manager.dart';

/// Manages training state transitions and ensures consistency
/// This is the single source of truth for training state
class TrainingStateManager {
  TrainingState _currentState = TrainingState.loading;
  TrainingStateData _currentData = TrainingStateData.empty();
  final TrainingTimerManager _timerManager = TrainingTimerManager();
  bool _isAnimatingDots = false;

  /// Current training state
  TrainingState get currentState => _currentState;

  /// Current state data
  TrainingStateData get currentData => _currentData;

  /// Timer manager for handling delayed transitions
  TrainingTimerManager get timerManager => _timerManager;

  /// Whether we're currently animating move sequence dots
  bool get isAnimatingDots => _isAnimatingDots;

  /// Set whether we're animating dots
  set isAnimatingDots(bool value) {
    _isAnimatingDots = value;
    onStateChanged?.call();
  }

  /// Callback for state change notifications
  VoidCallback? onStateChanged;

  /// Transition to a new state with optional data
  /// Validates the transition and cancels any pending timers
  void transitionTo(TrainingState newState, [TrainingStateData? data]) {
    // Validate transition
    if (!_currentState.canTransitionTo(newState)) {
      throw StateError(
        'Invalid transition from ${_currentState.displayName} to ${newState.displayName}. '
        'Valid transitions: ${_currentState.validTransitions.map((s) => s.displayName).join(', ')}',
      );
    }

    // Cancel any pending timers when transitioning states
    _timerManager.cancelAllTimers();

    // Update state atomically
    final oldState = _currentState;
    _currentState = newState;
    _currentData = data ?? TrainingStateData.empty();

    // Notify observers
    onStateChanged?.call();

    // Log transition for debugging
    debugPrint('Training state transition: ${oldState.displayName} -> ${newState.displayName}');
  }

  /// Force transition without validation (for error recovery)
  void forceTransitionTo(TrainingState newState, [TrainingStateData? data]) {
    _timerManager.cancelAllTimers();

    final oldState = _currentState;
    _currentState = newState;
    _currentData = data ?? TrainingStateData.empty();

    onStateChanged?.call();

    debugPrint('Training state FORCED transition: ${oldState.displayName} -> ${newState.displayName}');
  }

  /// Check if we can transition to a specific state
  bool canTransitionTo(TrainingState targetState) {
    return _currentState.canTransitionTo(targetState);
  }

  /// Get derived properties from current state
  bool get shouldRunTimer => _currentState.shouldRunTimer && !_isAnimatingDots;
  bool get shouldShowFeedbackOverlay => _currentState.shouldShowFeedbackOverlay;
  bool get hasAnswered => _currentState.hasAnswered;
  bool get isWaitingForNext => _currentState.isWaitingForNext;

  /// Check if answer was correct (from state data)
  bool get isCorrectAnswer => _currentData.isCorrect ?? false;

  /// Check if answer was due to timeout (from state data)
  bool get wasTimeout => _currentData.wasTimeout ?? false;

  /// Get error message if in error state (from state data)
  String? get errorMessage => _currentData.errorMessage;

  /// Schedule a delayed transition to a new state
  /// This is useful for auto-advance scenarios
  void scheduleTransition(TrainingState targetState, Duration delay, [TrainingStateData? data]) {
    _timerManager.scheduleAutoAdvance(delay, () {
      if (canTransitionTo(targetState)) {
        transitionTo(targetState, data);
      }
    });
  }

  /// Cancel any scheduled transitions
  void cancelScheduledTransitions() {
    _timerManager.cancelAllTimers();
  }

  /// Reset to initial state
  void reset() {
    _timerManager.cancelAllTimers();
    _currentState = TrainingState.loading;
    _currentData = TrainingStateData.empty();
    _isAnimatingDots = false;
    onStateChanged?.call();
  }

  /// Dispose and clean up resources
  void dispose() {
    _timerManager.dispose();
    onStateChanged = null;
  }
}