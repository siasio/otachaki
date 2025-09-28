import 'package:flutter/material.dart';
import '../models/go_position.dart';
import '../models/training_position.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/sequence_display_mode.dart';
import '../models/board_view_mode.dart';
import '../models/ownership_display_mode.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import 'go_board.dart';

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

          // Account for margins and ensure minimum size
          _cachedBoardSize = (availableSize - 32).clamp(200.0, double.infinity);
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