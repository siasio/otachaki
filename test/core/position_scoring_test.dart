import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/position_scoring.dart';
import '../../lib/models/training_position.dart';
import '../../lib/models/position_type.dart';

void main() {
  group('PositionScoring', () {
    late TrainingPosition testPosition;

    setUp(() {
      testPosition = TrainingPosition(
        id: 'test_position',
        boardSize: 19,
        stonesBase64: 'test_stones',
        score: 5.5,
        komi: 6.5,
        movesBase64: 'test_moves',
        numberOfMoves: 10,
        ownershipBase64: 'test_ownership',
        blackTerritory: 45,
        whiteTerritory: 38,
        ultimateStonesBase64: 'test_ultimate_stones',
        additionalWhiteMove: false,
      );
    });

    group('calculateEffectiveScore', () {
      test('returns original score for with filled neutral points mode', () {
        final result = PositionScoring.calculateEffectiveScore(
          testPosition,
          PositionType.withFilledNeutralPoints,
        );
        expect(result, equals(5.5));
      });

      test('returns original score when additional white move is false', () {
        final result = PositionScoring.calculateEffectiveScore(
          testPosition,
          PositionType.beforeFillingNeutralPoints,
        );
        expect(result, equals(5.5));
      });

      test('adjusts score when additional white move is true', () {
        final positionWithAdditionalMove = TrainingPosition(
          id: 'test_position',
          boardSize: 19,
          stonesBase64: 'test_stones',
          score: 5.5,
          komi: 6.5,
          additionalWhiteMove: true,
        );

        final result = PositionScoring.calculateEffectiveScore(
          positionWithAdditionalMove,
          PositionType.beforeFillingNeutralPoints,
        );
        expect(result, equals(4.5)); // 5.5 - 1.0
      });
    });

    group('formatScore', () {
      test('formats integer scores without decimal places', () {
        expect(PositionScoring.formatScore(3.0), equals('3'));
        expect(PositionScoring.formatScore(15.0), equals('15'));
      });

      test('formats non-integer scores with one decimal place', () {
        expect(PositionScoring.formatScore(2.5), equals('2.5'));
        expect(PositionScoring.formatScore(0.5), equals('0.5'));
      });
    });

    group('scoreToResult', () {
      test('returns Draw for zero score', () {
        expect(PositionScoring.scoreToResult(0.0), equals('Draw'));
      });

      test('returns Black win for positive score', () {
        expect(PositionScoring.scoreToResult(3.5), equals('B+3.5'));
        expect(PositionScoring.scoreToResult(2.0), equals('B+2'));
      });

      test('returns White win for negative score', () {
        expect(PositionScoring.scoreToResult(-3.5), equals('W+3.5'));
        expect(PositionScoring.scoreToResult(-2.0), equals('W+2'));
      });
    });

    group('calculateBlackTerritoryScore', () {
      test('calculates correct black territory score', () {
        final result = PositionScoring.calculateBlackTerritoryScore(testPosition);
        // blackTerritory (45) - prisoners are always equal, so no adjustment
        expect(result, equals(45));
      });
    });

    group('calculateWhiteTerritoryScore', () {
      test('calculates correct white territory score without adjustment', () {
        final result = PositionScoring.calculateWhiteTerritoryScore(testPosition);
        // whiteTerritory (38) - prisoners are always equal, so no adjustment + 0 = 38
        expect(result, equals(38));
      });

      test('calculates correct white territory score with additional white move adjustment', () {
        final positionWithAdditionalMove = TrainingPosition(
          id: 'test_position',
          boardSize: 19,
          stonesBase64: 'test_stones',
          score: 5.5,
          komi: 6.5,
          whiteTerritory: 38,
          additionalWhiteMove: true,
        );

        final result = PositionScoring.calculateWhiteTerritoryScore(positionWithAdditionalMove);
        // whiteTerritory (38) - prisoners are always equal, so no adjustment + 1 = 39
        expect(result, equals(39));
      });
    });

    // Note: generateBlackScoringText and generateWhiteScoringText methods were removed from PositionScoring
    // These functionalities have been moved to the TrainingPosition class and ResultTextService

    // Note: generateWhiteScoringText was removed from PositionScoring
    // This functionality has been moved to the TrainingPosition class and ResultTextService
  });
}