import 'package:flutter/material.dart';
import '../models/rough_lead_button_state.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../themes/theme_enforcement.dart';

/// A specialized button widget for rough lead prediction mode.
///
/// This widget displays three buttons (White, Close, Black) with sophisticated
/// visual feedback that can show multiple correct answers simultaneously.
///
/// Key features:
/// - Multiple buttons can be marked as correct at the same time
/// - Pressed buttons show green (correct) or red (incorrect) backgrounds
/// - Unpressed correct buttons show green outlines
/// - Follows the app's theme system and supports both layout orientations
/// - Integrates with keyboard controls (left/down/right arrows)
///
/// Visual feedback states:
/// - Pressed + Correct: Green background with thick green border
/// - Pressed + Incorrect: Red background with thick red border
/// - Not pressed + Correct: Green outline (shows missed opportunities)
/// - Not pressed + Incorrect: Normal appearance
class RoughLeadPredictionButtons extends StatelessWidget {
  final Function(RoughLeadButtonType) onButtonPressed;
  final RoughLeadPredictionState predictionState;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const RoughLeadPredictionButtons({
    super.key,
    required this.onButtonPressed,
    required this.predictionState,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    ThemeEnforcement.enforceThemeUsage(
      widgetName: 'RoughLeadPredictionButtons',
      skin: appSkin,
      layoutType: layoutType,
    );

    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);

    final buttons = predictionState.buttons.map((buttonState) {
      return _buildRoughLeadButton(
        buttonState: buttonState,
        themeProvider: themeProvider,
      );
    }).toList();

    final containerPadding = themeProvider.getElementStyle(UIElement.cardContainer).padding!;

    if (layoutType == LayoutType.horizontal) {
      // Vertical arrangement: White (top), Close (middle), Black (bottom)
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

  Widget _buildRoughLeadButton({
    required RoughLeadButtonState buttonState,
    required UnifiedThemeProvider themeProvider,
  }) {
    // Map button type to UI element
    final UIElement element;
    switch (buttonState.buttonType) {
      case RoughLeadButtonType.white:
        element = UIElement.buttonResultWhite;
        break;
      case RoughLeadButtonType.close:
        element = UIElement.buttonResultDraw;
        break;
      case RoughLeadButtonType.black:
        element = UIElement.buttonResultBlack;
        break;
    }

    final style = ThemeEnforcement.enforceElementUsage(
      'RoughLeadPredictionButtons',
      element.toString(),
      () => themeProvider.getElementStyle(element),
    );

    final isVertical = layoutType == LayoutType.horizontal;

    // Determine the container decoration based on button state
    BoxDecoration containerDecoration;
    if (predictionState.hasAnswered) {
      if (buttonState.wasPressed) {
        // This button was pressed - show green if correct, red if incorrect
        containerDecoration = themeProvider.getContainerDecoration(element).copyWith(
          border: Border.all(
            color: buttonState.isCorrect ? Colors.green : Colors.red,
            width: 3.0,
          ),
          color: buttonState.isCorrect
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        );
      } else if (buttonState.isCorrect) {
        // This button was not pressed but was correct - show green outline
        containerDecoration = themeProvider.getContainerDecoration(element).copyWith(
          border: Border.all(
            color: Colors.green,
            width: 2.0,
          ),
          color: Colors.green.withOpacity(0.1),
        );
      } else {
        // This button was not pressed and was incorrect - normal appearance
        containerDecoration = themeProvider.getContainerDecoration(element);
      }
    } else {
      // No answer yet - normal appearance
      containerDecoration = themeProvider.getContainerDecoration(element);
    }

    return Material(
      elevation: style.elevation ?? 0,
      borderRadius: style.borderRadius,
      child: InkWell(
        onTap: predictionState.hasAnswered
            ? null
            : () => onButtonPressed(buttonState.buttonType),
        borderRadius: style.borderRadius,
        child: Container(
          height: isVertical ? null : 60,
          width: isVertical ? double.infinity : null,
          constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
          decoration: containerDecoration,
          child: Center(
            child: isVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_getKeyboardIcon(buttonState.buttonType) != null) ...[
                        Icon(
                          _getKeyboardIcon(buttonState.buttonType),
                          size: themeProvider.getElementStyle(element).fontSize?.clamp(16, 24) ?? 20,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        buttonState.displayText,
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
                      if (_getKeyboardIcon(buttonState.buttonType) != null) ...[
                        Icon(
                          _getKeyboardIcon(buttonState.buttonType),
                          size: themeProvider.getElementStyle(element).fontSize?.clamp(14, 20) ?? 16,
                          color: style.hasAnimation == true
                              ? style.color?.withOpacity(0.7)
                              : style.color,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        buttonState.displayText,
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

  IconData? _getKeyboardIcon(RoughLeadButtonType buttonType) {
    switch (buttonType) {
      case RoughLeadButtonType.white:
        return Icons.arrow_back;
      case RoughLeadButtonType.close:
        return Icons.arrow_downward;
      case RoughLeadButtonType.black:
        return Icons.arrow_forward;
    }
  }
}