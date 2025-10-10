import '../models/dataset_type.dart';

/// Represents a single problem attempt during training
class ProblemAttempt {
  final DatasetType datasetType;
  final String? datasetId; // ID of custom dataset, null for legacy attempts
  final bool isCorrect;
  final int timeSpentMs;
  final DateTime timestamp;
  final bool wasTimeout;

  const ProblemAttempt({
    required this.datasetType,
    this.datasetId,
    required this.isCorrect,
    required this.timeSpentMs,
    required this.timestamp,
    this.wasTimeout = false,
  });

  /// Create from JSON map
  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    return ProblemAttempt(
      datasetType: DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9,
      datasetId: json['datasetId'] as String?,
      isCorrect: json['isCorrect'] as bool,
      timeSpentMs: json['timeSpentMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasTimeout: json['wasTimeout'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'datasetType': datasetType.value,
      'isCorrect': isCorrect,
      'timeSpentMs': timeSpentMs,
      'timestamp': timestamp.toIso8601String(),
      'wasTimeout': wasTimeout,
    };

    if (datasetId != null) {
      json['datasetId'] = datasetId;
    }

    return json;
  }

  /// Get time spent in seconds (capped at 15s for timeouts)
  double get timeSpentSeconds => timeSpentMs / 1000.0;

  /// Get the unique identifier for this attempt's dataset
  /// Returns datasetId for custom datasets, or a generated ID for built-in datasets
  String get effectiveDatasetId => datasetId ?? 'builtin_${datasetType.value}';

  @override
  String toString() {
    return 'ProblemAttempt(datasetType: $datasetType, datasetId: $datasetId, isCorrect: $isCorrect, timeSpentMs: $timeSpentMs, timestamp: $timestamp, wasTimeout: $wasTimeout)';
  }
}