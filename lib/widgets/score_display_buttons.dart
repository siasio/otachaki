import 'package:flutter/material.dart';
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

  const ScoreDisplayButtons({
    super.key,
    required this.resultString,
    required this.onNextPressed,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.useColoredBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final scoreInfo = _parseScoreInfo(resultString);

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

    final borderColor = themeProvider.getElementStyle(UIElement.buttonResultWhite).borderColor!;
    final isVertical = layoutType == LayoutType.horizontal;

    return Container(
      height: isVertical ? null : 60,
      width: isVertical ? double.infinity : null,
      constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: appSkin == AppSkin.eink ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
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

  ScoreInfo _parseScoreInfo(String result) {
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