import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/training_position.dart';
import '../models/game_stage.dart';
import '../core/dataset_parser.dart' as parser;
import 'logger_service.dart';

enum DatasetSource {
  asset,
  file,
  bytes,
}

class PositionLoader {
  static TrainingDataset? _cachedDataset;
  static final Random _random = Random();
  static String _datasetFile = 'assets/19x19_midgame_positions.json';
  static DatasetSource _datasetSource = DatasetSource.asset;
  static String? _filePath;
  static Uint8List? _fileBytes;
  static String? _currentDatasetType;

  /// Set which dataset file to load from assets
  static void setDatasetFile(String filename) {
    _datasetFile = filename.startsWith('assets/') ? filename : 'assets/$filename';
    _datasetSource = DatasetSource.asset;
    _filePath = null;
    _fileBytes = null;
    _cachedDataset = null; // Clear cache when switching datasets
    _currentDatasetType = null; // Clear dataset type when switching
  }

  /// Load dataset from a file path (mobile/desktop)
  static Future<TrainingDataset> loadFromFile(String filePath) async {
    _datasetFile = filePath;
    _datasetSource = DatasetSource.file;
    _filePath = filePath;
    _fileBytes = null;
    _cachedDataset = null;
    _currentDatasetType = null;
    return await loadDataset();
  }

  /// Load dataset from bytes (web)
  static Future<TrainingDataset> loadFromBytes(Uint8List bytes, String filename) async {
    _datasetFile = filename;
    _datasetSource = DatasetSource.bytes;
    _filePath = null;
    _fileBytes = bytes;
    _cachedDataset = null;
    _currentDatasetType = null;
    return await loadDataset();
  }

  /// Get the current dataset filename
  static String get datasetFile => _datasetFile;

  /// Load the training dataset from the configured source
  static Future<TrainingDataset> loadDataset() async {
    if (_cachedDataset != null) {
      return _cachedDataset!;
    }

    try {
      String jsonString;

      switch (_datasetSource) {
        case DatasetSource.asset:
          jsonString = await rootBundle.loadString(_datasetFile);
          break;
        case DatasetSource.file:
          if (_filePath == null) {
            throw Exception('File path not set for file source');
          }
          if (kIsWeb) {
            throw Exception('File system access not supported on web');
          }
          try {
            final file = File(_filePath!);
            jsonString = await file.readAsString();
          } catch (e) {
            throw Exception('Failed to read file $_filePath: $e');
          }
          break;
        case DatasetSource.bytes:
          if (_fileBytes == null) {
            throw Exception('File bytes not set for bytes source');
          }
          jsonString = String.fromCharCodes(_fileBytes!);
          break;
      }

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Validate dataset before parsing
      final validationErrors = parser.DatasetParser.validateDataset(jsonData);
      if (validationErrors.isNotEmpty) {
        throw Exception('Dataset validation failed: ${validationErrors.join(', ')}');
      }

      _cachedDataset = TrainingDataset.fromJson(jsonData);

      // Extract and store dataset type from metadata
      final metadata = jsonData['metadata'] as Map<String, dynamic>?;
      _currentDatasetType = metadata?['dataset_type'] as String?;

      LoggerService.info('Dataset loaded successfully from $_datasetFile: '
        '${_cachedDataset!.metadata.totalPositions} positions', context: 'PositionLoader');
      LoggerService.debug('Dataset details: name=${_cachedDataset!.metadata.name}, '
        'type=$_currentDatasetType', context: 'PositionLoader');

      return _cachedDataset!;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load dataset from $_datasetFile',
        error: e, stackTrace: stackTrace, context: 'PositionLoader');
      rethrow;
    }
  }

  /// Get a random position from the dataset
  static Future<TrainingPosition> getRandomPosition() async {
    final dataset = await loadDataset();
    final randomIndex = _random.nextInt(dataset.positions.length);
    return dataset.positions[randomIndex];
  }

  /// Get a random position from the dataset that has at least the required number of moves
  /// for the given minimum sequence length (minSequenceLength + 1 for the triangle marker)
  static Future<TrainingPosition> getRandomPositionWithMinMoves(int minSequenceLength) async {
    final dataset = await loadDataset();

    // Filter positions that have enough moves
    final validPositions = dataset.positions.where((position) =>
        position.hasEnoughMovesForSequence(minSequenceLength)).toList();

    if (validPositions.isEmpty) {
      LoggerService.warning('No positions found with at least ${minSequenceLength + 1} moves, '
        'falling back to any random position', context: 'PositionLoader');
      // Fallback to any random position if no valid positions found
      final randomIndex = _random.nextInt(dataset.positions.length);
      return dataset.positions[randomIndex];
    }

    final randomIndex = _random.nextInt(validPositions.length);
    return validPositions[randomIndex];
  }

  /// Get a random position filtered by game stage (for midgame datasets)
  static Future<TrainingPosition> getRandomPositionByGameStage(GameStage gameStage, {int minSequenceLength = 0}) async {
    final dataset = await loadDataset();

    // Get the move numbers for this game stage
    final targetMoveNumbers = gameStage.moveNumbers;


    List<TrainingPosition> validPositions;

    if (targetMoveNumbers == null) {
      // GameStage.all - use all positions, but still filter by sequence length if needed
      validPositions = dataset.positions.where((position) =>
          position.hasEnoughMovesForSequence(minSequenceLength)).toList();
    } else {
      // Filter by specific move numbers and sequence length
      validPositions = dataset.positions.where((position) {
        final moveNumber = position.moveNumber;
        final hasValidMoveNumber = moveNumber != null && targetMoveNumbers.contains(moveNumber);
        final hasEnoughMoves = position.hasEnoughMovesForSequence(minSequenceLength);


        return hasValidMoveNumber && hasEnoughMoves;
      }).toList();
    }

    if (validPositions.isEmpty) {
      final totalForStage = targetMoveNumbers != null
        ? dataset.positions.where((p) => targetMoveNumbers.contains(p.moveNumber)).length
        : dataset.positions.length;

      LoggerService.warning('No positions found for game stage ${gameStage.displayName} '
        'with at least ${sequenceLength + 1} moves (found $totalForStage positions for this stage, '
        'but none have enough recorded moves for sequence length $sequenceLength). '
        'Consider reducing sequence length or selecting a different game stage. '
        'Falling back to any random position.', context: 'PositionLoader');

      // Debug: Show distribution of numberOfMoves for this stage when no valid positions found
      if (targetMoveNumbers != null) {
        final moveCountDistribution = <int, int>{};
        for (final position in dataset.positions) {
          if (targetMoveNumbers.contains(position.moveNumber)) {
            final count = position.numberOfMoves;
            moveCountDistribution[count] = (moveCountDistribution[count] ?? 0) + 1;
          }
        }
        LoggerService.debug('numberOfMoves distribution for ${gameStage.displayName}: $moveCountDistribution',
          context: 'PositionLoader');
      }
      // Fallback to any random position if no valid positions found
      final randomIndex = _random.nextInt(dataset.positions.length);
      return dataset.positions[randomIndex];
    }

    final randomIndex = _random.nextInt(validPositions.length);
    LoggerService.debug('Selected position for game stage ${gameStage.displayName}: '
      'move ${validPositions[randomIndex].moveNumber}, ${validPositions.length} total options',
      context: 'PositionLoader');
    return validPositions[randomIndex];
  }

  /// Get dataset statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final dataset = await loadDataset();
    return {
      'total_positions': dataset.metadata.totalPositions,
      'created_at': dataset.metadata.createdAt.toIso8601String(),
      'version': dataset.metadata.version,
      'dataset_type': _currentDatasetType,
    };
  }

  /// Preload the dataset (call this during app initialization)
  static Future<void> preloadDataset() async {
    await loadDataset();
  }

  /// Clear the cached dataset (useful for testing)
  static void clearCache() {
    _cachedDataset = null;
    _currentDatasetType = null;
  }

  /// Get current dataset source information
  static Map<String, dynamic> getSourceInfo() {
    return {
      'source': _datasetSource.toString().split('.').last,
      'file': _datasetFile,
      'path': _filePath,
      'has_bytes': _fileBytes != null,
    };
  }
}