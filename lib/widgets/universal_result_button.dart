import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/game_result_option.dart';
import '../models/rough_lead_button_state.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../themes/theme_enforcement.dart';

/// Universal button widget that handles all interactive result button types
///
/// This widget consolidates the functionality of ContextAwareResultButtons,
/// ResultButtons, ExactScoreButtons, and RoughLeadPredictionButtons into
/// a single configurable widget.
///
/// Supports:
/// - Basic result selection (White/Draw/Black)
/// - Exact score buttons with specific values
/// - Rough lead prediction with multi-state feedback
/// - Context-aware buttons based on dataset type
/// - Flexible theming and layout support
class UniversalResultButton extends StatelessWidget {
  final String displayText;
  final bool isCorrect;
  final bool isPressed;
  final VoidCallback onPressed;
  final UniversalButtonType buttonType;
  final AppSkin appSkin;
  final LayoutType layoutType;
  final bool showCorrectnessFeedback;
  final IconData? icon;
  final double? exactScore;

  const UniversalResultButton({
    super.key,
    required this.displayText,
    required this.onPressed,
    this.isCorrect = false,
    this.isPressed = false,
    this.buttonType = UniversalButtonType.basic,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
    this.showCorrectnessFeedback = false,
    this.icon,
    this.exactScore,
  });

  /// Factory for basic result buttons (White/Draw/Black)
  factory UniversalResultButton.basic({
    required String text,
    required VoidCallback onPressed,
    required ButtonType buttonType,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return UniversalResultButton(
      displayText: text,
      onPressed: onPressed,
      buttonType: UniversalButtonType.basic,
      appSkin: appSkin,
      layoutType: layoutType,
      icon: _getIconForButtonType(buttonType),
    );
  }

  /// Factory for context-aware buttons (dataset-specific logic)
  factory UniversalResultButton.contextAware({
    required GameResultOption option,
    required VoidCallback onPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return UniversalResultButton(
      displayText: option.displayText,
      onPressed: onPressed,
      isCorrect: option.isCorrect,
      buttonType: UniversalButtonType.contextAware,
      appSkin: appSkin,
      layoutType: layoutType,
      exactScore: option.exactScore,
      icon: _getIconForButtonType(option.buttonType),
    );
  }

  /// Factory for exact score buttons
  factory UniversalResultButton.exactScore({
    required String scoreText,
    required VoidCallback onPressed,
    required bool isCorrect,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return UniversalResultButton(
      displayText: scoreText,
      onPressed: onPressed,
      isCorrect: isCorrect,
      buttonType: UniversalButtonType.exactScore,
      appSkin: appSkin,
      layoutType: layoutType,
    );
  }

  /// Factory for rough lead prediction buttons with multi-state feedback
  factory UniversalResultButton.roughLead({
    required RoughLeadButtonState buttonState,
    required VoidCallback onPressed,
    AppSkin appSkin = AppSkin.classic,
    LayoutType layoutType = LayoutType.vertical,
  }) {
    return UniversalResultButton(
      displayText: buttonState.displayText,
      onPressed: onPressed,
      isCorrect: buttonState.isCorrect,
      isPressed: buttonState.wasPressed,
      buttonType: UniversalButtonType.roughLead,
      appSkin: appSkin,
      layoutType: layoutType,
      showCorrectnessFeedback: true,
      icon: _getIconForRoughLeadType(buttonState.buttonType),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeEnforcement.enforceThemeUsage(
      widgetName: 'UniversalResultButton',
      skin: appSkin,
      layoutType: layoutType,
    );

    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final uiElement = _getUIElement();
    final style = ThemeEnforcement.enforceElementUsage(
      'UniversalResultButton',
      uiElement.toString(),
      () => themeProvider.getElementStyle(uiElement),
    );

    final isVertical = layoutType == LayoutType.horizontal;

    // Get colors based on button state and type
    final colors = _getButtonColors(themeProvider, uiElement);

    return Material(
      elevation: style.elevation ?? 0,
      borderRadius: style.borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: style.borderRadius,
        child: Container(
          height: isVertical ? null : 60,
          width: isVertical ? double.infinity : null,
          constraints: isVertical ? const BoxConstraints(minHeight: 80) : null,
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: style.borderRadius,
            border: Border.all(
              color: colors.borderColor,
              width: colors.borderWidth,
            ),
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
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: style.fontSize?.clamp(16, 24) ?? 20,
                          color: colors.iconColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        displayText,
                        style: themeProvider.getTextStyle(uiElement).copyWith(
                          fontSize: themeProvider.getElementStyle(UIElement.textButtonLabel).fontSize,
                          fontWeight: themeProvider.getElementStyle(UIElement.textButtonLabel).fontWeight,
                          color: colors.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: style.fontSize?.clamp(14, 20) ?? 16,
                          color: colors.iconColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        displayText,
                        style: themeProvider.getTextStyle(uiElement).copyWith(
                          fontSize: themeProvider.getElementStyle(UIElement.textButtonLabel).fontSize,
                          fontWeight: themeProvider.getElementStyle(UIElement.textButtonLabel).fontWeight,
                          color: colors.textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  UIElement _getUIElement() {
    switch (buttonType) {
      case UniversalButtonType.basic:
      case UniversalButtonType.contextAware:
        // Use the appropriate element based on the display text
        if (displayText.toLowerCase().contains('white')) {
          return UIElement.buttonResultWhite;
        } else if (displayText.toLowerCase().contains('black')) {
          return UIElement.buttonResultBlack;
        } else {
          return UIElement.buttonResultDraw;
        }
      case UniversalButtonType.exactScore:
        return UIElement.buttonResultWhite; // Default to white for scores
      case UniversalButtonType.roughLead:
        // Use the appropriate element based on the display text for rough lead
        if (displayText.toLowerCase().contains('white')) {
          return UIElement.buttonResultWhite;
        } else if (displayText.toLowerCase().contains('black')) {
          return UIElement.buttonResultBlack;
        } else {
          return UIElement.buttonResultDraw; // For "Close" buttons
        }
    }
  }

  ButtonColors _getButtonColors(UnifiedThemeProvider themeProvider, UIElement uiElement) {
    final style = themeProvider.getElementStyle(uiElement);

    // Use consistent styling for all button types
    return ButtonColors(
      backgroundColor: style.backgroundColor!,
      borderColor: style.borderColor!,
      borderWidth: 2.0,
      textColor: style.color!,
      iconColor: style.hasAnimation == true
          ? style.color!.withOpacity(0.7)
          : style.color!,
    );
  }

  static IconData? _getIconForButtonType(ButtonType buttonType) {
    switch (buttonType) {
      case ButtonType.whiteWins:
        return Icons.arrow_back;
      case ButtonType.draw:
        return Icons.arrow_downward;
      case ButtonType.blackWins:
        return Icons.arrow_forward;
    }
  }

  static IconData? _getIconForRoughLeadType(RoughLeadButtonType buttonType) {
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

/// Button type enum for Universal Result Button
enum UniversalButtonType {
  basic,
  contextAware,
  exactScore,
  roughLead,
}

/// Helper class for button color management
class ButtonColors {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final Color iconColor;

  const ButtonColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.iconColor,
  });
}

/// Container widget for multiple Universal Result Buttons
class UniversalResultButtonGroup extends StatelessWidget {
  final List<UniversalResultButton> buttons;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const UniversalResultButtonGroup({
    super.key,
    required this.buttons,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
    final containerPadding = themeProvider.getElementStyle(UIElement.cardContainer).padding!;
    final buttonPadding = themeProvider.getElementStyle(UIElement.buttonResultWhite).padding!;

    if (layoutType == LayoutType.horizontal) {
      // Vertical arrangement for horizontal mode
      return Container(
        padding: containerPadding,
        child: Column(
          children: buttons.map((button) {
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
      // Horizontal arrangement for vertical mode
      return Container(
        padding: containerPadding,
        child: Row(
          children: buttons.map((button) {
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
}