/// Display mode for move sequences on the board
enum SequenceDisplayMode {
  /// Show numbers only on empty intersections (problem view)
  numbersOnly,

  /// Show stones with numbers overlaid (review view)
  stonesWithNumbers,
}

extension SequenceDisplayModeExtension on SequenceDisplayMode {
  /// Human-readable name for the display mode
  String get displayName {
    switch (this) {
      case SequenceDisplayMode.numbersOnly:
        return 'Numbers Only';
      case SequenceDisplayMode.stonesWithNumbers:
        return 'Stones with Numbers';
    }
  }

  /// Whether to show stones for sequence positions
  bool get showStones {
    switch (this) {
      case SequenceDisplayMode.numbersOnly:
        return false;
      case SequenceDisplayMode.stonesWithNumbers:
        return true;
    }
  }

  /// Whether to show numbers for sequence positions
  bool get showNumbers {
    return true; // Both modes show numbers
  }
}