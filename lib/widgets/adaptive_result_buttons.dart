import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/game_result_option.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/auto_advance_mode.dart';
import '../models/scoring_config.dart';
import '../models/positioned_score_options.dart';
import '../models/rough_lead_button_state.dart';
import '../models/black_territory_options.dart';
import '../models/both_territories_state.dart';
import '../models/training_position.dart';
import '../models/position_type.dart';
import 'score_display_buttons.dart';
import 'universal_result_button.dart';

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
  final Function(int)? onBlackTerritoryButtonPressed; // Takes button position
  final Function(RoughLeadButtonType)? onRoughLeadButtonPressed;
  final Function(int, bool)? onBothTerritoriesButtonPressed; // Takes position and isBlackRow
  final VoidCallback? onNextPressed;
  final PositionedScoreOptions? positionedScoreOptions;
  final BlackTerritoryOptions? blackTerritoryOptions;
  final BothTerritoriesState? bothTerritoriesState;
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
  final bool noPaddingForScores;

  const AdaptiveResultButtons({
    super.key,
    this.datasetType,
    this.actualScore,
    this.resultString,
    this.onResultOptionSelected,
    this.onResultSelected,
    this.onExactScoreButtonPressed,
    this.onBlackTerritoryButtonPressed,
    this.onRoughLeadButtonPressed,
    this.onBothTerritoriesButtonPressed,
    this.onNextPressed,
    this.positionedScoreOptions,
    this.blackTerritoryOptions,
    this.bothTerritoriesState,
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
    this.noPaddingForScores = false,
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

  factory AdaptiveResultButtons.forBlackTerritory({
    required BlackTerritoryOptions blackTerritoryOptions,
    required Function(int) onBlackTerritoryButtonPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return AdaptiveResultButtons(
      blackTerritoryOptions: blackTerritoryOptions,
      onBlackTerritoryButtonPressed: onBlackTerritoryButtonPressed,
      appSkin: appSkin,
      layoutType: layoutType,
      displayMode: ButtonDisplayMode.choices,
    );
  }

  factory AdaptiveResultButtons.forBothTerritories({
    required BothTerritoriesState bothTerritoriesState,
    required Function(int, bool) onBothTerritoriesButtonPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return AdaptiveResultButtons(
      bothTerritoriesState: bothTerritoriesState,
      onBothTerritoriesButtonPressed: onBothTerritoriesButtonPressed,
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
    bool noPadding = false,
    bool useTwoRowLayout = false,
  }) {
    return AdaptiveResultButtons(
      resultString: resultString,
      onNextPressed: onNextPressed,
      appSkin: appSkin,
      layoutType: layoutType,
      displayMode: useTwoRowLayout ? ButtonDisplayMode.choices : ButtonDisplayMode.scores,
      useColoredBackgroundForScores: useColoredBackgroundForScores,
      blackTerritory: blackTerritory,
      whiteTerritory: whiteTerritory,
      komi: komi,
      trainingPosition: trainingPosition,
      positionType: positionType,
      datasetType: datasetType,
      noPaddingForScores: noPadding,
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
      // Exact score buttons
      final buttons = positionedScoreOptions!.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isCorrect = index == positionedScoreOptions!.correctButtonPosition;
        return UniversalResultButton.exactScore(
          scoreText: option.scoreText,
          onPressed: () => onExactScoreButtonPressed!(index),
          isCorrect: isCorrect,
          appSkin: appSkin,
          layoutType: layoutType,
          buttonPosition: index,
        );
      }).toList();

      return UniversalResultButtonGroup(
        buttons: buttons,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (blackTerritoryOptions != null && onBlackTerritoryButtonPressed != null) {
      // Black territory buttons
      final buttons = blackTerritoryOptions!.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isCorrect = index == blackTerritoryOptions!.correctButtonPosition;
        return UniversalResultButton.exactScore(
          scoreText: option.territoryText,
          onPressed: () => onBlackTerritoryButtonPressed!(index),
          isCorrect: isCorrect,
          appSkin: appSkin,
          layoutType: layoutType,
          buttonPosition: index,
        );
      }).toList();

      return UniversalResultButtonGroup(
        buttons: buttons,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (bothTerritoriesState != null && onBothTerritoriesButtonPressed != null) {
      // Both territories buttons
      if (layoutType == LayoutType.horizontal) {
        // Horizontal mode: Two columns (Black left, White right)
        return Row(
          children: [
            // Black territory column (keys 1, 2, 3)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: bothTerritoriesState!.blackButtons.map((button) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: UniversalResultButton(
                        displayText: button.displayText,
                        onPressed: () => onBothTerritoriesButtonPressed!(button.buttonPosition, true),
                        isCorrect: button.isCorrect,
                        isPressed: button.wasPressed,
                        buttonType: UniversalButtonType.exactScore,
                        appSkin: appSkin,
                        layoutType: layoutType,
                        showCorrectnessFeedback: false,
                        keyText: _getKeyTextForBothTerritoriesPosition(button.buttonPosition, true),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            // White territory column (keys 4, 5, 6)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: bothTerritoriesState!.whiteButtons.map((button) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: UniversalResultButton(
                        displayText: button.displayText,
                        onPressed: () => onBothTerritoriesButtonPressed!(button.buttonPosition, false),
                        isCorrect: button.isCorrect,
                        isPressed: button.wasPressed,
                        buttonType: UniversalButtonType.exactScore,
                        appSkin: appSkin,
                        layoutType: layoutType,
                        showCorrectnessFeedback: false,
                        keyText: _getKeyTextForBothTerritoriesPosition(button.buttonPosition, false),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      } else {
        // Vertical mode: Two rows (Black top, White bottom)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Black territory row (keys 1, 2, 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bothTerritoriesState!.blackButtons.map((button) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: UniversalResultButton(
                      displayText: button.displayText,
                      onPressed: () => onBothTerritoriesButtonPressed!(button.buttonPosition, true),
                      isCorrect: button.isCorrect,
                      isPressed: button.wasPressed,
                      buttonType: UniversalButtonType.exactScore,
                      appSkin: appSkin,
                      layoutType: layoutType,
                      showCorrectnessFeedback: false,
                      keyText: _getKeyTextForBothTerritoriesPosition(button.buttonPosition, true),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // White territory row (keys 4, 5, 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bothTerritoriesState!.whiteButtons.map((button) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: UniversalResultButton(
                      displayText: button.displayText,
                      onPressed: () => onBothTerritoriesButtonPressed!(button.buttonPosition, false),
                      isCorrect: button.isCorrect,
                      isPressed: button.wasPressed,
                      buttonType: UniversalButtonType.exactScore,
                      appSkin: appSkin,
                      layoutType: layoutType,
                      showCorrectnessFeedback: false,
                      keyText: _getKeyTextForBothTerritoriesPosition(button.buttonPosition, false),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }
    } else if (roughLeadPredictionState != null && onRoughLeadButtonPressed != null) {
      // Rough lead prediction buttons
      final buttons = roughLeadPredictionState!.buttons.map((buttonState) {
        return UniversalResultButton.roughLead(
          buttonState: buttonState,
          onPressed: () => onRoughLeadButtonPressed!(buttonState.buttonType),
          appSkin: appSkin,
          layoutType: layoutType,
        );
      }).toList();

      return UniversalResultButtonGroup(
        buttons: buttons,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (datasetType != null &&
        actualScore != null &&
        resultString != null &&
        onResultOptionSelected != null) {
      // Context-aware buttons (dataset-specific logic)
      final options = GameResultOption.generateOptions(
        datasetType!,
        actualScore!,
        resultString!,
        thresholdGood: thresholdGood,
        thresholdClose: thresholdClose,
      );

      final buttons = options.map((option) {
        return UniversalResultButton.contextAware(
          option: option,
          onPressed: () => onResultOptionSelected!(option),
          appSkin: appSkin,
          layoutType: layoutType,
        );
      }).toList();

      return UniversalResultButtonGroup(
        buttons: buttons,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else if (onResultSelected != null) {
      // Basic result buttons (White/Draw/Black)
      final buttons = [
        UniversalResultButton.basic(
          text: 'White Wins',
          onPressed: () => onResultSelected!(GameResult.whiteWins),
          buttonType: ButtonType.whiteWins,
          appSkin: appSkin,
          layoutType: layoutType,
        ),
        UniversalResultButton.basic(
          text: 'Draw',
          onPressed: () => onResultSelected!(GameResult.draw),
          buttonType: ButtonType.draw,
          appSkin: appSkin,
          layoutType: layoutType,
        ),
        UniversalResultButton.basic(
          text: 'Black Wins',
          onPressed: () => onResultSelected!(GameResult.blackWins),
          buttonType: ButtonType.blackWins,
          appSkin: appSkin,
          layoutType: layoutType,
        ),
      ];

      return UniversalResultButtonGroup(
        buttons: buttons,
        appSkin: appSkin,
        layoutType: layoutType,
      );
    } else {
      return Container();
    }
  }

  IconData? _getIconForPosition(int position) {
    switch (position) {
      case 0:
        return Icons.arrow_back; // Left
      case 1:
        return Icons.arrow_downward; // Middle
      case 2:
        return Icons.arrow_forward; // Right
      default:
        return null;
    }
  }

  String? _getKeyTextForBothTerritoriesPosition(int position, bool isBlackRow) {
    if (isBlackRow) {
      // Black territory row uses keys 1, 2, 3
      switch (position) {
        case 0:
          return '1';
        case 1:
          return '2';
        case 2:
          return '3';
        default:
          return null;
      }
    } else {
      // White territory row uses keys 4, 5, 6
      switch (position) {
        case 0:
          return '4';
        case 1:
          return '5';
        case 2:
          return '6';
        default:
          return null;
      }
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
        noPadding: noPaddingForScores,
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