import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/game_result_option.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/auto_advance_mode.dart';
import '../models/scoring_config.dart';
import '../models/positioned_score_options.dart';
import '../models/rough_lead_button_state.dart';
import '../models/training_position.dart';
import '../models/position_type.dart';
import 'result_buttons.dart';
import 'context_aware_result_buttons.dart';
import 'score_display_buttons.dart';
import 'exact_score_buttons.dart';
import 'rough_lead_prediction_buttons.dart';

enum ButtonDisplayMode {
  choices,
  scores,
}

class AdaptiveResultButtons extends StatelessWidget {
  final DatasetType? datasetType;
  final double? actualScore;
  final String? resultString;
  final Function(GameResultOption)? onResultOptionSelected;
  final Function(GameResult)? onResultSelected;
  final Function(int)? onExactScoreButtonPressed; // Takes button position
  final Function(RoughLeadButtonType)? onRoughLeadButtonPressed;
  final VoidCallback? onNextPressed;
  final PositionedScoreOptions? positionedScoreOptions;
  final RoughLeadPredictionState? roughLeadPredictionState;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final ButtonDisplayMode displayMode;
  final bool useColoredBackgroundForScores;
  final int? blackTerritory;
  final int? whiteTerritory;
  final double? komi;
  final TrainingPosition? trainingPosition;
  final PositionType? positionType;
  final double? thresholdGood;
  final double? thresholdClose;

  const AdaptiveResultButtons({
    super.key,
    this.datasetType,
    this.actualScore,
    this.resultString,
    this.onResultOptionSelected,
    this.onResultSelected,
    this.onExactScoreButtonPressed,
    this.onRoughLeadButtonPressed,
    this.onNextPressed,
    this.positionedScoreOptions,
    this.roughLeadPredictionState,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.displayMode = ButtonDisplayMode.choices,
    this.useColoredBackgroundForScores = true,
    this.blackTerritory,
    this.whiteTerritory,
    this.komi,
    this.trainingPosition,
    this.positionType,
    this.thresholdGood,
    this.thresholdClose,
  });

  factory AdaptiveResultButtons.forChoices({
    DatasetType? datasetType,
    double? actualScore,
    String? resultString,
    Function(GameResultOption)? onResultOptionSelected,
    Function(GameResult)? onResultSelected,
    Function(RoughLeadButtonType)? onRoughLeadButtonPressed,
    RoughLeadPredictionState? roughLeadPredictionState,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
    double? thresholdGood,
    double? thresholdClose,
  }) {
    return AdaptiveResultButtons(
      datasetType: datasetType,
      actualScore: actualScore,
      resultString: resultString,
      onResultOptionSelected: onResultOptionSelected,
      onResultSelected: onResultSelected,
      onRoughLeadButtonPressed: onRoughLeadButtonPressed,
      roughLeadPredictionState: roughLeadPredictionState,
      appSkin: appSkin,
      layoutType: layoutType,
      displayMode: ButtonDisplayMode.choices,
      thresholdGood: thresholdGood,
      thresholdClose: thresholdClose,
    );
  }

  factory AdaptiveResultButtons.forExactScores({
    required PositionedScoreOptions positionedScoreOptions,
    required Function(int) onExactScoreButtonPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return AdaptiveResultButtons(
      positionedScoreOptions: positionedScoreOptions,
      onExactScoreButtonPressed: onExactScoreButtonPressed,
      appSkin: appSkin,
      layoutType: layoutType,
      displayMode: ButtonDisplayMode.choices,
    );
  }

  factory AdaptiveResultButtons.forScores({
    required String resultString,
    required VoidCallback onNextPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
    bool useColoredBackgroundForScores = true,
    int? blackTerritory,
    int? whiteTerritory,
    double? komi,
    TrainingPosition? trainingPosition,
    PositionType? positionType,
    DatasetType? datasetType,
  }) {
    return AdaptiveResultButtons(
      resultString: resultString,
      onNextPressed: onNextPressed,
      appSkin: appSkin,
      layoutType: layoutType,
      displayMode: ButtonDisplayMode.scores,
      useColoredBackgroundForScores: useColoredBackgroundForScores,
      blackTerritory: blackTerritory,
      whiteTerritory: whiteTerritory,
      komi: komi,
      trainingPosition: trainingPosition,
      positionType: positionType,
      datasetType: datasetType,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (displayMode) {
      case ButtonDisplayMode.choices:
        return _buildChoiceButtons();
      case ButtonDisplayMode.scores:
        return _buildScoreDisplay();
    }
  }

  Widget _buildChoiceButtons() {
    if (positionedScoreOptions != null && onExactScoreButtonPressed != null) {
      return ExactScoreButtons(
        scoreOptions: positionedScoreOptions!,
        onButtonPressed: onExactScoreButtonPressed!,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (roughLeadPredictionState != null && onRoughLeadButtonPressed != null) {
      return RoughLeadPredictionButtons(
        predictionState: roughLeadPredictionState!,
        onButtonPressed: onRoughLeadButtonPressed!,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (datasetType != null &&
        actualScore != null &&
        resultString != null &&
        onResultOptionSelected != null) {
      return ContextAwareResultButtons(
        datasetType: datasetType!,
        actualScore: actualScore!,
        resultString: resultString!,
        onResultSelected: onResultOptionSelected!,
        appSkin: appSkin,
        layoutType: layoutType,
        thresholdGood: thresholdGood,
        thresholdClose: thresholdClose,
      );
    } else if (onResultSelected != null) {
      return ResultButtons(
        onResultSelected: onResultSelected!,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else {
      return Container();
    }
  }

  Widget _buildScoreDisplay() {
    if (resultString != null && onNextPressed != null) {
      return ScoreDisplayButtons(
        resultString: resultString!,
        onNextPressed: onNextPressed!,
        appSkin: appSkin,
        layoutType: layoutType,
        useColoredBackground: useColoredBackgroundForScores,
        blackTerritory: blackTerritory,
        whiteTerritory: whiteTerritory,
        komi: komi,
        trainingPosition: trainingPosition,
        positionType: positionType,
        datasetType: datasetType,
      );
    } else {
      return Container();
    }
  }
}

class ButtonStateManager {
  final AutoAdvanceMode autoAdvanceMode;
  final bool isAnswerCorrect;
  final bool hasAnswered;
  final bool pausePressed;

  ButtonStateManager({
    required this.autoAdvanceMode,
    required this.isAnswerCorrect,
    required this.hasAnswered,
    this.pausePressed = false,
  });

  ButtonDisplayMode getDisplayMode() {
    if (!hasAnswered) {
      return ButtonDisplayMode.choices;
    }

    // If pause was pressed, always show scores (Next button)
    if (pausePressed) {
      return ButtonDisplayMode.scores;
    }

    switch (autoAdvanceMode) {
      case AutoAdvanceMode.always:
        return ButtonDisplayMode.choices;
      case AutoAdvanceMode.never:
        return ButtonDisplayMode.scores;
      case AutoAdvanceMode.onCorrectOnly:
        return isAnswerCorrect ? ButtonDisplayMode.choices : ButtonDisplayMode.scores;
    }
  }

  bool shouldAutoAdvance() {
    if (!hasAnswered) {
      return false;
    }

    switch (autoAdvanceMode) {
      case AutoAdvanceMode.always:
        return true;
      case AutoAdvanceMode.never:
        return false;
      case AutoAdvanceMode.onCorrectOnly:
        return isAnswerCorrect;
    }
  }
}