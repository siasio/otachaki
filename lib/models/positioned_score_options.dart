import 'dart:math';
import '../utils/score_utils.dart';

class PositionedScoreOption {
  final String scoreText; // e.g., "W+3", "Draw", "B+1"
  final double numericScore; // White positive, black negative, 0 for draw
  final int buttonPosition; // 0=left, 1=middle, 2=right

  const PositionedScoreOption({
    required this.scoreText,
    required this.numericScore,
    required this.buttonPosition,
  });
}

class PositionedScoreOptions {
  final List<PositionedScoreOption> options; // Always 3 options
  final int correctButtonPosition; // 0=left, 1=middle, 2=right

  const PositionedScoreOptions({
    required this.options,
    required this.correctButtonPosition,
  });

  /// Generate three positioned score options based on the actual score and granularity
  /// Left button = White's best score among the 3 options
  /// Right button = Black's best score among the 3 options
  /// Middle button = remaining score
  /// Randomization determines which scenario (and thus which button is correct)
  static PositionedScoreOptions generate({
    required String actualScoreString,
    required int scoreGranularity,
  }) {
    final actualScore = ScoreUtils.parseScore(actualScoreString);
    final random = Random();

    // Generate 3 different scenarios and randomly pick one
    final scenarios = [
      _generateScenario1(actualScore, scoreGranularity),
      _generateScenario2(actualScore, scoreGranularity),
      _generateScenario3(actualScore, scoreGranularity),
    ];

    return scenarios[random.nextInt(scenarios.length)];
  }

  /// Scenario 1: Actual score is in the middle
  /// Scores: [actual+granularity, actual, actual-granularity]
  /// Positions: [Left=White's best, Middle=actual✓, Right=Black's best]
  static PositionedScoreOptions _generateScenario1(double actualScore, int granularity) {
    final leftScore = actualScore + granularity;   // White's best
    final middleScore = actualScore;               // Actual (correct)
    final rightScore = actualScore - granularity;  // Black's best

    final options = [
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(leftScore),
        numericScore: leftScore,
        buttonPosition: 0, // Left
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(middleScore),
        numericScore: middleScore,
        buttonPosition: 1, // Middle
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(rightScore),
        numericScore: rightScore,
        buttonPosition: 2, // Right
      ),
    ];

    return PositionedScoreOptions(
      options: options,
      correctButtonPosition: 1, // Middle button is correct
    );
  }

  /// Scenario 2: Actual score is on the left (White's best)
  /// Scores: [actual, actual-granularity, actual-2*granularity]
  /// Positions: [Left=actual✓, Middle=middle, Right=Black's best]
  static PositionedScoreOptions _generateScenario2(double actualScore, int granularity) {
    final leftScore = actualScore;                     // Actual (correct) - also White's best
    final middleScore = actualScore - granularity;     // Middle
    final rightScore = actualScore - (2 * granularity); // Black's best

    final options = [
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(leftScore),
        numericScore: leftScore,
        buttonPosition: 0, // Left
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(middleScore),
        numericScore: middleScore,
        buttonPosition: 1, // Middle
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(rightScore),
        numericScore: rightScore,
        buttonPosition: 2, // Right
      ),
    ];

    return PositionedScoreOptions(
      options: options,
      correctButtonPosition: 0, // Left button is correct
    );
  }

  /// Scenario 3: Actual score is on the right (Black's best)
  /// Scores: [actual+2*granularity, actual+granularity, actual]
  /// Positions: [Left=White's best, Middle=middle, Right=actual✓]
  static PositionedScoreOptions _generateScenario3(double actualScore, int granularity) {
    final leftScore = actualScore + (2 * granularity); // White's best
    final middleScore = actualScore + granularity;     // Middle
    final rightScore = actualScore;                    // Actual (correct) - also Black's best

    final options = [
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(leftScore),
        numericScore: leftScore,
        buttonPosition: 0, // Left
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(middleScore),
        numericScore: middleScore,
        buttonPosition: 1, // Middle
      ),
      PositionedScoreOption(
        scoreText: ScoreUtils.formatScore(rightScore),
        numericScore: rightScore,
        buttonPosition: 2, // Right
      ),
    ];

    return PositionedScoreOptions(
      options: options,
      correctButtonPosition: 2, // Right button is correct
    );
  }

}