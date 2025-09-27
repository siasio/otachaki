import 'package:flutter/material.dart';
import '../models/training_position.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/app_theme.dart';

class GameStatusBar extends StatelessWidget {
  final TrainingPosition? position;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const GameStatusBar({
    super.key,
    required this.position,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = SkinConfig.getResultBackgroundColor(appSkin);
    final textColor = SkinConfig.getTextColor(appSkin);
    final shouldAnimate = SkinConfig.shouldAnimate(appSkin);

    if (position == null) {
      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Demo position', style: TextStyle(fontSize: 12, color: textColor)),
          ],
        ),
      );
    }

    final gameInfo = position!.gameInfo;

    // Build the info widgets
    final blackCapturesWidget = _buildCaptureInfo(
      'Black stones dead',
      gameInfo?.whiteCaptured ?? 0, // White captured black stones
      Colors.black,
    );

    final komiWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Komi',
          style: TextStyle(
            fontSize: layoutType == LayoutType.horizontal ? 14 : 10,
            color: textColor.withOpacity(0.6),
          ),
        ),
        Text(
          '${gameInfo?.komi ?? 0}',
          style: TextStyle(
            fontSize: layoutType == LayoutType.horizontal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );

    final whiteCapturesWidget = _buildCaptureInfo(
      'White stones dead',
      gameInfo?.blackCaptured ?? 0, // Black captured white stones
      Colors.white,
    );

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: shouldAnimate ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: layoutType == LayoutType.horizontal
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: blackCapturesWidget),
                Expanded(child: komiWidget),
                Expanded(child: whiteCapturesWidget),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: blackCapturesWidget),
                Expanded(child: komiWidget),
                Expanded(child: whiteCapturesWidget),
              ],
            ),
    );
  }

  Widget _buildCaptureInfo(String label, int count, Color stoneColor) {
    final textColor = SkinConfig.getTextColor(appSkin);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: layoutType == LayoutType.horizontal ? 20 : 16,
              height: layoutType == LayoutType.horizontal ? 20 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stoneColor,
                border: Border.all(
                  color: stoneColor == Colors.white ? Colors.black : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: layoutType == LayoutType.horizontal ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: layoutType == LayoutType.horizontal ? 12 : 9,
            color: textColor.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}