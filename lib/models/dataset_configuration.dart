import 'dataset_type.dart';
import 'ownership_display_mode.dart';
import 'prediction_type.dart';

class DatasetConfiguration {
  final double thresholdGood;
  final double thresholdClose;
  final int timePerProblemSeconds;
  final bool hideGameInfoBar;
  final int sequenceLength;
  final OwnershipDisplayMode ownershipDisplayMode;
  final bool timerEnabled;
  final PredictionType predictionType;
  final int scoreGranularity;

  const DatasetConfiguration({
    required this.thresholdGood,
    required this.thresholdClose,
    required this.timePerProblemSeconds,
    required this.hideGameInfoBar,
    this.sequenceLength = 0,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.timerEnabled = true,
    this.predictionType = PredictionType.winnerPrediction,
    this.scoreGranularity = 1,
  });

  static DatasetConfiguration getDefaultFor(DatasetType datasetType) {
    switch (datasetType) {
      case DatasetType.final9x9Area:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 15,
          hideGameInfoBar: true,
        );
      case DatasetType.final19x19Area:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 60,
          hideGameInfoBar: true,
        );
      case DatasetType.midgame19x19Estimation:
        return const DatasetConfiguration(
          thresholdGood: 1.5,
          thresholdClose: 5.0,
          timePerProblemSeconds: 15,
          hideGameInfoBar: false,
        );
      case DatasetType.final9x9AreaVars:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 10,
          hideGameInfoBar: true,
        );
      case DatasetType.partialArea:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 7,
          hideGameInfoBar: false,
        );
    }
  }

  DatasetConfiguration copyWith({
    double? thresholdGood,
    double? thresholdClose,
    int? timePerProblemSeconds,
    bool? hideGameInfoBar,
    int? sequenceLength,
    OwnershipDisplayMode? ownershipDisplayMode,
    bool? timerEnabled,
    PredictionType? predictionType,
    int? scoreGranularity,
  }) {
    return DatasetConfiguration(
      thresholdGood: thresholdGood ?? this.thresholdGood,
      thresholdClose: thresholdClose ?? this.thresholdClose,
      timePerProblemSeconds: timePerProblemSeconds ?? this.timePerProblemSeconds,
      hideGameInfoBar: hideGameInfoBar ?? this.hideGameInfoBar,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      ownershipDisplayMode: ownershipDisplayMode ?? this.ownershipDisplayMode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      predictionType: predictionType ?? this.predictionType,
      scoreGranularity: scoreGranularity ?? this.scoreGranularity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thresholdGood': thresholdGood,
      'thresholdClose': thresholdClose,
      'timePerProblemSeconds': timePerProblemSeconds,
      'hideGameInfoBar': hideGameInfoBar,
      'sequenceLength': sequenceLength,
      'ownershipDisplayMode': ownershipDisplayMode.name,
      'timerEnabled': timerEnabled,
      'predictionType': predictionType.value,
      'scoreGranularity': scoreGranularity,
    };
  }

  static DatasetConfiguration fromJson(Map<String, dynamic> json) {
    OwnershipDisplayMode ownershipDisplayMode = OwnershipDisplayMode.none;
    if (json['ownershipDisplayMode'] != null) {
      try {
        ownershipDisplayMode = OwnershipDisplayMode.values.byName(json['ownershipDisplayMode'] as String);
      } catch (_) {
        ownershipDisplayMode = OwnershipDisplayMode.none;
      }
    }

    return DatasetConfiguration(
      thresholdGood: (json['thresholdGood'] as num?)?.toDouble() ?? 0.0,
      thresholdClose: (json['thresholdClose'] as num?)?.toDouble() ?? 0.0,
      timePerProblemSeconds: json['timePerProblemSeconds'] as int? ?? 30,
      hideGameInfoBar: json['hideGameInfoBar'] as bool? ?? false,
      sequenceLength: json['sequenceLength'] as int? ?? 0,
      ownershipDisplayMode: ownershipDisplayMode,
      timerEnabled: json['timerEnabled'] as bool? ?? true,
      predictionType: PredictionType.fromString(json['predictionType'] as String?) ?? PredictionType.winnerPrediction,
      scoreGranularity: json['scoreGranularity'] as int? ?? 1,
    );
  }

  bool isValidConfiguration() {
    return thresholdClose >= thresholdGood &&
           timePerProblemSeconds > 0 &&
           sequenceLength >= 0 &&
           scoreGranularity > 0;
  }
}