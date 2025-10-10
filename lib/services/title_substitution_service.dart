import '../models/custom_dataset.dart';
import '../models/daily_statistics.dart';
import '../services/statistics_manager.dart';
import '../services/custom_dataset_manager.dart';

/// Service for substituting dynamic values in custom title strings
class TitleSubstitutionService {
  /// Substitute placeholders in custom title with actual statistics
  ///
  /// Available placeholders:
  /// %d - current dataset name
  /// %n - total number of problems solved today on current dataset
  /// %a - today's accuracy percentage on current dataset
  /// %t - today's average time per problem on current dataset
  /// %s - today's average points/second speed on current dataset
  static Future<String> substituteTitle(
    String customTitle,
    CustomDataset? currentDataset,
  ) async {
    if (currentDataset == null) {
      // If no dataset selected, only substitute %d with placeholder
      return customTitle.replaceAll('%d', 'No Dataset');
    }

    final statisticsManager = await StatisticsManager.getInstance();
    final todayStats = statisticsManager.getTodayStatistics();
    final datasetStats = todayStats.getStatsForDatasetId(currentDataset.id);

    String result = customTitle;

    // %d - current dataset name
    result = result.replaceAll('%d', currentDataset.name);

    if (datasetStats != null) {
      // %n - total number of problems solved today
      result = result.replaceAll('%n', datasetStats.totalAttempts.toString());

      // %a - today's accuracy percentage
      result = result.replaceAll('%a', '${datasetStats.accuracyPercentage.toStringAsFixed(1)}%');

      // %t - today's average time per problem
      result = result.replaceAll('%t', '${datasetStats.averageTimeSeconds.toStringAsFixed(1)}s');

      // %s - today's average points/second speed
      // if (datasetStats.hasSpeedData) {
      result = result.replaceAll('%s', '${datasetStats.averagePointsPerSecond.toStringAsFixed(1)} pts/s');
      // } else {
      //   result = result.replaceAll('%s', 'N/A');
      // }
    } else {
      // No statistics for today - use default values
      result = result.replaceAll('%n', '0');
      result = result.replaceAll('%a', '0.0%');
      result = result.replaceAll('%t', '0.0s');
      result = result.replaceAll('%s', 'N/A');
    }

    return result;
  }

  /// Get help text explaining the available placeholders
  static const String helpText =
    'Available placeholders:\n'
    '%d - Current dataset name\n'
    '%n - Problems solved today\n'
    '%a - Today\'s accuracy percentage\n'
    '%t - Today\'s average time per problem\n'
    '%s - Today\'s average points/second speed';
}