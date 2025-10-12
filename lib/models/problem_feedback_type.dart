/// Types of feedback to show for individual problems after answering
enum ProblemFeedbackType {
  /// Show only the result (e.g., "W+5.5", "B+3")
  result('result'),

  /// Show result with time taken for this problem (e.g., "W+5.5\n2.3s")
  resultWithTime('result_with_time'),

  /// Show result with speed for this problem (e.g., "W+5.5\n3.2 pts/s")
  resultWithSpeed('result_with_speed');

  const ProblemFeedbackType(this.value);

  final String value;

  /// Get ProblemFeedbackType from string value
  static ProblemFeedbackType? fromString(String? value) {
    switch (value) {
      case 'result':
        return ProblemFeedbackType.result;
      case 'result_with_time':
        return ProblemFeedbackType.resultWithTime;
      case 'result_with_speed':
        return ProblemFeedbackType.resultWithSpeed;
      default:
        return null;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case ProblemFeedbackType.result:
        return 'Result';
      case ProblemFeedbackType.resultWithTime:
        return 'Result + Time';
      case ProblemFeedbackType.resultWithSpeed:
        return 'Result + Speed';
    }
  }

  /// Check if this feedback type is available for the given dataset type
  static List<ProblemFeedbackType> getAvailableTypes(String datasetTypeValue) {
    // Midgame datasets don't have speed calculation (no territory counting)
    if (datasetTypeValue == 'midgame19x19') {
      return [ProblemFeedbackType.result, ProblemFeedbackType.resultWithTime];
    }

    // All other datasets support all feedback types
    return ProblemFeedbackType.values;
  }
}