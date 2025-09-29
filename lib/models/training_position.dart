import '../core/dataset_parser.dart' as core;
import '../core/go_logic.dart';
import '../core/game_result_parser.dart';
import 'dataset_type.dart';

class TrainingPosition {
  final String id;
  final int boardSize;
  final String stonesBase64;
  final double score;
  final String result;
  final GameInfo? gameInfo;
  final String? movesBase64;
  final int numberOfMoves;
  final String? ownershipBase64;
  final int? blackTerritory;
  final int? whiteTerritory;
  final String? ultimateStonesBase64;

  const TrainingPosition({
    required this.id,
    required this.boardSize,
    required this.stonesBase64,
    required this.score,
    required this.result,
    this.gameInfo,
    this.movesBase64,
    this.numberOfMoves = 0,
    this.ownershipBase64,
    this.blackTerritory,
    this.whiteTerritory,
    this.ultimateStonesBase64,
  });

  factory TrainingPosition.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseTrainingPositionToMap(json);
    return TrainingPosition(
      id: parsed['id'] as String,
      boardSize: parsed['board_size'] as int,
      stonesBase64: parsed['stones'] as String,
      score: parsed['score'] as double,
      result: parsed['result'] as String,
      gameInfo: parsed['game_info'] != null
          ? GameInfo.fromJson(parsed['game_info'] as Map<String, dynamic>)
          : null,
      movesBase64: parsed['moves'] as String?,
      numberOfMoves: parsed['number_of_moves'] as int? ?? 0,
      ownershipBase64: parsed['ownership'] as String?,
      blackTerritory: parsed['black_territory'] as int?,
      whiteTerritory: parsed['white_territory'] as int?,
      ultimateStonesBase64: parsed['ultimate_stones'] as String?,
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

  /// Get the winner from the result
  String get winner {
    return GameResultParser.parseWinner(result);
  }

  /// Get the margin of victory
  String get margin {
    return GameResultParser.parseMargin(result);
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
      datasetType: DatasetType.fromString(parsed['dataset_type'] as String?) ?? DatasetType.final9x9Area,
    );
  }
}

class GameInfo {
  final int blackCaptured;
  final int whiteCaptured;
  final double komi;
  final int? lastMoveRow;
  final int? lastMoveCol;
  final List<MoveSequence>? moveSequence;
  final BoardDisplay? boardDisplay;

  const GameInfo({
    this.blackCaptured = 0,
    this.whiteCaptured = 0,
    this.komi = 0.0,
    this.lastMoveRow,
    this.lastMoveCol,
    this.moveSequence,
    this.boardDisplay,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    final parsed = core.DatasetParser.parseGameInfoToMap(json);
    return GameInfo(
      blackCaptured: parsed['black_captured'] as int,
      whiteCaptured: parsed['white_captured'] as int,
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