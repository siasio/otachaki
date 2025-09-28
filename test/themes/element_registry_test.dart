import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/themes/element_registry.dart';

void main() {
  group('UIElement', () {
    test('should have all board elements in board category', () {
      final boardElements = [
        UIElement.boardBackground,
        UIElement.boardGridLines,
        UIElement.boardStarPoints,
        UIElement.stoneBlack,
        UIElement.stoneWhite,
        UIElement.stoneBlackBorder,
        UIElement.stoneWhiteBorder,
        UIElement.lastMoveMarker,
        UIElement.moveNumber,
        UIElement.focusOverlay,
      ];

      for (final element in boardElements) {
        expect(element.category, ElementCategory.board,
            reason: '$element should be in board category');
      }
    });

    test('should have all button elements in button category', () {
      final buttonElements = [
        UIElement.buttonResultWhite,
        UIElement.buttonResultBlack,
        UIElement.buttonResultDraw,
        UIElement.buttonNext,
        UIElement.buttonPause,
        UIElement.buttonNavigation,
      ];

      for (final element in buttonElements) {
        expect(element.category, ElementCategory.button,
            reason: '$element should be in button category');
      }
    });

    test('should have all container elements in container category', () {
      final containerElements = [
        UIElement.gameStatusBar,
        UIElement.timerBarContainer,
        UIElement.timerBarProgress,
        UIElement.progressIndicator,
        UIElement.cardContainer,
        UIElement.appBarContainer,
        UIElement.feedbackOverlay,
      ];

      for (final element in containerElements) {
        expect(element.category, ElementCategory.container,
            reason: '$element should be in container category');
      }
    });

    test('should have all text elements in text category', () {
      final textElements = [
        UIElement.textHeading,
        UIElement.textBody,
        UIElement.textCaption,
        UIElement.textButtonLabel,
        UIElement.textStatusIndicator,
        UIElement.textGameInfo,
      ];

      for (final element in textElements) {
        expect(element.category, ElementCategory.text,
            reason: '$element should be in text category');
      }
    });

    test('should have all interactive elements in interactive category', () {
      final interactiveElements = [
        UIElement.correctIndicator,
        UIElement.incorrectIndicator,
      ];

      for (final element in interactiveElements) {
        expect(element.category, ElementCategory.interactive,
            reason: '$element should be in interactive category');
      }
    });

    test('should have all layout elements in layout category', () {
      final layoutElements = [
        UIElement.spacingSmall,
        UIElement.spacingMedium,
        UIElement.spacingLarge,
        UIElement.spacingExtraLarge,
      ];

      for (final element in layoutElements) {
        expect(element.category, ElementCategory.layout,
            reason: '$element should be in layout category');
      }
    });

    test('should have all decoration elements in decoration category', () {
      final decorationElements = [
        UIElement.borderThin,
        UIElement.borderMedium,
        UIElement.borderThick,
        UIElement.elevationLow,
        UIElement.elevationMedium,
        UIElement.elevationHigh,
      ];

      for (final element in decorationElements) {
        expect(element.category, ElementCategory.decoration,
            reason: '$element should be in decoration category');
      }
    });

    test('should have all elements categorized', () {
      // Ensure no elements are missed in categorization
      for (final element in UIElement.values) {
        expect(() => element.category, returnsNormally,
            reason: '$element should have a valid category');
      }
    });

    test('should have unique enum values', () {
      final values = UIElement.values;
      final uniqueValues = values.toSet();
      expect(values.length, uniqueValues.length,
          reason: 'All UIElement values should be unique');
    });
  });

  group('ElementCategory', () {
    test('should have all expected categories', () {
      final expectedCategories = [
        ElementCategory.board,
        ElementCategory.button,
        ElementCategory.container,
        ElementCategory.text,
        ElementCategory.interactive,
        ElementCategory.layout,
        ElementCategory.decoration,
      ];

      expect(ElementCategory.values, expectedCategories);
    });
  });
}