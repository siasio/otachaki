import 'element_registry.dart';
import 'unified_theme_provider.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';

class ThemeValidator {
  static void validateElementExists(UIElement element) {
    if (!UIElement.values.contains(element)) {
      throw ArgumentError('UI element $element is not registered in ElementRegistry');
    }
  }

  static void validateThemeConfiguration(AppSkin skin, LayoutType layoutType) {
    final provider = UnifiedThemeProvider(skin: skin, layoutType: layoutType);

    for (final element in UIElement.values) {
      try {
        final style = provider.getElementStyle(element);

        // Skip validation for elements that don't need colors (like spacing elements)
        final skippableElements = {
          UIElement.spacingSmall,
          UIElement.spacingMedium,
          UIElement.spacingLarge,
          UIElement.spacingExtraLarge,
        };

        if (!skippableElements.contains(element) &&
            style.color == null &&
            style.backgroundColor == null &&
            style.borderColor == null) {
          throw StateError('Element $element has no color, backgroundColor, or borderColor defined for skin $skin');
        }
      } catch (e) {
        throw StateError('Failed to get style for element $element with skin $skin: $e');
      }
    }
  }

  static void validateAllSkins() {
    for (final skin in AppSkin.values) {
      for (final layout in LayoutType.values) {
        validateThemeConfiguration(skin, layout);
      }
    }
  }
}

class ThemeComplianceError extends Error {
  final String message;

  ThemeComplianceError(this.message);

  @override
  String toString() => 'ThemeComplianceError: $message';
}