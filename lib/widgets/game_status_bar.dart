import 'package:flutter/material.dart';
import '../models/training_position.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';

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
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final statusBarStyle = themeProvider.getElementStyle(UIElement.gameStatusBar);

    if (position == null) {
      return Container(
        height: 60,
        margin: statusBarStyle.margin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Demo position',
              style: themeProvider.getTextStyle(UIElement.textCaption),
            ),
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
          style: themeProvider.getTextStyle(UIElement.textStatusIndicator),
        ),
        Text(
          '${gameInfo?.komi ?? 0}',
          style: themeProvider.getTextStyle(UIElement.textGameInfo),
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
      margin: statusBarStyle.margin,
      decoration: themeProvider.getContainerDecoration(UIElement.gameStatusBar),
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
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);

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
              style: themeProvider.getTextStyle(UIElement.textGameInfo),
            ),
          ],
        ),
        Text(
          label,
          style: themeProvider.getTextStyle(UIElement.textStatusIndicator),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}