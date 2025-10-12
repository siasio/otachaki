import 'dataset_type.dart';
import 'ownership_display_mode.dart';
import 'prediction_type.dart';
import 'position_type.dart';
import 'auto_advance_mode.dart';
import 'game_stage.dart';

class DatasetConfiguration {
  final double thresholdGood;
  final double thresholdClose;
  final int timePerProblemSeconds;
  // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
  // final bool hideGameInfoBar;
  final int sequenceLength;
  final OwnershipDisplayMode ownershipDisplayMode;
  final bool timerEnabled;
  final PredictionType predictionType;
  final int scoreGranularity;
  final PositionType positionType;
  final bool showMoveNumbers;
  final AutoAdvanceMode autoAdvanceMode;
  final GameStage gameStage;

  const DatasetConfiguration({
    required this.thresholdGood,
    required this.thresholdClose,
    required this.timePerProblemSeconds,
    // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
    // required this.hideGameInfoBar,
    this.sequenceLength = 0,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.timerEnabled = true,
    this.predictionType = PredictionType.winnerPrediction,
    this.scoreGranularity = 2,
    this.positionType = PositionType.withFilledNeutralPoints,
    this.showMoveNumbers = true,
    this.autoAdvanceMode = AutoAdvanceMode.always,
    this.gameStage = GameStage.all,
  });

  static DatasetConfiguration getDefaultFor(DatasetType datasetType) {
    switch (datasetType) {
      case DatasetType.final9x9:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 20,
          predictionType: PredictionType.winnerPrediction,
          positionType: PositionType.withFilledNeutralPoints,
          ownershipDisplayMode: OwnershipDisplayMode.squares,
          autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        );
      case DatasetType.final13x13:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 45,
          timerEnabled: false,
          predictionType: PredictionType.exactScorePrediction,
          scoreGranularity: 2,
          positionType: PositionType.beforeFillingNeutralPoints,
          sequenceLength: 0,
          showMoveNumbers: true,
          autoAdvanceMode: AutoAdvanceMode.never,
        );
      case DatasetType.final19x19:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 90,
          predictionType: PredictionType.winnerPrediction,
          positionType: PositionType.beforeFillingNeutralPoints,
          sequenceLength: 9,
          showMoveNumbers: true,
          autoAdvanceMode: AutoAdvanceMode.never,
        );
      case DatasetType.midgame19x19:
        return const DatasetConfiguration(
          thresholdGood: 3.0,
          thresholdClose: 7.0,
          timePerProblemSeconds: 30,
          predictionType: PredictionType.roughLeadPrediction,
          sequenceLength: 5,
          ownershipDisplayMode: OwnershipDisplayMode.squares,
          gameStage: GameStage.all,
          autoAdvanceMode: AutoAdvanceMode.always,
        );
      case DatasetType.partialPositions:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 10,
          // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
          // hideGameInfoBar: false,
          predictionType: PredictionType.winnerPrediction,
        );
    }
  }

  DatasetConfiguration copyWith({
    double? thresholdGood,
    double? thresholdClose,
    int? timePerProblemSeconds,
    // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
    // bool? hideGameInfoBar,
    int? sequenceLength,
    OwnershipDisplayMode? ownershipDisplayMode,
    bool? timerEnabled,
    PredictionType? predictionType,
    int? scoreGranularity,
    PositionType? positionType,
    bool? showMoveNumbers,
    AutoAdvanceMode? autoAdvanceMode,
    GameStage? gameStage,
  }) {
    return DatasetConfiguration(
      thresholdGood: thresholdGood ?? this.thresholdGood,
      thresholdClose: thresholdClose ?? this.thresholdClose,
      timePerProblemSeconds: timePerProblemSeconds ?? this.timePerProblemSeconds,
      // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
      // hideGameInfoBar: hideGameInfoBar ?? this.hideGameInfoBar,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      ownershipDisplayMode: ownershipDisplayMode ?? this.ownershipDisplayMode,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      predictionType: predictionType ?? this.predictionType,
      scoreGranularity: scoreGranularity ?? this.scoreGranularity,
      positionType: positionType ?? this.positionType,
      showMoveNumbers: showMoveNumbers ?? this.showMoveNumbers,
      autoAdvanceMode: autoAdvanceMode ?? this.autoAdvanceMode,
      gameStage: gameStage ?? this.gameStage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thresholdGood': thresholdGood,
      'thresholdClose': thresholdClose,
      'timePerProblemSeconds': timePerProblemSeconds,
      // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
      // 'hideGameInfoBar': hideGameInfoBar,
      'sequenceLength': sequenceLength,
      'ownershipDisplayMode': ownershipDisplayMode.name,
      'timerEnabled': timerEnabled,
      'predictionType': predictionType.value,
      'scoreGranularity': scoreGranularity,
      'positionType': positionType.value,
      'showMoveNumbers': showMoveNumbers,
      'autoAdvanceMode': autoAdvanceMode.value,
      'gameStage': gameStage.value,
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
      // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
      // hideGameInfoBar: json['hideGameInfoBar'] as bool? ?? false,
      sequenceLength: json['sequenceLength'] as int? ?? 0,
      ownershipDisplayMode: ownershipDisplayMode,
      timerEnabled: json['timerEnabled'] as bool? ?? true,
      predictionType: PredictionType.fromString(json['predictionType'] as String?) ?? PredictionType.winnerPrediction,
      scoreGranularity: json['scoreGranularity'] as int? ?? 2,
      positionType: PositionType.fromString(json['positionType'] as String?) ?? PositionType.withFilledNeutralPoints,
      showMoveNumbers: json['showMoveNumbers'] as bool? ?? true,
      autoAdvanceMode: AutoAdvanceMode.fromString(json['autoAdvanceMode'] as String?),
      gameStage: GameStage.fromString(json['gameStage'] as String?),
    );
  }

  bool isValidConfiguration() {
    return thresholdClose >= thresholdGood &&
           timePerProblemSeconds > 0 &&
           sequenceLength >= 0 &&
           scoreGranularity > 0;
  }
}