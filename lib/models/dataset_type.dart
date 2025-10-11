/// Dataset types enum for Go Territory Trainer project.
/// These represent the 5 base dataset types that define different training scenarios.
enum DatasetType {
  /// Final positions on 9x9 boards for quick territory evaluation practice
  final9x9('final-9x9'),

  /// Final positions on 13x13 boards for intermediate territory evaluation
  final13x13('final-13x13'),

  /// Final positions on 19x19 boards for full-size territory evaluation
  final19x19('final-19x19'),

  /// Middle game positions on 19x19 boards for score estimation during play
  midgame19x19('midgame-19x19'),

  /// Partial board positions (hidden from UI)
  partialPositions('partial-positions');

  const DatasetType(this.value);

  /// The string representation of the dataset type
  final String value;

  /// Convert from string value to enum
  static DatasetType? fromString(String? value) {
    if (value == null) return null;
    for (DatasetType type in DatasetType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  @override
  String toString() => value;
}