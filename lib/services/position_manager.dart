import 'dart:async';
import '../models/go_position.dart';
import '../models/training_position.dart';
import '../models/position_type.dart';
import 'position_loader.dart';
import 'dataset_preference_manager.dart';
import 'configuration_manager.dart';

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
      _currentTrainingPosition = await PositionLoader.getRandomPosition();

      // Get position type from configuration
      final configManager = await ConfigurationManager.getInstance();
      final datasetType = _currentDataset!.metadata.datasetType;
      final config = configManager.getConfiguration(datasetType);
      final positionType = config.positionType;

      // Create GoPosition with appropriate position type
      _currentPosition = GoPosition.fromTrainingPositionWithType(_currentTrainingPosition!, positionType);

      print('Loaded position: ${_currentTrainingPosition!.id}');
      print('Position type: ${positionType.value}');
      print('Result: ${_currentTrainingPosition!.getResult(positionType)}');
      print('Dataset type: ${_currentDataset!.metadata.datasetType}');

      return _currentPosition!;
    } catch (e) {
      print('Error loading position: $e');
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
      print('Position manager initialized successfully');
    } catch (e) {
      print('Warning: Failed to preload positions: $e');
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
            print('Loaded last session dataset: $lastDataset');
            return;
          } else {
            await PositionLoader.loadFromFile(lastDataset);
            print('Loaded last session dataset from file: $lastDataset');
            return;
          }
        } catch (e) {
          print('Failed to load last session dataset: $e');
          // Fall through to default
        }
      }

      // No previous selection or failed to load, use default
      // Use 9x9 final positions as default
      const defaultDataset = 'final_9x9_katago.json';
      PositionLoader.setDatasetFile(defaultDataset);
      await preferenceManager.setSelectedDataset('assets/$defaultDataset');
      print('Loaded default dataset: $defaultDataset');

    } catch (e) {
      print('Error in default dataset loading: $e');
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