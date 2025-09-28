import 'dart:convert';
import 'dart:typed_data';

/// Pure functions for Go game logic without Flutter dependencies
class GoLogic {
  /// Decode base64 stones to a 2D array of integers
  /// Returns boardSize x boardSize array where 0=empty, 1=black, 2=white
  static List<List<int>> decodeStones(String stonesBase64, int boardSize) {
    final bytes = base64Decode(stonesBase64);
    final board = List.generate(boardSize, (_) => List.generate(boardSize, (_) => 0));

    for (int i = 0; i < bytes.length && i < boardSize * boardSize; i++) {
      final row = i ~/ boardSize;
      final col = i % boardSize;
      board[row][col] = bytes[i];
    }

    return board;
  }

  /// Decode base64 ownership to a 2D array of doubles
  /// Returns boardSize x boardSize array where ownership values range from -1.0 to 1.0
  /// Negative values indicate white ownership, positive indicate black ownership
  /// Uses the same conversion as the Python generator: (val - 16) / 16.0
  static List<List<double>> decodeOwnership(String ownershipBase64, int boardSize) {
    final bytes = base64Decode(ownershipBase64);
    final ownership = List.generate(boardSize, (_) => List.generate(boardSize, (_) => 0.0));

    for (int i = 0; i < bytes.length && i < boardSize * boardSize; i++) {
      final row = i ~/ boardSize;
      final col = i % boardSize;
      // Convert from 0-32 range to -1.0 to 1.0 range
      // Same conversion as in enhanced_final_position_generator.py:261
      final rawValue = bytes[i];
      ownership[row][col] = (rawValue - 16.0) / 16.0;
      // Clamp to valid range
      ownership[row][col] = ownership[row][col].clamp(-1.0, 1.0);
    }

    return ownership;
  }

  /// Encode a 2D board array to base64 string
  static String encodeStones(List<List<int>> board) {
    final boardSize = board.length;
    final bytes = Uint8List(boardSize * boardSize);

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        final index = row * boardSize + col;
        bytes[index] = board[row][col];
      }
    }

    return base64Encode(bytes);
  }

  /// Create an empty board of given size
  static List<List<int>> createEmptyBoard(int size) {
    return List.generate(size, (_) => List.generate(size, (_) => 0));
  }

  /// Check if coordinates are valid for the given board size
  static bool isValidCoordinate(int row, int col, int boardSize) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }

  /// Count stones of a specific color on the board
  static int countStones(List<List<int>> board, int stoneColor) {
    int count = 0;
    for (final row in board) {
      for (final stone in row) {
        if (stone == stoneColor) {
          count++;
        }
      }
    }
    return count;
  }

  /// Get a copy of the board
  static List<List<int>> copyBoard(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList();
  }

  /// Check if two boards are equal
  static bool boardsEqual(List<List<int>> board1, List<List<int>> board2) {
    if (board1.length != board2.length) return false;

    for (int i = 0; i < board1.length; i++) {
      if (board1[i].length != board2[i].length) return false;
      for (int j = 0; j < board1[i].length; j++) {
        if (board1[i][j] != board2[i][j]) return false;
      }
    }
    return true;
  }

  /// Get neighbors of a position (adjacent positions only)
  static List<Position> getNeighbors(int row, int col, int boardSize) {
    final neighbors = <Position>[];
    final directions = [[-1, 0], [1, 0], [0, -1], [0, 1]]; // up, down, left, right

    for (final dir in directions) {
      final newRow = row + dir[0];
      final newCol = col + dir[1];
      if (isValidCoordinate(newRow, newCol, boardSize)) {
        neighbors.add(Position(newRow, newCol));
      }
    }

    return neighbors;
  }

  /// Find all empty positions on the board
  static List<Position> getEmptyPositions(List<List<int>> board) {
    final empty = <Position>[];
    for (int row = 0; row < board.length; row++) {
      for (int col = 0; col < board[row].length; col++) {
        if (board[row][col] == 0) {
          empty.add(Position(row, col));
        }
      }
    }
    return empty;
  }

  /// Convert board to a string representation for debugging
  static String boardToString(List<List<int>> board) {
    final buffer = StringBuffer();
    for (final row in board) {
      for (final stone in row) {
        switch (stone) {
          case 0:
            buffer.write('.');
            break;
          case 1:
            buffer.write('B');
            break;
          case 2:
            buffer.write('W');
            break;
          default:
            buffer.write('?');
        }
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Decode base64 moves to a 2D array of move numbers
  /// Returns boardSize x boardSize array where 0=no move, 1-50=move order (1=most recent)
  static List<List<int>> decodeMoves(String movesBase64, int boardSize) {
    final bytes = base64Decode(movesBase64);
    final board = List.generate(boardSize, (_) => List.generate(boardSize, (_) => 0));

    for (int i = 0; i < bytes.length && i < boardSize * boardSize; i++) {
      final row = i ~/ boardSize;
      final col = i % boardSize;
      board[row][col] = bytes[i];
    }

    return board;
  }

  /// Extract recent move sequence from moves data
  /// Returns list of MoveSequenceData for display (1 = oldest in sequence, sequenceLength = newest)
  static List<MoveSequenceData> extractRecentMoves(
    String movesBase64,
    int boardSize,
    int numberOfMoves,
    int sequenceLength
  ) {
    if (sequenceLength <= 0 || numberOfMoves < sequenceLength) {
      return [];
    }

    final movesBoard = decodeMoves(movesBase64, boardSize);
    final movesList = <MoveSequenceData>[];

    // Calculate the range of moves to extract (last sequenceLength moves)
    final startMoveNum = numberOfMoves - sequenceLength + 1; // e.g., for 5 moves out of 37: 37-5+1 = 33
    final endMoveNum = numberOfMoves; // e.g., 37

    // Find moves in the range [startMoveNum, endMoveNum]
    for (int moveNum = startMoveNum; moveNum <= endMoveNum; moveNum++) {
      for (int row = 0; row < boardSize; row++) {
        for (int col = 0; col < boardSize; col++) {
          if (movesBoard[row][col] == moveNum) {
            // Display number: 1 for oldest in sequence, sequenceLength for newest
            final displayNumber = moveNum - startMoveNum + 1;
            movesList.add(MoveSequenceData(
              row: row,
              col: col,
              moveNumber: displayNumber,
            ));
            break; // Found this move number, continue to next
          }
        }
      }
    }

    return movesList;
  }

  /// Find the last move before sequence (for last move marker)
  /// Returns position of move that should have the last move marker
  static Position? findLastMoveBeforeSequence(
    String movesBase64,
    int boardSize,
    int numberOfMoves,
    int sequenceLength
  ) {
    if (sequenceLength <= 0 || numberOfMoves <= sequenceLength) {
      return null;
    }

    final movesBoard = decodeMoves(movesBase64, boardSize);
    // The move before the sequence is the one just before the range we're showing
    final targetMoveNum = numberOfMoves - sequenceLength; // e.g., for 5 moves out of 37: 37-5 = 32

    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (movesBoard[row][col] == targetMoveNum) {
          return Position(row, col);
        }
      }
    }

    return null;
  }
}

/// Simple position class for coordinates
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

/// Move sequence data for display
class MoveSequenceData {
  final int row;
  final int col;
  final int moveNumber;

  const MoveSequenceData({
    required this.row,
    required this.col,
    required this.moveNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveSequenceData &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          moveNumber == other.moveNumber;

  @override
  int get hashCode => row.hashCode ^ col.hashCode ^ moveNumber.hashCode;

  @override
  String toString() => 'MoveSequenceData($row, $col, move: $moveNumber)';
}