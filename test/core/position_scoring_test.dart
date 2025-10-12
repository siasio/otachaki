import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/core/position_scoring.dart';
import 'package:otachaki/models/training_position.dart';
import 'package:otachaki/models/position_type.dart';

void main() {
  group('PositionScoring', () {
    late TrainingPosition testPosition;

    setUp(() {
      testPosition = TrainingPosition(
        id: 'test_position',
        boardSize: 19,
        stonesBase64: 'test_stones',
        score: 5.5,
        blackCaptured: 3,
        whiteCaptured: 2,
        komi: 6.5,
        movesBase64: 'test_moves',
        numberOfMoves: 10,
        ownershipBase64: 'test_ownership',
        blackTerritory: 45,
        whiteTerritory: 38,
        ultimateStonesBase64: 'test_ultimate_stones',
        ultimateBlackCaptured: 5,
        ultimateWhiteCaptured: 4,
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
          blackCaptured: 3,
          whiteCaptured: 2,
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
        // blackTerritory (45) + (ultimateWhiteCaptured (4) - whiteCaptured (2)) = 45 + 2 = 47
        expect(result, equals(47));
      });
    });

    group('calculateWhiteTerritoryScore', () {
      test('calculates correct white territory score without adjustment', () {
        final result = PositionScoring.calculateWhiteTerritoryScore(testPosition);
        // whiteTerritory (38) + (ultimateBlackCaptured (5) - blackCaptured (3)) + adjustment (0) = 38 + 2 + 0 = 40
        expect(result, equals(40));
      });

      test('calculates correct white territory score with additional white move adjustment', () {
        final positionWithAdditionalMove = TrainingPosition(
          id: 'test_position',
          boardSize: 19,
          stonesBase64: 'test_stones',
          score: 5.5,
          blackCaptured: 3,
          whiteCaptured: 2,
          komi: 6.5,
          whiteTerritory: 38,
          ultimateBlackCaptured: 5,
          additionalWhiteMove: true,
        );

        final result = PositionScoring.calculateWhiteTerritoryScore(positionWithAdditionalMove);
        // whiteTerritory (38) + (ultimateBlackCaptured (5) - blackCaptured (3)) + adjustment (1) = 38 + 2 + 1 = 41
        expect(result, equals(41));
      });
    });

    group('generateBlackScoringText', () {
      test('generates correct text for with filled neutral points mode', () {
        final result = PositionScoring.generateBlackScoringText(
          testPosition,
          PositionType.withFilledNeutralPoints,
        );
        // blackTerritory (45) + whiteCaptured (2) = 47
        expect(result, equals('45+2=47'));
      });

      test('generates correct text for before filling neutral points mode', () {
        final result = PositionScoring.generateBlackScoringText(
          testPosition,
          PositionType.beforeFillingNeutralPoints,
        );
        // territory score (47) + whiteCaptured (2) = 49
        expect(result, equals('47+2=49'));
      });
    });

    group('generateWhiteScoringText', () {
      test('generates correct text for with filled neutral points mode', () {
        final result = PositionScoring.generateWhiteScoringText(
          testPosition,
          PositionType.withFilledNeutralPoints,
        );
        // whiteTerritory (38) + blackCaptured (3) + komi (6.5) = 47.5
        expect(result, equals('38+3+6.5=47.5'));
      });

      test('generates correct text for before filling neutral points mode', () {
        final result = PositionScoring.generateWhiteScoringText(
          testPosition,
          PositionType.beforeFillingNeutralPoints,
        );
        // territory score (40) + blackCaptured (3) + komi (6.5) = 49.5
        expect(result, equals('40+3+6.5=49.5'));
      });
    });
  });
}