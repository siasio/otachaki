import 'package:flutter/foundation.dart';
import 'theme_validator.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';

class ThemeEnforcement {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    if (kDebugMode) {
      try {
        ThemeValidator.validateAllSkins();
        debugPrint('✅ Theme validation passed for all skins and layouts');
      } catch (e) {
        debugPrint('❌ Theme validation failed: $e');
        throw ThemeComplianceError('Theme system validation failed: $e');
      }
    }

    _initialized = true;
  }

  static void enforceThemeUsage({
    required String widgetName,
    required AppSkin skin,
    required LayoutType layoutType,
  }) {
    if (kDebugMode) {
      debugPrint('🎨 $widgetName using theme: $skin, layout: $layoutType');
    }
  }

  static T enforceElementUsage<T>(
    String widgetName,
    String elementName,
    T Function() styleGetter,
  ) {
    if (kDebugMode) {
      debugPrint('🎯 $widgetName accessing style for: $elementName');
    }
    return styleGetter();
  }
}