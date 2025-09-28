import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/themes/style_definitions.dart';
import 'package:countingapp/themes/element_registry.dart';
import 'package:countingapp/models/layout_type.dart';
import 'package:countingapp/models/app_skin.dart';

void main() {
  group('ElementStyle', () {
    test('should create with all properties', () {
      const style = ElementStyle(
        color: Colors.red,
        backgroundColor: Colors.blue,
        borderColor: Colors.green,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.all(4),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        elevation: 4,
        strokeWidth: 2,
        hasAnimation: true,
        animationDuration: Duration(milliseconds: 200),
      );

      expect(style.color, Colors.red);
      expect(style.backgroundColor, Colors.blue);
      expect(style.borderColor, Colors.green);
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.bold);
      expect(style.padding, const EdgeInsets.all(8));
      expect(style.margin, const EdgeInsets.all(4));
      expect(style.borderRadius, const BorderRadius.all(Radius.circular(8)));
      expect(style.elevation, 4);
      expect(style.strokeWidth, 2);
      expect(style.hasAnimation, true);
      expect(style.animationDuration, const Duration(milliseconds: 200));
    });

    test('should copyWith correctly', () {
      const original = ElementStyle(
        color: Colors.red,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

      final copied = original.copyWith(
        color: Colors.blue,
        fontSize: 20,
      );

      expect(copied.color, Colors.blue);
      expect(copied.fontSize, 20);
      expect(copied.fontWeight, FontWeight.normal); // Should retain original
    });
  });

  group('DimensionConfig', () {
    test('should return correct padding for spacing elements', () {
      expect(DimensionConfig.getPadding(UIElement.spacingSmall, LayoutType.vertical),
          const EdgeInsets.all(4));
      expect(DimensionConfig.getPadding(UIElement.spacingMedium, LayoutType.vertical),
          const EdgeInsets.all(8));
      expect(DimensionConfig.getPadding(UIElement.spacingLarge, LayoutType.vertical),
          const EdgeInsets.all(16));
      expect(DimensionConfig.getPadding(UIElement.spacingExtraLarge, LayoutType.vertical),
          const EdgeInsets.all(24));
    });

    test('should return layout-specific padding for result buttons', () {
      const verticalPadding = EdgeInsets.symmetric(horizontal: 6);
      const horizontalPadding = EdgeInsets.symmetric(vertical: 8);

      expect(DimensionConfig.getPadding(UIElement.buttonResultWhite, LayoutType.vertical),
          verticalPadding);
      expect(DimensionConfig.getPadding(UIElement.buttonResultWhite, LayoutType.horizontal),
          horizontalPadding);

      expect(DimensionConfig.getPadding(UIElement.buttonResultBlack, LayoutType.vertical),
          verticalPadding);
      expect(DimensionConfig.getPadding(UIElement.buttonResultBlack, LayoutType.horizontal),
          horizontalPadding);

      expect(DimensionConfig.getPadding(UIElement.buttonResultDraw, LayoutType.vertical),
          verticalPadding);
      expect(DimensionConfig.getPadding(UIElement.buttonResultDraw, LayoutType.horizontal),
          horizontalPadding);
    });

    test('should return correct font sizes for different layouts', () {
      // Test heading sizes
      expect(DimensionConfig.getFontSize(UIElement.textHeading, LayoutType.vertical), 20);
      expect(DimensionConfig.getFontSize(UIElement.textHeading, LayoutType.horizontal), 24);

      // Test body sizes
      expect(DimensionConfig.getFontSize(UIElement.textBody, LayoutType.vertical), 16);
      expect(DimensionConfig.getFontSize(UIElement.textBody, LayoutType.horizontal), 18);

      // Test caption sizes
      expect(DimensionConfig.getFontSize(UIElement.textCaption, LayoutType.vertical), 12);
      expect(DimensionConfig.getFontSize(UIElement.textCaption, LayoutType.horizontal), 14);
    });

    test('should return correct border radius for elements', () {
      expect(DimensionConfig.getBorderRadius(UIElement.buttonResultWhite),
          BorderRadius.circular(12));
      expect(DimensionConfig.getBorderRadius(UIElement.gameStatusBar),
          BorderRadius.circular(8));
      expect(DimensionConfig.getBorderRadius(UIElement.timerBarContainer),
          BorderRadius.circular(4));
    });

    test('should return zero elevation for e-ink skin', () {
      for (final element in [
        UIElement.buttonResultWhite,
        UIElement.gameStatusBar,
        UIElement.boardBackground,
        UIElement.appBarContainer,
      ]) {
        expect(DimensionConfig.getElevation(element, AppSkin.eink), 0,
            reason: '$element should have zero elevation for e-ink skin');
      }
    });

    test('should return positive elevation for non-e-ink skins', () {
      for (final skin in [AppSkin.classic, AppSkin.modern, AppSkin.ocean]) {
        expect(DimensionConfig.getElevation(UIElement.buttonResultWhite, skin), greaterThan(0),
            reason: 'Button should have elevation for $skin');
        expect(DimensionConfig.getElevation(UIElement.boardBackground, skin), greaterThan(0),
            reason: 'Board should have elevation for $skin');
      }
    });

    test('should return correct stroke widths', () {
      expect(DimensionConfig.getStrokeWidth(UIElement.borderThin), 1.0);
      expect(DimensionConfig.getStrokeWidth(UIElement.borderMedium), 2.0);
      expect(DimensionConfig.getStrokeWidth(UIElement.borderThick), 3.0);
      expect(DimensionConfig.getStrokeWidth(UIElement.boardGridLines), 1.0);
      expect(DimensionConfig.getStrokeWidth(UIElement.stoneWhiteBorder), 2.0);
    });

    test('should return layout-specific bar thickness', () {
      expect(DimensionConfig.getBarThickness(UIElement.timerBarProgress, LayoutType.vertical), 8.0);
      expect(DimensionConfig.getBarThickness(UIElement.timerBarProgress, LayoutType.horizontal), 8.0);

      expect(DimensionConfig.getBarThickness(UIElement.progressIndicator, LayoutType.vertical), 8.0);
      expect(DimensionConfig.getBarThickness(UIElement.progressIndicator, LayoutType.horizontal), 12.0);
    });

    test('should return layout-specific icon sizes', () {
      const verticalSize = Size(16, 16);
      const horizontalSize = Size(20, 20);

      expect(DimensionConfig.getIconSize(UIElement.buttonResultWhite, LayoutType.vertical),
          verticalSize);
      expect(DimensionConfig.getIconSize(UIElement.buttonResultWhite, LayoutType.horizontal),
          horizontalSize);

      const buttonSize = Size(24, 24);
      expect(DimensionConfig.getIconSize(UIElement.buttonNext, LayoutType.vertical),
          buttonSize);
      expect(DimensionConfig.getIconSize(UIElement.buttonPause, LayoutType.horizontal),
          buttonSize);
    });
  });
}