import 'package:flutter/material.dart';
import '../models/go_position.dart';
import '../models/training_position.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/sequence_display_mode.dart';
import '../models/board_view_mode.dart';
import '../models/ownership_display_mode.dart';
import '../models/position_type.dart';
import '../models/sequence_visualization_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../core/go_logic.dart';
import 'go_board.dart';
import 'move_sequence_dot_animator.dart';

/// A container widget that encapsulates the Go board with consistent overlay behavior
/// and stable sizing across different layout modes.
class GameBoardContainer extends StatefulWidget {
  final GoPosition position;
  final TrainingPosition? trainingPosition;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final bool showFeedbackOverlay;
  final Widget? feedbackWidget;
  final int sequenceLength;
  final SequenceDisplayMode sequenceDisplayMode;
  final BoardViewMode viewMode;
  final OwnershipDisplayMode ownershipDisplayMode;
  final PositionType positionType;
  final bool showMoveNumbers;
  final bool isSequenceLengthDefined;
  final bool shouldAnimateDots;
  final SequenceVisualizationType sequenceVisualization;
  final double initialTimeSeconds;
  final double timePerMoveSeconds;
  final VoidCallback? onDotAnimationComplete;

  const GameBoardContainer({
    super.key,
    required this.position,
    this.trainingPosition,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.showFeedbackOverlay = false,
    this.feedbackWidget,
    this.sequenceLength = 0,
    this.sequenceDisplayMode = SequenceDisplayMode.numbersOnly,
    this.viewMode = BoardViewMode.problem,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.positionType = PositionType.withFilledNeutralPoints,
    this.showMoveNumbers = true,
    this.isSequenceLengthDefined = false,
    this.shouldAnimateDots = false,
    this.sequenceVisualization = SequenceVisualizationType.numbers,
    this.initialTimeSeconds = 1.0,
    this.timePerMoveSeconds = 1.0,
    this.onDotAnimationComplete,
  });

  @override
  State<GameBoardContainer> createState() => _GameBoardContainerState();
}

class _GameBoardContainerState extends State<GameBoardContainer> {
  double? _cachedBoardSize;

  @override
  Widget build(BuildContext context) {
    final shouldGrayOutBoard = true;
    final themeProvider = UnifiedThemeProvider(skin: widget.appSkin, layoutType: widget.layoutType);
    final overlayColor = themeProvider.getElementStyle(UIElement.boardOverlay).backgroundColor!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only recalculate board size when the overlay is not showing to prevent jumping
        if (_cachedBoardSize == null || !widget.showFeedbackOverlay) {
          // Calculate optimal board size to maintain 1:1 aspect ratio
          final availableSize = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          // Account for reduced margins and ensure minimum size
          _cachedBoardSize = (availableSize - 8).clamp(200.0, double.infinity);
        }

        return Center(
          child: SizedBox(
            width: _cachedBoardSize!,
            height: _cachedBoardSize!,
            child: Stack(
              children: [
                // The Go board itself with optional theme-aware overlay
                shouldGrayOutBoard && widget.showFeedbackOverlay
                    ? ColorFiltered(
                        colorFilter: widget.appSkin == AppSkin.eink
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                            : ColorFilter.mode(overlayColor.withOpacity(0.3), BlendMode.multiply),
                        child: GoBoard(
                          position: widget.position,
                          trainingPosition: widget.trainingPosition,
                          appSkin: widget.appSkin,
                          layoutType: widget.layoutType,
                          sequenceLength: widget.sequenceLength,
                          sequenceDisplayMode: widget.sequenceDisplayMode,
                          viewMode: widget.viewMode,
                          ownershipDisplayMode: widget.ownershipDisplayMode,
                          positionType: widget.positionType,
                          showMoveNumbers: widget.showMoveNumbers,
                          isSequenceLengthDefined: widget.isSequenceLengthDefined,
                          sequenceVisualization: widget.sequenceVisualization,
                          shouldAnimateDots: widget.shouldAnimateDots,
                          initialTimeSeconds: widget.initialTimeSeconds,
                          timePerMoveSeconds: widget.timePerMoveSeconds,
                          onDotAnimationComplete: widget.onDotAnimationComplete,
                        ),
                      )
                    : GoBoard(
                        position: widget.position,
                        trainingPosition: widget.trainingPosition,
                        appSkin: widget.appSkin,
                        layoutType: widget.layoutType,
                        sequenceLength: widget.sequenceLength,
                        sequenceDisplayMode: widget.sequenceDisplayMode,
                        viewMode: widget.viewMode,
                        ownershipDisplayMode: widget.ownershipDisplayMode,
                        positionType: widget.positionType,
                        showMoveNumbers: widget.showMoveNumbers,
                        isSequenceLengthDefined: widget.isSequenceLengthDefined,
                        sequenceVisualization: widget.sequenceVisualization,
                        shouldAnimateDots: widget.shouldAnimateDots,
                        initialTimeSeconds: widget.initialTimeSeconds,
                        timePerMoveSeconds: widget.timePerMoveSeconds,
                        onDotAnimationComplete: widget.onDotAnimationComplete,
                      ),
                // Overlay for feedback widget only (no background color)
                if (widget.showFeedbackOverlay && widget.feedbackWidget != null)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Center(child: widget.feedbackWidget!),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}