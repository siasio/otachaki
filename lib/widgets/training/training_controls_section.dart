import 'package:flutter/material.dart';
import '../../models/global_configuration.dart';
import '../../models/dataset_configuration.dart';
import '../../models/positioned_score_options.dart';
import '../../models/rough_lead_button_state.dart';
import '../../models/game_result_option.dart';
import '../../models/prediction_type.dart';
import '../../models/auto_advance_mode.dart';
import '../../widgets/adaptive_result_buttons.dart';
import '../../widgets/pause_button.dart';
import '../../models/button_state_manager.dart';

/// Controls section component for the training screen
/// Handles result buttons, pause button, and next button
class TrainingControlsSection extends StatelessWidget {
  final GlobalConfiguration? globalConfig;
  final DatasetConfiguration? currentConfig;
  final PositionedScoreOptions? currentScoreOptions;
  final RoughLeadPredictionState? currentRoughLeadState;
  final bool showFeedbackOverlay;
  final bool isCorrectAnswer;
  final bool hasAnswered;
  final bool pausePressed;
  final bool waitingForNext;
  final Function(GameResultOption) onResultOptionSelected;
  final Function(int) onExactScoreButtonPressed;
  final Function(RoughLeadButtonType) onRoughLeadButtonPressed;
  final VoidCallback onPausePressed;
  final VoidCallback onNextPressed;

  const TrainingControlsSection({
    super.key,
    required this.globalConfig,
    required this.currentConfig,
    required this.currentScoreOptions,
    required this.currentRoughLeadState,
    required this.showFeedbackOverlay,
    required this.isCorrectAnswer,
    required this.hasAnswered,
    required this.pausePressed,
    required this.waitingForNext,
    required this.onResultOptionSelected,
    required this.onExactScoreButtonPressed,
    required this.onRoughLeadButtonPressed,
    required this.onPausePressed,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    final predictionType = currentConfig?.predictionType ?? PredictionType.winnerPrediction;

    return Column(
      children: [
        // Result buttons
        AdaptiveResultButtons(
          globalConfig: globalConfig,
          currentConfig: currentConfig,
          currentScoreOptions: currentScoreOptions,
          currentRoughLeadState: currentRoughLeadState,
          onResultOptionSelected: onResultOptionSelected,
          onExactScoreButtonPressed: onExactScoreButtonPressed,
          onRoughLeadButtonPressed: onRoughLeadButtonPressed,
        ),

        const SizedBox(height: 8),

        // Control buttons section
        _buildControlButtons(context),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final autoAdvanceMode = globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: isCorrectAnswer,
      hasAnswered: hasAnswered,
      pausePressed: pausePressed,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause button (conditional)
        if (showFeedbackOverlay && stateManager.shouldAutoAdvance() && !pausePressed)
          PauseButton(
            appSkin: globalConfig?.appSkin,
            layoutType: globalConfig?.layoutType,
            onPressed: onPausePressed,
          ),

        // Next button (conditional)
        if (waitingForNext || (showFeedbackOverlay && pausePressed))
          ElevatedButton(
            onPressed: onNextPressed,
            child: const Text('Next'),
          ),
      ],
    );
  }
}