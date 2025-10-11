import '../models/training_position.dart';
import '../models/position_type.dart';
import '../models/dataset_type.dart';
import 'position_scoring.dart';
import 'game_result_parser.dart';

/// Centralized service for generating all score and result text displays
class ResultTextService {
  /// Format a number to not show decimals if it's an integer
  static String formatNumber(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  /// Format threshold values (used in game result options)
  static String formatThreshold(double value) {
    return formatNumber(value);
  }

  /// Generate Black's scoring text for feedback display
  static String generateBlackText(TrainingPosition position, PositionType positionType, {DatasetType? datasetType}) {
    // Special handling for midgame datasets
    if (datasetType == DatasetType.midgame19x19) {
      final effectiveScore = PositionScoring.calculateEffectiveScore(position, positionType);
      if (effectiveScore == 0.0) {
        return 'Even game';
      } else if (effectiveScore > 0) {
        // Black is ahead
        return PositionScoring.scoreToResult(effectiveScore);
      } else {
        // White is ahead, Black is behind
        return 'Black\'s behind';
      }
    }

    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        final territory = position.blackTerritory ?? 0;
        return 'Black: ${formatNumber(territory.toDouble())}';

      case PositionType.beforeFillingNeutralPoints:
        final blackTerritory = position.blackTerritory ?? 0;
        return 'Black: ${formatNumber(blackTerritory.toDouble())}';
    }
  }

  /// Generate White's scoring text for feedback display
  static String generateWhiteText(TrainingPosition position, PositionType positionType, {DatasetType? datasetType}) {
    // Special handling for midgame datasets
    if (datasetType == DatasetType.midgame19x19) {
      final effectiveScore = PositionScoring.calculateEffectiveScore(position, positionType);
      if (effectiveScore == 0.0) {
        return 'Even game';
      } else if (effectiveScore < 0) {
        // White is ahead
        return PositionScoring.scoreToResult(effectiveScore);
      } else {
        // Black is ahead, White is behind
        return 'White\'s behind';
      }
    }

    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        final territory = position.whiteTerritory ?? 0;
        final komi = position.komi;
        final total = territory + komi;
        return 'White: ${formatNumber(territory.toDouble())} + ${formatNumber(komi)} = ${formatNumber(total)}';

      case PositionType.beforeFillingNeutralPoints:
        final whiteTerritory = position.whiteTerritory ?? 0;
        final komi = position.komi;

        // Apply additional white move adjustment if needed
        int adjustment = 0;
        if (position.additionalWhiteMove == true) {
          adjustment = 1;
        }

        if (adjustment > 0) {
          final total = whiteTerritory + adjustment + komi;
          return 'White: ${formatNumber(whiteTerritory.toDouble())} + ${formatNumber(adjustment.toDouble())} + ${formatNumber(komi)} = ${formatNumber(total)}';
        } else {
          final total = whiteTerritory + komi;
          return 'White: ${formatNumber(whiteTerritory.toDouble())} + ${formatNumber(komi)} = ${formatNumber(total)}';
        }
    }
  }

  /// Generate complete score info for score display buttons
  static ScoreInfo generateScoreInfo(
    String result, {
    TrainingPosition? trainingPosition,
    PositionType? positionType,
    DatasetType? datasetType,
    int? blackTerritory,
    int? whiteTerritory,
    double? komi,
  }) {
    // If we have complete position and type data, use the proper scoring text
    if (trainingPosition != null && positionType != null) {
      final blackText = generateBlackText(trainingPosition, positionType, datasetType: datasetType);
      final whiteText = generateWhiteText(trainingPosition, positionType, datasetType: datasetType);
      return ScoreInfo(whiteScore: whiteText, blackScore: blackText);
    }

    // Fallback: if we have territory data, use the legacy format
    if (blackTerritory != null && whiteTerritory != null) {
      final blackText = "Black's territory: $blackTerritory points";

      String whiteText;
      if (komi != null) {
        // Check if komi is a whole number to avoid .0 display
        final komiDisplay = formatNumber(komi);
        final whiteTotal = whiteTerritory + komi;
        final whiteTotalDisplay = formatNumber(whiteTotal);
        whiteText = "White's territory: $whiteTerritory + $komiDisplay = $whiteTotalDisplay points";
      } else {
        whiteText = "White's territory: $whiteTerritory points";
      }

      return ScoreInfo(whiteScore: whiteText, blackScore: blackText);
    }

    // Fallback to old format if no territory data is available
    if (result.isEmpty) {
      return ScoreInfo(whiteScore: 'W: ?', blackScore: 'B: ?');
    }

    final winner = GameResultParser.parseWinner(result);

    if (winner == 'Draw') {
      return ScoreInfo(whiteScore: 'Draw', blackScore: 'Draw');
    }

    if (result.startsWith('W+')) {
      final points = result.substring(2);
      return ScoreInfo(
        whiteScore: 'W+$points',
        blackScore: 'B loses',
      );
    } else if (result.startsWith('B+')) {
      final points = result.substring(2);
      return ScoreInfo(
        whiteScore: 'W loses',
        blackScore: 'B+$points',
      );
    }

    return ScoreInfo(whiteScore: 'W: ?', blackScore: 'B: ?');
  }
}

/// Information about score display for both sides
class ScoreInfo {
  final String whiteScore;
  final String blackScore;

  ScoreInfo({
    required this.whiteScore,
    required this.blackScore,
  });
}