import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/problem_feedback_type.dart';

void main() {
  group('ProblemFeedbackType', () {
    test('should have correct string values', () {
      expect(ProblemFeedbackType.result.value, 'result');
      expect(ProblemFeedbackType.resultWithTime.value, 'result_with_time');
      expect(ProblemFeedbackType.resultWithSpeed.value, 'result_with_speed');
    });

    test('should have correct display names', () {
      expect(ProblemFeedbackType.result.displayName, 'Result');
      expect(ProblemFeedbackType.resultWithTime.displayName, 'Result + Time');
      expect(ProblemFeedbackType.resultWithSpeed.displayName, 'Result + Speed');
    });

    test('fromString should return correct types', () {
      expect(ProblemFeedbackType.fromString('result'), ProblemFeedbackType.result);
      expect(ProblemFeedbackType.fromString('result_with_time'), ProblemFeedbackType.resultWithTime);
      expect(ProblemFeedbackType.fromString('result_with_speed'), ProblemFeedbackType.resultWithSpeed);
    });

    test('fromString should return null for invalid strings', () {
      expect(ProblemFeedbackType.fromString('invalid'), null);
      expect(ProblemFeedbackType.fromString(''), null);
      expect(ProblemFeedbackType.fromString(null), null);
    });

    test('getAvailableTypes should return all types for non-midgame datasets', () {
      final types = ProblemFeedbackType.getAvailableTypes('final9x9');
      expect(types, ProblemFeedbackType.values);

      final types13x13 = ProblemFeedbackType.getAvailableTypes('final13x13');
      expect(types13x13, ProblemFeedbackType.values);

      final types19x19 = ProblemFeedbackType.getAvailableTypes('final19x19');
      expect(types19x19, ProblemFeedbackType.values);

      final typesPartial = ProblemFeedbackType.getAvailableTypes('partialPositions');
      expect(typesPartial, ProblemFeedbackType.values);
    });

    test('getAvailableTypes should return limited types for midgame datasets', () {
      final types = ProblemFeedbackType.getAvailableTypes('midgame19x19');
      expect(types, [ProblemFeedbackType.result, ProblemFeedbackType.resultWithTime]);
      expect(types.contains(ProblemFeedbackType.resultWithSpeed), false);
    });
  });
}