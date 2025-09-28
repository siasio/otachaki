/// Display mode for ownership information on the board
enum OwnershipDisplayMode {
  /// No ownership information displayed
  none,

  /// Small squares on intersections sized by ownership strength
  squares,

  /// Semi-transparent overlay covering intersections
  overlay,
}

extension OwnershipDisplayModeExtension on OwnershipDisplayMode {
  /// Human-readable name for the display mode
  String get displayName {
    switch (this) {
      case OwnershipDisplayMode.none:
        return 'None';
      case OwnershipDisplayMode.squares:
        return 'Squares';
      case OwnershipDisplayMode.overlay:
        return 'Overlay';
    }
  }

  /// Whether to show ownership information
  bool get showOwnership {
    return this != OwnershipDisplayMode.none;
  }

  /// Whether to use overlay style rendering
  bool get useOverlay {
    return this == OwnershipDisplayMode.overlay;
  }

  /// Whether to use square style rendering
  bool get useSquares {
    return this == OwnershipDisplayMode.squares;
  }
}