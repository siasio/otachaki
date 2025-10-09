import '../models/training_position.dart';
import '../models/position_type.dart';

/// Helper class for calculating scores and results based on position type
class PositionScoring {
  /// Calculate the effective score for correctness checking
  static double calculateEffectiveScore(TrainingPosition position, PositionType positionType) {
    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        // Use score directly
        return position.score;

      case PositionType.beforeFillingNeutralPoints:
        // Apply additional white move adjustment if needed
        if (position.additionalWhiteMove == true) {
          return position.score - 1.0;
        }
        return position.score;
    }
  }

  /// Format score for display (no decimal places for integers, one decimal place for non-integers)
  static String formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    } else {
      return score.toStringAsFixed(1);
    }
  }

  /// Convert effective score to result string
  static String scoreToResult(double effectiveScore) {
    if (effectiveScore == 0) {
      return 'Draw';
    } else if (effectiveScore > 0) {
      return 'B+${formatScore(effectiveScore)}';
    } else {
      return 'W+${formatScore(-effectiveScore)}';
    }
  }

  /// Calculate Black's territory score for "before filling" mode
  static int calculateBlackTerritoryScore(TrainingPosition position) {
    final blackTerritory = position.blackTerritory ?? 0;
    final ultimateWhiteCaptured = position.ultimateWhiteCaptured ?? 0;
    final whiteCaptured = position.whiteCaptured;

    return blackTerritory + (ultimateWhiteCaptured - whiteCaptured);
  }

  /// Calculate White's territory score for "before filling" mode
  static int calculateWhiteTerritoryScore(TrainingPosition position) {
    final whiteTerritory = position.whiteTerritory ?? 0;
    final ultimateBlackCaptured = position.ultimateBlackCaptured ?? 0;
    final blackCaptured = position.blackCaptured;

    // Apply additional white move adjustment if needed
    int adjustment = 0;
    if (position.additionalWhiteMove == true) {
      adjustment = 1;
    }

    return whiteTerritory + (ultimateBlackCaptured - blackCaptured) + adjustment;
  }

  /// Generate Black's scoring text for feedback display
  static String generateBlackScoringText(TrainingPosition position, PositionType positionType) {
    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        // Simple: just show territory + captured
        final territory = position.blackTerritory ?? 0;
        final captured = position.whiteCaptured;
        final total = territory + captured;
        return '$territory+$captured=$total';

      case PositionType.beforeFillingNeutralPoints:
        // Complex: territory points on board + captured
        final territoryScore = calculateBlackTerritoryScore(position);
        final captured = position.whiteCaptured;
        final total = territoryScore + captured;
        return '$territoryScore+$captured=$total';
    }
  }

  /// Generate White's scoring text for feedback display
  static String generateWhiteScoringText(TrainingPosition position, PositionType positionType) {
    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        // Simple: territory + captured + komi
        final territory = position.whiteTerritory ?? 0;
        final captured = position.blackCaptured;
        final komi = position.komi;
        final total = territory + captured + komi;

        // Format komi for display
        final komiStr = formatScore(komi);
        final totalStr = formatScore(total);

        return '$territory+$captured+$komiStr=$totalStr';

      case PositionType.beforeFillingNeutralPoints:
        // Complex: territory points on board + captured + komi
        final territoryScore = calculateWhiteTerritoryScore(position);
        final captured = position.blackCaptured;
        final komi = position.komi;
        final total = territoryScore + captured + komi;

        // Format komi for display
        final komiStr = formatScore(komi);
        final totalStr = formatScore(total);

        return '$territoryScore+$captured+$komiStr=$totalStr';
    }
  }
}