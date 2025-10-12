import 'package:flutter/material.dart';
import '../models/layout_type.dart';

class AdaptiveLayout extends StatelessWidget {
  final LayoutType layoutType;
  final Widget timerBar;
  // REMOVED: gameInfoBar - GameInfo functionality has been removed but kept for compatibility
  final Widget? gameInfoBar;
  final Widget board;
  final Widget buttons;

  const AdaptiveLayout({
    super.key,
    required this.layoutType,
    required this.timerBar,
    this.gameInfoBar,
    required this.board,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    if (layoutType == LayoutType.horizontal) {
      return _buildHorizontalLayout();
    } else {
      return _buildVerticalLayout();
    }
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        // Traditional vertical layout: gear icon is in AppBar, timer bar here
        timerBar,
        // REMOVED: GameInfoBar display - GameInfo functionality has been removed
        // if (gameInfoBar != null) gameInfoBar!,
        Expanded(child: board),
        buttons,
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: Vertical timer bar (narrow, flex: 1)
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: timerBar,
          ),
        ),

        // REMOVED: Column 2: Game info bar - GameInfo functionality has been removed
        // if (gameInfoBar != null)
        //   Expanded(
        //     flex: 2,
        //     child: Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: gameInfoBar!,
        //     ),
        //   ),

        // Column 2: Main board area (largest, flex: 12)
        Expanded(
          flex: 12,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(1.0),
            child: board,
          ),
        ),

        // Column 3: Vertical buttons (flex: 2)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: buttons,
          ),
        ),
      ],
    );
  }
}