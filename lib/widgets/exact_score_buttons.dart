import 'package:flutter/material.dart';
import '../models/positioned_score_options.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../themes/theme_enforcement.dart';

class ExactScoreButtons extends StatelessWidget {
  final Function(int) onButtonPressed; // Takes button position (0, 1, 2)
  final PositionedScoreOptions scoreOptions;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const ExactScoreButtons({
    super.key,
    required this.onButtonPressed,
    required this.scoreOptions,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    ThemeEnforcement.enforceThemeUsage(
      widgetName: 'ExactScoreButtons',
      skin: appSkin,
      layoutType: layoutType,
    );

    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);

    final buttons = scoreOptions.options.map((option) {
      return _buildScoreButton(
        option: option,
        themeProvider: themeProvider,
      );
    }).toList();

    final containerPadding = themeProvider.getElementStyle(UIElement.cardContainer).padding!;

    if (layoutType == LayoutType.horizontal) {
      // Vertical layout of buttons for horizontal screen layout
      return Container(
        padding: containerPadding,
        child: Column(
          children: buttons.map((button) {
            final buttonPadding = themeProvider.getElementStyle(UIElement.buttonResultWhite).padding!;
            return Expanded(
              child: Padding(
                padding: buttonPadding,
                child: button,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Horizontal layout of buttons for vertical screen layout
      return Container(
        padding: containerPadding,
        child: Row(
          children: buttons.map((button) {
            final buttonPadding = themeProvider.getElementStyle(UIElement.buttonResultWhite).padding!;
            return Expanded(
              child: Padding(
                padding: buttonPadding,
                child: button,
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildScoreButton({
    required PositionedScoreOption option,
    required UnifiedThemeProvider themeProvider,
  }) {
    // Determine UI element based on score type
    UIElement element;
    if (option.scoreText.toLowerCase() == 'draw') {
      element = UIElement.buttonResultDraw;
    } else if (option.scoreText.startsWith('W+')) {
      element = UIElement.buttonResultWhite;
    } else {
      element = UIElement.buttonResultBlack;
    }

    final style = themeProvider.getElementStyle(element);
    final isVertical = layoutType == LayoutType.horizontal;

    return Material(
      elevation: style.elevation ?? 0,
      borderRadius: style.borderRadius,
      child: InkWell(
        onTap: () => onButtonPressed(option.buttonPosition),
        borderRadius: style.borderRadius,
        child: Container(
          height: isVertical ? null : 60, // Match ResultButtons height
          width: isVertical ? double.infinity : null,
          constraints: isVertical ? const BoxConstraints(minHeight: 80) : null, // Match ResultButtons constraints
          decoration: themeProvider.getContainerDecoration(element),
          child: Center(
            child: Text(
              option.scoreText,
              style: TextStyle(
                color: style.color,
                fontSize: style.fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}