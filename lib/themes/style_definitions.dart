import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import 'element_registry.dart';

/// Defines the styling properties for UI elements
class ElementStyle {
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double? elevation;
  final double? strokeWidth;
  final bool? hasAnimation;
  final Duration? animationDuration;

  const ElementStyle({
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.strokeWidth,
    this.hasAnimation,
    this.animationDuration,
  });

  /// Creates a copy with modified properties
  ElementStyle copyWith({
    Color? color,
    Color? backgroundColor,
    Color? borderColor,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    double? elevation,
    double? strokeWidth,
    bool? hasAnimation,
    Duration? animationDuration,
  }) {
    return ElementStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      hasAnimation: hasAnimation ?? this.hasAnimation,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}

/// Dimension configuration for different layout types
class DimensionConfig {
  static EdgeInsets getPadding(UIElement element, LayoutType layoutType) {
    switch (element) {
      case UIElement.spacingSmall:
        return const EdgeInsets.all(4);
      case UIElement.spacingMedium:
        return const EdgeInsets.all(8);
      case UIElement.spacingLarge:
        return const EdgeInsets.all(16);
      case UIElement.spacingExtraLarge:
        return const EdgeInsets.all(24);

      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
        return layoutType == LayoutType.horizontal
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 6);

      case UIElement.gameStatusBar:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

      case UIElement.timerBarContainer:
        return layoutType == LayoutType.horizontal
            ? const EdgeInsets.all(8)
            : const EdgeInsets.all(16);

      case UIElement.cardContainer:
        return const EdgeInsets.all(16);

      default:
        return const EdgeInsets.all(8);
    }
  }

  static EdgeInsets getMargin(UIElement element, LayoutType layoutType) {
    switch (element) {
      // case UIElement.boardBackground:
      //   return const EdgeInsets.all(2);

      case UIElement.gameStatusBar:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

      case UIElement.timerBarContainer:
        return layoutType == LayoutType.horizontal
            ? const EdgeInsets.all(8)
            : const EdgeInsets.all(16);

      default:
        return EdgeInsets.zero;
    }
  }

  static double getFontSize(UIElement element, LayoutType layoutType) {
    switch (element) {
      case UIElement.textHeading:
        return layoutType == LayoutType.horizontal ? 24 : 20;

      case UIElement.textBody:
        return layoutType == LayoutType.horizontal ? 18 : 16;

      case UIElement.textCaption:
        return layoutType == LayoutType.horizontal ? 14 : 12;

      case UIElement.textButtonLabel:
        return layoutType == LayoutType.horizontal ? 20 : 18;

      case UIElement.textGameInfo:
        return layoutType == LayoutType.horizontal ? 20 : 16;

      case UIElement.textStatusIndicator:
        return layoutType == LayoutType.horizontal ? 12 : 9;

      case UIElement.moveNumber:
        return 14; // Fixed size for move numbers

      default:
        return 16;
    }
  }

  static BorderRadius getBorderRadius(UIElement element) {
    switch (element) {
      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
      case UIElement.buttonNext:
      case UIElement.buttonPause:
        return BorderRadius.circular(12);

      case UIElement.gameStatusBar:
      case UIElement.cardContainer:
        return BorderRadius.circular(8);

      case UIElement.timerBarContainer:
      case UIElement.timerBarProgress:
        return BorderRadius.circular(4);

      case UIElement.boardBackground:
        return BorderRadius.circular(8);

      default:
        return BorderRadius.circular(4);
    }
  }

  static double getElevation(UIElement element, AppSkin skin) {
    // E-ink skin never has elevation
    if (skin == AppSkin.eink) return 0;

    switch (element) {
      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
      case UIElement.buttonNext:
      case UIElement.buttonPause:
        return 4;

      case UIElement.gameStatusBar:
      case UIElement.cardContainer:
        return 2;

      // case UIElement.boardBackground:
      //   return 8;

      case UIElement.appBarContainer:
        return 4;

      default:
        return 0;
    }
  }

  static double getStrokeWidth(UIElement element) {
    switch (element) {
      case UIElement.borderThin:
      case UIElement.boardGridLines:
        return 1.0;

      case UIElement.borderMedium:
      case UIElement.stoneWhiteBorder:
        return 2.0;

      case UIElement.borderThick:
        return 3.0;

      default:
        return 1.0;
    }
  }

  static double getBarThickness(UIElement element, LayoutType layoutType) {
    switch (element) {
      case UIElement.timerBarProgress:
        return 8.0;

      case UIElement.progressIndicator:
        return layoutType == LayoutType.horizontal ? 12.0 : 8.0;

      default:
        return 8.0;
    }
  }

  static Size getIconSize(UIElement element, LayoutType layoutType) {
    switch (element) {
      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
        return layoutType == LayoutType.horizontal
            ? const Size(20, 20)
            : const Size(16, 16);

      case UIElement.buttonNext:
      case UIElement.buttonPause:
        return const Size(24, 24);

      default:
        return const Size(20, 20);
    }
  }
}