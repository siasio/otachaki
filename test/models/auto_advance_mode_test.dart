import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/auto_advance_mode.dart';

void main() {
  group('AutoAdvanceMode', () {
    test('should have correct values', () {
      expect(AutoAdvanceMode.always.value, 'always');
      expect(AutoAdvanceMode.never.value, 'never');
      expect(AutoAdvanceMode.onCorrectOnly.value, 'on_correct_only');
    });

    test('should convert from string correctly', () {
      expect(AutoAdvanceMode.fromString('always'), AutoAdvanceMode.always);
      expect(AutoAdvanceMode.fromString('never'), AutoAdvanceMode.never);
      expect(AutoAdvanceMode.fromString('on_correct_only'), AutoAdvanceMode.onCorrectOnly);
      expect(AutoAdvanceMode.fromString('invalid'), AutoAdvanceMode.always); // default
      expect(AutoAdvanceMode.fromString(null), AutoAdvanceMode.always); // default
    });

    test('should have correct display names', () {
      expect(AutoAdvanceMode.always.displayName, 'Auto-advance to the next problem');
      expect(AutoAdvanceMode.never.displayName, 'Don\'t auto-advance to the next problem');
      expect(AutoAdvanceMode.onCorrectOnly.displayName, 'Auto-advance to the next problem after correct solutions');
    });
  });
}