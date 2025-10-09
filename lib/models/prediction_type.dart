enum PredictionType {
  /// Traditional winner prediction buttons (White/Draw/Black)
  winnerPrediction('winner_prediction'),

  /// Exact score prediction buttons (specific scores)
  exactScorePrediction('exact_score_prediction');

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
    }
  }

  @override
  String toString() => value;
}