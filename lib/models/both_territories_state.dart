import 'dart:math';

/// Represents the state of a single territory button (black or white).
class TerritoryButtonState {
  final String displayText; // e.g., "B=45" or "W=52"
  final int territoryCount;
  final int buttonPosition; // 0=left, 1=middle, 2=right
  final bool isCorrect;
  final bool wasPressed;

  const TerritoryButtonState({
    required this.displayText,
    required this.territoryCount,
    required this.buttonPosition,
    required this.isCorrect,
    this.wasPressed = false,
  });

  TerritoryButtonState copyWith({
    String? displayText,
    int? territoryCount,
    int? buttonPosition,
    bool? isCorrect,
    bool? wasPressed,
  }) {
    return TerritoryButtonState(
      displayText: displayText ?? this.displayText,
      territoryCount: territoryCount ?? this.territoryCount,
      buttonPosition: buttonPosition ?? this.buttonPosition,
      isCorrect: isCorrect ?? this.isCorrect,
      wasPressed: wasPressed ?? this.wasPressed,
    );
  }
}

/// Manages the complete state for both territories prediction mode.
///
/// Contains two rows of buttons (black territory and white territory),
/// tracks which button is selected in each row, and only considers
/// the problem answered when both selections are made.
class BothTerritoriesState {
  final List<TerritoryButtonState> blackButtons; // Always 3 buttons
  final List<TerritoryButtonState> whiteButtons; // Always 3 buttons
  final int? selectedBlackPosition; // 0, 1, or 2
  final int? selectedWhitePosition; // 0, 1, or 2
  final bool hasAnswered; // True when both selections are made

  const BothTerritoriesState({
    required this.blackButtons,
    required this.whiteButtons,
    this.selectedBlackPosition,
    this.selectedWhitePosition,
    this.hasAnswered = false,
  });

  /// Generate initial state with both black and white territory options
  static BothTerritoriesState generate({
    required int actualBlackTerritory,
    required int actualWhiteTerritory,
    required double komi,
    required int scoreGranularity,
  }) {
    final random = Random();
    
    // Generate black territory options
    final blackScenarioIndex = random.nextInt(3);
    final blackOptions = _generateTerritoryOptions(
      actualTerritory: actualBlackTerritory,
      scoreGranularity: scoreGranularity,
      scenarioIndex: blackScenarioIndex,
      isBlack: true,
    );

    // Generate white territory options (including komi)
    final whiteScenarioIndex = random.nextInt(3);
    final actualWhiteWithKomi = (actualWhiteTerritory + komi).round();
    final whiteOptions = _generateTerritoryOptions(
      actualTerritory: actualWhiteWithKomi,
      scoreGranularity: scoreGranularity,
      scenarioIndex: whiteScenarioIndex,
      isBlack: false,
    );

    return BothTerritoriesState(
      blackButtons: blackOptions,
      whiteButtons: whiteOptions,
    );
  }

  /// Generate three territory options for a single row
  static List<TerritoryButtonState> _generateTerritoryOptions({
    required int actualTerritory,
    required int scoreGranularity,
    required int scenarioIndex,
    required bool isBlack,
  }) {
    final prefix = isBlack ? 'B=' : 'W=';
    
    List<int> counts;
    int correctPosition;

    switch (scenarioIndex) {
      case 0: // Actual is in the middle
        counts = [
          actualTerritory - scoreGranularity,  // Left
          actualTerritory,                      // Middle (correct)
          actualTerritory + scoreGranularity,   // Right
        ];
        correctPosition = 1;
        break;
      case 1: // Actual is on the left
        counts = [
          actualTerritory,                          // Left (correct)
          actualTerritory + scoreGranularity,       // Middle
          actualTerritory + (2 * scoreGranularity), // Right
        ];
        correctPosition = 0;
        break;
      case 2: // Actual is on the right
        counts = [
          actualTerritory - (2 * scoreGranularity), // Left
          actualTerritory - scoreGranularity,       // Middle
          actualTerritory,                          // Right (correct)
        ];
        correctPosition = 2;
        break;
      default:
        throw ArgumentError('Invalid scenario index');
    }

    return List.generate(3, (index) {
      return TerritoryButtonState(
        displayText: '$prefix${counts[index]}',
        territoryCount: counts[index],
        buttonPosition: index,
        isCorrect: index == correctPosition,
      );
    });
  }

  BothTerritoriesState copyWith({
    List<TerritoryButtonState>? blackButtons,
    List<TerritoryButtonState>? whiteButtons,
    int? selectedBlackPosition,
    int? selectedWhitePosition,
    bool? hasAnswered,
  }) {
    return BothTerritoriesState(
      blackButtons: blackButtons ?? this.blackButtons,
      whiteButtons: whiteButtons ?? this.whiteButtons,
      selectedBlackPosition: selectedBlackPosition ?? this.selectedBlackPosition,
      selectedWhitePosition: selectedWhitePosition ?? this.selectedWhitePosition,
      hasAnswered: hasAnswered ?? this.hasAnswered,
    );
  }

  /// Mark a black territory button as pressed
  BothTerritoriesState selectBlackButton(int position) {
    final updatedBlackButtons = blackButtons.asMap().entries.map((entry) {
      final button = entry.value;
      return button.copyWith(wasPressed: entry.key == position);
    }).toList();

    // Check if both selections are now complete
    final bothSelected = selectedWhitePosition != null;

    return copyWith(
      blackButtons: updatedBlackButtons,
      selectedBlackPosition: position,
      hasAnswered: bothSelected,
    );
  }

  /// Mark a white territory button as pressed
  BothTerritoriesState selectWhiteButton(int position) {
    final updatedWhiteButtons = whiteButtons.asMap().entries.map((entry) {
      final button = entry.value;
      return button.copyWith(wasPressed: entry.key == position);
    }).toList();

    // Check if both selections are now complete
    final bothSelected = selectedBlackPosition != null;

    return copyWith(
      whiteButtons: updatedWhiteButtons,
      selectedWhitePosition: position,
      hasAnswered: bothSelected,
    );
  }

  /// Returns true if both selections are correct
  bool get wasAnswerCorrect {
    if (!hasAnswered || selectedBlackPosition == null || selectedWhitePosition == null) {
      return false;
    }

    final blackCorrect = blackButtons[selectedBlackPosition!].isCorrect;
    final whiteCorrect = whiteButtons[selectedWhitePosition!].isCorrect;

    return blackCorrect && whiteCorrect;
  }

  /// Get the correct black territory count
  int get correctBlackTerritory {
    return blackButtons.firstWhere((b) => b.isCorrect).territoryCount;
  }

  /// Get the correct white territory count (including komi)
  int get correctWhiteTerritory {
    return whiteButtons.firstWhere((b) => b.isCorrect).territoryCount;
  }
}
