import '../models/training_position.dart';
import '../models/position_type.dart';
import '../models/dataset_type.dart';

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
    // REMOVED: Prisoner logic - prisoners are always equal, so captured stone difference is 0
    // final ultimateWhiteCaptured = position.ultimateWhiteCaptured ?? 0;
    // final whiteCaptured = position.whiteCaptured;
    // return blackTerritory + (ultimateWhiteCaptured - whiteCaptured);
    return blackTerritory;
  }

  /// Calculate White's territory score for "before filling" mode
  static int calculateWhiteTerritoryScore(TrainingPosition position) {
    final whiteTerritory = position.whiteTerritory ?? 0;
    // REMOVED: Prisoner logic - prisoners are always equal, so captured stone difference is 0
    // final ultimateBlackCaptured = position.ultimateBlackCaptured ?? 0;
    // final blackCaptured = position.blackCaptured;

    // Apply additional white move adjustment if needed
    int adjustment = 0;
    if (position.additionalWhiteMove == true) {
      adjustment = 1;
    }

    // return whiteTerritory + (ultimateBlackCaptured - blackCaptured) + adjustment;
    return whiteTerritory + adjustment;
  }

  /// Generate Black's scoring text for feedback display
  static String generateBlackScoringText(TrainingPosition position, PositionType positionType, {DatasetType? datasetType}) {
    // Special handling for midgame datasets
    if (datasetType == DatasetType.midgame19x19) {
      final effectiveScore = calculateEffectiveScore(position, positionType);
      if (effectiveScore == 0.0) {
        return 'Even game';
      } else if (effectiveScore > 0) {
        // Black is ahead
        return scoreToResult(effectiveScore);
      } else {
        // White is ahead, Black is behind
        return 'Black\'s behind';
      }
    }

    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        // "Black: {blackTerritory}"
        final territory = position.blackTerritory ?? 0;
        return 'Black: ${formatScore(territory.toDouble())}';

      case PositionType.beforeFillingNeutralPoints:
        // REMOVED: Prisoner logic - prisoners are always equal, so no need to show captured stones
        // "Black: {blackTerritory}"
        final blackTerritory = position.blackTerritory ?? 0;
        // final whiteCaptured = position.whiteCaptured;
        // final ultimateWhiteCaptured = position.ultimateWhiteCaptured ?? whiteCaptured;
        // final territoryPart = blackTerritory + (ultimateWhiteCaptured - whiteCaptured);
        // final total = blackTerritory + ultimateWhiteCaptured;
        // return 'Black: ${formatScore(territoryPart.toDouble())} + ${formatScore(whiteCaptured.toDouble())} = ${formatScore(total.toDouble())}';
        return 'Black: ${formatScore(blackTerritory.toDouble())}';
    }
  }

  /// Generate White's scoring text for feedback display
  static String generateWhiteScoringText(TrainingPosition position, PositionType positionType, {DatasetType? datasetType}) {
    // Special handling for midgame datasets
    if (datasetType == DatasetType.midgame19x19) {
      final effectiveScore = calculateEffectiveScore(position, positionType);
      if (effectiveScore == 0.0) {
        return 'Even game';
      } else if (effectiveScore < 0) {
        // White is ahead
        return scoreToResult(effectiveScore);
      } else {
        // Black is ahead, White is behind
        return 'White\'s behind';
      }
    }

    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        // "White: {whiteTerritory} + {komi} = {whiteTerritory + komi}"
        final territory = position.whiteTerritory ?? 0;
        final komi = position.komi;
        final total = territory + komi;

        return 'White: ${formatScore(territory.toDouble())} + ${formatScore(komi)} = ${formatScore(total)}';

      case PositionType.beforeFillingNeutralPoints:
        // REMOVED: Prisoner logic - prisoners are always equal, so no need to show captured stones
        final whiteTerritory = position.whiteTerritory ?? 0;
        // final blackCaptured = position.blackCaptured;
        // final ultimateBlackCaptured = position.ultimateBlackCaptured ?? blackCaptured;
        final komi = position.komi;

        // Apply additional white move adjustment if needed
        int adjustment = 0;
        if (position.additionalWhiteMove == true) {
          adjustment = 1;
        }

        // final territoryPart = whiteTerritory + (ultimateBlackCaptured - blackCaptured) + adjustment;
        // final total = whiteTerritory + ultimateBlackCaptured + adjustment + komi;
        // return 'White: ${formatScore(territoryPart.toDouble())} + ${formatScore(blackCaptured.toDouble())} + ${formatScore(komi)} = ${formatScore(total)}';

        if (adjustment > 0) {
          final total = whiteTerritory + adjustment + komi;
          return 'White: ${formatScore(whiteTerritory.toDouble())} + ${formatScore(adjustment.toDouble())} + ${formatScore(komi)} = ${formatScore(total)}';
        } else {
          final total = whiteTerritory + komi;
          return 'White: ${formatScore(whiteTerritory.toDouble())} + ${formatScore(komi)} = ${formatScore(total)}';
        }
    }
  }
}