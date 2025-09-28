import 'sequence_display_mode.dart';

/// Defines how the board should be displayed in different contexts
enum BoardViewMode {
  /// Problem view: timer running, user solving
  problem,

  /// Review view: after answering, showing feedback
  review,
}

extension BoardViewModeExtension on BoardViewMode {
  /// Human-readable name for the view mode
  String get displayName {
    switch (this) {
      case BoardViewMode.problem:
        return 'Problem View';
      case BoardViewMode.review:
        return 'Review View';
    }
  }

  /// Whether stones should be hidden for sequence positions
  bool get hideSequenceStones {
    switch (this) {
      case BoardViewMode.problem:
        return true; // Hide stones where numbers should appear
      case BoardViewMode.review:
        return false; // Show all stones
    }
  }

  /// Default sequence display mode for this view
  SequenceDisplayMode get defaultSequenceDisplayMode {
    switch (this) {
      case BoardViewMode.problem:
        return SequenceDisplayMode.numbersOnly;
      case BoardViewMode.review:
        return SequenceDisplayMode.stonesWithNumbers;
    }
  }

  /// Whether ownership can be displayed in this view
  bool get canShowOwnership {
    switch (this) {
      case BoardViewMode.problem:
        return false; // Never show ownership in problem view
      case BoardViewMode.review:
        return true; // Can show ownership in review view
    }
  }
}