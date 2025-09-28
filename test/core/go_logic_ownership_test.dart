import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/core/go_logic.dart';

void main() {
  group('GoLogic ownership decoding', () {
    test('decodeOwnership converts bytes correctly', () {
      // Create test ownership data where:
      // 0 = -1.0 (white), 128 = 0.0 (neutral), 255 = 1.0 (black)
      final testBytes = Uint8List.fromList([
        0,   // -1.0 (white)
        64,  // -0.5 (moderate white)
        128, // 0.0 (neutral)
        192, // 0.5 (moderate black)
        255, // 1.0 (black)
      ]);
      final base64String = base64Encode(testBytes);

      final ownership = GoLogic.decodeOwnership(base64String, 3);

      expect(ownership.length, 3);
      expect(ownership[0].length, 3);

      // Check the first 5 values
      expect(ownership[0][0], closeTo(-1.0, 0.01));
      expect(ownership[0][1], closeTo(-0.5, 0.01));
      expect(ownership[0][2], closeTo(0.0, 0.01));
      expect(ownership[1][0], closeTo(0.5, 0.01));
      expect(ownership[1][1], closeTo(1.0, 0.01));

      // Remaining values should be 0 (default)
      expect(ownership[1][2], closeTo(0.0, 0.01));
      expect(ownership[2][0], closeTo(0.0, 0.01));
      expect(ownership[2][1], closeTo(0.0, 0.01));
      expect(ownership[2][2], closeTo(0.0, 0.01));
    });

    test('decodeOwnership handles edge cases', () {
      // Test with empty data
      final emptyBytes = Uint8List(0);
      final emptyBase64 = base64Encode(emptyBytes);

      final emptyOwnership = GoLogic.decodeOwnership(emptyBase64, 2);
      expect(emptyOwnership.length, 2);
      expect(emptyOwnership[0].length, 2);
      expect(emptyOwnership[0][0], 0.0);
      expect(emptyOwnership[0][1], 0.0);
      expect(emptyOwnership[1][0], 0.0);
      expect(emptyOwnership[1][1], 0.0);
    });

    test('decodeOwnership clamps values to valid range', () {
      // Test with extreme values that should be clamped
      final testBytes = Uint8List.fromList([
        0,   // Should become -1.0
        255, // Should become 1.0
      ]);
      final base64String = base64Encode(testBytes);

      final ownership = GoLogic.decodeOwnership(base64String, 2);

      expect(ownership[0][0], closeTo(-1.0, 0.01));
      expect(ownership[0][1], closeTo(1.0, 0.01));
    });
  });
}