import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/themes/app_theme.dart';
import 'package:otachaki/themes/unified_theme_provider.dart';
import 'package:otachaki/themes/element_registry.dart';
import 'package:otachaki/models/app_skin.dart';
import 'package:otachaki/models/layout_type.dart';

void main() {
  group('AppTheme', () {
    test('should return classic theme for AppSkin.classic', () {
      final theme = AppTheme.getTheme(AppSkin.classic);

      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F5DC));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF8B4513));
    });

    test('should return modern dark theme for AppSkin.modern', () {
      final theme = AppTheme.getTheme(AppSkin.modern);

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
    });

    test('should return e-ink theme for AppSkin.eink', () {
      final theme = AppTheme.getTheme(AppSkin.eink);

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.appBarTheme.backgroundColor, Colors.white);
      expect(theme.appBarTheme.foregroundColor, Colors.black);
      expect(theme.appBarTheme.elevation, 0);
    });
  });

  group('UnifiedThemeProvider', () {
    test('should return correct button styles for white result button', () {
      final provider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.vertical);
      final style = provider.getElementStyle(UIElement.buttonResultWhite);

      expect(style.backgroundColor, Colors.white);
      expect(style.color, Colors.black);
    });

    test('should return correct button styles for black result button', () {
      final provider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.vertical);
      final style = provider.getElementStyle(UIElement.buttonResultBlack);

      expect(style.backgroundColor, Colors.black87);
      expect(style.color, Colors.white);
    });

    test('should return correct button styles for draw result button', () {
      final provider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.vertical);
      final style = provider.getElementStyle(UIElement.buttonResultDraw);

      expect(style.backgroundColor, const Color(0xFFD4B896));
      expect(style.color, const Color(0xFF5D4037));
    });

    test('should return correct board styles for different skins', () {
      final classicProvider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.vertical);
      final modernProvider = UnifiedThemeProvider(skin: AppSkin.modern, layoutType: LayoutType.vertical);
      final einkProvider = UnifiedThemeProvider(skin: AppSkin.eink, layoutType: LayoutType.vertical);

      expect(classicProvider.getElementStyle(UIElement.boardBackground).backgroundColor, const Color(0xFFDEB887));
      expect(modernProvider.getElementStyle(UIElement.boardBackground).backgroundColor, const Color(0xFF424242));
      expect(einkProvider.getElementStyle(UIElement.boardBackground).backgroundColor, Colors.white);
    });

    test('should return different styles for different layouts', () {
      final verticalProvider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.vertical);
      final horizontalProvider = UnifiedThemeProvider(skin: AppSkin.classic, layoutType: LayoutType.horizontal);

      final verticalStyle = verticalProvider.getElementStyle(UIElement.buttonResultWhite);
      final horizontalStyle = horizontalProvider.getElementStyle(UIElement.buttonResultWhite);

      // Layouts should have the same colors but potentially different dimensions
      expect(verticalStyle.backgroundColor, horizontalStyle.backgroundColor);
      expect(verticalStyle.color, horizontalStyle.color);
    });

    test('should handle e-ink specific styles', () {
      final provider = UnifiedThemeProvider(skin: AppSkin.eink, layoutType: LayoutType.vertical);

      // E-ink should have no animations
      final buttonStyle = provider.getElementStyle(UIElement.buttonResultWhite);
      expect(buttonStyle.hasAnimation, false);

      // E-ink should have no elevation
      expect(buttonStyle.elevation, 0);
    });
  });
}