import 'package:flutter/material.dart';
import '../../models/go_position.dart';
import '../../models/training_position.dart';
import '../../models/global_configuration.dart';
import '../../models/dataset_configuration.dart';
import '../../models/app_skin.dart';
import '../../models/layout_type.dart';
import '../../models/sequence_display_mode.dart';
import '../../models/board_view_mode.dart';
import '../../models/ownership_display_mode.dart';
import '../../models/position_type.dart';
import '../game_board_container.dart';

/// Board section component for the training screen
/// Contains the game board and related display logic
class TrainingBoardSection extends StatelessWidget {
  final GoPosition currentPosition;
  final TrainingPosition? trainingPosition;
  final GlobalConfiguration? globalConfig;
  final DatasetConfiguration? currentConfig;
  final bool showFeedbackOverlay;
  final bool isCorrectAnswer;

  const TrainingBoardSection({
    super.key,
    required this.currentPosition,
    this.trainingPosition,
    required this.globalConfig,
    required this.currentConfig,
    required this.showFeedbackOverlay,
    required this.isCorrectAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final currentSkin = globalConfig?.appSkin ?? AppSkin.classic;
    // Note: themeProvider is created inside GameBoardContainer

    // Determine board view mode based on current state
    BoardViewMode viewMode;
    if (showFeedbackOverlay) {
      viewMode = BoardViewMode.review; // Use review mode for feedback
    } else {
      viewMode = BoardViewMode.problem;
    }

    return GameBoardContainer(
      position: currentPosition,
      trainingPosition: trainingPosition,
      appSkin: currentSkin,
      layoutType: globalConfig?.layoutType ?? LayoutType.vertical,
      sequenceLength: currentConfig?.sequenceLength ?? 0,
      sequenceDisplayMode: globalConfig?.sequenceDisplayMode ?? SequenceDisplayMode.numbersOnly,
      viewMode: viewMode,
      ownershipDisplayMode: globalConfig?.ownershipDisplayMode ?? OwnershipDisplayMode.none,
      positionType: currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
      showMoveNumbers: globalConfig?.showMoveNumbers ?? true,
    );
  }
}