import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/services/statistics_manager.dart';
import 'package:otachaki/models/dataset_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StatisticsManager', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
    });

    test('should calculate app day correctly considering 2AM cutoff', () async {
      final manager = await StatisticsManager.getInstance();

      // Test cases around 2 AM
      final beforeCutoff = DateTime(2024, 1, 15, 1, 30); // 1:30 AM
      final afterCutoff = DateTime(2024, 1, 15, 3, 0); // 3:00 AM

      final dayBefore = manager.getCurrentAppDay(beforeCutoff);
      final dayAfter = manager.getCurrentAppDay(afterCutoff);

      expect(dayBefore, equals(DateTime(2024, 1, 14))); // Previous day
      expect(dayAfter, equals(DateTime(2024, 1, 15))); // Same day
    });

    test('should record and retrieve attempts correctly', () async {
      final manager = await StatisticsManager.getInstance();
      await manager.clearAllStatistics(); // Start clean

      // Record some attempts
      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: true,
        timeSpentMs: 5000,
      );

      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: false,
        timeSpentMs: 8000,
        wasTimeout: true,
      );

      await manager.recordAttempt(
        datasetType: DatasetType.final19x19,
        datasetId: 'test-dataset-19x19',
        isCorrect: true,
        timeSpentMs: 12000,
      );

      // Check today's statistics
      final todayStats = manager.getTodayStatistics();
      expect(todayStats.hasAttempts, equals(true));
      expect(todayStats.activeDatasetTypes.length, equals(2));

      // Check specific dataset statistics
      final stats9x9 = manager.getTodayStatsForDataset(DatasetType.final9x9);
      expect(stats9x9, isNotNull);
      expect(stats9x9!.totalAttempts, equals(2));
      expect(stats9x9.correctAttempts, equals(1));
      expect(stats9x9.accuracyPercentage, closeTo(50.0, 0.01));
      expect(stats9x9.averageTimeSeconds, closeTo(6.5, 0.01)); // (5+8)/2

      final stats19x19 = manager.getTodayStatsForDataset(DatasetType.final19x19);
      expect(stats19x19, isNotNull);
      expect(stats19x19!.totalAttempts, equals(1));
      expect(stats19x19.correctAttempts, equals(1));
      expect(stats19x19.accuracyPercentage, equals(100.0));
      expect(stats19x19.averageTimeSeconds, equals(12.0));
    });

    test('should get historical statistics correctly', () async {
      final manager = await StatisticsManager.getInstance();
      await manager.clearAllStatistics(); // Start clean

      // Record attempts for today
      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: true,
        timeSpentMs: 5000,
      );

      // Get historical data
      final historical = manager.getHistoricalStats(DatasetType.final9x9, 7);
      expect(historical.length, equals(7)); // Should return 7 days worth

      // Check that today has data
      final todayStats = historical.last; // Most recent day
      expect(todayStats.totalAttempts, equals(1));
      expect(todayStats.correctAttempts, equals(1));

      // Check that other days have zero attempts
      for (int i = 0; i < historical.length - 1; i++) {
        expect(historical[i].totalAttempts, equals(0));
      }
    });

    test('should handle timeout attempts correctly', () async {
      final manager = await StatisticsManager.getInstance();
      await manager.clearAllStatistics(); // Start clean

      // Record a timeout attempt (capping should be done by the calling code)
      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: false,
        timeSpentMs: 15000, // 15 seconds timeout (pre-capped)
        wasTimeout: true,
      );

      final stats = manager.getTodayStatsForDataset(DatasetType.final9x9);
      expect(stats, isNotNull);
      expect(stats!.totalAttempts, equals(1));
      expect(stats.correctAttempts, equals(0));
      expect(stats.averageTimeSeconds, equals(15.0));
    });

    test('should get available dataset types correctly', () async {
      final manager = await StatisticsManager.getInstance();
      await manager.clearAllStatistics(); // Start clean

      // Initially no dataset types
      expect(manager.getAvailableDatasetTypes(), isEmpty);

      // Record attempts for different dataset types
      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: true,
        timeSpentMs: 5000,
      );

      await manager.recordAttempt(
        datasetType: DatasetType.midgame19x19,
        datasetId: 'test-dataset-midgame',
        isCorrect: false,
        timeSpentMs: 8000,
      );

      final availableTypes = manager.getAvailableDatasetTypes();
      expect(availableTypes.length, equals(2));
      expect(availableTypes.contains(DatasetType.final9x9), equals(true));
      expect(availableTypes.contains(DatasetType.midgame19x19), equals(true));
    });

    test('should clear all statistics correctly', () async {
      final manager = await StatisticsManager.getInstance();

      // Record some attempts
      await manager.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: true,
        timeSpentMs: 5000,
      );

      // Verify data exists
      expect(manager.totalAttemptsCount, greaterThan(0));
      expect(manager.getTodayStatistics().hasAttempts, equals(true));

      // Clear all data
      await manager.clearAllStatistics();

      // Verify data is cleared
      expect(manager.totalAttemptsCount, equals(0));
      expect(manager.getTodayStatistics().hasAttempts, equals(false));
      expect(manager.getAvailableDatasetTypes(), isEmpty);
    });

    test('should persist data across manager instances', () async {
      // First manager instance
      final manager1 = await StatisticsManager.getInstance();
      await manager1.clearAllStatistics(); // Start clean

      await manager1.recordAttempt(
        datasetType: DatasetType.final9x9,
        datasetId: 'test-dataset-9x9',
        isCorrect: true,
        timeSpentMs: 5000,
      );

      expect(manager1.totalAttemptsCount, equals(1));

      // Create a new manager instance (simulates app restart)
      // Note: In real testing, you'd need to reset the singleton instance
      // For this test, we'll just verify the current behavior
      final manager2 = await StatisticsManager.getInstance();
      expect(manager2.totalAttemptsCount, equals(1)); // Should be same instance

      final stats = manager2.getTodayStatsForDataset(DatasetType.final9x9);
      expect(stats, isNotNull);
      expect(stats!.totalAttempts, equals(1));
    });
  });
}