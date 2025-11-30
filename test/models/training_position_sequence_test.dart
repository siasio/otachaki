import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/training_position.dart';

void main() {
  group('TrainingPosition Sequence Length', () {
    test('hasEnoughMovesForSequence should validate minimum moves', () {
      // Position with 10 moves
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 10,
      );

      expect(position.hasEnoughMovesForSequence(0), isTrue);
      expect(position.hasEnoughMovesForSequence(5), isTrue);
      expect(position.hasEnoughMovesForSequence(9), isTrue); // 10 >= 9+1
      expect(position.hasEnoughMovesForSequence(10), isFalse); // 10 < 10+1
      expect(position.hasEnoughMovesForSequence(15), isFalse);
    });

    test('getActualSequenceLength should return 0 when disabled', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 50,
      );

      expect(position.getActualSequenceLength(0, 0), 0);
    });

    test('getActualSequenceLength should return min when min equals max', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 50,
      );

      expect(position.getActualSequenceLength(5, 5), 5);
      expect(position.getActualSequenceLength(10, 10), 10);
    });

    test('getActualSequenceLength should return min when max is 0', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 50,
      );

      expect(position.getActualSequenceLength(5, 0), 5);
      expect(position.getActualSequenceLength(10, 0), 10);
    });

    test('getActualSequenceLength should cap at maxSequenceLength for range', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 100, // Plenty of moves
      );

      // With 100 moves available (99 can be shown since we need 1 for marker)
      // Should cap at maxSequenceLength
      expect(position.getActualSequenceLength(25, 30), 30);
      expect(position.getActualSequenceLength(10, 20), 20);
    });

    test('getActualSequenceLength should cap at available moves when limited', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 35, // Limited moves
      );

      // With 35 moves, 34 can be shown (35 - 1 for marker)
      // Should cap at available moves when maxSequenceLength > available
      expect(position.getActualSequenceLength(25, 50), 34); // Cap at 34
      expect(position.getActualSequenceLength(30, 40), 34); // Cap at 34
    });

    test('getActualSequenceLength should use maxSequenceLength when within available', () {
      const position = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 35,
      );

      // With 35 moves, 34 available
      // Should use maxSequenceLength when it's less than available
      expect(position.getActualSequenceLength(25, 30), 30); // 30 < 34
      expect(position.getActualSequenceLength(20, 33), 33); // 33 < 34
    });

    test('getActualSequenceLength edge cases', () {
      const positionFewMoves = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 5,
      );

      // With only 5 moves, 4 available for sequence
      expect(positionFewMoves.getActualSequenceLength(0, 10), 4);
      expect(positionFewMoves.getActualSequenceLength(3, 8), 4);

      const positionManyMoves = TrainingPosition(
        id: 'test',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 200,
      );

      // With 200 moves, maxSequenceLength should be limiting factor
      expect(positionManyMoves.getActualSequenceLength(25, 30), 30);
      expect(positionManyMoves.getActualSequenceLength(40, 50), 50);
    });

    test('realistic sequence range scenario: 25-30 moves', () {
      // Position with 40 moves total
      const position40 = TrainingPosition(
        id: 'test1',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 40,
      );

      // Should show 30 moves (capped at maxSequenceLength)
      expect(position40.getActualSequenceLength(25, 30), 30);

      // Position with 28 moves total
      const position28 = TrainingPosition(
        id: 'test2',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 28,
      );

      // Should show 27 moves (capped at available: 28-1)
      expect(position28.getActualSequenceLength(25, 30), 27);

      // Position with exactly 26 moves
      const position26 = TrainingPosition(
        id: 'test3',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 26,
      );

      // Should show 25 moves (capped at available: 26-1)
      expect(position26.getActualSequenceLength(25, 30), 25);

      // Position with 24 moves (below minimum)
      const position24 = TrainingPosition(
        id: 'test4',
        boardSize: 19,
        stonesBase64: '',
        score: 10.5,
        komi: 6.5,
        ownershipBase64: '',
        numberOfMoves: 24,
      );

      // Should be filtered out by hasEnoughMovesForSequence
      expect(position24.hasEnoughMovesForSequence(25), isFalse);
    });
  });
}
