/// Position display types for final datasets
enum PositionType {
  /// Display ultimate stones (filled neutral points)
  withFilledNeutralPoints('with-filled-neutral-points'),

  /// Display original stones (before filling neutral points)
  beforeFillingNeutralPoints('before-filling-neutral-points');

  const PositionType(this.value);

  /// The string representation of the position type
  final String value;

  /// Convert from string value to enum
  static PositionType? fromString(String? value) {
    if (value == null) return null;
    for (PositionType type in PositionType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case PositionType.withFilledNeutralPoints:
        return 'With filled neutral points';
      case PositionType.beforeFillingNeutralPoints:
        return 'Before filling neutral points';
    }
  }

  /// Explanation text shown below the dropdown
  String get explanationText {
    switch (this) {
      case PositionType.withFilledNeutralPoints:
        return 'You can use area or territory scoring - the result will be the same.';
      case PositionType.beforeFillingNeutralPoints:
        return 'Count points with territory scoring.';
    }
  }

  /// Whether to show game info for this position type
  bool get showGameInfo {
    switch (this) {
      case PositionType.withFilledNeutralPoints:
        return false;
      case PositionType.beforeFillingNeutralPoints:
        return true;
    }
  }

  /// Whether to show move sequence selection for this position type
  bool get showMoveSequenceSelection {
    switch (this) {
      case PositionType.withFilledNeutralPoints:
        return false;
      case PositionType.beforeFillingNeutralPoints:
        return true;
    }
  }

  /// Whether overlay mode is available for ownership display
  bool get allowOverlayMode {
    switch (this) {
      case PositionType.withFilledNeutralPoints:
        return true;
      case PositionType.beforeFillingNeutralPoints:
        return false; // Only squares allowed
    }
  }

  @override
  String toString() => value;
}