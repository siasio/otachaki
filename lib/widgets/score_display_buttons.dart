import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../core/game_result_parser.dart';

class ScoreDisplayButtons extends StatelessWidget {
  final String resultString;
  final VoidCallback onNextPressed;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final bool useColoredBackground;
  final int? blackTerritory;
  final int? whiteTerritory;
  final double? komi;

  const ScoreDisplayButtons({
    super.key,
    required this.resultString,
    required this.onNextPressed,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.useColoredBackground = true,
    this.blackTerritory,
    this.whiteTerritory,
    this.komi,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final scoreInfo = parseScoreInfo(resultString);

    if (layoutType == LayoutType.horizontal) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _buildScoreDisplay(
                text: scoreInfo.whiteScore,
                isWhite: true,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildNextButton(themeProvider: themeProvider),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildScoreDisplay(
                text: scoreInfo.blackScore,
                isWhite: false,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildScoreDisplay(
                text: scoreInfo.whiteScore,
                isWhite: true,
                themeProvider: themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNextButton(themeProvider: themeProvider),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScoreDisplay(
                text: scoreInfo.blackScore,
                isWhite: false,
                themeProvider: themeProvider,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildScoreDisplay({
    required String text,
    required bool isWhite,
    required UnifiedThemeProvider themeProvider,
  }) {
    final backgroundColor = useColoredBackground
        ? (isWhite
            ? themeProvider.getElementStyle(UIElement.buttonResultWhite).backgroundColor!
            : themeProvider.getElementStyle(UIElement.buttonResultBlack).backgroundColor!)
        : themeProvider.getElementStyle(UIElement.buttonResultDraw).backgroundColor!;

    final textColor = useColoredBackground
        ? (isWhite
            ? themeProvider.getElementStyle(UIElement.buttonResultWhite).color!
            : themeProvider.getElementStyle(UIElement.buttonResultBlack).color!)
        : themeProvider.getElementStyle(UIElement.textBody).color!;

    // Use thick dashed border of opposite color for territory displays
    final shouldUseDashedBorder = blackTerritory != null && whiteTerritory != null;
    final borderColor = shouldUseDashedBorder
        ? (isWhite ? Colors.black : Colors.white)
        : themeProvider.getElementStyle(UIElement.buttonResultWhite).borderColor!;

    final isVertical = layoutType == LayoutType.horizontal;

    return Container(
      height: isVertical ? null : 60,
      width: isVertical ? double.infinity : null,
      constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: shouldUseDashedBorder
            ? null  // We'll use a custom dashed border painter
            : Border.all(color: borderColor, width: 2),
        boxShadow: appSkin == AppSkin.eink ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: shouldUseDashedBorder
          ? ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none,
              ),
            )
          : null,
      child: shouldUseDashedBorder
          ? CustomPaint(
              painter: DashedBorderPainter(
                color: borderColor,
                strokeWidth: 4.0,
                dashLength: 8.0,
                dashGap: 4.0,
                borderRadius: 12.0,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: layoutType == LayoutType.horizontal ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: layoutType == LayoutType.horizontal ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Widget _buildNextButton({required UnifiedThemeProvider themeProvider}) {
    final color = themeProvider.getElementStyle(UIElement.buttonNext).backgroundColor!;
    final textColor = themeProvider.getElementStyle(UIElement.buttonNext).color!;
    // final borderColor = themeProvider.getElementStyle(UIElement.buttonResultWhite).borderColor!;
    final isVertical = layoutType == LayoutType.horizontal;

    return Material(
      elevation: appSkin == AppSkin.eink ? 0 : 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onNextPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: isVertical ? null : 60,
          width: isVertical ? double.infinity : null,
          constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: appSkin == AppSkin.eink ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: appSkin == AppSkin.eink
                            ? textColor
                            : textColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: appSkin == AppSkin.eink
                            ? textColor
                            : textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @visibleForTesting
  ScoreInfo parseScoreInfo(String result) {
    // If we have territory data, use the new format
    if (blackTerritory != null && whiteTerritory != null) {
      final blackText = "Black's territory: $blackTerritory points";

      String whiteText;
      if (komi != null) {
        // Check if komi is a whole number to avoid .0 display
        final komiDisplay = komi! == komi!.roundToDouble() ? komi!.round().toString() : komi.toString();
        final whiteTotal = whiteTerritory! + komi!;
        final whiteTotalDisplay = whiteTotal == whiteTotal.roundToDouble() ? whiteTotal.round().toString() : whiteTotal.toString();
        whiteText = "White's territory: $whiteTerritory + $komiDisplay = $whiteTotalDisplay points";
      } else {
        whiteText = "White's territory: $whiteTerritory points";
      }

      return ScoreInfo(whiteScore: whiteText, blackScore: blackText);
    }

    // Fallback to old format if territory data is not available
    if (result.isEmpty) {
      return ScoreInfo(whiteScore: 'W: ?', blackScore: 'B: ?');
    }

    final winner = GameResultParser.parseWinner(result);

    if (winner == 'Draw') {
      return ScoreInfo(whiteScore: 'Draw', blackScore: 'Draw');
    }

    if (result.startsWith('W+')) {
      final points = result.substring(2);
      return ScoreInfo(
        whiteScore: 'W+$points',
        blackScore: 'B loses',
      );
    } else if (result.startsWith('B+')) {
      final points = result.substring(2);
      return ScoreInfo(
        whiteScore: 'W loses',
        blackScore: 'B+$points',
      );
    }

    return ScoreInfo(whiteScore: 'W: ?', blackScore: 'B: ?');
  }
}

class ScoreInfo {
  final String whiteScore;
  final String blackScore;

  ScoreInfo({
    required this.whiteScore,
    required this.blackScore,
  });
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
                     size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(borderRadius),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}