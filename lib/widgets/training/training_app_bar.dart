import 'package:flutter/material.dart';
import '../../models/global_configuration.dart';
import '../../models/app_skin.dart';
import '../../models/layout_type.dart';
import '../../themes/unified_theme_provider.dart';
import '../../themes/element_registry.dart';
import '../adaptive_app_bar.dart';

/// App bar component for the training screen
/// Extracted from TrainingScreen to improve maintainability
class TrainingAppBar extends StatelessWidget {
  final GlobalConfiguration? globalConfig;
  final VoidCallback onInfoPressed;
  final VoidCallback onConfigPressed;

  const TrainingAppBar({
    super.key,
    required this.globalConfig,
    required this.onInfoPressed,
    required this.onConfigPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currentSkin = globalConfig?.appSkin ?? AppSkin.classic;
    final themeProvider = UnifiedThemeProvider(
      skin: currentSkin,
      layoutType: globalConfig?.layoutType ?? LayoutType.vertical,
    );

    return AdaptiveAppBar(
      layoutType: globalConfig?.layoutType ?? LayoutType.vertical,
      onInfoPressed: onInfoPressed,
      onSettingsPressed: onConfigPressed,
      backgroundColor: themeProvider.getElementStyle(UIElement.appBarContainer).backgroundColor,
      foregroundColor: themeProvider.getElementStyle(UIElement.textHeading).color,
    );
  }
}