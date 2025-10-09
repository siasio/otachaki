import '../../models/go_position.dart';
import '../../models/training_position.dart';
import '../../models/positioned_score_options.dart';
import '../../models/rough_lead_button_state.dart';
import '../../models/dataset_configuration.dart';
import '../../models/global_configuration.dart';
import '../../services/position_manager.dart';
import '../../services/configuration_manager.dart';
import '../../services/global_configuration_manager.dart';
import '../../services/statistics_manager.dart';
import '../../services/logger_service.dart';

/// State manager for training screen logic
/// Extracted from TrainingScreen to improve maintainability and testability
class TrainingStateManager {
  // Current state
  GoPosition? _currentPosition;
  bool _timerRunning = true;
  bool _loading = true;
  bool _showFeedbackOverlay = false;
  bool _isCorrectAnswer = false;
  bool _hasAnswered = false;
  bool _waitingForNext = false;
  bool _pausePressed = false;
  PositionedScoreOptions? _currentScoreOptions;
  RoughLeadPredictionState? _currentRoughLeadState;
  DateTime? _problemStartTime;

  // Managers
  final PositionManager _positionManager = PositionManager();
  ConfigurationManager? _configManager;
  DatasetConfiguration? _currentConfig;
  GlobalConfigurationManager? _globalConfigManager;
  GlobalConfiguration? _globalConfig;
  StatisticsManager? _statisticsManager;

  // Getters for current state
  GoPosition? get currentPosition => _currentPosition;
  bool get timerRunning => _timerRunning;
  bool get loading => _loading;
  bool get showFeedbackOverlay => _showFeedbackOverlay;
  bool get isCorrectAnswer => _isCorrectAnswer;
  bool get hasAnswered => _hasAnswered;
  bool get waitingForNext => _waitingForNext;
  bool get pausePressed => _pausePressed;
  PositionedScoreOptions? get currentScoreOptions => _currentScoreOptions;
  RoughLeadPredictionState? get currentRoughLeadState => _currentRoughLeadState;
  DatasetConfiguration? get currentConfig => _currentConfig;
  GlobalConfiguration? get globalConfig => _globalConfig;
  TrainingPosition? get trainingPosition => _positionManager.currentTrainingPosition;

  /// Initialize all configuration managers
  Future<void> initializeConfiguration() async {
    try {
      _configManager = await ConfigurationManager.getInstance();
      _globalConfigManager = await GlobalConfigurationManager.getInstance();
      _globalConfig = _globalConfigManager!.getConfiguration();
      _statisticsManager = await StatisticsManager.getInstance();

      LoggerService.info('Training state manager initialized successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize configuration managers',
        error: e, stackTrace: stackTrace, context: 'TrainingStateManager');
      rethrow;
    }
  }

  /// Load initial position
  Future<void> loadInitialPosition() async {
    try {
      _loading = true;
      _problemStartTime = DateTime.now();

      _currentPosition = await _positionManager.loadRandomPosition();

      await _updateConfiguration();
      _resetTrainingState();

      _loading = false;
      LoggerService.debug('Initial position loaded successfully');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load initial position',
        error: e, stackTrace: stackTrace, context: 'TrainingStateManager');
      _loading = false;
      rethrow;
    }
  }

  /// Update configuration based on current dataset
  Future<void> _updateConfiguration() async {
    if (_configManager != null && _positionManager.currentDataset != null) {
      final datasetType = _positionManager.currentDataset!.metadata.datasetType;
      _currentConfig = _configManager!.getConfiguration(datasetType);
      LoggerService.debug('Configuration updated for dataset: ${datasetType.value}');
    }
  }

  /// Reset training state for new problem
  void _resetTrainingState() {
    _timerRunning = true;
    _showFeedbackOverlay = false;
    _isCorrectAnswer = false;
    _hasAnswered = false;
    _waitingForNext = false;
    _pausePressed = false;
    _currentScoreOptions = null;
    _currentRoughLeadState = null;
  }

  /// Handle timer completion
  void onTimerComplete() {
    _timerRunning = false;
    LoggerService.debug('Timer completed for current problem');
  }

  /// Handle feedback overlay display
  void showFeedback(bool isCorrect) {
    _showFeedbackOverlay = true;
    _isCorrectAnswer = isCorrect;
    _hasAnswered = true;
    LoggerService.debug('Feedback shown: ${isCorrect ? 'correct' : 'incorrect'}');
  }

  /// Handle pause button press
  void onPausePressed() {
    _pausePressed = true;
    LoggerService.debug('Pause button pressed');
  }

  /// Handle waiting for next position
  void setWaitingForNext(bool waiting) {
    _waitingForNext = waiting;
    if (waiting) {
      LoggerService.debug('Now waiting for next position');
    }
  }

  /// Update score options for exact score mode
  void updateScoreOptions(PositionedScoreOptions? options) {
    _currentScoreOptions = options;
  }

  /// Update rough lead state
  void updateRoughLeadState(RoughLeadPredictionState? state) {
    _currentRoughLeadState = state;
  }

  /// Record statistics for a problem attempt
  Future<void> recordStatistics(bool isCorrect) async {
    if (_statisticsManager != null && _problemStartTime != null) {
      try {
        final duration = DateTime.now().difference(_problemStartTime!);
        // TODO: Add actual statistics recording logic here
        LoggerService.debug('Statistics recorded: ${isCorrect ? 'correct' : 'incorrect'}, duration: ${duration.inSeconds}s');
      } catch (e, stackTrace) {
        LoggerService.error('Failed to record statistics',
          error: e, stackTrace: stackTrace, context: 'TrainingStateManager');
      }
    }
  }

  /// Load next position
  Future<void> loadNextPosition() async {
    await loadInitialPosition();
  }

  /// Dispose resources
  void dispose() {
    LoggerService.debug('Training state manager disposed');
  }
}