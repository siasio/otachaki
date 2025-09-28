import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import 'element_registry.dart';
import 'style_definitions.dart';

/// Unified theme provider that centralizes all styling decisions
class UnifiedThemeProvider {
  final AppSkin skin;
  final LayoutType layoutType;

  const UnifiedThemeProvider({
    required this.skin,
    required this.layoutType,
  });

  /// Get complete style for any UI element
  ElementStyle getElementStyle(UIElement element) {
    return ElementStyle(
      color: _getElementColor(element),
      backgroundColor: _getElementBackgroundColor(element),
      borderColor: _getElementBorderColor(element),
      fontSize: DimensionConfig.getFontSize(element, layoutType),
      fontWeight: _getElementFontWeight(element),
      padding: DimensionConfig.getPadding(element, layoutType),
      margin: DimensionConfig.getMargin(element, layoutType),
      borderRadius: DimensionConfig.getBorderRadius(element),
      elevation: DimensionConfig.getElevation(element, skin),
      strokeWidth: DimensionConfig.getStrokeWidth(element),
      hasAnimation: _shouldAnimate(element),
      animationDuration: _getAnimationDuration(element),
    );
  }

  /// Color definitions for each skin and element
  Color? _getElementColor(UIElement element) {
    switch (element) {
      // Board elements
      case UIElement.boardGridLines:
      case UIElement.boardStarPoints:
        return Colors.black;

      case UIElement.stoneBlack:
        return Colors.black;

      case UIElement.stoneWhite:
        return Colors.white;

      case UIElement.stoneBlackBorder:
      case UIElement.stoneWhiteBorder:
        return Colors.black;

      case UIElement.lastMoveMarker:
        return switch (skin) {
          AppSkin.classic => Colors.red,
          AppSkin.modern => Colors.orange,
          AppSkin.ocean => Colors.amber,
          AppSkin.eink => Colors.black,
        };

      case UIElement.moveNumber:
        return Colors.black;

      case UIElement.focusOverlay:
        return skin == AppSkin.eink ? Colors.transparent : Colors.grey.withOpacity(0.6);

      // Button text colors
      case UIElement.buttonResultWhite:
        return Colors.black; // Black text on white background

      case UIElement.buttonResultBlack:
        return Colors.white; // White text on dark background

      case UIElement.buttonResultDraw:
        return _getDrawButtonTextColor();

      case UIElement.buttonNext:
        return Colors.black; // Black text on green/grey background

      // Text colors
      case UIElement.textHeading:
      case UIElement.textBody:
      case UIElement.textGameInfo:
        return _getGeneralTextColor();

      case UIElement.textCaption:
      case UIElement.textStatusIndicator:
        return _getGeneralTextColor().withOpacity(0.6);

      case UIElement.textButtonLabel:
        return _getGeneralTextColor();

      // Interactive feedback
      case UIElement.correctIndicator:
        return skin == AppSkin.eink ? Colors.black : Colors.green;

      case UIElement.incorrectIndicator:
        return skin == AppSkin.eink ? Colors.black : Colors.red;

      default:
        return _getGeneralTextColor();
    }
  }

  Color? _getElementBackgroundColor(UIElement element) {
    switch (element) {
      // Board elements
      case UIElement.boardBackground:
        return _getBoardColor();

      // Button backgrounds
      case UIElement.buttonResultWhite:
        return Colors.white;

      case UIElement.buttonResultBlack:
        return _getBlackButtonColor();

      case UIElement.buttonResultDraw:
        return _getDrawButtonColor();

      case UIElement.buttonNext:
        return _getNextButtonColor();

      case UIElement.buttonPause:
      case UIElement.buttonNavigation:
        return _getGeneralButtonColor();

      // Container backgrounds
      case UIElement.gameStatusBar:
      case UIElement.cardContainer:
        return _getContainerBackgroundColor();

      case UIElement.timerBarContainer:
        return _getProgressBarBackgroundColor();

      case UIElement.timerBarProgress:
      case UIElement.progressIndicator:
        return _getProgressBarColor();

      case UIElement.appBarContainer:
        return _getAppBarBackgroundColor();

      case UIElement.feedbackOverlay:
        return skin == AppSkin.eink ? Colors.transparent : Colors.black26;

      case UIElement.boardOverlay:
        return switch (skin) {
          AppSkin.classic => const Color(0xFF8B4513), // Brown theme color
          AppSkin.modern => const Color(0xFF424242), // Dark gray theme color
          AppSkin.ocean => const Color(0xFF1565C0), // Blue theme color
          AppSkin.eink => Colors.transparent,
        };

      default:
        return null;
    }
  }

  Color? _getElementBorderColor(UIElement element) {
    switch (element) {
      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
      case UIElement.buttonNext:
      case UIElement.buttonPause:
      case UIElement.buttonNavigation:
      case UIElement.gameStatusBar:
      case UIElement.cardContainer:
        return _getBorderColor();

      case UIElement.stoneWhiteBorder:
        return Colors.black;

      default:
        return null;
    }
  }

  FontWeight? _getElementFontWeight(UIElement element) {
    switch (element) {
      case UIElement.textHeading:
      case UIElement.textButtonLabel:
      case UIElement.textGameInfo:
        return FontWeight.bold;

      case UIElement.moveNumber:
        return FontWeight.bold;

      default:
        return FontWeight.normal;
    }
  }

  bool _shouldAnimate(UIElement element) {
    // E-ink skin never animates
    if (skin == AppSkin.eink) return false;

    switch (element.category) {
      case ElementCategory.interactive:
      case ElementCategory.container:
        return true;
      default:
        return false;
    }
  }

  Duration _getAnimationDuration(UIElement element) {
    switch (element.category) {
      case ElementCategory.interactive:
        return const Duration(milliseconds: 150);
      case ElementCategory.container:
        return const Duration(milliseconds: 200);
      default:
        return const Duration(milliseconds: 300);
    }
  }

  // Private helper methods for skin-specific colors
  Color _getBoardColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFFDEB887); // Tan
      case AppSkin.modern:
        return const Color(0xFF424242); // Dark grey
      case AppSkin.ocean:
        return const Color(0xFFD2B48C); // Light brown
      case AppSkin.eink:
        return Colors.white;
    }
  }

  Color _getBlackButtonColor() {
    switch (skin) {
      case AppSkin.classic:
        return Colors.black87;
      case AppSkin.modern:
        return const Color(0xFF1A1A1A);
      case AppSkin.ocean:
        return const Color(0xFF0D47A1);
      case AppSkin.eink:
        return Colors.black;
    }
  }

  Color _getDrawButtonColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFFD4B896); // Warm beige
      case AppSkin.modern:
        return const Color(0xFF424242); // Dark grey
      case AppSkin.ocean:
        return const Color(0xFF42A5F5); // Light blue
      case AppSkin.eink:
        return Colors.grey.shade400;
    }
  }

  Color _getDrawButtonTextColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFF5D4037); // Dark brown
      case AppSkin.modern:
        return Colors.white;
      case AppSkin.ocean:
        return Colors.white;
      case AppSkin.eink:
        return Colors.black;
    }
  }

  Color _getNextButtonColor() {
    switch (skin) {
      case AppSkin.classic:
      case AppSkin.modern:
      case AppSkin.ocean:
        return Colors.green;
      case AppSkin.eink:
        return Colors.grey.shade400;
    }
  }

  Color _getGeneralButtonColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFFF5F5DC); // Beige
      case AppSkin.modern:
        return const Color(0xFF2D2D2D); // Dark grey
      case AppSkin.ocean:
        return const Color(0xFFE3F2FD); // Light blue
      case AppSkin.eink:
        return Colors.white;
    }
  }

  Color _getContainerBackgroundColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color.fromRGBO(210, 180, 140, 0.9); // Tan/beige
      case AppSkin.modern:
        return const Color(0xFF2D2D2D);
      case AppSkin.ocean:
        return const Color(0xFFE3F2FD);
      case AppSkin.eink:
        return Colors.white;
    }
  }

  Color _getProgressBarColor() {
    switch (skin) {
      case AppSkin.classic:
        return Colors.green;
      case AppSkin.modern:
        return Colors.indigo;
      case AppSkin.ocean:
        return Colors.blue;
      case AppSkin.eink:
        return Colors.black;
    }
  }

  Color _getProgressBarBackgroundColor() {
    switch (skin) {
      case AppSkin.classic:
        return Colors.grey[300]!;
      case AppSkin.modern:
        return const Color(0xFF2D2D2D);
      case AppSkin.ocean:
        return const Color(0xFFBBDEFB);
      case AppSkin.eink:
        return Colors.grey.shade200;
    }
  }

  Color _getAppBarBackgroundColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFF8B4513);
      case AppSkin.modern:
        return const Color(0xFF1F1F1F);
      case AppSkin.ocean:
        return const Color(0xFF1565C0);
      case AppSkin.eink:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFF8B4513); // Brown
      case AppSkin.modern:
        return const Color(0xFF424242); // Dark grey
      case AppSkin.ocean:
        return const Color(0xFF1565C0); // Blue
      case AppSkin.eink:
        return Colors.black;
    }
  }

  Color _getGeneralTextColor() {
    switch (skin) {
      case AppSkin.classic:
        return const Color(0xFF3E2723); // Dark brown
      case AppSkin.modern:
        return Colors.white;
      case AppSkin.ocean:
        return const Color(0xFF0D47A1); // Dark blue
      case AppSkin.eink:
        return Colors.black;
    }
  }

  // Convenience methods for common styling patterns
  TextStyle getTextStyle(UIElement element) {
    final style = getElementStyle(element);
    return TextStyle(
      color: style.color,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
    );
  }

  BoxDecoration getContainerDecoration(UIElement element) {
    final style = getElementStyle(element);
    return BoxDecoration(
      color: style.backgroundColor,
      borderRadius: style.borderRadius,
      border: style.borderColor != null
          ? Border.all(color: style.borderColor!, width: style.strokeWidth ?? 1.0)
          : null,
      boxShadow: style.elevation != null && style.elevation! > 0
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: style.elevation! * 2,
                offset: Offset(0, style.elevation!),
              ),
            ]
          : null,
    );
  }

  ButtonStyle getButtonStyle(UIElement element) {
    final style = getElementStyle(element);
    return ElevatedButton.styleFrom(
      backgroundColor: style.backgroundColor,
      foregroundColor: style.color,
      elevation: style.elevation ?? 0,
      padding: style.padding,
      shape: RoundedRectangleBorder(
        borderRadius: style.borderRadius ?? BorderRadius.circular(4),
        side: style.borderColor != null
            ? BorderSide(color: style.borderColor!, width: style.strokeWidth ?? 1.0)
            : BorderSide.none,
      ),
    );
  }
}