import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/problem_attempt.dart';
import 'package:otachaki/models/dataset_type.dart';

void main() {
  group('ProblemAttempt', () {
    test('should create a problem attempt with correct properties', () {
      final now = DateTime.now();
      final attempt = ProblemAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset',
        isCorrect: true,
        timeSpentMs: 5000,
        timestamp: now,
        wasTimeout: false,
      );

      expect(attempt.datasetType, equals(DatasetType.final9x9));
      expect(attempt.isCorrect, equals(true));
      expect(attempt.timeSpentMs, equals(5000));
      expect(attempt.timestamp, equals(now));
      expect(attempt.wasTimeout, equals(false));
      expect(attempt.timeSpentSeconds, equals(5.0));
    });

    test('should create a problem attempt with default wasTimeout value', () {
      final now = DateTime.now();
      final attempt = ProblemAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset',
        isCorrect: true,
        timeSpentMs: 5000,
        timestamp: now,
      );

      expect(attempt.wasTimeout, equals(false));
    });

    test('should correctly convert time from milliseconds to seconds', () {
      final attempt = ProblemAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset',
        isCorrect: true,
        timeSpentMs: 7500,
        timestamp: DateTime.now(),
      );

      expect(attempt.timeSpentSeconds, equals(7.5));
    });

    test('should convert to and from JSON correctly', () {
      final now = DateTime.now();
      final originalAttempt = ProblemAttempt(
        datasetType: DatasetType.midgame19x19,
        datasetId: 'test-dataset-midgame',
        isCorrect: false,
        timeSpentMs: 12000,
        timestamp: now,
        wasTimeout: true,
      );

      final json = originalAttempt.toJson();
      final restoredAttempt = ProblemAttempt.fromJson(json);

      expect(restoredAttempt.datasetType, equals(originalAttempt.datasetType));
      expect(restoredAttempt.isCorrect, equals(originalAttempt.isCorrect));
      expect(restoredAttempt.timeSpentMs, equals(originalAttempt.timeSpentMs));
      expect(restoredAttempt.timestamp, equals(originalAttempt.timestamp));
      expect(restoredAttempt.wasTimeout, equals(originalAttempt.wasTimeout));
    });

    test('should handle null wasTimeout in JSON conversion', () {
      final json = {
        'datasetType': 'final-9x9-area',
        'datasetId': 'test-dataset',
        'isCorrect': true,
        'timeSpentMs': 5000,
        'timestamp': DateTime.now().toIso8601String(),
        // wasTimeout is missing
      };

      final attempt = ProblemAttempt.fromJson(json);
      expect(attempt.wasTimeout, equals(false));
    });

    test('should handle unknown dataset type in JSON conversion', () {
      final json = {
        'datasetType': 'unknown-dataset-type',
        'datasetId': 'test-dataset',
        'isCorrect': true,
        'timeSpentMs': 5000,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final attempt = ProblemAttempt.fromJson(json);
      expect(attempt.datasetType, equals(DatasetType.final9x9)); // Default fallback
    });
  });
}