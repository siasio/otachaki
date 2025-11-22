import 'dart:math';

class BlackTerritoryOption {
  final String territoryText; // e.g., "B=45", "B=47", "B=49"
  final int territoryCount; // The actual number of Black's territory points
  final int buttonPosition; // 0=left, 1=middle, 2=right

  const BlackTerritoryOption({
    required this.territoryText,
    required this.territoryCount,
    required this.buttonPosition,
  });
}

class BlackTerritoryOptions {
  final List<BlackTerritoryOption> options; // Always 3 options
  final int correctButtonPosition; // 0=left, 1=middle, 2=right

  const BlackTerritoryOptions({
    required this.options,
    required this.correctButtonPosition,
  });

  /// Generate three positioned black territory options based on the actual count and granularity
  /// Left button = smallest territory count among the 3 options
  /// Right button = largest territory count among the 3 options
  /// Middle button = remaining territory count
  /// Randomization determines which scenario (and thus which button is correct)
  static BlackTerritoryOptions generate({
    required int actualBlackTerritory,
    required int scoreGranularity,
  }) {
    final random = Random();

    // Generate 3 different scenarios and randomly pick one
    final scenarios = [
      _generateScenario1(actualBlackTerritory, scoreGranularity),
      _generateScenario2(actualBlackTerritory, scoreGranularity),
      _generateScenario3(actualBlackTerritory, scoreGranularity),
    ];

    return scenarios[random.nextInt(scenarios.length)];
  }

  /// Scenario 1: Actual count is in the middle
  /// Counts: [actual+granularity, actual, actual-granularity]
  /// Positions: [Left=smallest, Middle=actual✓, Right=largest]
  static BlackTerritoryOptions _generateScenario1(int actualTerritory, int granularity) {
    final leftCount = actualTerritory - granularity;     // Smallest
    final middleCount = actualTerritory;                 // Actual (correct)
    final rightCount = actualTerritory + granularity;    // Largest

    final options = [
      BlackTerritoryOption(
        territoryText: 'B=$leftCount',
        territoryCount: leftCount,
        buttonPosition: 0, // Left
      ),
      BlackTerritoryOption(
        territoryText: 'B=$middleCount',
        territoryCount: middleCount,
        buttonPosition: 1, // Middle
      ),
      BlackTerritoryOption(
        territoryText: 'B=$rightCount',
        territoryCount: rightCount,
        buttonPosition: 2, // Right
      ),
    ];

    return BlackTerritoryOptions(
      options: options,
      correctButtonPosition: 1, // Middle button is correct
    );
  }

  /// Scenario 2: Actual count is on the left (smallest)
  /// Counts: [actual, actual+granularity, actual+2*granularity]
  /// Positions: [Left=actual✓, Middle=middle, Right=largest]
  static BlackTerritoryOptions _generateScenario2(int actualTerritory, int granularity) {
    final leftCount = actualTerritory;                       // Actual (correct) - also smallest
    final middleCount = actualTerritory + granularity;       // Middle
    final rightCount = actualTerritory + (2 * granularity);  // Largest

    final options = [
      BlackTerritoryOption(
        territoryText: 'B=$leftCount',
        territoryCount: leftCount,
        buttonPosition: 0, // Left
      ),
      BlackTerritoryOption(
        territoryText: 'B=$middleCount',
        territoryCount: middleCount,
        buttonPosition: 1, // Middle
      ),
      BlackTerritoryOption(
        territoryText: 'B=$rightCount',
        territoryCount: rightCount,
        buttonPosition: 2, // Right
      ),
    ];

    return BlackTerritoryOptions(
      options: options,
      correctButtonPosition: 0, // Left button is correct
    );
  }

  /// Scenario 3: Actual count is on the right (largest)
  /// Counts: [actual-2*granularity, actual-granularity, actual]
  /// Positions: [Left=smallest, Middle=middle, Right=actual✓]
  static BlackTerritoryOptions _generateScenario3(int actualTerritory, int granularity) {
    final leftCount = actualTerritory - (2 * granularity);  // Smallest
    final middleCount = actualTerritory - granularity;      // Middle
    final rightCount = actualTerritory;                     // Actual (correct) - also largest

    final options = [
      BlackTerritoryOption(
        territoryText: 'B=$leftCount',
        territoryCount: leftCount,
        buttonPosition: 0, // Left
      ),
      BlackTerritoryOption(
        territoryText: 'B=$middleCount',
        territoryCount: middleCount,
        buttonPosition: 1, // Middle
      ),
      BlackTerritoryOption(
        territoryText: 'B=$rightCount',
        territoryCount: rightCount,
        buttonPosition: 2, // Right
      ),
    ];

    return BlackTerritoryOptions(
      options: options,
      correctButtonPosition: 2, // Right button is correct
    );
  }
}
