import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/training_position.dart';

void main() {
  group('TrainingPosition ownership', () {
    test('hasOwnership returns correct values', () {
      final withOwnership = TrainingPosition(
        id: 'test1',
        boardSize: 9,
        stonesBase64: 'AAAA',
        score: 0.0,
        blackCaptured: 0,
        whiteCaptured: 0,
        komi: 6.5,
        ownershipBase64: 'AAAA',
      );

      final withoutOwnership = TrainingPosition(
        id: 'test2',
        boardSize: 9,
        stonesBase64: 'AAAA',
        score: 0.0,
        blackCaptured: 0,
        whiteCaptured: 0,
        komi: 6.5,
        ownershipBase64: null,
      );

      expect(withOwnership.hasOwnership, true);
      expect(withoutOwnership.hasOwnership, false);
    });

    test('decodeOwnership returns null when no ownership data', () {
      final position = TrainingPosition(
        id: 'test',
        boardSize: 9,
        stonesBase64: 'AAAA',
        score: 0.0,
        blackCaptured: 0,
        whiteCaptured: 0,
        komi: 6.5,
        ownershipBase64: null,
      );

      expect(position.decodeOwnership(), null);
    });

    test('decodeOwnership returns ownership data when available', () {
      // Create test ownership data
      final testBytes = Uint8List.fromList([
        0,   // -1.0 (white)
        128, // 0.0 (neutral)
        255, // 1.0 (black)
      ]);
      final base64String = base64Encode(testBytes);

      final position = TrainingPosition(
        id: 'test',
        boardSize: 2, // 2x2 board for simplicity
        stonesBase64: 'AAAA',
        score: 0.0,
        blackCaptured: 0,
        whiteCaptured: 0,
        komi: 6.5,
        ownershipBase64: base64String,
      );

      final ownership = position.decodeOwnership();
      expect(ownership, isNotNull);
      expect(ownership!.length, 2);
      expect(ownership[0].length, 2);

      expect(ownership[0][0], closeTo(-1.0, 0.01));
      expect(ownership[0][1], closeTo(0.0, 0.01));
      expect(ownership[1][0], closeTo(1.0, 0.01));
      expect(ownership[1][1], closeTo(0.0, 0.01)); // Default for missing data
    });
  });
}