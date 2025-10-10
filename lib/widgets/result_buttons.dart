import 'package:flutter/material.dart';
import '../models/scoring_config.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../themes/theme_enforcement.dart';

class ResultButtons extends StatelessWidget {
  final Function(GameResult) onResultSelected;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const ResultButtons({
    super.key,
    required this.onResultSelected,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    ThemeEnforcement.enforceThemeUsage(
      widgetName: 'ResultButtons',
      skin: appSkin,
      layoutType: layoutType,
    );

    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);

    final buttons = [
      _buildResultButton(
        label: 'White Wins',
        element: UIElement.buttonResultWhite,
        result: GameResult.whiteWins,
        themeProvider: themeProvider,
      ),
      _buildResultButton(
        label: 'Draw',
        element: UIElement.buttonResultDraw,
        result: GameResult.draw,
        themeProvider: themeProvider,
      ),
      _buildResultButton(
        label: 'Black Wins',
        element: UIElement.buttonResultBlack,
        result: GameResult.blackWins,
        themeProvider: themeProvider,
      ),
    ];

    final containerPadding = themeProvider.getElementStyle(UIElement.cardContainer).padding!;

    if (layoutType == LayoutType.horizontal) {
      // Vertical arrangement: White (top), Draw (middle), Black (bottom)
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
      // Horizontal arrangement
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

  Widget _buildResultButton({
    required String label,
    required UIElement element,
    required GameResult result,
    required UnifiedThemeProvider themeProvider,
  }) {
    final style = ThemeEnforcement.enforceElementUsage(
      'ResultButtons',
      element.toString(),
      () => themeProvider.getElementStyle(element),
    );
    final isVertical = layoutType == LayoutType.horizontal;

    return Material(
      elevation: style.elevation ?? 0,
      borderRadius: style.borderRadius,
      child: InkWell(
        onTap: () => onResultSelected(result),
        borderRadius: style.borderRadius,
        child: Container(
          height: isVertical ? null : 60,
          width: isVertical ? double.infinity : null,
          constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
          decoration: themeProvider.getContainerDecoration(element),
          child: Center(
            child: isVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_getKeyboardIcon(result) != null) ...[
                        Icon(
                          _getKeyboardIcon(result),
                          size: themeProvider.getElementStyle(element).fontSize?.clamp(16, 24) ?? 20,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        label,
                        style: themeProvider.getTextStyle(element).copyWith(
                          fontSize: themeProvider.getElementStyle(UIElement.textButtonLabel).fontSize,
                          fontWeight: themeProvider.getElementStyle(UIElement.textButtonLabel).fontWeight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_getKeyboardIcon(result) != null) ...[
                        Icon(
                          _getKeyboardIcon(result),
                          size: themeProvider.getElementStyle(element).fontSize?.clamp(14, 20) ?? 16,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: themeProvider.getTextStyle(element).copyWith(
                          fontSize: themeProvider.getElementStyle(UIElement.textButtonLabel).fontSize,
                          fontWeight: themeProvider.getElementStyle(UIElement.textButtonLabel).fontWeight,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData? _getKeyboardIcon(GameResult result) {
    switch (result) {
      case GameResult.whiteWins:
        return Icons.arrow_back;
      case GameResult.draw:
        return Icons.arrow_downward;
      case GameResult.blackWins:
        return Icons.arrow_forward;
    }
  }
}