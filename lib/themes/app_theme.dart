import 'package:flutter/material.dart';
import '../models/app_skin.dart';

class AppTheme {
  static ThemeData getTheme(AppSkin skin) {
    switch (skin) {
      case AppSkin.classic:
        return _classicTheme;
      case AppSkin.modern:
        return _modernTheme;
      case AppSkin.eink:
        return _einkTheme;
    }
  }

  // Classic brown wood theme (current default)
  static final ThemeData _classicTheme = ThemeData(
    primarySwatch: Colors.brown,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F5DC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8B4513),
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B4513),
      brightness: Brightness.light,
    ),
  );

  // Modern dark theme
  static final ThemeData _modernTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),
    cardColor: const Color(0xFF2D2D2D),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
  );


  // E-ink minimalist black and white theme
  static final ThemeData _einkTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: false, // Disable Material 3 for simpler appearance
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0, // No shadow for e-ink
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: Colors.white,
    cardTheme: const CardThemeData(
      elevation: 0, // No shadow for e-ink
      color: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.grey,
      surface: Colors.white,
      background: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      outline: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        side: const BorderSide(color: Colors.black, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        side: const BorderSide(color: Colors.black, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Colors.black),
      displayLarge: TextStyle(color: Colors.black),
      displayMedium: TextStyle(color: Colors.black),
      displaySmall: TextStyle(color: Colors.black),
      headlineLarge: TextStyle(color: Colors.black),
      headlineMedium: TextStyle(color: Colors.black),
      headlineSmall: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleSmall: TextStyle(color: Colors.black),
      labelLarge: TextStyle(color: Colors.black),
      labelMedium: TextStyle(color: Colors.black),
      labelSmall: TextStyle(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.black,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: Colors.black),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.black),
      hintStyle: TextStyle(color: Colors.grey),
      helperStyle: TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    ),
  );
}

// Legacy SkinConfig class removed - replaced by UnifiedThemeProvider
// Import '../themes/unified_theme_provider.dart' and '../themes/element_registry.dart' instead