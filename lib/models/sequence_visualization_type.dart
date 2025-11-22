/// Type of visualization for move sequences
enum SequenceVisualizationType {
  /// Show move sequence as numbers (1, 2, 3...)
  numbers('numbers'),

  /// Show move sequence as animated appearing/disappearing dots
  dots('dots'),

  /// Don't show move sequence at all
  dontShow('dont-show');

  const SequenceVisualizationType(this.value);

  /// The string representation of the visualization type
  final String value;

  /// Convert from string value to enum
  static SequenceVisualizationType? fromString(String? value) {
    if (value == null) return null;
    for (SequenceVisualizationType type in SequenceVisualizationType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case SequenceVisualizationType.numbers:
        return 'Numbers';
      case SequenceVisualizationType.dots:
        return 'Dots';
      case SequenceVisualizationType.dontShow:
        return "Don't show";
    }
  }

  @override
  String toString() => value;
}
