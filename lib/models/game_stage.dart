/// Represents different game stages for midgame position filtering
enum GameStage {
  all,
  early,
  middle,
  late;

  /// Display name for the UI
  String get displayName {
    switch (this) {
      case GameStage.all:
        return 'All';
      case GameStage.early:
        return 'Early (Move 100)';
      case GameStage.middle:
        return 'Middle (Move 150)';
      case GameStage.late:
        return 'Late (Move 200)';
    }
  }

  /// Get the move numbers associated with this game stage
  List<int>? get moveNumbers {
    switch (this) {
      case GameStage.all:
        return null; // No filtering, show all positions
      case GameStage.early:
        return [100, 101];
      case GameStage.middle:
        return [150, 151];
      case GameStage.late:
        return [200, 201];
    }
  }

  /// Convert from string representation
  static GameStage fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'all':
        return GameStage.all;
      case 'early':
        return GameStage.early;
      case 'middle':
        return GameStage.middle;
      case 'late':
        return GameStage.late;
      default:
        return GameStage.all; // Default to all if unknown
    }
  }

  /// Convert to string representation for storage
  String get value {
    return name;
  }
}