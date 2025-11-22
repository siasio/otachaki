import 'dataset_type.dart';
import 'ownership_display_mode.dart';
import 'prediction_type.dart';
import 'position_type.dart';
import 'auto_advance_mode.dart';
import 'game_stage.dart';
import 'problem_feedback_type.dart';
import 'sequence_visualization_type.dart';

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
  final SequenceVisualizationType sequenceVisualization;
  final double timePerMoveSeconds;
  final double initialTimeSeconds;
  final AutoAdvanceMode autoAdvanceMode;
  final GameStage gameStage;
  final ProblemFeedbackType problemFeedbackType;

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
    this.sequenceVisualization = SequenceVisualizationType.numbers,
    this.timePerMoveSeconds = 1.0,
    this.initialTimeSeconds = 1.0,
    this.autoAdvanceMode = AutoAdvanceMode.always,
    this.gameStage = GameStage.all,
    this.problemFeedbackType = ProblemFeedbackType.result,
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
          problemFeedbackType: ProblemFeedbackType.result,
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
          sequenceVisualization: SequenceVisualizationType.numbers,
          timePerMoveSeconds: 1.0,
          initialTimeSeconds: 1.0,
          autoAdvanceMode: AutoAdvanceMode.never,
          problemFeedbackType: ProblemFeedbackType.resultWithTime,
        );
      case DatasetType.final19x19:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 90,
          predictionType: PredictionType.winnerPrediction,
          positionType: PositionType.beforeFillingNeutralPoints,
          sequenceLength: 0,
          sequenceVisualization: SequenceVisualizationType.numbers,
          timePerMoveSeconds: 1.0,
          initialTimeSeconds: 1.0,
          autoAdvanceMode: AutoAdvanceMode.never,
          problemFeedbackType: ProblemFeedbackType.resultWithSpeed,
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
          problemFeedbackType: ProblemFeedbackType.result,
        );
      case DatasetType.partialPositions:
        return const DatasetConfiguration(
          thresholdGood: 0.0,
          thresholdClose: 0.0,
          timePerProblemSeconds: 10,
          // REMOVED: hideGameInfoBar - GameInfo functionality has been removed
          // hideGameInfoBar: false,
          predictionType: PredictionType.winnerPrediction,
          problemFeedbackType: ProblemFeedbackType.result,
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
    SequenceVisualizationType? sequenceVisualization,
    double? timePerMoveSeconds,
    double? initialTimeSeconds,
    AutoAdvanceMode? autoAdvanceMode,
    GameStage? gameStage,
    ProblemFeedbackType? problemFeedbackType,
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
      sequenceVisualization: sequenceVisualization ?? this.sequenceVisualization,
      timePerMoveSeconds: timePerMoveSeconds ?? this.timePerMoveSeconds,
      initialTimeSeconds: initialTimeSeconds ?? this.initialTimeSeconds,
      autoAdvanceMode: autoAdvanceMode ?? this.autoAdvanceMode,
      gameStage: gameStage ?? this.gameStage,
      problemFeedbackType: problemFeedbackType ?? this.problemFeedbackType,
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
      'sequenceVisualization': sequenceVisualization.value,
      'timePerMoveSeconds': timePerMoveSeconds,
      'initialTimeSeconds': initialTimeSeconds,
      'autoAdvanceMode': autoAdvanceMode.value,
      'gameStage': gameStage.value,
      'problemFeedbackType': problemFeedbackType.value,
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
      sequenceVisualization: SequenceVisualizationType.fromString(json['sequenceVisualization'] as String?) ?? 
          (json['showMoveNumbers'] as bool? ?? true ? SequenceVisualizationType.numbers : SequenceVisualizationType.dontShow),
      timePerMoveSeconds: (json['timePerMoveSeconds'] as num?)?.toDouble() ?? 1.0,
      initialTimeSeconds: (json['initialTimeSeconds'] as num?)?.toDouble() ?? 1.0,
      autoAdvanceMode: AutoAdvanceMode.fromString(json['autoAdvanceMode'] as String?),
      gameStage: GameStage.fromString(json['gameStage'] as String?),
      problemFeedbackType: ProblemFeedbackType.fromString(json['problemFeedbackType'] as String?) ?? ProblemFeedbackType.result,
    );
  }

  bool isValidConfiguration() {
    return thresholdClose >= thresholdGood &&
           timePerProblemSeconds > 0 &&
           sequenceLength >= 0 &&
           scoreGranularity > 0;
  }
}