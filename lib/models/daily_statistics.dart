import '../models/dataset_type.dart';
import '../models/problem_attempt.dart';

/// Daily statistics for a specific dataset (either custom or built-in)
class DailyDatasetStatistics {
  final DatasetType datasetType;
  final String? datasetId; // ID for custom datasets, null for legacy/built-in
  final DateTime date;
  final int totalAttempts;
  final int correctAttempts;
  final double totalTimeSeconds;
  final List<ProblemAttempt> attempts;

  const DailyDatasetStatistics({
    required this.datasetType,
    this.datasetId,
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
    List<ProblemAttempt> attempts, {
    required String datasetId,
  }) {
    final filteredAttempts = attempts
        .where((attempt) =>
            attempt.datasetType == datasetType &&
            attempt.datasetId == datasetId &&
            _isSameAppDay(attempt.timestamp, date))
        .toList();

    final totalAttempts = filteredAttempts.length;
    final correctAttempts = filteredAttempts.where((a) => a.isCorrect).length;
    final totalTimeSeconds = filteredAttempts
        .map((a) => a.timeSpentSeconds)
        .fold(0.0, (sum, time) => sum + time);

    return DailyDatasetStatistics(
      datasetType: datasetType,
      datasetId: datasetId,
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

  /// Calculate average points per second (speed) for positions with territory data
  double get averagePointsPerSecond {
    // Midgame datasets don't have meaningful territory/speed data
    if (datasetType == DatasetType.midgame19x19) return 0.0;

    final speedAttempts = attempts.where((a) => a.pointsPerSecond != null).toList();
    if (speedAttempts.isEmpty) return 0.0;

    final totalSpeed = speedAttempts
        .map((a) => a.pointsPerSecond!)
        .fold(0.0, (sum, speed) => sum + speed);
    return totalSpeed / speedAttempts.length;
  }

  /// Check if this dataset has speed tracking data
  // bool get hasSpeedData => attempts.any((a) => a.pointsPerSecond != null);

  /// Check if this day has any attempts
  bool get hasAttempts => totalAttempts > 0;

  /// Get effective dataset ID
  String get effectiveDatasetId => datasetId ?? 'default_${datasetType.value}';

  /// Create from JSON map
  factory DailyDatasetStatistics.fromJson(Map<String, dynamic> json) {
    return DailyDatasetStatistics(
      datasetType: DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9,
      datasetId: json['datasetId'] as String?,
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
    final Map<String, dynamic> json = {
      'datasetType': datasetType.value,
      'date': date.toIso8601String(),
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'totalTimeSeconds': totalTimeSeconds,
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };

    if (datasetId != null) {
      json['datasetId'] = datasetId;
    }

    return json;
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if two timestamps belong to the same app day (considering 2AM cutoff)
  static bool _isSameAppDay(DateTime timestamp, DateTime appDay) {
    // Convert timestamp to app day
    final timestampAppDay = _getAppDay(timestamp);
    return _isSameDay(timestampAppDay, appDay);
  }

  /// Get the app day for a given timestamp (considering 2AM cutoff)
  static DateTime _getAppDay(DateTime timestamp) {
    // If it's before 2 AM, consider it the previous day
    if (timestamp.hour < 2) {
      return DateTime(timestamp.year, timestamp.month, timestamp.day - 1);
    } else {
      return DateTime(timestamp.year, timestamp.month, timestamp.day);
    }
  }

  @override
  String toString() {
    return 'DailyDatasetStatistics(datasetType: $datasetType, datasetId: $datasetId, date: $date, '
           'totalAttempts: $totalAttempts, correctAttempts: $correctAttempts, '
           'accuracyPercentage: ${accuracyPercentage.toStringAsFixed(1)}%, '
           'averageTimeSeconds: ${averageTimeSeconds.toStringAsFixed(1)}s)';
  }
}

/// Daily statistics for all datasets (both built-in and custom)
class DailyStatistics {
  final DateTime date;
  /// Legacy field for backward compatibility - maps DatasetType to stats
  final Map<DatasetType, DailyDatasetStatistics> datasetStats;
  /// New field - maps dataset ID to stats (includes both built-in and custom)
  final Map<String, DailyDatasetStatistics> datasetStatsById;

  const DailyStatistics({
    required this.date,
    required this.datasetStats,
    required this.datasetStatsById,
  });

  /// Create from a list of problem attempts for a specific date
  factory DailyStatistics.fromAttempts(DateTime date, List<ProblemAttempt> attempts) {
    final Map<DatasetType, DailyDatasetStatistics> datasetStats = {};
    final Map<String, DailyDatasetStatistics> datasetStatsById = {};

    // Group attempts by dataset ID
    final Map<String, List<ProblemAttempt>> attemptsByDatasetId = {};
    for (final attempt in attempts) {
      final datasetId = attempt.datasetId;
      attemptsByDatasetId.putIfAbsent(datasetId, () => []).add(attempt);
    }

    // Create statistics for each dataset ID
    for (final entry in attemptsByDatasetId.entries) {
      final datasetId = entry.key;
      final datasetAttempts = entry.value;

      if (datasetAttempts.isNotEmpty) {
        final datasetType = datasetAttempts.first.datasetType;

        final stats = DailyDatasetStatistics.fromAttempts(
          datasetType,
          date,
          attempts,
          datasetId: datasetId,
        );

        if (stats.hasAttempts) {
          datasetStatsById[datasetId] = stats;

          // Legacy compatibility: Also populate datasetStats by type for old code
          // Use the first dataset of each type for backwards compatibility
          if (!datasetStats.containsKey(datasetType)) {
            datasetStats[datasetType] = stats;
          }
        }
      }
    }

    return DailyStatistics(
      date: date,
      datasetStats: datasetStats,
      datasetStatsById: datasetStatsById,
    );
  }

  /// Get statistics for a specific dataset type (legacy method)
  DailyDatasetStatistics? getStatsForDataset(DatasetType datasetType) {
    return datasetStats[datasetType];
  }

  /// Get statistics for a specific dataset by ID
  DailyDatasetStatistics? getStatsForDatasetId(String datasetId) {
    return datasetStatsById[datasetId];
  }

  /// Get all dataset types that have attempts today (legacy method)
  List<DatasetType> get activeDatasetTypes => datasetStats.keys.toList();

  /// Get all dataset IDs that have attempts today
  List<String> get activeDatasetIds => datasetStatsById.keys.toList();

  /// Get all statistics (by ID)
  Map<String, DailyDatasetStatistics> get allStats => Map.unmodifiable(datasetStatsById);

  /// Check if this day has any attempts
  bool get hasAttempts => datasetStatsById.isNotEmpty;

  /// Create from JSON map
  factory DailyStatistics.fromJson(Map<String, dynamic> json) {
    final Map<DatasetType, DailyDatasetStatistics> datasetStats = {};
    final Map<String, DailyDatasetStatistics> datasetStatsById = {};

    // Load legacy datasetStats for backward compatibility
    final legacyStatsMap = json['datasetStats'] as Map<String, dynamic>? ?? {};
    for (final entry in legacyStatsMap.entries) {
      final datasetType = DatasetType.fromString(entry.key);
      if (datasetType != null) {
        final stats = DailyDatasetStatistics.fromJson(
          entry.value as Map<String, dynamic>
        );
        datasetStats[datasetType] = stats;
        // Also add to new format with default ID
        datasetStatsById['default_${datasetType.value}'] = stats;
      }
    }

    // Load new datasetStatsById (this will override any duplicate entries)
    final newStatsMap = json['datasetStatsById'] as Map<String, dynamic>? ?? {};
    for (final entry in newStatsMap.entries) {
      final stats = DailyDatasetStatistics.fromJson(
        entry.value as Map<String, dynamic>
      );
      datasetStatsById[entry.key] = stats;

      // Update legacy format for default datasets
      if (entry.key.startsWith('default_') || entry.key.startsWith('builtin_')) {
        datasetStats[stats.datasetType] = stats;
      }
    }

    return DailyStatistics(
      date: DateTime.parse(json['date'] as String),
      datasetStats: datasetStats,
      datasetStatsById: datasetStatsById,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    // Legacy format for backward compatibility
    final Map<String, dynamic> legacyStatsMap = {};
    for (final entry in datasetStats.entries) {
      legacyStatsMap[entry.key.value] = entry.value.toJson();
    }

    // New format with dataset IDs
    final Map<String, dynamic> newStatsMap = {};
    for (final entry in datasetStatsById.entries) {
      newStatsMap[entry.key] = entry.value.toJson();
    }

    return {
      'date': date.toIso8601String(),
      'datasetStats': legacyStatsMap, // Keep for backward compatibility
      'datasetStatsById': newStatsMap, // New format
    };
  }
}