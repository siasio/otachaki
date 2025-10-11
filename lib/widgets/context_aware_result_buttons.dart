import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/game_result_option.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';

class ContextAwareResultButtons extends StatelessWidget {
  final DatasetType datasetType;
  final double actualScore;
  final String resultString;
  final Function(GameResultOption) onResultSelected;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final double? thresholdGood;
  final double? thresholdClose;

  const ContextAwareResultButtons({
    super.key,
    required this.datasetType,
    required this.actualScore,
    required this.resultString,
    required this.onResultSelected,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.thresholdGood,
    this.thresholdClose,
  });

  @override
  Widget build(BuildContext context) {
    final options = GameResultOption.generateOptions(
      datasetType,
      actualScore,
      resultString,
      thresholdGood: thresholdGood,
      thresholdClose: thresholdClose,
    );

    if (layoutType == LayoutType.horizontal) {
      // Vertical arrangement for horizontal mode: White (top), Draw (middle), Black (bottom)
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: options.map((option) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildResultButton(option, isVertical: true),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Horizontal arrangement for vertical mode
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: options.map((option) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: options.length == 3 ? 6 : 8,
                ),
                child: _buildResultButton(option, isVertical: false),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildResultButton(GameResultOption option, {required bool isVertical}) {
    final String buttonTypeKey = option.buttonType == ButtonType.whiteWins
        ? 'white'
        : option.buttonType == ButtonType.blackWins
        ? 'black'
        : 'draw';

    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);

    // Map the button type to UIElement
    final UIElement element;
    switch (buttonTypeKey) {
      case 'white':
        element = UIElement.buttonResultWhite;
        break;
      case 'black':
        element = UIElement.buttonResultBlack;
        break;
      case 'draw':
        element = UIElement.buttonResultDraw;
        break;
      default:
        element = UIElement.buttonNext;
    }

    final style = themeProvider.getElementStyle(element);

    return Material(
      elevation: style.elevation ?? 0,
      borderRadius: style.borderRadius,
      child: InkWell(
        onTap: () => onResultSelected(option),
        borderRadius: BorderRadius.circular(12),
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
                      if (_getKeyboardIcon(option.buttonType) != null) ...[
                        Icon(
                          _getKeyboardIcon(option.buttonType),
                          size: 20,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        option.displayText,
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
                      if (_getKeyboardIcon(option.buttonType) != null) ...[
                        Icon(
                          _getKeyboardIcon(option.buttonType),
                          size: 16,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        option.displayText,
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

  IconData? _getKeyboardIcon(ButtonType buttonType) {
    switch (buttonType) {
      case ButtonType.whiteWins:
        return Icons.arrow_back;
      case ButtonType.draw:
        return Icons.arrow_downward;
      case ButtonType.blackWins:
        return Icons.arrow_forward;
    }
  }
}