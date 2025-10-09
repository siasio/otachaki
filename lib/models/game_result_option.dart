import 'dart:math';
import 'dataset_type.dart';

enum ButtonType { whiteWins, draw, blackWins }

class GameResultOption {
  final String displayText;
  final ButtonType buttonType;
  final bool isCorrect;
  final double? exactScore;

  const GameResultOption({
    required this.displayText,
    required this.buttonType,
    required this.isCorrect,
    this.exactScore,
  });

  static List<GameResultOption> generateOptions(
    DatasetType datasetType,
    double actualScore,
    String resultString,
  ) {
    switch (datasetType) {
      case DatasetType.midgame19x19Estimation:
        return _generateMidgameOptions(actualScore);

      case DatasetType.final9x9Area:
      case DatasetType.final9x9AreaVars:
      case DatasetType.final19x19Area:
        return _generateFinalOptions(actualScore, true);

      case DatasetType.partialArea:
        return _generateScoreOptions(actualScore, resultString);
    }
  }

  /// Generates options for rough lead prediction mode with custom threshold logic.
  ///
  /// This method creates three options (White, Close, Black) where multiple
  /// options can be correct simultaneously based on the score and thresholds.
  ///
  /// Parameters:
  /// - [actualScore]: The actual game score (negative = White advantage)
  /// - [thresholdGood]: Minimum absolute score difference for a "good" position
  /// - [thresholdClose]: Maximum absolute score difference for a "close" position
  ///
  /// Logic:
  /// - White: correct if score < 0 AND abs(score) > thresholdGood
  /// - Close: correct if abs(score) <= thresholdClose
  /// - Black: correct if score > 0 AND abs(score) > thresholdGood
  ///
  /// Example: score = -3.5, thresholdGood = 2.0, thresholdClose = 5.0
  /// - White: correct (score < 0 and 3.5 > 2.0)
  /// - Close: correct (3.5 <= 5.0)
  /// - Black: incorrect (score is not > 0)
  static List<GameResultOption> generateRoughLeadOptions(
    double actualScore,
    double thresholdGood,
    double thresholdClose,
  ) {
    final absScore = actualScore.abs();

    return [
      GameResultOption(
        displayText: 'White',
        buttonType: ButtonType.whiteWins,
        isCorrect: actualScore < 0 && absScore > thresholdGood,
      ),
      GameResultOption(
        displayText: 'Close',
        buttonType: ButtonType.draw,
        isCorrect: absScore <= thresholdClose,
      ),
      GameResultOption(
        displayText: 'Black',
        buttonType: ButtonType.blackWins,
        isCorrect: actualScore > 0 && absScore > thresholdGood,
      ),
    ];
  }

  static List<GameResultOption> _generateMidgameOptions(double actualScore) {
    return [
      GameResultOption(
        displayText: 'White',
        buttonType: ButtonType.whiteWins,
        isCorrect: actualScore < -1.5,
      ),
      GameResultOption(
        displayText: 'Close',
        buttonType: ButtonType.draw,
        isCorrect: actualScore >= -4.0 && actualScore <= 4.0,
      ),
      GameResultOption(
        displayText: 'Black',
        buttonType: ButtonType.blackWins,
        isCorrect: actualScore > 1.5,
      ),
    ];
  }

  static List<GameResultOption> _generateFinalOptions(
    double actualScore,
    bool isDraw,
  ) {
    return [
      GameResultOption(
        displayText: 'White',
        buttonType: ButtonType.whiteWins,
        isCorrect: actualScore < 0,
      ),
      GameResultOption(
        displayText: isDraw ? 'Draw' : 'Draw',
        buttonType: ButtonType.draw,
        isCorrect: actualScore.abs() < 0.5,
      ),
      GameResultOption(
        displayText: 'Black',
        buttonType: ButtonType.blackWins,
        isCorrect: actualScore > 0,
      ),
    ];
  }

  static List<GameResultOption> _generateScoreOptions(
    double actualScore,
    String resultString,
  ) {
    final absScore = actualScore.abs();
    final isBlackWin = actualScore > 0;
    final random = Random();

    List<double> possibleScores = [];
    if (absScore >= 2.0) {
      possibleScores = [
        absScore - 2.0,
        absScore,
        absScore + 2.0,
      ];
    } else {
      possibleScores = [
        0.5,
        absScore,
        absScore + 2.0,
      ];
    }

    possibleScores.shuffle(random);

    return possibleScores.map((score) {
      final displayScore = score == 0.5 ? score : score;
      final prefix = isBlackWin ? 'B+' : 'W+';
      final displayText = '$prefix${displayScore.toStringAsFixed(1)}';

      final isCorrect = (score == absScore);

      return GameResultOption(
        displayText: displayText,
        buttonType: isBlackWin ? ButtonType.blackWins : ButtonType.whiteWins,
        isCorrect: isCorrect,
        exactScore: isBlackWin ? score : -score,
      );
    }).toList();
  }
}