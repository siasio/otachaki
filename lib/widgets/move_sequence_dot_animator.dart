import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/go_position.dart';
import '../core/go_logic.dart';

/// Data class for a dot to be animated
class AnimatedDot {
  final int row;
  final int col;
  final int sequenceNumber;

  const AnimatedDot({
    required this.row,
    required this.col,
    required this.sequenceNumber,
  });
}

/// Widget that animates dots appearing and disappearing sequentially
/// to show a move sequence. Also animates the last move marker.
class MoveSequenceDotAnimator extends StatefulWidget {
  final List<MoveSequenceData> sequence;
  final double initialTimeSeconds;
  final double timePerMoveSeconds;
  final VoidCallback? onAnimationComplete;
  final double cellSize;
  final double boardStart;
  final int displayStartRow;
  final int displayStartCol;
  final Color dotColor;
  final bool hasLastMoveMarker;
  final MoveSequenceData? lastMoveData;
  final GoPosition position;
  final double stoneRadius;

  const MoveSequenceDotAnimator({
    super.key,
    required this.sequence,
    required this.initialTimeSeconds,
    required this.timePerMoveSeconds,
    this.onAnimationComplete,
    required this.cellSize,
    required this.boardStart,
    required this.displayStartRow,
    required this.displayStartCol,
    required this.dotColor,
    this.hasLastMoveMarker = false,
    this.lastMoveData,
    required this.position,
    required this.stoneRadius,
  });

  @override
  State<MoveSequenceDotAnimator> createState() => _MoveSequenceDotAnimatorState();
}

class _MoveSequenceDotAnimatorState extends State<MoveSequenceDotAnimator> {
  int _currentDotIndex = -1; // -1 means showing last move marker, 0+ means showing dot
  Timer? _timer;
  Timer? _refreshTimer; // Periodic timer to force UI refresh on e-ink devices
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    _isAnimating = true;
    
    // Enable wakelock to prevent screen from sleeping during animation
    // This helps prevent aggressive power management from freezing the animation
    try {
      await WakelockPlus.enable();
    } catch (e) {
      // Silently fail if wakelock not available (e.g., on desktop)
    }
    
    // Start periodic refresh timer to force UI updates
    // This prevents e-ink devices from suspending rendering
    // Update every 500ms to ensure smooth state changes are reflected
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _isAnimating) {
        // Force a frame to be scheduled
        SchedulerBinding.instance.scheduleFrame();
      }
    });
    
    // Start with last move marker if present
    if (widget.hasLastMoveMarker && widget.lastMoveData != null) {
      _currentDotIndex = -1;
      
      // Show last move marker for initialTime duration
      _timer = Timer(Duration(milliseconds: (widget.initialTimeSeconds * 1000).toInt()), () {
        if (mounted) {
          _advanceToNextDot();
        }
      });
    } else {
      // No last move marker, start with first dot
      _advanceToNextDot();
    }
  }

  void _advanceToNextDot() {
    if (!mounted) return;
    
    setState(() {
      _currentDotIndex++;
    });
    
    // Force an immediate frame callback to ensure the UI updates
    // This is crucial for e-ink devices that might delay rendering
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Trigger a rebuild to ensure changes are visible
        // This is a no-op but forces the render pipeline to process
      }
    });

    if (_currentDotIndex < widget.sequence.length) {
      // Schedule next dot
      _timer = Timer(Duration(milliseconds: (widget.timePerMoveSeconds * 1000).toInt()), () {
        if (mounted) {
          _advanceToNextDot();
        }
      });
    } else {
      // Animation complete
      _stopAnimation();
      widget.onAnimationComplete?.call();
    }
  }

  void _stopAnimation() async {
    _isAnimating = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    // Disable wakelock when animation completes
    try {
      await WakelockPlus.disable();
    } catch (e) {
      // Silently fail if wakelock not available
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotAnimationPainter(
        currentDotIndex: _currentDotIndex,
        sequence: widget.sequence,
        cellSize: widget.cellSize,
        boardStart: widget.boardStart,
        displayStartRow: widget.displayStartRow,
        displayStartCol: widget.displayStartCol,
        dotColor: widget.dotColor,
        hasLastMoveMarker: widget.hasLastMoveMarker,
        lastMoveData: widget.lastMoveData,
        position: widget.position,
        stoneRadius: widget.stoneRadius,
      ),
      size: Size.infinite,
    );
  }
}

/// Custom painter that draws only the currently active dot or last move marker
class _DotAnimationPainter extends CustomPainter {
  final int currentDotIndex;
  final List<MoveSequenceData> sequence;
  final double cellSize;
  final double boardStart;
  final int displayStartRow;
  final int displayStartCol;
  final Color dotColor;
  final bool hasLastMoveMarker;
  final MoveSequenceData? lastMoveData;
  final GoPosition position;
  final double stoneRadius;

  _DotAnimationPainter({
    required this.currentDotIndex,
    required this.sequence,
    required this.cellSize,
    required this.boardStart,
    required this.displayStartRow,
    required this.displayStartCol,
    required this.dotColor,
    required this.hasLastMoveMarker,
    required this.lastMoveData,
    required this.position,
    required this.stoneRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentDotIndex == -1 && hasLastMoveMarker && lastMoveData != null) {
      // Draw last move marker (triangle)
      _drawLastMoveMarker(canvas, lastMoveData!);
    } else if (currentDotIndex >= 0 && currentDotIndex < sequence.length) {
      // Draw current dot
      final move = sequence[currentDotIndex];
      _drawDot(canvas, move);
    }
  }

  void _drawLastMoveMarker(Canvas canvas, MoveSequenceData moveData) {
    final double x = boardStart + (moveData.col - displayStartCol) * cellSize;
    final double y = boardStart + (moveData.row - displayStartRow) * cellSize;
    
    // Get the stone color at this position
    final stoneColor = position.board[moveData.row][moveData.col];
    
    // Use white triangle on black stones, black triangle on white stones
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

  void _drawDot(Canvas canvas, MoveSequenceData moveData) {
    final double x = boardStart + (moveData.col - displayStartCol) * cellSize;
    final double y = boardStart + (moveData.row - displayStartRow) * cellSize;
    final double dotRadius = cellSize * 0.15;

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), dotRadius, paint);
  }

  @override
  bool shouldRepaint(_DotAnimationPainter oldDelegate) {
    return currentDotIndex != oldDelegate.currentDotIndex;
  }
}
