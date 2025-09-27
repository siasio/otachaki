import 'package:flutter/material.dart';
import '../models/layout_type.dart';

class AdaptiveAppBar extends StatelessWidget {
  final LayoutType layoutType;
  final VoidCallback onInfoPressed;
  final VoidCallback onSettingsPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const AdaptiveAppBar({
    super.key,
    required this.layoutType,
    required this.onInfoPressed,
    required this.onSettingsPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (layoutType == LayoutType.horizontal) {
      return _buildVerticalAppBar(context);
    } else {
      return _buildHorizontalAppBar(context);
    }
  }

  Widget _buildHorizontalAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: onInfoPressed,
        tooltip: 'App Information',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettingsPressed,
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildVerticalAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final effectiveBackgroundColor = backgroundColor ??
        appBarTheme.backgroundColor ??
        theme.colorScheme.surface;
    final effectiveForegroundColor = foregroundColor ??
        appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;

    return Material(
      elevation: elevation,
      color: effectiveBackgroundColor,
      child: SizedBox(
        width: 72, // Standard width for vertical app bar
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Settings icon at the top
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: effectiveForegroundColor,
                ),
                onPressed: onSettingsPressed,
                tooltip: 'Settings',
              ),
            ),

            // Info icon at the bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: effectiveForegroundColor,
                ),
                onPressed: onInfoPressed,
                tooltip: 'App Information',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the height needed for horizontal app bar
  static double getHorizontalHeight() {
    return kToolbarHeight;
  }

  /// Returns the width needed for vertical app bar
  static double getVerticalWidth() {
    return 72.0;
  }
}