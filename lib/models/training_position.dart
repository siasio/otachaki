import '../core/dataset_parser.dart' as core;
import '../core/go_logic.dart';
import '../core/game_result_parser.dart';
import '../core/position_scoring.dart';
import 'dataset_type.dart';
import 'position_type.dart';
import 'board_view_mode.dart';


class TrainingPosition {
  final String id;
  final int boardSize;
  final String stonesBase64;
  final double score;
  final GameInfo? gameInfo;
  final String? movesBase64;
  final int numberOfMoves;
  final String? ownershipBase64;
  final int? blackTerritory;
  final int? whiteTerritory;
  final String? ultimateStonesBase64;

  // REMOVED: Captured stones - prisoners are always equal, no need to track them
  // final int blackCaptured;
  // final int whiteCaptured;
  final double komi;

  // Final position generator fields (optional)
  // REMOVED: Ultimate captured stones - prisoners are always equal
  // final int? ultimateBlackCaptured;
  // final int? ultimateWhiteCaptured;
  final bool? additionalWhiteMove;
  final int? moveNumber;

  const TrainingPosition({
    required this.id,
    required this.boardSize,
    required this.stonesBase64,
    required this.score,
    this.gameInfo,
    this.movesBase64,
    this.numberOfMoves = 0,
    this.ownershipBase64,
    this.blackTerritory,
    this.whiteTerritory,
    this.ultimateStonesBase64,
    // REMOVED: Captured stones - prisoners are always equal
    // required this.blackCaptured,
    // required this.whiteCaptured,
    required this.komi,
    // REMOVED: Ultimate captured stones - prisoners are always equal
    // this.ultimateBlackCaptured,
    // this.ultimateWhiteCaptured,
    this.additionalWhiteMove,
    this.moveNumber,
  });

  factory TrainingPosition.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseTrainingPositionToMap(json);
    return TrainingPosition(
      id: parsed['id'] as String,
      boardSize: parsed['board_size'] as int,
      stonesBase64: parsed['stones'] as String,
      score: parsed['score'] as double,
      gameInfo: parsed['game_info'] != null
          ? GameInfo.fromJson(parsed['game_info'] as Map<String, dynamic>)
          : null,
      movesBase64: parsed['moves'] as String?,
      numberOfMoves: parsed['number_of_moves'] as int? ?? 0,
      ownershipBase64: parsed['ownership'] as String?,
      blackTerritory: parsed['black_territory'] as int?,
      whiteTerritory: parsed['white_territory'] as int?,
      ultimateStonesBase64: parsed['ultimate_stones'] as String?,
      // REMOVED: Captured stones - prisoners are always equal
      // blackCaptured: parsed['black_captured'] as int,
      // whiteCaptured: parsed['white_captured'] as int,
      komi: parsed['komi'] as double,
      // REMOVED: Ultimate captured stones - prisoners are always equal
      // ultimateBlackCaptured: parsed['ultimate_black_captured'] as int?,
      // ultimateWhiteCaptured: parsed['ultimate_white_captured'] as int?,
      additionalWhiteMove: parsed['additional_white_move'] as bool?,
      moveNumber: parsed['move_number'] as int?,
    );
  }

  /// Decode the base64 stones to a 2D array of integers
  /// Returns boardSize x boardSize array where 0=empty, 1=black, 2=white
  List<List<int>> decodeStones() {
    return GoLogic.decodeStones(stonesBase64, boardSize);
  }

  /// Decode the base64 ownership to a 2D array of doubles
  /// Returns boardSize x boardSize array where ownership values range from -1.0 to 1.0
  /// Negative values indicate white ownership, positive indicate black ownership
  /// Returns null if no ownership data is available
  List<List<double>>? decodeOwnership() {
    if (ownershipBase64 == null) return null;
    return GoLogic.decodeOwnership(ownershipBase64!, boardSize);
  }

  /// Decode the base64 ultimate-stones to a 2D array of integers
  /// Returns boardSize x boardSize array where 0=empty, 1=black, 2=white
  /// Returns null if no ultimate stones data is available
  List<List<int>>? decodeUltimateStones() {
    if (ultimateStonesBase64 == null) return null;
    return GoLogic.decodeStones(ultimateStonesBase64!, boardSize);
  }

  /// Check if this position has ownership data
  bool get hasOwnership => ownershipBase64 != null;

  /// Check if this position has ultimate stones data
  bool get hasUltimateStones => ultimateStonesBase64 != null;

  /// Check if this position has territory data
  bool get hasTerritoryData => blackTerritory != null && whiteTerritory != null;

  /// Get a human-readable description of the position
  String get description {
    return 'Position ${id.split('_').first}';
  }

  /// Convert score to result string format
  /// Negative score = White wins, Positive score = Black wins, 0 = Draw
  String get result {
    if (score == 0) {
      return 'Draw';
    } else if (score > 0) {
      // Black wins
      return 'B+${_formatScore(score)}';
    } else {
      // White wins
      return 'W+${_formatScore(-score)}';
    }
  }

  /// Format score for display (no decimal places for integers, one decimal place for non-integers)
  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    } else {
      return score.toStringAsFixed(1);
    }
  }

  /// Get the winner from the score
  String get winner {
    return GameResultParser.parseWinner(result);
  }

  /// Get the margin of victory from the score
  String get margin {
    return GameResultParser.parseMargin(result);
  }

  /// REMOVED: Check if this position has ultimate capture data - prisoners are always equal
  // bool get hasUltimateCaptureData => ultimateBlackCaptured != null && ultimateWhiteCaptured != null;

  /// Check if this position supports position type modes (has ultimate stones data)
  bool get supportsPositionTypes => ultimateStonesBase64 != null;

  /// Get stones to display based on position type
  List<List<int>> getStonesToDisplay(PositionType positionType) {
    switch (positionType) {
      case PositionType.withFilledNeutralPoints:
        if (ultimateStonesBase64 != null) {
          return GoLogic.decodeStones(ultimateStonesBase64!, boardSize);
        }
        // Fallback to regular stones if ultimate stones not available
        return decodeStones();

      case PositionType.beforeFillingNeutralPoints:
        return decodeStones();
    }
  }

  /// Get the effective score for correctness checking based on position type
  double getEffectiveScore(PositionType positionType) {
    return PositionScoring.calculateEffectiveScore(this, positionType);
  }

  /// Get the result string based on position type
  String getResult(PositionType positionType) {
    final effectiveScore = getEffectiveScore(positionType);
    return PositionScoring.scoreToResult(effectiveScore);
  }

  /// Get Black's scoring text for feedback display
  String getBlackScoringText(PositionType positionType) {
    return PositionScoring.generateBlackScoringText(this, positionType);
  }

  /// Get White's scoring text for feedback display
  String getWhiteScoringText(PositionType positionType) {
    return PositionScoring.generateWhiteScoringText(this, positionType);
  }

  /// Check if game info should be shown based on position type
  bool shouldShowGameInfo(PositionType positionType) {
    return positionType.showGameInfo;
  }

  /// Check if move sequence selection should be shown based on position type
  bool shouldShowMoveSequenceSelection(PositionType positionType) {
    return positionType.showMoveSequenceSelection;
  }

  /// Extract recent move sequence for display with position type logic
  ///
  /// Parameters:
  /// - sequenceLength: Number of moves to show in sequence
  /// - positionType: The position type mode (used for backward compatibility)
  /// - showMoveNumbers: Whether to show move numbers (only affects problem view)
  /// - viewMode: The current board view mode (problem vs review/feedback)
  ///
  /// Key logic: Returns the last sequenceLength moves as numbered sequence
  List<MoveSequenceData> extractMoveSequenceWithType(int sequenceLength, PositionType positionType, bool showMoveNumbers, BoardViewMode viewMode) {
    if (movesBase64 == null) {
      return [];
    }

    // Show sequence moves when sequenceLength > 0
    if (sequenceLength <= 0) {
      return [];
    }

    final moves = GoLogic.extractRecentMoves(
      movesBase64!,
      boardSize,
      numberOfMoves,
      sequenceLength,
    );

    // Only hide move numbers in problem view when showMoveNumbers is false
    // In review/feedback view, always show move numbers
    if (viewMode == BoardViewMode.problem && !showMoveNumbers) {
      // Return moves with moveNumber 0 to indicate no number should be shown
      return moves.map((move) => MoveSequenceData(
        row: move.row,
        col: move.col,
        moveNumber: 0, // 0 indicates no number should be shown
      )).toList();
    }

    return moves;
  }

  /// Get position of last move before sequence with position type logic
  ///
  /// Key logic: Returns the triangle marker position at (sequenceLength + 1) from the end
  /// The caller is responsible for determining if sequence length is defined/available
  Position? getLastMoveBeforeSequenceWithType(int sequenceLength, PositionType positionType) {
    if (movesBase64 == null) {
      return null;
    }

    if (sequenceLength < 0) {
      return null;
    }

    if (sequenceLength == 0) {
      // Triangle at position 1 from end (the last move)
      if (numberOfMoves > 0) {
        final lastMoves = GoLogic.extractRecentMoves(
          movesBase64!,
          boardSize,
          numberOfMoves,
          1,
        );
        if (lastMoves.isNotEmpty) {
          return Position(lastMoves.first.row, lastMoves.first.col);
        }
      }
      return null;
    }

    // Triangle at position (sequenceLength + 1) from end
    return GoLogic.findLastMoveBeforeSequence(
      movesBase64!,
      boardSize,
      numberOfMoves,
      sequenceLength,
    );
  }

  /// Get position of last move for triangle marker when sequence length is defined
  ///
  /// Parameters:
  /// - sequenceLength: The sequence length value (0 or positive)
  /// - isSequenceLengthDefined: Whether sequence length controls are available for this dataset/position type
  Position? getTriangleMarkerPosition(int sequenceLength, bool isSequenceLengthDefined) {
    if (movesBase64 == null || !isSequenceLengthDefined) {
      return null;
    }

    return getLastMoveBeforeSequenceWithType(sequenceLength, PositionType.beforeFillingNeutralPoints);
  }

  /// Extract recent move sequence for display
  /// Returns list of moves to show as numbers, ordered from most recent
  List<MoveSequenceData> extractMoveSequence(int sequenceLength) {
    if (movesBase64 == null || sequenceLength <= 0) {
      return [];
    }
    return GoLogic.extractRecentMoves(
      movesBase64!,
      boardSize,
      numberOfMoves,
      sequenceLength,
    );
  }

  /// Get position of last move before sequence (for last move marker)
  Position? getLastMoveBeforeSequence(int sequenceLength) {
    if (movesBase64 == null || sequenceLength <= 0) {
      return null;
    }
    return GoLogic.findLastMoveBeforeSequence(
      movesBase64!,
      boardSize,
      numberOfMoves,
      sequenceLength,
    );
  }

  /// Check if this position has enough moves for the given sequence length
  bool hasEnoughMovesForSequence(int sequenceLength) {
    return numberOfMoves >= sequenceLength + 1; // +1 for last move marker
  }
}


class TrainingDataset {
  final DatasetMetadata metadata;
  final List<TrainingPosition> positions;

  const TrainingDataset({
    required this.metadata,
    required this.positions,
  });

  factory TrainingDataset.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseDatasetToMap(json);
    final metadata = DatasetMetadata.fromJson(parsed['metadata'] as Map<String, dynamic>);

    // Use raw JSON positions instead of pre-parsed ones to avoid double-parsing
    final rawPositions = json['positions'] as List;
    final positions = rawPositions
        .map((p) => TrainingPosition.fromJson(p as Map<String, dynamic>))
        .toList();

    return TrainingDataset(
      metadata: metadata,
      positions: positions,
    );
  }

}

class DatasetMetadata {
  final String name;
  final String description;
  final String version;
  final DateTime createdAt;
  final int totalPositions;
  final DatasetType datasetType;

  const DatasetMetadata({
    required this.name,
    required this.description,
    required this.version,
    required this.createdAt,
    required this.totalPositions,
    required this.datasetType,
  });

  factory DatasetMetadata.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseMetadataToMap(json);
    return DatasetMetadata(
      name: parsed['name'] as String,
      description: parsed['description'] as String,
      version: parsed['version'] as String,
      createdAt: DateTime.parse(parsed['created_at'] as String),
      totalPositions: parsed['total_positions'] as int,
      datasetType: DatasetType.fromString(parsed['dataset_type'] as String?) ?? DatasetType.final9x9,
    );
  }
}

class GameInfo {
  // REMOVED: Captured stones - prisoners are always equal, no need to track them
  // final int blackCaptured;
  // final int whiteCaptured;
  final double komi;
  final int? lastMoveRow;
  final int? lastMoveCol;
  final List<MoveSequence>? moveSequence;
  final BoardDisplay? boardDisplay;

  const GameInfo({
    // REMOVED: Captured stones - prisoners are always equal
    // this.blackCaptured = 0,
    // this.whiteCaptured = 0,
    this.komi = 0.0,
    this.lastMoveRow,
    this.lastMoveCol,
    this.moveSequence,
    this.boardDisplay,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseGameInfoToMap(json);
    return GameInfo(
      // REMOVED: Captured stones - prisoners are always equal
      // blackCaptured: parsed['black_captured'] as int,
      // whiteCaptured: parsed['white_captured'] as int,
      komi: parsed['komi'] as double,
      lastMoveRow: parsed['last_move_row'] as int?,
      lastMoveCol: parsed['last_move_col'] as int?,
      moveSequence: parsed['move_sequence'] != null
          ? (parsed['move_sequence'] as List)
              .map((m) => MoveSequence.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
      boardDisplay: parsed['board_display'] != null
          ? BoardDisplay.fromJson(parsed['board_display'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MoveSequence {
  final int row;
  final int col;
  final int moveNumber;

  const MoveSequence({
    required this.row,
    required this.col,
    required this.moveNumber,
  });

  factory MoveSequence.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseMoveSequenceToMap(json);
    return MoveSequence(
      row: parsed['row'] as int,
      col: parsed['col'] as int,
      moveNumber: parsed['move_number'] as int,
    );
  }
}

class BoardDisplay {
  final int? cropStartRow;
  final int? cropStartCol;
  final int? cropWidth;
  final int? cropHeight;
  final int? focusStartRow;
  final int? focusStartCol;
  final int? focusWidth;
  final int? focusHeight;

  const BoardDisplay({
    this.cropStartRow,
    this.cropStartCol,
    this.cropWidth,
    this.cropHeight,
    this.focusStartRow,
    this.focusStartCol,
    this.focusWidth,
    this.focusHeight,
  });

  factory BoardDisplay.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseBoardDisplayToMap(json);
    return BoardDisplay(
      cropStartRow: parsed['crop_start_row'] as int?,
      cropStartCol: parsed['crop_start_col'] as int?,
      cropWidth: parsed['crop_width'] as int?,
      cropHeight: parsed['crop_height'] as int?,
      focusStartRow: parsed['focus_start_row'] as int?,
      focusStartCol: parsed['focus_start_col'] as int?,
      focusWidth: parsed['focus_width'] as int?,
      focusHeight: parsed['focus_height'] as int?,
    );
  }
}