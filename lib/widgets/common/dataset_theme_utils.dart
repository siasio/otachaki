import 'package:flutter/material.dart';
import '../../models/dataset_type.dart';
import '../../models/app_skin.dart';

/// Shared utilities for dataset theming and colors
/// Used across dataset selectors to maintain consistency
class DatasetThemeUtils {
  /// Get the color for a dataset type based on app skin
  static Color getDatasetTypeColor(DatasetType type, AppSkin appSkin) {
    if (appSkin == AppSkin.eink) {
      // E-ink theme uses only black/white/grays
      switch (type) {
        case DatasetType.final9x9:
          return Colors.black;
        case DatasetType.final13x13:
          return Colors.grey.shade800;
        case DatasetType.final19x19:
          return Colors.grey.shade700;
        case DatasetType.midgame19x19:
          return Colors.grey.shade500;
        case DatasetType.partialPositions:
          return Colors.grey.shade300;
      }
    }

    // Other themes use original colors
    switch (type) {
      case DatasetType.final9x9:
        return Colors.green;
      case DatasetType.final13x13:
        return Colors.teal;
      case DatasetType.final19x19:
        return Colors.blue;
      case DatasetType.midgame19x19:
        return Colors.orange;
      case DatasetType.partialPositions:
        return Colors.purple;
    }
  }

  /// Get the background color for a selected dataset chip/button
  static Color getSelectedBackgroundColor(DatasetType type, AppSkin appSkin) {
    final baseColor = getDatasetTypeColor(type, appSkin);
    if (appSkin == AppSkin.eink) {
      return Colors.grey.shade200;
    }
    return baseColor.withOpacity(0.2);
  }

  /// Get the foreground color for a selected dataset chip/button
  static Color getSelectedForegroundColor(DatasetType type, AppSkin appSkin) {
    final baseColor = getDatasetTypeColor(type, appSkin);
    if (appSkin == AppSkin.eink) {
      return Colors.black;
    }
    return baseColor.withOpacity(0.8);
  }

  /// Get the border color for a selected dataset chip/button
  static Color getSelectedBorderColor(DatasetType type, AppSkin appSkin) {
    if (appSkin == AppSkin.eink) {
      return Colors.black;
    }
    return getDatasetTypeColor(type, appSkin);
  }

  /// Get the default border color for unselected items
  static Color getDefaultBorderColor() {
    return Colors.grey.shade300;
  }
}