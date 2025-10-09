/// Utilities for parsing and formatting Go game scores
///
/// Consistent convention used throughout:
/// - Positive values indicate White advantage/wins
/// - Negative values indicate Black advantage/wins
/// - Zero indicates a draw
class ScoreUtils {
  /// Parse a score string like "W+3.5", "B+2", "Draw" to numeric value
  /// Returns positive for White wins, negative for Black wins, 0 for draw
  ///
  /// Examples:
  /// - "W+7.5" -> 7.5
  /// - "B+2" -> -2.0
  /// - "Draw" -> 0.0
  /// - "W+R" -> 100.0 (large value for resignation)
  /// - "B+R" -> -100.0
  static double parseScore(String scoreString) {
    if (scoreString.toLowerCase() == 'draw') {
      return 0.0;
    }

    // Handle resignation
    if (scoreString.endsWith('+R')) {
      return scoreString.startsWith('W') ? 100.0 : -100.0;
    }

    if (scoreString.startsWith('W+')) {
      return double.tryParse(scoreString.substring(2)) ?? 0.0;
    }

    if (scoreString.startsWith('B+')) {
      return -(double.tryParse(scoreString.substring(2)) ?? 0.0);
    }

    // Fallback for other formats
    return 0.0;
  }

  /// Format a numeric score back to string representation
  /// Expects positive for White wins, negative for Black wins
  ///
  /// Examples:
  /// - 7.5 -> "W+7.5"
  /// - -2.0 -> "B+2"
  /// - 0.0 -> "Draw"
  static String formatScore(double score) {
    if (score == 0.0) {
      return 'Draw';
    }

    if (score > 0) {
      // White wins
      if (score >= 100.0) {
        return 'W+R'; // Resignation
      }
      if (score == score.toInt()) {
        return 'W+${score.toInt()}';
      } else {
        return 'W+${score.toStringAsFixed(1)}';
      }
    } else {
      // Black wins
      final positiveScore = -score;
      if (positiveScore >= 100.0) {
        return 'B+R'; // Resignation
      }
      if (positiveScore == positiveScore.toInt()) {
        return 'B+${positiveScore.toInt()}';
      } else {
        return 'B+${positiveScore.toStringAsFixed(1)}';
      }
    }
  }

  /// Convert from ScoringConfig convention (negative for White) to our convention (positive for White)
  /// This is a temporary helper to maintain compatibility
  static double fromScoringConfigConvention(double scoringConfigValue) {
    return -scoringConfigValue;
  }

  /// Convert to ScoringConfig convention (negative for White) from our convention (positive for White)
  /// This is a temporary helper to maintain compatibility
  static double toScoringConfigConvention(double ourValue) {
    return -ourValue;
  }
}