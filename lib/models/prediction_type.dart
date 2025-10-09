enum PredictionType {
  /// Traditional winner prediction buttons (White/Draw/Black)
  /// Uses simple winner-takes-all logic based on game result.
  winnerPrediction('winner_prediction'),

  /// Exact score prediction buttons (specific scores)
  /// Shows three possible scores with only one correct answer.
  exactScorePrediction('exact_score_prediction'),

  /// Rough lead prediction buttons (White/Close/Black with custom thresholds)
  /// Allows multiple correct answers based on configurable thresholds.
  /// Provides educational feedback showing which answers would be acceptable.
  roughLeadPrediction('rough_lead_prediction');

  const PredictionType(this.value);

  final String value;

  static PredictionType? fromString(String? value) {
    if (value == null) return null;
    for (PredictionType type in PredictionType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  String get displayName {
    switch (this) {
      case PredictionType.winnerPrediction:
        return 'Winner Prediction';
      case PredictionType.exactScorePrediction:
        return 'Exact Score Prediction';
      case PredictionType.roughLeadPrediction:
        return 'Rough Lead Prediction';
    }
  }

  @override
  String toString() => value;
}