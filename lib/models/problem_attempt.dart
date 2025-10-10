import '../models/dataset_type.dart';

/// Represents a single problem attempt during training
class ProblemAttempt {
  final DatasetType datasetType;
  final String datasetId; // Dataset ID (always required in unified architecture)
  final bool isCorrect;
  final int timeSpentMs;
  final DateTime timestamp;
  final bool wasTimeout;
  final double? pointsPerSecond; // Speed calculation for positions with territory data

  const ProblemAttempt({
    required this.datasetType,
    required this.datasetId,
    required this.isCorrect,
    required this.timeSpentMs,
    required this.timestamp,
    this.wasTimeout = false,
    this.pointsPerSecond,
  });

  /// Create from JSON map
  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    return ProblemAttempt(
      datasetType: DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9,
      datasetId: json['datasetId'] as String? ?? 'default_${(DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9).value}',
      isCorrect: json['isCorrect'] as bool,
      timeSpentMs: json['timeSpentMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasTimeout: json['wasTimeout'] as bool? ?? false,
      pointsPerSecond: json['pointsPerSecond'] as double?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final json = {
      'datasetType': datasetType.value,
      'datasetId': datasetId, // Always include datasetId
      'isCorrect': isCorrect,
      'timeSpentMs': timeSpentMs,
      'timestamp': timestamp.toIso8601String(),
      'wasTimeout': wasTimeout,
    };

    if (pointsPerSecond != null) {
      json['pointsPerSecond'] = pointsPerSecond!;
    }

    return json;
  }

  /// Get time spent in seconds (capped at 15s for timeouts)
  double get timeSpentSeconds => timeSpentMs / 1000.0;

  /// Get the unique identifier for this attempt's dataset
  /// Returns the dataset ID (always present in unified architecture)
  String get effectiveDatasetId => datasetId;

  @override
  String toString() {
    return 'ProblemAttempt(datasetType: $datasetType, datasetId: $datasetId, isCorrect: $isCorrect, timeSpentMs: $timeSpentMs, timestamp: $timestamp, wasTimeout: $wasTimeout)';
  }
}