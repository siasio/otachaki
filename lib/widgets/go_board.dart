import 'package:flutter/material.dart';
import '../models/go_position.dart';
import '../models/training_position.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/sequence_display_mode.dart';
import '../models/sequence_visualization_type.dart';
import '../models/board_view_mode.dart';
import '../models/ownership_display_mode.dart';
import '../models/position_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../core/go_logic.dart';
import 'move_sequence_dot_animator.dart';

class GoBoard extends StatelessWidget {
  final GoPosition position;
  final TrainingPosition? trainingPosition;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final int sequenceLength;
  final SequenceDisplayMode sequenceDisplayMode;
  final BoardViewMode viewMode;
  final OwnershipDisplayMode ownershipDisplayMode;
  final PositionType positionType;
  final bool showMoveNumbers;
  final bool isSequenceLengthDefined;
  final SequenceVisualizationType sequenceVisualization;
  final bool shouldAnimateDots;
  final double initialTimeSeconds;
  final double timePerMoveSeconds;
  final VoidCallback? onDotAnimationComplete;

  const GoBoard({
    super.key,
    required this.position,
    this.trainingPosition,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.sequenceLength = 0,
    this.sequenceDisplayMode = SequenceDisplayMode.numbersOnly,
    this.viewMode = BoardViewMode.problem,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.positionType = PositionType.withFilledNeutralPoints,
    this.showMoveNumbers = true,
    this.isSequenceLengthDefined = false,
    this.sequenceVisualization = SequenceVisualizationType.numbers,
    this.shouldAnimateDots = false,
    this.initialTimeSeconds = 1.0,
    this.timePerMoveSeconds = 1.0,
    this.onDotAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final boardStyle = themeProvider.getElementStyle(UIElement.boardBackground);

    // Check if we need to show dot animation
    // Only show animator while actively animating dots
    final shouldShowAnimator = shouldAnimateDots &&
        sequenceVisualization == SequenceVisualizationType.dots &&
        sequenceLength > 0 &&
        trainingPosition != null;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: boardStyle.margin,
        decoration: themeProvider.getContainerDecoration(UIElement.boardBackground),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate board parameters for dot animator
            final boardDisplay = trainingPosition?.gameInfo?.boardDisplay;
            final int displayWidth = boardDisplay?.cropWidth ?? position.size;
            final double cellSize = constraints.maxWidth / (displayWidth + 1);
            final double boardStart = cellSize;
            final int displayStartRow = boardDisplay?.cropStartRow ?? 0;
            final int displayStartCol = boardDisplay?.cropStartCol ?? 0;

            return Stack(
              children: [
                // Base board
                CustomPaint(
                  painter: GoBoardPainter(
                    position,
                    trainingPosition,
                    themeProvider,
                    sequenceLength,
                    sequenceDisplayMode,
                    viewMode,
                    ownershipDisplayMode,
                    positionType,
                    showMoveNumbers,
                    isSequenceLengthDefined,
                    sequenceVisualization,
                  ),
                  size: Size.infinite,
                ),
                // Dot animator overlay - only shown while actively animating
                if (shouldShowAnimator)
                  MoveSequenceDotAnimator(
                    sequence: trainingPosition!.extractMoveSequenceWithType(
                      sequenceLength,
                      positionType,
                      showMoveNumbers,
                      viewMode,
                    ),
                    initialTimeSeconds: initialTimeSeconds,
                    timePerMoveSeconds: timePerMoveSeconds,
                    onAnimationComplete: onDotAnimationComplete,
                    cellSize: cellSize,
                    boardStart: boardStart,
                    displayStartRow: displayStartRow,
                    displayStartCol: displayStartCol,
                    dotColor: themeProvider.getElementStyle(UIElement.boardGridLines).color!,
                    hasLastMoveMarker: sequenceLength > 0 && isSequenceLengthDefined,
                    lastMoveData: sequenceLength > 0 && isSequenceLengthDefined && trainingPosition != null
                        ? _getLastMoveAsSequenceData(trainingPosition!)
                        : null,
                    position: position,
                    stoneRadius: cellSize * 0.4,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Helper to get last move marker position as MoveSequenceData
  MoveSequenceData? _getLastMoveAsSequenceData(TrainingPosition tp) {
    final pos = tp.getTriangleMarkerPosition(sequenceLength, isSequenceLengthDefined);
    if (pos == null) return null;
    return MoveSequenceData(row: pos.row, col: pos.col, moveNumber: 0);
  }
}

class GoBoardPainter extends CustomPainter {
  final GoPosition position;
  final TrainingPosition? trainingPosition;
  final UnifiedThemeProvider themeProvider;
  final int sequenceLength;
  final SequenceDisplayMode sequenceDisplayMode;
  final BoardViewMode viewMode;
  final OwnershipDisplayMode ownershipDisplayMode;
  final PositionType positionType;
  final bool showMoveNumbers;
  final bool isSequenceLengthDefined;
  final SequenceVisualizationType sequenceVisualization;

  GoBoardPainter(
    this.position,
    this.trainingPosition,
    this.themeProvider,
    this.sequenceLength,
    this.sequenceDisplayMode,
    this.viewMode,
    this.ownershipDisplayMode,
    this.positionType,
    this.showMoveNumbers,
    this.isSequenceLengthDefined,
    this.sequenceVisualization,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final gridStyle = themeProvider.getElementStyle(UIElement.boardGridLines);
    final paint = Paint()
      ..color = gridStyle.color!
      ..strokeWidth = gridStyle.strokeWidth!;

    // Determine board display area
    final boardDisplay = trainingPosition?.gameInfo?.boardDisplay;
    final int displayStartRow = boardDisplay?.cropStartRow ?? 0;
    final int displayStartCol = boardDisplay?.cropStartCol ?? 0;
    final int displayWidth = boardDisplay?.cropWidth ?? position.size;
    final int displayHeight = boardDisplay?.cropHeight ?? position.size;

    final double cellSize = size.width / (displayWidth + 1);
    final double boardStart = cellSize;

    // Draw grid lines with proper intersection handling for cropped boards
    _drawGridLines(canvas, size, boardStart, cellSize, displayStartRow, displayStartCol,
                   displayWidth, displayHeight, paint);

    // Draw star points based on board size (only if visible in crop)
    List<int>? starPoints;
    if (position.size == 19) {
      starPoints = [3, 9, 15];
    } else if (position.size == 13) {
      starPoints = [3, 6, 9];
    } else if (position.size == 9) {
      starPoints = [2, 4, 6];
    }

    if (starPoints != null) {
      final starStyle = themeProvider.getElementStyle(UIElement.boardStarPoints);
      final starPaint = Paint()
        ..color = starStyle.color!
        ..style = PaintingStyle.fill;

      for (int row in starPoints) {
        for (int col in starPoints) {
          if (row >= displayStartRow && row < displayStartRow + displayHeight &&
              col >= displayStartCol && col < displayStartCol + displayWidth) {
            final double x = boardStart + (col - displayStartCol) * cellSize;
            final double y = boardStart + (row - displayStartRow) * cellSize;
            canvas.drawCircle(Offset(x, y), 3, starPaint);
          }
        }
      }
    }

    // Get sequence moves if available (using position-type-aware method)
    final List<MoveSequenceData> sequenceMoves = trainingPosition != null
        ? trainingPosition!.extractMoveSequenceWithType(sequenceLength, positionType, showMoveNumbers, viewMode)
        : [];

    // Get last move before sequence for marker (using unified defined/undefined logic)
    final Position? lastMovePosition = trainingPosition != null
        ? trainingPosition!.getTriangleMarkerPosition(sequenceLength, isSequenceLengthDefined)
        : null;

    // Create a set of sequence positions for quick lookup
    final Set<String> sequencePositions = sequenceMoves
        .map((move) => '${move.row},${move.col}')
        .toSet();

    // Draw stones
    final double stoneRadius = cellSize * 0.4;

    for (int row = displayStartRow; row < displayStartRow + displayHeight && row < position.size; row++) {
      for (int col = displayStartCol; col < displayStartCol + displayWidth && col < position.size; col++) {
        final stone = position.board[row][col];
        final positionKey = '$row,$col';
        final isSequencePosition = sequencePositions.contains(positionKey);

        // Determine if we should draw the stone based on view mode
        bool shouldDrawStone = stone != StoneColor.empty;

        // In problem view, hide stones where sequence numbers should appear
        if (viewMode == BoardViewMode.problem &&
            isSequencePosition &&
            sequenceDisplayMode == SequenceDisplayMode.numbersOnly) {
          shouldDrawStone = false;
        }

        // In review view, always show stones (they can have numbers overlaid)
        // No additional logic needed for review view stone visibility

        if (shouldDrawStone) {
          final double x = boardStart + (col - displayStartCol) * cellSize;
          final double y = boardStart + (row - displayStartRow) * cellSize;

          if (themeProvider.skin == AppSkin.eink) {
            // E-ink style: solid colors with borders for white stones
            final stoneStyle = themeProvider.getElementStyle(
              stone == StoneColor.black ? UIElement.stoneBlack : UIElement.stoneWhite
            );
            final stonePaint = Paint()
              ..style = PaintingStyle.fill
              ..color = stoneStyle.color!;

            canvas.drawCircle(Offset(x, y), stoneRadius, stonePaint);

            // Add thick black border for white stones in e-ink mode
            if (stone == StoneColor.white) {
              final borderStyle = themeProvider.getElementStyle(UIElement.stoneWhiteBorder);
              final borderPaint = Paint()
                ..color = borderStyle.color!
                ..style = PaintingStyle.stroke
                ..strokeWidth = borderStyle.strokeWidth!;
              canvas.drawCircle(Offset(x, y), stoneRadius, borderPaint);
            }
          } else {
            // Traditional style with shadows, gradients, and highlights

            // Stone shadow
            final shadowPaint = Paint()
              ..color = Colors.black.withOpacity(0.3)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(
              Offset(x + 1, y + 1),
              stoneRadius,
              shadowPaint,
            );

            // Stone body
            final stonePaint = Paint()
              ..style = PaintingStyle.fill;

            if (stone == StoneColor.black) {
              stonePaint.shader = RadialGradient(
                colors: [
                  const Color(0xFF4A4A4A),
                  const Color(0xFF1A1A1A),
                ],
              ).createShader(Rect.fromCircle(
                center: Offset(x, y),
                radius: stoneRadius,
              ));
            } else {
              stonePaint.shader = RadialGradient(
                colors: [
                  const Color(0xFFFFFFF0),
                  const Color(0xFFE8E8E8),
                ],
              ).createShader(Rect.fromCircle(
                center: Offset(x, y),
                radius: stoneRadius,
              ));
            }

            canvas.drawCircle(Offset(x, y), stoneRadius, stonePaint);

            // Stone highlight
            final highlightPaint = Paint()
              ..color = Colors.white.withOpacity(stone == StoneColor.black ? 0.3 : 0.6)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(
              Offset(x - stoneRadius * 0.3, y - stoneRadius * 0.3),
              stoneRadius * 0.2,
              highlightPaint,
            );
          }

          // Draw last move marker (triangle) using unified sequence length logic
          // Skip when using dot visualization (handled by animator)
          if (lastMovePosition != null && lastMovePosition.row == row && lastMovePosition.col == col && 
              sequenceVisualization != SequenceVisualizationType.dots) {
            _drawLastMoveMarker(canvas, x, y, stoneRadius, stone);
          }

          // Draw sequence numbers on stones (for stonesWithNumbers mode)
          // Skip when using dot visualization (handled by animator)
          if (isSequencePosition && sequenceDisplayMode == SequenceDisplayMode.stonesWithNumbers &&
              sequenceVisualization != SequenceVisualizationType.dots) {
            final sequenceMove = sequenceMoves.firstWhere((move) => move.row == row && move.col == col);
            if (sequenceMove.moveNumber > 0) { // Only draw if not hidden
              _drawSequenceNumberOnStone(canvas, x, y, sequenceMove.moveNumber, stoneRadius, stone);
            }
          }
        }

        // Draw sequence numbers based on view mode and sequence display mode
        // Skip when using dot visualization (handled by animator)
        if (isSequencePosition && sequenceVisualization != SequenceVisualizationType.dots) {
          final sequenceMove = sequenceMoves.firstWhere((move) => move.row == row && move.col == col);
          final double x = boardStart + (col - displayStartCol) * cellSize;
          final double y = boardStart + (row - displayStartRow) * cellSize;

          if (viewMode == BoardViewMode.problem && sequenceDisplayMode == SequenceDisplayMode.numbersOnly) {
            // Problem view: numbers with background blobs (stones are hidden)
            if (sequenceMove.moveNumber > 0) { // Only draw if not hidden
              _drawMoveNumberOnEmptyIntersection(canvas, x, y, sequenceMove.moveNumber, stoneRadius);
            }
          } else if (viewMode == BoardViewMode.review && sequenceDisplayMode == SequenceDisplayMode.stonesWithNumbers) {
            // Review view: numbers overlaid on stones
            if (sequenceMove.moveNumber > 0) { // Only draw if not hidden
              if (position.board[row][col] != StoneColor.empty) {
                _drawSequenceNumberOnStone(canvas, x, y, sequenceMove.moveNumber, stoneRadius, position.board[row][col]);
              } else {
                _drawMoveNumberOnEmptyIntersection(canvas, x, y, sequenceMove.moveNumber, stoneRadius);
              }
            }
          }
        }

        // Legacy: Draw old move sequence numbers for backward compatibility
        if (sequenceLength == 0 && showMoveNumbers && trainingPosition?.gameInfo?.moveSequence != null) {
          for (final move in trainingPosition!.gameInfo!.moveSequence!) {
            if (move.row == row && move.col == col && position.board[row][col] == StoneColor.empty) {
              final double x = boardStart + (col - displayStartCol) * cellSize;
              final double y = boardStart + (row - displayStartRow) * cellSize;
              _drawMoveNumberOnEmptyIntersection(canvas, x, y, move.moveNumber, stoneRadius);
            }
          }
        }
      }
    }

    // Draw focus area highlighting (gray out everything except focus area)
    if (boardDisplay?.focusStartRow != null && boardDisplay?.focusStartCol != null &&
        boardDisplay?.focusWidth != null && boardDisplay?.focusHeight != null) {
      _drawFocusHighlight(canvas, size, boardStart, cellSize, displayStartRow, displayStartCol,
                         displayWidth, displayHeight, boardDisplay!);
    }

    // Draw ownership information (only in review view) - drawn last to be on top
    if (viewMode == BoardViewMode.review &&
        ownershipDisplayMode.showOwnership &&
        trainingPosition?.hasOwnership == true) {
      _drawOwnership(canvas, size, boardStart, cellSize, displayStartRow, displayStartCol,
                    displayWidth, displayHeight);
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double boardStart, double cellSize,
                     int displayStartRow, int displayStartCol, int displayWidth, int displayHeight,
                     Paint paint) {
    final halfCell = cellSize * 0.5;

    // Draw lines for each intersection
    for (int displayRow = 0; displayRow < displayHeight; displayRow++) {
      for (int displayCol = 0; displayCol < displayWidth; displayCol++) {
        final actualRow = displayStartRow + displayRow;
        final actualCol = displayStartCol + displayCol;

        final double x = boardStart + displayCol * cellSize;
        final double y = boardStart + displayRow * cellSize;

        // Draw horizontal line through this intersection
        double leftEnd = x;
        double rightEnd = x;

        // Extend left
        if (displayCol > 0 || actualCol > 0) {
          leftEnd = displayCol > 0 ? boardStart : x - halfCell;
        }

        // Extend right
        if (displayCol < displayWidth - 1 || actualCol < position.size - 1) {
          rightEnd = displayCol < displayWidth - 1
              ? boardStart + (displayWidth - 1) * cellSize
              : x + halfCell;
        }

        if (leftEnd != rightEnd) {
          canvas.drawLine(Offset(leftEnd, y), Offset(rightEnd, y), paint);
        }

        // Draw vertical line through this intersection
        double topEnd = y;
        double bottomEnd = y;

        // Extend up
        if (displayRow > 0 || actualRow > 0) {
          topEnd = displayRow > 0 ? boardStart : y - halfCell;
        }

        // Extend down
        if (displayRow < displayHeight - 1 || actualRow < position.size - 1) {
          bottomEnd = displayRow < displayHeight - 1
              ? boardStart + (displayHeight - 1) * cellSize
              : y + halfCell;
        }

        if (topEnd != bottomEnd) {
          canvas.drawLine(Offset(x, topEnd), Offset(x, bottomEnd), paint);
        }
      }
    }
  }

  void _drawFocusHighlight(Canvas canvas, Size size, double boardStart, double cellSize,
                          int displayStartRow, int displayStartCol, int displayWidth, int displayHeight,
                          BoardDisplay boardDisplay) {
    final focusStartRow = boardDisplay.focusStartRow!;
    final focusStartCol = boardDisplay.focusStartCol!;
    final focusWidth = boardDisplay.focusWidth!;
    final focusHeight = boardDisplay.focusHeight!;

    final overlayStyle = themeProvider.getElementStyle(UIElement.focusOverlay);
    final overlayPaint = Paint()
      ..color = overlayStyle.color!
      ..style = PaintingStyle.fill;

    // Calculate focus area in display coordinates
    final focusDisplayStartRow = focusStartRow - displayStartRow;
    final focusDisplayStartCol = focusStartCol - displayStartCol;

    // Only draw overlay if focus area intersects with display area
    if (focusDisplayStartRow < displayHeight && focusDisplayStartCol < displayWidth &&
        focusDisplayStartRow + focusHeight > 0 && focusDisplayStartCol + focusWidth > 0) {

      // Draw overlay on areas outside the focus
      final focusLeft = boardStart + (focusDisplayStartCol * cellSize) - (cellSize * 0.5);
      final focusTop = boardStart + (focusDisplayStartRow * cellSize) - (cellSize * 0.5);
      final focusRight = focusLeft + (focusWidth * cellSize);
      final focusBottom = focusTop + (focusHeight * cellSize);

      final boardRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final focusRect = Rect.fromLTWH(
        focusLeft.clamp(0, size.width),
        focusTop.clamp(0, size.height),
        (focusRight - focusLeft).clamp(0, size.width - focusLeft.clamp(0, size.width)),
        (focusBottom - focusTop).clamp(0, size.height - focusTop.clamp(0, size.height)),
      );

      // Create path excluding focus area
      final path = Path()
        ..addRect(boardRect)
        ..addRect(focusRect)
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, overlayPaint);
    }
  }

  void _drawLastMoveMarker(Canvas canvas, double x, double y, double stoneRadius, StoneColor stoneColor) {
    final trianglePaint = Paint()
      ..color = stoneColor == StoneColor.black ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;

    final triangleSize = stoneRadius * 0.5;
    final path = Path();

    // Draw triangle pointing up
    path.moveTo(x, y - triangleSize);
    path.lineTo(x - triangleSize * 0.8, y + triangleSize * 0.5);
    path.lineTo(x + triangleSize * 0.8, y + triangleSize * 0.5);
    path.close();

    canvas.drawPath(path, trianglePaint);
  }

  void _drawMoveNumberOnEmptyIntersection(Canvas canvas, double x, double y, int moveNumber, double stoneRadius) {
    // Draw background circle to hide grid lines
    final boardStyle = themeProvider.getElementStyle(UIElement.boardBackground);
    final backgroundPaint = Paint()
      ..color = boardStyle.backgroundColor!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), stoneRadius * 0.7, backgroundPaint);

    // Draw the number with black text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$moveNumber',
        style: TextStyle(
          color: Colors.black,
          fontSize: stoneRadius * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }

  void _drawSequenceNumberOnStone(Canvas canvas, double x, double y, int moveNumber,
                                   double stoneRadius, StoneColor stoneColor) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: moveNumber.toString(),
        style: TextStyle(
          color: stoneColor == StoneColor.black ? Colors.white : Colors.black,
          fontSize: stoneRadius * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }

  void _drawOwnership(Canvas canvas, Size size, double boardStart, double cellSize,
                     int displayStartRow, int displayStartCol, int displayWidth, int displayHeight) {
    final ownership = trainingPosition!.decodeOwnership()!;

    // Get ultimate stones if available, fallback to regular stones
    final List<List<int>>? ultimateStones = trainingPosition!.hasUltimateStones
        ? trainingPosition!.decodeUltimateStones()
        : null;

    for (int row = displayStartRow; row < displayStartRow + displayHeight && row < position.size; row++) {
      for (int col = displayStartCol; col < displayStartCol + displayWidth && col < position.size; col++) {
        final ownershipValue = ownership[row][col];
        if (ownershipValue.abs() < 0.01) continue; // Skip nearly neutral intersections

        final double x = boardStart + (col - displayStartCol) * cellSize;
        final double y = boardStart + (row - displayStartRow) * cellSize;

        // For squares mode: use ultimate stones if available, fallback to regular stones
        final StoneColor stoneAtPosition = ultimateStones != null
            ? _intToStoneColor(ultimateStones[row][col])
            : position.board[row][col];

        if (ownershipDisplayMode.useSquares) {
          _drawOwnershipSquare(canvas, x, y, ownershipValue, cellSize, stoneAtPosition);
        } else if (ownershipDisplayMode.useOverlay) {
          // For overlay mode, we need additional filtering logic
          final StoneColor currentStone = position.board[row][col];
          final StoneColor ultimateStone = ultimateStones != null ? _intToStoneColor(ultimateStones[row][col]) : currentStone;
          _drawOwnershipOverlay(canvas, x, y, ownershipValue, cellSize, currentStone, ultimateStone);
        }
      }
    }
  }

  void _drawOwnershipSquare(Canvas canvas, double x, double y, double ownership, double cellSize, StoneColor stoneAtPosition) {
    final isBlackOwnership = ownership > 0;
    final strength = ownership.abs();

    // Only show Black squares over empty intersections and White stones
    // Only show White squares over empty intersections and Black stones
    if (isBlackOwnership && stoneAtPosition == StoneColor.black) {
      return; // Don't show Black square over Black stone
    }
    if (!isBlackOwnership && stoneAtPosition == StoneColor.white) {
      return; // Don't show White square over White stone
    }

    // Square size based on ownership strength (0.125 increments from 0 to 1)
    final quantizedStrength = (strength * 8).round() / 8.0; // Quantize to 0.125 increments
    final squareSize = cellSize * 0.2 * quantizedStrength.clamp(0.125, 1.0);

    if (isBlackOwnership) {
      // Black ownership: black squares
      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: squareSize, height: squareSize),
        paint,
      );
    } else {
      // White ownership: white squares with thick black border for visibility
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0; // Thick border for visibility

      // Draw white fill
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: squareSize, height: squareSize),
        whitePaint,
      );

      // Draw black border
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: squareSize, height: squareSize),
        borderPaint,
      );
    }
  }

  /// Helper method to convert int stone representation to StoneColor enum
  StoneColor _intToStoneColor(int stoneValue) {
    switch (stoneValue) {
      case 0:
        return StoneColor.empty;
      case 1:
        return StoneColor.black;
      case 2:
        return StoneColor.white;
      default:
        return StoneColor.empty;
    }
  }

  void _drawOwnershipOverlay(Canvas canvas, double x, double y, double ownership, double cellSize,
                              StoneColor currentStone, StoneColor ultimateStone) {
    final isBlackOwnership = ownership > 0;
    final strength = ownership.abs();

    // Special filtering for overlay mode:
    // Show overlays over all intersections owned by a given color
    // EXCEPT for those which have stones of that color in ultimate-stones but not in stones
    if (isBlackOwnership) {
      // For black ownership: don't show if there's a black stone in ultimate-stones but not in stones
      if (ultimateStone == StoneColor.black && currentStone != StoneColor.black) {
        return; // Skip this intersection
      }
    } else {
      // For white ownership: don't show if there's a white stone in ultimate-stones but not in stones
      if (ultimateStone == StoneColor.white && currentStone != StoneColor.white) {
        return; // Skip this intersection
      }
    }

    // Cover the entire intersection area with no gaps between neighboring overlays
    final overlaySize = cellSize;

    if (isBlackOwnership) {
      // Black ownership: black overlay with reduced opacity
      final maxOpacity = 0.3; // Reduced from 0.5
      final opacity = (strength * maxOpacity).clamp(0.0, maxOpacity);

      final paint = Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: overlaySize, height: overlaySize),
        paint,
      );
    } else {
      // White ownership: use a light gray overlay with reduced opacity
      final maxOpacity = 0.4; // Reduced from 0.6
      final opacity = (strength * maxOpacity).clamp(0.1, maxOpacity); // Reduced minimum from 0.2

      final paint = Paint()
        ..color = const Color(0xFFE0E0E0).withValues(alpha: opacity) // Light gray instead of white
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: overlaySize, height: overlaySize),
        paint,
      );

    }
  }

  @override
  bool shouldRepaint(GoBoardPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.trainingPosition != trainingPosition ||
           oldDelegate.sequenceLength != sequenceLength ||
           oldDelegate.sequenceDisplayMode != sequenceDisplayMode ||
           oldDelegate.viewMode != viewMode ||
           oldDelegate.ownershipDisplayMode != ownershipDisplayMode ||
           oldDelegate.positionType != positionType ||
           oldDelegate.showMoveNumbers != showMoveNumbers ||
           oldDelegate.isSequenceLengthDefined != isSequenceLengthDefined;
  }
}