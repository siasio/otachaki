import 'dart:async';
import '../models/go_position.dart';
import '../models/training_position.dart';
import '../models/position_type.dart';
import 'position_loader.dart';
import 'dataset_preference_manager.dart';
import 'configuration_manager.dart';
import 'logger_service.dart';

class PositionManager {
  GoPosition? _currentPosition;
  TrainingPosition? _currentTrainingPosition;
  TrainingDataset? _currentDataset;
  bool _isLoading = false;

  /// Get the current position
  GoPosition? get currentPosition => _currentPosition;

  /// Get the current training position data
  TrainingPosition? get currentTrainingPosition => _currentTrainingPosition;

  /// Get the current dataset
  TrainingDataset? get currentDataset => _currentDataset;

  /// Check if currently loading a position
  bool get isLoading => _isLoading;

  /// Get the current position type from configuration
  Future<PositionType> getCurrentPositionType() async {
    try {
      if (_currentDataset == null) {
        return PositionType.withFilledNeutralPoints;
      }

      final configManager = await ConfigurationManager.getInstance();
      final datasetType = _currentDataset!.metadata.datasetType;
      final config = configManager.getConfiguration(datasetType);
      return config.positionType;
    } catch (e) {
      return PositionType.withFilledNeutralPoints;
    }
  }

  /// Load and return a random position
  Future<GoPosition> loadRandomPosition() async {
    _isLoading = true;

    try {
      _currentDataset = await PositionLoader.loadDataset();

      // Get configuration to check sequence length
      final configManager = await ConfigurationManager.getInstance();
      final datasetType = _currentDataset!.metadata.datasetType;
      final config = configManager.getConfiguration(datasetType);
      final positionType = config.positionType;
      final sequenceLength = config.sequenceLength;

      // Get a random position with enough moves for the sequence length
      _currentTrainingPosition = await PositionLoader.getRandomPositionWithMinMoves(sequenceLength);

      // Create GoPosition with appropriate position type
      _currentPosition = GoPosition.fromTrainingPositionWithType(_currentTrainingPosition!, positionType);

      LoggerService.debug('Position loaded successfully',
        context: 'PositionManager');
      LoggerService.debug('Position details: ID=${_currentTrainingPosition!.id}, '
        'Type=${positionType.value}, Result=${_currentTrainingPosition!.getResult(positionType)}, '
        'Dataset=${_currentDataset!.metadata.datasetType}, SequenceLength=$sequenceLength', context: 'PositionManager');

      return _currentPosition!;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load position, falling back to demo position',
        error: e, stackTrace: stackTrace, context: 'PositionManager');
      // Fallback to demo position
      _currentPosition = GoPosition.demo();
      _currentTrainingPosition = null;
      _currentDataset = null;
      return _currentPosition!;
    } finally {
      _isLoading = false;
    }
  }


  /// Check if the user's result selection is correct
  bool checkResult(String userResult) {
    if (_currentPosition == null || _currentTrainingPosition == null) {
      return false;
    }

    final correctResult = _currentTrainingPosition!.winner.toLowerCase();
    final userGuess = userResult.toLowerCase();

    return correctResult == userGuess;
  }

  /// Get feedback message for the user's selection
  String getFeedbackMessage(String userResult) {
    if (_currentTrainingPosition == null) {
      return 'You selected: $userResult';
    }

    final isCorrect = checkResult(userResult);
    final correctAnswer = _currentTrainingPosition!.winner;
    final margin = _currentTrainingPosition!.margin;

    if (isCorrect) {
      return '✓ Correct! $correctAnswer wins by $margin';
    } else {
      return '✗ Incorrect. $correctAnswer wins by $margin';
    }
  }

  /// Get position info for display
  String getPositionInfo() {
    if (_currentTrainingPosition == null) {
      return 'Demo position';
    }

    return _currentTrainingPosition!.description;
  }

  /// Preload the dataset during app initialization
  static Future<void> initialize() async {
    try {
      // Try to load the previously selected dataset, or use a default
      await _loadDefaultOrSelectedDataset();
      await PositionLoader.preloadDataset();
      LoggerService.info('Position manager initialized successfully', context: 'PositionManager');
    } catch (e) {
      LoggerService.warning('Failed to preload positions during initialization',
        error: e, context: 'PositionManager');
    }
  }

  /// Load the previously selected dataset or choose a default one
  static Future<void> _loadDefaultOrSelectedDataset() async {
    try {
      // Import inside the method to avoid circular dependencies
      final DatasetPreferenceManager preferenceManager =
          await DatasetPreferenceManager.getInstance();

      // Check if there's a last session dataset
      final lastDataset = preferenceManager.getLastSessionDataset();

      if (lastDataset != null) {
        // Try to load the last selected dataset
        try {
          if (lastDataset.startsWith('assets/')) {
            PositionLoader.setDatasetFile(lastDataset.substring(7));
            LoggerService.info('Loaded last session dataset: $lastDataset', context: 'PositionManager');
            return;
          } else {
            await PositionLoader.loadFromFile(lastDataset);
            LoggerService.info('Loaded last session dataset from file: $lastDataset', context: 'PositionManager');
            return;
          }
        } catch (e) {
          LoggerService.warning('Failed to load last session dataset, using default',
            error: e, context: 'PositionManager');
          // Fall through to default
        }
      }

      // No previous selection or failed to load, use default
      // Use 9x9 final positions as default
      const defaultDataset = 'final_9x9_katago.json';
      PositionLoader.setDatasetFile(defaultDataset);
      await preferenceManager.setSelectedDataset('assets/$defaultDataset');
      LoggerService.info('Loaded default dataset: $defaultDataset', context: 'PositionManager');

    } catch (e, stackTrace) {
      LoggerService.error('Error in default dataset loading',
        error: e, stackTrace: stackTrace, context: 'PositionManager');
      // PositionLoader will fall back to its default behavior
    }
  }

  /// Clear current position (useful for testing)
  void clear() {
    _currentPosition = null;
    _currentTrainingPosition = null;
    _isLoading = false;
  }
}