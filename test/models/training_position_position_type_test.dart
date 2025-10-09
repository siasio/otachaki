import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/training_position.dart';
import 'package:countingapp/models/position_type.dart';

void main() {
  group('TrainingPosition Position Type Methods', () {
    late TrainingPosition testPosition;

    setUp(() {
      testPosition = TrainingPosition(
        id: 'test_position',
        boardSize: 9,
        stonesBase64: 'dGVzdF9zdG9uZXM=', // base64 for "test_stones"
        score: 3.5,
        blackCaptured: 2,
        whiteCaptured: 1,
        komi: 5.5,
        movesBase64: 'dGVzdF9tb3Zlcw==', // base64 for "test_moves"
        numberOfMoves: 8,
        ownershipBase64: 'dGVzdF9vd25lcnNoaXA=', // base64 for "test_ownership"
        blackTerritory: 25,
        whiteTerritory: 20,
        ultimateStonesBase64: 'dGVzdF91bHRpbWF0ZV9zdG9uZXM=', // base64 for "test_ultimate_stones"
        ultimateBlackCaptured: 4,
        ultimateWhiteCaptured: 3,
        additionalWhiteMove: false,
      );
    });

    group('supportsPositionTypes', () {
      test('returns true when ultimate stones data is available', () {
        expect(testPosition.supportsPositionTypes, isTrue);
      });

      test('returns false when ultimate stones data is not available', () {
        final positionWithoutUltimate = TrainingPosition(
          id: 'test_position',
          boardSize: 9,
          stonesBase64: 'dGVzdF9zdG9uZXM=',
          score: 3.5,
          blackCaptured: 2,
          whiteCaptured: 1,
          komi: 5.5,
          // ultimateStonesBase64 is null
        );
        expect(positionWithoutUltimate.supportsPositionTypes, isFalse);
      });
    });

    group('getEffectiveScore', () {
      test('returns original score for with filled neutral points mode', () {
        final result = testPosition.getEffectiveScore(PositionType.withFilledNeutralPoints);
        expect(result, equals(3.5));
      });

      test('returns adjusted score for before filling neutral points mode with additional white move', () {
        final positionWithAdditionalMove = TrainingPosition(
          id: 'test_position',
          boardSize: 9,
          stonesBase64: 'dGVzdF9zdG9uZXM=',
          score: 3.5,
          blackCaptured: 2,
          whiteCaptured: 1,
          komi: 5.5,
          additionalWhiteMove: true,
        );

        final result = positionWithAdditionalMove.getEffectiveScore(
          PositionType.beforeFillingNeutralPoints,
        );
        expect(result, equals(2.5)); // 3.5 - 1.0
      });
    });

    group('getResult', () {
      test('returns correct result format for with filled neutral points mode', () {
        final result = testPosition.getResult(PositionType.withFilledNeutralPoints);
        expect(result, equals('B+3.5'));
      });

      test('returns correct result format for before filling neutral points mode', () {
        final result = testPosition.getResult(PositionType.beforeFillingNeutralPoints);
        expect(result, equals('B+3.5'));
      });

      test('handles draw result correctly', () {
        final drawPosition = TrainingPosition(
          id: 'draw_position',
          boardSize: 9,
          stonesBase64: 'dGVzdF9zdG9uZXM=',
          score: 0.0,
          blackCaptured: 2,
          whiteCaptured: 1,
          komi: 5.5,
        );

        final result = drawPosition.getResult(PositionType.withFilledNeutralPoints);
        expect(result, equals('Draw'));
      });
    });

    group('shouldShowGameInfo', () {
      test('returns false for with filled neutral points mode', () {
        final result = testPosition.shouldShowGameInfo(PositionType.withFilledNeutralPoints);
        expect(result, isFalse);
      });

      test('returns true for before filling neutral points mode', () {
        final result = testPosition.shouldShowGameInfo(PositionType.beforeFillingNeutralPoints);
        expect(result, isTrue);
      });
    });

    group('shouldShowMoveSequenceSelection', () {
      test('returns false for with filled neutral points mode', () {
        final result = testPosition.shouldShowMoveSequenceSelection(PositionType.withFilledNeutralPoints);
        expect(result, isFalse);
      });

      test('returns true for before filling neutral points mode', () {
        final result = testPosition.shouldShowMoveSequenceSelection(PositionType.beforeFillingNeutralPoints);
        expect(result, isTrue);
      });
    });

    group('getBlackScoringText', () {
      test('generates correct text for with filled neutral points mode', () {
        final result = testPosition.getBlackScoringText(PositionType.withFilledNeutralPoints);
        // blackTerritory (25) + whiteCaptured (1) = 26
        expect(result, equals('25+1=26'));
      });

      test('generates correct text for before filling neutral points mode', () {
        final result = testPosition.getBlackScoringText(PositionType.beforeFillingNeutralPoints);
        // territory score: blackTerritory (25) + (ultimateWhiteCaptured (3) - whiteCaptured (1)) = 25 + 2 = 27
        // total: 27 + whiteCaptured (1) = 28
        expect(result, equals('27+1=28'));
      });
    });

    group('getWhiteScoringText', () {
      test('generates correct text for with filled neutral points mode', () {
        final result = testPosition.getWhiteScoringText(PositionType.withFilledNeutralPoints);
        // whiteTerritory (20) + blackCaptured (2) + komi (5.5) = 27.5
        expect(result, equals('20+2+5.5=27.5'));
      });

      test('generates correct text for before filling neutral points mode', () {
        final result = testPosition.getWhiteScoringText(PositionType.beforeFillingNeutralPoints);
        // territory score: whiteTerritory (20) + (ultimateBlackCaptured (4) - blackCaptured (2)) = 20 + 2 = 22
        // total: 22 + blackCaptured (2) + komi (5.5) = 29.5
        expect(result, equals('22+2+5.5=29.5'));
      });
    });
  });
}