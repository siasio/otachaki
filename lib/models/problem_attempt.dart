import '../models/dataset_type.dart';

/// Represents a single problem attempt during training
class ProblemAttempt {
  final DatasetType datasetType;
  final bool isCorrect;
  final int timeSpentMs;
  final DateTime timestamp;
  final bool wasTimeout;

  const ProblemAttempt({
    required this.datasetType,
    required this.isCorrect,
    required this.timeSpentMs,
    required this.timestamp,
    this.wasTimeout = false,
  });

  /// Create from JSON map
  factory ProblemAttempt.fromJson(Map<String, dynamic> json) {
    return ProblemAttempt(
      datasetType: DatasetType.fromString(json['datasetType']) ?? DatasetType.final9x9Area,
      isCorrect: json['isCorrect'] as bool,
      timeSpentMs: json['timeSpentMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasTimeout: json['wasTimeout'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'datasetType': datasetType.value,
      'isCorrect': isCorrect,
      'timeSpentMs': timeSpentMs,
      'timestamp': timestamp.toIso8601String(),
      'wasTimeout': wasTimeout,
    };
  }

  /// Get time spent in seconds (capped at 15s for timeouts)
  double get timeSpentSeconds => timeSpentMs / 1000.0;

  @override
  String toString() {
    return 'ProblemAttempt(datasetType: $datasetType, isCorrect: $isCorrect, timeSpentMs: $timeSpentMs, timestamp: $timestamp, wasTimeout: $wasTimeout)';
  }
}