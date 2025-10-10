import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/daily_statistics.dart';
import 'package:countingapp/models/problem_attempt.dart';
import 'package:countingapp/models/dataset_type.dart';

void main() {
  group('DailyDatasetStatistics', () {
    test('should create from attempts correctly', () {
      final date = DateTime(2024, 1, 15);
      final attempts = [
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 5000,
          timestamp: DateTime(2024, 1, 15, 10, 30),
        ),
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: false,
          timeSpentMs: 8000,
          timestamp: DateTime(2024, 1, 15, 11, 45),
        ),
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 3000,
          timestamp: DateTime(2024, 1, 15, 14, 20),
        ),
        // Different dataset type - should be ignored
        ProblemAttempt(
          datasetType: DatasetType.final19x19,
          isCorrect: true,
          timeSpentMs: 6000,
          timestamp: DateTime(2024, 1, 15, 12, 0),
        ),
        // Different date - should be ignored
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 4000,
          timestamp: DateTime(2024, 1, 16, 9, 0),
        ),
      ];

      final stats = DailyDatasetStatistics.fromAttempts(
        DatasetType.final9x9,
        date,
        attempts,
      );

      expect(stats.datasetType, equals(DatasetType.final9x9));
      expect(stats.date, equals(date));
      expect(stats.totalAttempts, equals(3));
      expect(stats.correctAttempts, equals(2));
      expect(stats.totalTimeSeconds, equals(16.0)); // 5+8+3 seconds
      expect(stats.hasAttempts, equals(true));
    });

    test('should calculate accuracy percentage correctly', () {
      final stats = DailyDatasetStatistics(
        datasetType: DatasetType.final9x9,
        date: DateTime(2024, 1, 15),
        totalAttempts: 5,
        correctAttempts: 3,
        totalTimeSeconds: 25.0,
        attempts: [],
      );

      expect(stats.accuracyPercentage, closeTo(60.0, 0.01));
    });

    test('should calculate average time correctly', () {
      final stats = DailyDatasetStatistics(
        datasetType: DatasetType.final9x9,
        date: DateTime(2024, 1, 15),
        totalAttempts: 4,
        correctAttempts: 2,
        totalTimeSeconds: 20.0,
        attempts: [],
      );

      expect(stats.averageTimeSeconds, closeTo(5.0, 0.01));
    });

    test('should handle zero attempts correctly', () {
      final stats = DailyDatasetStatistics(
        datasetType: DatasetType.final9x9,
        date: DateTime(2024, 1, 15),
        totalAttempts: 0,
        correctAttempts: 0,
        totalTimeSeconds: 0.0,
        attempts: [],
      );

      expect(stats.accuracyPercentage, equals(0.0));
      expect(stats.averageTimeSeconds, equals(0.0));
      expect(stats.hasAttempts, equals(false));
    });

    test('should convert to and from JSON correctly', () {
      final originalStats = DailyDatasetStatistics(
        datasetType: DatasetType.midgame19x19,
        date: DateTime(2024, 1, 15),
        totalAttempts: 3,
        correctAttempts: 2,
        totalTimeSeconds: 15.5,
        attempts: [
          ProblemAttempt(
            datasetType: DatasetType.midgame19x19,
            isCorrect: true,
            timeSpentMs: 5000,
            timestamp: DateTime(2024, 1, 15, 10, 30),
          ),
        ],
      );

      final json = originalStats.toJson();
      final restoredStats = DailyDatasetStatistics.fromJson(json);

      expect(restoredStats.datasetType, equals(originalStats.datasetType));
      expect(restoredStats.date, equals(originalStats.date));
      expect(restoredStats.totalAttempts, equals(originalStats.totalAttempts));
      expect(restoredStats.correctAttempts, equals(originalStats.correctAttempts));
      expect(restoredStats.totalTimeSeconds, equals(originalStats.totalTimeSeconds));
      expect(restoredStats.attempts.length, equals(originalStats.attempts.length));
    });
  });

  group('DailyStatistics', () {
    test('should create from attempts correctly', () {
      final date = DateTime(2024, 1, 15);
      final attempts = [
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 5000,
          timestamp: DateTime(2024, 1, 15, 10, 30),
        ),
        ProblemAttempt(
          datasetType: DatasetType.final19x19,
          isCorrect: false,
          timeSpentMs: 8000,
          timestamp: DateTime(2024, 1, 15, 11, 45),
        ),
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 3000,
          timestamp: DateTime(2024, 1, 15, 14, 20),
        ),
      ];

      final dailyStats = DailyStatistics.fromAttempts(date, attempts);

      expect(dailyStats.date, equals(date));
      expect(dailyStats.hasAttempts, equals(true));
      expect(dailyStats.activeDatasetTypes.length, equals(2));
      expect(dailyStats.activeDatasetTypes.contains(DatasetType.final9x9), equals(true));
      expect(dailyStats.activeDatasetTypes.contains(DatasetType.final19x19), equals(true));

      final stats9x9 = dailyStats.getStatsForDataset(DatasetType.final9x9);
      expect(stats9x9, isNotNull);
      expect(stats9x9!.totalAttempts, equals(2));
      expect(stats9x9.correctAttempts, equals(2));

      final stats19x19 = dailyStats.getStatsForDataset(DatasetType.final19x19);
      expect(stats19x19, isNotNull);
      expect(stats19x19!.totalAttempts, equals(1));
      expect(stats19x19.correctAttempts, equals(0));
    });

    test('should return null for dataset types with no attempts', () {
      final date = DateTime(2024, 1, 15);
      final attempts = [
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 5000,
          timestamp: DateTime(2024, 1, 15, 10, 30),
        ),
      ];

      final dailyStats = DailyStatistics.fromAttempts(date, attempts);
      final stats = dailyStats.getStatsForDataset(DatasetType.midgame19x19);

      expect(stats, isNull);
    });

    test('should handle empty attempts', () {
      final date = DateTime(2024, 1, 15);
      final dailyStats = DailyStatistics.fromAttempts(date, []);

      expect(dailyStats.hasAttempts, equals(false));
      expect(dailyStats.activeDatasetTypes, isEmpty);
    });

    test('should convert to and from JSON correctly', () {
      final date = DateTime(2024, 1, 15);
      final attempts = [
        ProblemAttempt(
          datasetType: DatasetType.final9x9,
          isCorrect: true,
          timeSpentMs: 5000,
          timestamp: DateTime(2024, 1, 15, 10, 30),
        ),
      ];

      final originalStats = DailyStatistics.fromAttempts(date, attempts);
      final json = originalStats.toJson();
      final restoredStats = DailyStatistics.fromJson(json);

      expect(restoredStats.date, equals(originalStats.date));
      expect(restoredStats.hasAttempts, equals(originalStats.hasAttempts));
      expect(restoredStats.activeDatasetTypes, equals(originalStats.activeDatasetTypes));

      final originalDatasetStats = originalStats.getStatsForDataset(DatasetType.final9x9);
      final restoredDatasetStats = restoredStats.getStatsForDataset(DatasetType.final9x9);

      expect(restoredDatasetStats, isNotNull);
      expect(restoredDatasetStats!.totalAttempts, equals(originalDatasetStats!.totalAttempts));
      expect(restoredDatasetStats.correctAttempts, equals(originalDatasetStats.correctAttempts));
    });
  });
}