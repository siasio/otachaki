import '../models/dataset_type.dart';
import '../models/problem_attempt.dart';

/// Daily statistics for a specific dataset type
class DailyDatasetStatistics {
  final DatasetType datasetType;
  final DateTime date;
  final int totalAttempts;
  final int correctAttempts;
  final double totalTimeSeconds;
  final List<ProblemAttempt> attempts;

  const DailyDatasetStatistics({
    required this.datasetType,
    required this.date,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.totalTimeSeconds,
    required this.attempts,
  });

  /// Create from a list of problem attempts for a specific date and dataset
  factory DailyDatasetStatistics.fromAttempts(
    DatasetType datasetType,
    DateTime date,
    List<ProblemAttempt> attempts,
  ) {
    final filteredAttempts = attempts
        .where((attempt) =>
            attempt.datasetType == datasetType &&
            _isSameDay(attempt.timestamp, date))
        .toList();

    final totalAttempts = filteredAttempts.length;
    final correctAttempts = filteredAttempts.where((a) => a.isCorrect).length;
    final totalTimeSeconds = filteredAttempts
        .map((a) => a.timeSpentSeconds)
        .fold(0.0, (sum, time) => sum + time);

    return DailyDatasetStatistics(
      datasetType: datasetType,
      date: date,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      totalTimeSeconds: totalTimeSeconds,
      attempts: filteredAttempts,
    );
  }

  /// Calculate accuracy as a percentage (0-100)
  double get accuracyPercentage {
    if (totalAttempts == 0) return 0.0;
    return (correctAttempts / totalAttempts) * 100.0;
  }

  /// Calculate average time per problem in seconds
  double get averageTimeSeconds {
    if (totalAttempts == 0) return 0.0;
    return totalTimeSeconds / totalAttempts;
  }

  /// Check if this day has any attempts
  bool get hasAttempts => totalAttempts > 0;

  /// Create from JSON map
  factory DailyDatasetStatistics.fromJson(Map<String, dynamic> json) {
    return DailyDatasetStatistics(
      datasetType: DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9Area,
      date: DateTime.parse(json['date'] as String),
      totalAttempts: json['totalAttempts'] as int,
      correctAttempts: json['correctAttempts'] as int,
      totalTimeSeconds: (json['totalTimeSeconds'] as num).toDouble(),
      attempts: (json['attempts'] as List)
          .map((a) => ProblemAttempt.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'datasetType': datasetType.value,
      'date': date.toIso8601String(),
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'totalTimeSeconds': totalTimeSeconds,
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  String toString() {
    return 'DailyDatasetStatistics(datasetType: $datasetType, date: $date, '
           'totalAttempts: $totalAttempts, correctAttempts: $correctAttempts, '
           'accuracyPercentage: ${accuracyPercentage.toStringAsFixed(1)}%, '
           'averageTimeSeconds: ${averageTimeSeconds.toStringAsFixed(1)}s)';
  }
}

/// Daily statistics for all dataset types
class DailyStatistics {
  final DateTime date;
  final Map<DatasetType, DailyDatasetStatistics> datasetStats;

  const DailyStatistics({
    required this.date,
    required this.datasetStats,
  });

  /// Create from a list of problem attempts for a specific date
  factory DailyStatistics.fromAttempts(DateTime date, List<ProblemAttempt> attempts) {
    final Map<DatasetType, DailyDatasetStatistics> datasetStats = {};

    // Group attempts by dataset type
    for (final datasetType in DatasetType.values) {
      final stats = DailyDatasetStatistics.fromAttempts(datasetType, date, attempts);
      if (stats.hasAttempts) {
        datasetStats[datasetType] = stats;
      }
    }

    return DailyStatistics(
      date: date,
      datasetStats: datasetStats,
    );
  }

  /// Get statistics for a specific dataset type
  DailyDatasetStatistics? getStatsForDataset(DatasetType datasetType) {
    return datasetStats[datasetType];
  }

  /// Get all dataset types that have attempts today
  List<DatasetType> get activeDatasetTypes => datasetStats.keys.toList();

  /// Check if this day has any attempts
  bool get hasAttempts => datasetStats.isNotEmpty;

  /// Create from JSON map
  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    final Map<DatasetType, DailyDatasetStatistics> datasetStats = {};

    final statsMap = json['datasetStats'] as Map<String, dynamic>;
    for (final entry in statsMap.entries) {
      final datasetType = DatasetType.fromString(entry.key);
      if (datasetType != null) {
        datasetStats[datasetType] = DailyDatasetStatistics.fromJson(
          entry.value as Map<String, dynamic>
        );
      }
    }

    return DailyStatistics(
      date: DateTime.parse(json['date'] as String),
      datasetStats: datasetStats,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> statsMap = {};
    for (final entry in datasetStats.entries) {
      statsMap[entry.key.value] = entry.value.toJson();
    }

    return {
      'date': date.toIso8601String(),
      'datasetStats': statsMap,
    };
  }
}