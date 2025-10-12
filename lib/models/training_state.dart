/// Defines the current state of the training session
enum TrainingState {
  /// Loading position data and initializing
  loading,

  /// User is actively solving the problem (timer may be running)
  solving,

  /// Showing feedback overlay (correct/incorrect mark with optional pause button)
  feedback,

  /// Showing review mode (score tiles + NEXT button)
  review,

  /// User paused during feedback, staying in review mode
  paused,
}

/// Data associated with training state transitions
class TrainingStateData {
  final bool? isCorrect;
  final bool? wasTimeout;
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  const TrainingStateData({
    this.isCorrect,
    this.wasTimeout,
    this.errorMessage,
    this.additionalData,
  });

  /// Creates state data for a user answer
  factory TrainingStateData.answer({
    required bool isCorrect,
    bool wasTimeout = false,
  }) {
    return TrainingStateData(
      isCorrect: isCorrect,
      wasTimeout: wasTimeout,
    );
  }

  /// Creates state data for an error condition
  factory TrainingStateData.error(String message) {
    return TrainingStateData(
      errorMessage: message,
    );
  }

  /// Creates empty state data
  factory TrainingStateData.empty() {
    return const TrainingStateData();
  }
}

/// Extension methods for TrainingState
extension TrainingStateExtension on TrainingState {
  /// Human-readable name for debugging
  String get displayName {
    switch (this) {
      case TrainingState.loading:
        return 'Loading';
      case TrainingState.solving:
        return 'Solving';
      case TrainingState.feedback:
        return 'Feedback';
      case TrainingState.review:
        return 'Review';
      case TrainingState.paused:
        return 'Paused';
    }
  }

  /// Whether the timer should be running in this state
  bool get shouldRunTimer {
    switch (this) {
      case TrainingState.solving:
        return true;
      case TrainingState.loading:
      case TrainingState.feedback:
      case TrainingState.review:
      case TrainingState.paused:
        return false;
    }
  }

  /// Whether feedback overlay should be shown
  bool get shouldShowFeedbackOverlay {
    switch (this) {
      case TrainingState.feedback:
        return true;
      case TrainingState.loading:
      case TrainingState.solving:
      case TrainingState.review:
      case TrainingState.paused:
        return false;
    }
  }

  /// Whether user has answered (affects button state)
  bool get hasAnswered {
    switch (this) {
      case TrainingState.feedback:
      case TrainingState.review:
      case TrainingState.paused:
        return true;
      case TrainingState.loading:
      case TrainingState.solving:
        return false;
    }
  }

  /// Whether waiting for next button press
  bool get isWaitingForNext {
    switch (this) {
      case TrainingState.review:
      case TrainingState.paused:
        return true;
      case TrainingState.loading:
      case TrainingState.solving:
      case TrainingState.feedback:
        return false;
    }
  }

  /// Valid state transitions from this state
  Set<TrainingState> get validTransitions {
    switch (this) {
      case TrainingState.loading:
        return {TrainingState.solving, TrainingState.loading}; // Allow loading -> loading
      case TrainingState.solving:
        return {TrainingState.feedback, TrainingState.review, TrainingState.loading};
      case TrainingState.feedback:
        return {TrainingState.review, TrainingState.paused, TrainingState.loading};
      case TrainingState.review:
        return {TrainingState.loading};
      case TrainingState.paused:
        return {TrainingState.loading};
    }
  }

  /// Check if transition to target state is valid
  bool canTransitionTo(TrainingState target) {
    return validTransitions.contains(target);
  }
}