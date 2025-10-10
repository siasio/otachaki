import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/go_position.dart';
import '../models/scoring_config.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/position_type.dart';
import '../services/position_manager.dart';
import '../services/position_loader.dart';
import '../services/enhanced_configuration_manager.dart';
import '../services/custom_dataset_manager.dart';
import '../models/custom_dataset.dart';
import '../services/global_configuration_manager.dart';
import '../services/statistics_manager.dart';
import '../services/logger_service.dart';
import '../services/title_substitution_service.dart';
import '../models/global_configuration.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import '../models/timer_type.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/adaptive_app_bar.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../widgets/timer_bar.dart';
import '../widgets/game_board_container.dart';
import '../widgets/adaptive_result_buttons.dart';
import '../models/auto_advance_mode.dart';
import '../widgets/game_status_bar.dart';
import '../widgets/pause_button.dart';
import '../models/game_result_option.dart';
import '../models/sequence_display_mode.dart';
import '../models/board_view_mode.dart';
import '../models/ownership_display_mode.dart';
import '../models/prediction_type.dart';
import '../models/positioned_score_options.dart';
import '../models/rough_lead_button_state.dart';
import '../widgets/welcome_overlay.dart';
import './info_screen.dart';
import './config_screen.dart';

class ResultDisplayColors {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color? shadowColor;

  const ResultDisplayColors({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.shadowColor,
  });
}

class TrainingScreen extends StatefulWidget {
  final VoidCallback? onConfigurationChanged;

  const TrainingScreen({super.key, this.onConfigurationChanged});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late GoPosition _currentPosition;
  bool _timerRunning = true;
  final PositionManager _positionManager = PositionManager();
  bool _loading = true;
  bool _showFeedbackOverlay = false;
  bool _isCorrectAnswer = false;
  bool _hasAnswered = false;
  bool _waitingForNext = false;
  bool _pausePressed = false;
  bool _showWelcomeOverlay = false;
  PositionedScoreOptions? _currentScoreOptions;
  RoughLeadPredictionState? _currentRoughLeadState; // State for rough lead prediction mode
  final FocusNode _focusNode = FocusNode();
  EnhancedConfigurationManager? _configManager;
  CustomDatasetManager? _datasetManager;
  CustomDataset? _currentDataset;
  DatasetConfiguration? _currentConfig;
  GlobalConfigurationManager? _globalConfigManager;
  GlobalConfiguration? _globalConfig;
  StatisticsManager? _statisticsManager;
  DateTime? _problemStartTime;
  String _dynamicTitle = 'Go Position Training';

  @override
  void initState() {
    super.initState();
    _initializeConfiguration();
    // Ensure focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _initializeConfiguration() async {
    try {
      _configManager = await EnhancedConfigurationManager.getInstance();
      _datasetManager = await CustomDatasetManager.getInstance();

      // Load the currently selected dataset
      _currentDataset = _datasetManager!.getSelectedDataset();

      // If no dataset selected, use default
      if (_currentDataset == null) {
        _currentDataset = _datasetManager!.getDefaultDataset(DatasetType.final9x9);
        if (_currentDataset != null) {
          await _datasetManager!.setSelectedDataset(_currentDataset!.id);
        }
      }
      _globalConfigManager = await GlobalConfigurationManager.getInstance();
      _globalConfig = _globalConfigManager!.getConfiguration();
      _statisticsManager = await StatisticsManager.getInstance();

      await _updateDynamicTitle(); // Update title when config is loaded

      // Check if we should show the welcome screen
      if (_globalConfig!.showWelcomeScreen) {
        setState(() {
          _showWelcomeOverlay = true;
        });
      }

      _loadInitialPosition();
    } catch (e, stackTrace) {
      // Gracefully handle configuration manager errors
      LoggerService.error('Failed to initialize configuration manager',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Using default settings due to configuration error'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadInitialPosition();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Update dynamic title based on global configuration and current dataset
  Future<void> _updateDynamicTitle() async {
    if (_globalConfig != null) {
      final title = await TitleSubstitutionService.substituteTitle(
        _globalConfig!.customTitle,
        _currentDataset,
      );
      if (mounted) {
        setState(() {
          _dynamicTitle = title;
        });
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Don't handle key events while welcome overlay is shown
      if (_showWelcomeOverlay) {
        return;
      }

      if (_waitingForNext) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onNextPressed();
        }
        return;
      }

      // Handle space key for pause during feedback overlay
      if (_showFeedbackOverlay && event.logicalKey == LogicalKeyboardKey.space) {
        final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
        final stateManager = ButtonStateManager(
          autoAdvanceMode: autoAdvanceMode,
          isAnswerCorrect: _isCorrectAnswer,
          hasAnswered: _hasAnswered,
          pausePressed: _pausePressed,
        );
        // Only allow pause if the pause button would be visible
        if (stateManager.shouldAutoAdvance() && !_pausePressed) {
          _onPausePressed();
        }
        return;
      }

      final isTimerEnabled = _currentConfig?.timerEnabled ?? true;
      if ((!_timerRunning && isTimerEnabled) || _showFeedbackOverlay) return;

      final predictionType = _currentConfig?.predictionType ?? PredictionType.winnerPrediction;

      // Handle exact score prediction mode
      if (predictionType == PredictionType.exactScorePrediction && _currentScoreOptions != null) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _onExactScoreButtonPressed(0); // Left button
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onExactScoreButtonPressed(1); // Middle button
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _onExactScoreButtonPressed(2); // Right button
        }
      }
      // Handle rough lead prediction mode
      else if (predictionType == PredictionType.roughLeadPrediction && _currentRoughLeadState != null) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _onRoughLeadButtonPressed(RoughLeadButtonType.white); // Left arrow - White
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onRoughLeadButtonPressed(RoughLeadButtonType.close); // Down arrow - Close
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _onRoughLeadButtonPressed(RoughLeadButtonType.black); // Right arrow - Black
        }
      } else if (_positionManager.currentDataset != null &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        final options = GameResultOption.generateOptions(
          _positionManager.currentDataset!.metadata.datasetType,
          ScoringConfig.parseScore(effectiveResult),
          effectiveResult,
        );

        if (event.logicalKey == LogicalKeyboardKey.arrowLeft && options.isNotEmpty) {
          _onResultOptionSelected(options[0]);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && options.length > 2) {
          _onResultOptionSelected(options[2]);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && options.length > 1) {
          _onResultOptionSelected(options[1]);
        }
      } else {
        // Fallback to old system
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _onResultSelected(GameResult.whiteWins);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _onResultSelected(GameResult.blackWins);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onResultSelected(GameResult.draw);
        }
      }
    }
  }

  void _resetTrainingState() {
    setState(() {
      _timerRunning = false;
      _showFeedbackOverlay = false;
      _hasAnswered = false;
      _waitingForNext = false;
      _pausePressed = false;
    });
  }

  Future<void> _navigateToInfo() async {
    _resetTrainingState();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    );
    // Load fresh position when returning
    _loadNextPosition();
  }

  Future<void> _navigateToConfig() async {
    _resetTrainingState();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
    // Reload global configuration in case it changed
    if (_globalConfigManager != null) {
      _globalConfig = _globalConfigManager!.getConfiguration();
      await _updateDynamicTitle(); // Update title when config changes
    }

    // Reload the current selected dataset in case it changed
    if (_datasetManager != null) {
      final newSelectedDataset = _datasetManager!.getSelectedDataset();
      if (newSelectedDataset?.id != _currentDataset?.id) {
        setState(() {
          _currentDataset = newSelectedDataset;
        });
        await _updateDynamicTitle(); // Update title when dataset changes
      }
    }

    // Notify parent app of configuration changes
    widget.onConfigurationChanged?.call();
    // Load fresh position when returning (dataset may have changed)
    _loadNextPosition();
  }

  Future<void> _loadInitialPosition() async {
    try {
      // Ensure the correct dataset file is loaded for the current custom dataset
      if (_currentDataset != null) {
        final datasetFile = _currentDataset!.datasetFilePath.replaceFirst('assets/', '');
        PositionLoader.setDatasetFile(datasetFile);
        await PositionLoader.preloadDataset();
      }

      await _updateConfiguration();
      final position = await _positionManager.loadRandomPosition();

      // Generate score options for exact score prediction (if needed)
      PositionedScoreOptions? scoreOptions;
      if (_currentConfig?.predictionType == PredictionType.exactScorePrediction &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        scoreOptions = PositionedScoreOptions.generate(
          actualScoreString: effectiveResult,
          scoreGranularity: _currentConfig?.scoreGranularity ?? 1,
        );
      }

      // Generate rough lead prediction state (if needed)
      RoughLeadPredictionState? roughLeadState;
      if (_currentConfig?.predictionType == PredictionType.roughLeadPrediction &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        final actualScore = ScoringConfig.parseScore(effectiveResult);
        roughLeadState = RoughLeadPredictionState.generate(
          actualScore: actualScore,
          thresholdGood: _currentConfig?.thresholdGood ?? 2.0,
          thresholdClose: _currentConfig?.thresholdClose ?? 5.0,
        );
      }

      setState(() {
        _currentPosition = position;
        _loading = false;
        _currentScoreOptions = scoreOptions;
        _currentRoughLeadState = roughLeadState;
        // Only start timer if welcome overlay is not shown
        _timerRunning = !_showWelcomeOverlay;
      });
      // Start timing the problem only if welcome overlay is not shown
      if (!_showWelcomeOverlay) {
        _problemStartTime = DateTime.now();
      }
      // Request focus for keyboard input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load initial position',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
      setState(() {
        _currentPosition = GoPosition.demo();
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load position. Using demo position.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadNextPosition(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateConfiguration() async {
    if (_configManager == null || _currentDataset == null) {
      _currentConfig = DatasetConfiguration.getDefaultFor(DatasetType.final9x9);
      return;
    }

    _currentConfig = _configManager!.getConfigurationForDataset(_currentDataset!);
  }

  void _onResultSelected(GameResult result) {
    setState(() {
      _timerRunning = false;
      _hasAnswered = true;
    });

    final isCorrect = _checkResultUsingNewSystem(result);
    _recordAttempt(isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    setState(() {
      _showFeedbackOverlay = markDisplayEnabled;
      _isCorrectAnswer = isCorrect;
    });

    _handlePostAnswerFlow(isCorrect);
  }

  void _onResultOptionSelected(GameResultOption option) {
    setState(() {
      _timerRunning = false;
      _hasAnswered = true;
    });

    _recordAttempt(option.isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    setState(() {
      _showFeedbackOverlay = markDisplayEnabled;
      _isCorrectAnswer = option.isCorrect;
    });

    _handlePostAnswerFlow(option.isCorrect);
  }

  void _onExactScoreButtonPressed(int buttonPosition) {
    setState(() {
      _timerRunning = false;
      _hasAnswered = true;
    });

    // Check if the pressed button position is correct
    final isCorrect = buttonPosition == _currentScoreOptions?.correctButtonPosition;

    _recordAttempt(isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    setState(() {
      _showFeedbackOverlay = markDisplayEnabled;
      _isCorrectAnswer = isCorrect;
    });

    _handlePostAnswerFlow(isCorrect);
  }

  /// Handles button presses in rough lead prediction mode.
  ///
  /// Updates the prediction state to mark the pressed button and determines
  /// if the answer was correct based on the rough lead prediction logic.
  void _onRoughLeadButtonPressed(RoughLeadButtonType buttonType) {
    setState(() {
      _timerRunning = false;
      _hasAnswered = true;
    });

    if (_currentRoughLeadState != null) {
      final updatedState = _currentRoughLeadState!.markButtonPressed(buttonType);
      final isCorrect = updatedState.wasAnswerCorrect;

      _recordAttempt(isCorrect, false);

      final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
      setState(() {
        _currentRoughLeadState = updatedState;
        _showFeedbackOverlay = markDisplayEnabled;
        _isCorrectAnswer = isCorrect;
      });

      _handlePostAnswerFlow(isCorrect);
    }
  }

  bool _checkResultUsingNewSystem(GameResult selectedResult) {
    final currentTrainingPosition = _positionManager.currentTrainingPosition;
    if (currentTrainingPosition == null) return false;

    // Parse the score from the result string (using position-type-aware result)
    final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
    final effectiveResult = currentTrainingPosition.getResult(positionType);
    final actualScore = ScoringConfig.parseScore(effectiveResult);

    // Get all valid results for this score using default config
    final validResults = ScoringConfig.defaultConfig.getValidResults(actualScore);

    // Check if the selected result is among the valid ones
    return validResults.contains(selectedResult);
  }

  void _onTimerComplete() {
    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    setState(() {
      _timerRunning = false;
      _showFeedbackOverlay = markDisplayEnabled;
      _isCorrectAnswer = false;
      _hasAnswered = true;
    });

    _recordAttempt(false, true);

    _handlePostAnswerFlow(false);
  }

  void _handlePostAnswerFlow(bool isCorrect) {
    final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: isCorrect,
      hasAnswered: true,
    );

    if (stateManager.shouldAutoAdvance()) {
      if (markDisplayEnabled) {
        final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
        Future.delayed(Duration(milliseconds: (markDisplayTime * 1000).round()), () {
          // Check if pause was pressed during the delay
          if (!_pausePressed && mounted) {
            _loadNextPosition();
          }
        });
      } else {
        // No mark display - advance immediately but use a minimal delay to ensure state is properly set
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_pausePressed && mounted) {
            _loadNextPosition();
          }
        });
      }
    } else {
      if (markDisplayEnabled) {
        final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
        Future.delayed(Duration(milliseconds: (markDisplayTime * 1000).round()), () {
          if (mounted) {
            setState(() {
              _showFeedbackOverlay = false;
              _waitingForNext = true;
            });
          }
        });
      } else {
        // No mark display - go directly to waiting state
        setState(() {
          _showFeedbackOverlay = false;
          _waitingForNext = true;
        });
      }
    }
  }

  void _onNextPressed() {
    _loadNextPosition();
  }

  void _onPausePressed() {
    setState(() {
      _pausePressed = true;
      _showFeedbackOverlay = false;
      _waitingForNext = true;
    });
  }

  void _onWelcomeDismiss() {
    setState(() {
      _showWelcomeOverlay = false;
      _timerRunning = true; // Start timer when welcome is dismissed
    });
    // Start timing the problem now
    _problemStartTime = DateTime.now();
  }

  void _onWelcomeDontShowAgain() async {
    if (_globalConfigManager != null) {
      await _globalConfigManager!.dismissWelcomeScreen();
      _globalConfig = _globalConfigManager!.getConfiguration();
    }
    setState(() {
      _showWelcomeOverlay = false;
      _timerRunning = true; // Start timer when welcome is dismissed
    });
    // Start timing the problem now
    _problemStartTime = DateTime.now();
  }

  Widget _buildButtons() {
    final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: _isCorrectAnswer,
      hasAnswered: _hasAnswered,
      pausePressed: _pausePressed,
    );

    final displayMode = stateManager.getDisplayMode();
    final predictionType = _currentConfig?.predictionType ?? PredictionType.winnerPrediction;

    if (_waitingForNext || (displayMode == ButtonDisplayMode.scores && _hasAnswered && !_showFeedbackOverlay)) {
      final currentTrainingPosition = _positionManager.currentTrainingPosition;
      return AdaptiveResultButtons.forScores(
        resultString: currentTrainingPosition?.result ?? '',
        onNextPressed: _onNextPressed,
        appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
        layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        useColoredBackgroundForScores: true,
        blackTerritory: currentTrainingPosition?.blackTerritory,
        whiteTerritory: currentTrainingPosition?.whiteTerritory,
        komi: currentTrainingPosition?.komi,
        trainingPosition: currentTrainingPosition,
        positionType: _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
      );
    } else {
      final isEnabled = ((_timerRunning || !(_currentConfig?.timerEnabled ?? true)) && !_hasAnswered && !_showWelcomeOverlay);

      if (predictionType == PredictionType.exactScorePrediction && _positionManager.currentTrainingPosition != null) {
        // Use pre-generated score options (generated once when position was loaded)
        if (_currentScoreOptions == null) {
          // Fallback: generate if not already generated (shouldn't happen in normal flow)
          final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
          final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
          _currentScoreOptions = PositionedScoreOptions.generate(
            actualScoreString: effectiveResult,
            scoreGranularity: _currentConfig?.scoreGranularity ?? 1,
          );
        }

        return AdaptiveResultButtons.forExactScores(
          positionedScoreOptions: _currentScoreOptions!,
          onExactScoreButtonPressed: isEnabled ? _onExactScoreButtonPressed : (_) {},
          appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
          layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        );
      } else if (predictionType == PredictionType.roughLeadPrediction && _currentRoughLeadState != null) {
        return AdaptiveResultButtons.forChoices(
          roughLeadPredictionState: _currentRoughLeadState!,
          onRoughLeadButtonPressed: isEnabled ? _onRoughLeadButtonPressed : (_) {},
          appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
          layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        );
      } else if (_positionManager.currentDataset != null &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        return AdaptiveResultButtons.forChoices(
          datasetType: _positionManager.currentDataset!.metadata.datasetType,
          actualScore: ScoringConfig.parseScore(effectiveResult),
          resultString: effectiveResult,
          onResultOptionSelected: isEnabled ? _onResultOptionSelected : (_) {},
          appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
          layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        );
      } else {
        return AdaptiveResultButtons.forChoices(
          onResultSelected: isEnabled ? _onResultSelected : (_) {},
          appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
          layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        );
      }
    }
  }

  Future<void> _loadNextPosition() async {
    setState(() {
      _loading = true;
      _showFeedbackOverlay = false;
      _hasAnswered = false;
      _waitingForNext = false;
      _pausePressed = false;
      _currentScoreOptions = null;
      _currentRoughLeadState = null;
    });

    try {
      // Ensure the correct dataset file is loaded for the current custom dataset
      if (_currentDataset != null) {
        final datasetFile = _currentDataset!.datasetFilePath.replaceFirst('assets/', '');
        PositionLoader.setDatasetFile(datasetFile);
        await PositionLoader.preloadDataset();
      }

      await _updateConfiguration();
      final position = await _positionManager.loadRandomPosition();

      // Generate score options for exact score prediction (if needed)
      PositionedScoreOptions? scoreOptions;
      if (_currentConfig?.predictionType == PredictionType.exactScorePrediction &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        scoreOptions = PositionedScoreOptions.generate(
          actualScoreString: effectiveResult,
          scoreGranularity: _currentConfig?.scoreGranularity ?? 1,
        );
      }

      // Generate rough lead prediction state (if needed)
      RoughLeadPredictionState? roughLeadState;
      if (_currentConfig?.predictionType == PredictionType.roughLeadPrediction &&
          _positionManager.currentTrainingPosition != null) {
        final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
        final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
        final actualScore = ScoringConfig.parseScore(effectiveResult);
        roughLeadState = RoughLeadPredictionState.generate(
          actualScore: actualScore,
          thresholdGood: _currentConfig?.thresholdGood ?? 2.0,
          thresholdClose: _currentConfig?.thresholdClose ?? 5.0,
        );
      }

      setState(() {
        _currentPosition = position;
        _timerRunning = !_showWelcomeOverlay; // Only start timer if welcome overlay is not shown
        _loading = false;
        _currentScoreOptions = scoreOptions;
        _currentRoughLeadState = roughLeadState;
      });
      // Start timing the new problem only if welcome overlay is not shown
      if (!_showWelcomeOverlay) {
        _problemStartTime = DateTime.now();
      }
      // Request focus for keyboard input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load next position',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
      setState(() {
        _currentPosition = GoPosition.demo();
        _timerRunning = true;
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load new position: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: _navigateToConfig,
            ),
          ),
        );
      }

      // Request focus for keyboard input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  /// Record a problem attempt with the statistics manager
  Future<void> _recordAttempt(bool isCorrect, bool wasTimeout) async {
    if (_statisticsManager == null ||
        _problemStartTime == null ||
        _positionManager.currentDataset == null ||
        _currentDataset == null) {
      return;
    }

    final now = DateTime.now();
    final timeSpentMs = now.difference(_problemStartTime!).inMilliseconds;

    // Cap the time at 15 seconds (15000ms) for timeouts as specified
    final cappedTimeMs = wasTimeout ? 15000 : timeSpentMs;

    // Calculate points per second if territory data is available
    double? pointsPerSecond;
    final currentPosition = _positionManager.currentTrainingPosition;
    if (currentPosition != null && currentPosition.hasTerritoryData) {
      final totalPoints = (currentPosition.blackTerritory! + currentPosition.whiteTerritory!).toDouble();
      final timeSeconds = cappedTimeMs / 1000.0;
      if (timeSeconds > 0) {
        pointsPerSecond = totalPoints / timeSeconds;
      }
    }

    try {
      await _statisticsManager!.recordAttempt(
        datasetType: _positionManager.currentDataset!.metadata.datasetType,
        datasetId: _currentDataset!.id, // Pass the actual selected dataset ID
        isCorrect: isCorrect,
        timeSpentMs: cappedTimeMs,
        wasTimeout: wasTimeout,
        pointsPerSecond: pointsPerSecond,
      );

      // Update title with latest statistics
      await _updateDynamicTitle();
    } catch (e, stackTrace) {
      LoggerService.error('Failed to record attempt statistics',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
    }
  }

  Widget _buildFeedbackWidget() {
    // Use position-type-aware effective result
    final currentTrainingPosition = _positionManager.currentTrainingPosition;
    final String result;
    if (currentTrainingPosition != null) {
      final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
      result = currentTrainingPosition.getResult(positionType);
    } else {
      result = '';
    }
    final displayResult = _formatResultText(result);
    final colors = _getResultDisplayColors(result);
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = _globalConfig?.layoutType ?? LayoutType.vertical;
    final themeProvider = UnifiedThemeProvider(skin: currentSkin, layoutType: layoutType);

    final correctColor = themeProvider.getElementStyle(UIElement.correctIndicator).color!;
    final incorrectColor = themeProvider.getElementStyle(UIElement.incorrectIndicator).color!;
    final shouldAnimate = themeProvider.getElementStyle(UIElement.correctIndicator).hasAnimation ?? false;

    // Check if pause button should be shown
    final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: _isCorrectAnswer,
      hasAnswered: _hasAnswered,
      pausePressed: _pausePressed,
    );
    final shouldShowPauseButton = stateManager.shouldAutoAdvance() && !_pausePressed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated or static checkmark/cross
        if (shouldAnimate)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isCorrectAnswer ? correctColor : incorrectColor,
                    shape: BoxShape.circle,
                    boxShadow: currentSkin != AppSkin.eink ? [
                      BoxShadow(
                        color: (_isCorrectAnswer ? correctColor : incorrectColor).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    _isCorrectAnswer ? Icons.check_rounded : Icons.close_rounded,
                    size: 80,
                    color: currentSkin == AppSkin.eink ? Colors.white : Colors.white,
                  ),
                ),
              );
            },
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _isCorrectAnswer ? correctColor : incorrectColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: currentSkin == AppSkin.eink ? Colors.black : Colors.transparent,
                width: currentSkin == AppSkin.eink ? 2 : 0,
              ),
            ),
            child: Icon(
              _isCorrectAnswer ? Icons.check_rounded : Icons.close_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        const SizedBox(height: 20),
        // Animated or static result text
        if (shouldAnimate)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderColor, width: 2),
                      boxShadow: currentSkin != AppSkin.eink ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : [],
                    ),
                    child: Text(
                      displayResult,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.textColor,
                        shadows: colors.shadowColor != null && currentSkin != AppSkin.eink ? [
                          Shadow(
                            offset: const Offset(0, 0),
                            blurRadius: 3,
                            color: colors.shadowColor!,
                          ),
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: colors.shadowColor!,
                          ),
                        ] : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor, width: 2),
            ),
            child: Text(
              displayResult,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
          ),
        // Pause button appears below the result text when auto-advance is enabled
        if (shouldShowPauseButton) ...[
          const SizedBox(height: 20),
          PauseButton(
            onPressed: _onPausePressed,
            appSkin: currentSkin,
            backgroundColor: colors.backgroundColor,
          ),
        ],
      ],
    );
  }

  String _formatResultText(String result) {
    if (result.isEmpty) return 'UNKNOWN';

    // Handle resignation
    if (result.endsWith('+R')) {
      return result.startsWith('B') ? 'B+R' : 'W+R';
    }

    // Handle draws (0.5 point difference or exact draw)
    if (result == 'Draw') { // result.contains('+0.5') || result.contains('-0.5') || 
      return 'DRAW';
    }

    // Return result as-is for normal wins (B+7.5, W+2, etc.)
    return result;
  }

  ResultDisplayColors _getResultDisplayColors(String result) {
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = _globalConfig?.layoutType ?? LayoutType.vertical;
    final themeProvider = UnifiedThemeProvider(skin: currentSkin, layoutType: layoutType);

    if (result.isEmpty) {
      // Unknown result - use neutral colors
      final containerStyle = themeProvider.getElementStyle(UIElement.gameStatusBar);
      return ResultDisplayColors(
        backgroundColor: containerStyle.backgroundColor!,
        textColor: themeProvider.getElementStyle(UIElement.textBody).color!,
        borderColor: containerStyle.borderColor!,
        shadowColor: currentSkin == AppSkin.eink ? null : Colors.black.withOpacity(0.3),
      );
    }

    final displayResult = _formatResultText(result);
    String resultType;

    if (displayResult == 'DRAW') {
      resultType = 'draw';
    } else if (result.startsWith('W+')) {
      resultType = 'white';
    } else if (result.startsWith('B+')) {
      resultType = 'black';
    } else {
      resultType = 'default';
    }

    final UIElement buttonElement;
    switch (resultType) {
      case 'white':
        buttonElement = UIElement.buttonResultWhite;
        break;
      case 'black':
        buttonElement = UIElement.buttonResultBlack;
        break;
      case 'draw':
        buttonElement = UIElement.buttonResultDraw;
        break;
      default:
        buttonElement = UIElement.gameStatusBar;
    }

    final elementStyle = themeProvider.getElementStyle(buttonElement);
    final containerStyle = themeProvider.getElementStyle(UIElement.gameStatusBar);

    return ResultDisplayColors(
      backgroundColor: containerStyle.backgroundColor!,
      textColor: elementStyle.color!,
      borderColor: containerStyle.borderColor!,
      shadowColor: currentSkin == AppSkin.eink ? null : Colors.black.withOpacity(0.3),
    );
  }

  /// Get the sequence length from current configuration
  int get _currentSequenceLength {
    return _currentConfig?.sequenceLength ?? 0;
  }

  /// Determine the sequence display mode based on view mode
  SequenceDisplayMode get _currentSequenceDisplayMode {
    if (_currentSequenceLength <= 0) {
      return SequenceDisplayMode.numbersOnly; // Default when no sequence
    }

    // Use view mode to determine sequence display
    return _currentViewMode.defaultSequenceDisplayMode;
  }

  /// Determine the current board view mode based on game state
  BoardViewMode get _currentViewMode {
    // Problem view: timer running, user solving
    if (_timerRunning && !_hasAnswered) {
      return BoardViewMode.problem;
    }

    // Review view: after answering, during feedback, or waiting for next
    if (_hasAnswered || _showFeedbackOverlay || _waitingForNext) {
      return BoardViewMode.review;
    }

    // Default to problem view
    return BoardViewMode.problem;
  }

  /// Get the ownership display mode from current configuration
  OwnershipDisplayMode get _currentOwnershipDisplayMode {
    return _currentConfig?.ownershipDisplayMode ?? OwnershipDisplayMode.none;
  }


  @override
  Widget build(BuildContext context) {
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = _globalConfig?.layoutType ?? LayoutType.vertical;

    if (_loading) {
      if (layoutType == LayoutType.horizontal) {
        // Horizontal layout with vertical app bar on the left
        return Scaffold(
          body: Row(
            children: [
              AdaptiveAppBar(
                layoutType: layoutType,
                onInfoPressed: _navigateToInfo,
                onSettingsPressed: _navigateToConfig,
              ),
              Expanded(
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 24),
                      Text('Loading next position...', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Get ready to analyze the board!', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Vertical layout with horizontal app bar at the top
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(AdaptiveAppBar.getHorizontalHeight()),
            child: AdaptiveAppBar(
              layoutType: layoutType,
              title: _dynamicTitle,
              onInfoPressed: _navigateToInfo,
              onSettingsPressed: _navigateToConfig,
            ),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(height: 24),
                Text('Loading next position...', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Get ready to analyze the board!', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
      }
    }

    final timerType = _globalConfig?.timerType ?? TimerType.smooth;
    // Determine whether to show game info bar
    bool shouldShowGameInfo = true;
    if (_currentConfig != null) {
      final datasetType = _positionManager.currentDataset?.metadata.datasetType;
      final isFinalDataset = datasetType == DatasetType.final9x9 ||
                           datasetType == DatasetType.final13x13 ||
                           datasetType == DatasetType.final19x19;

      if (isFinalDataset) {
        // For final datasets, show game info based on position type
        final positionType = _currentConfig!.positionType;
        shouldShowGameInfo = positionType == PositionType.beforeFillingNeutralPoints;
      } else {
        // For non-final datasets, use the hideGameInfoBar setting
        shouldShowGameInfo = !_currentConfig!.hideGameInfoBar;
      }
    }
    final isTimerEnabled = _currentConfig?.timerEnabled ?? true;

    if (layoutType == LayoutType.horizontal) {
      // Horizontal layout with vertical app bar on the left
      return Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                AdaptiveAppBar(
                  layoutType: layoutType,
                  onInfoPressed: _navigateToInfo,
                  onSettingsPressed: _navigateToConfig,
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: _focusNode,
                    onKeyEvent: _handleKeyEvent,
                    autofocus: true,
                    child: SafeArea(
                      child: AdaptiveLayout(
                        layoutType: layoutType,
                        timerBar: (_timerRunning && isTimerEnabled && !_showWelcomeOverlay)
                            ? TimerBar(
                                duration: Duration(seconds: _currentConfig?.timePerProblemSeconds ?? 30),
                                onComplete: _onTimerComplete,
                                timerType: timerType,
                                appSkin: currentSkin,
                                layoutType: layoutType,
                                barThickness: layoutType == LayoutType.horizontal ? 16.0 : 8.0,
                                segmentGap: layoutType == LayoutType.horizontal ? 4.0 : 2.0,
                              )
                            : Container(
                                height: layoutType == LayoutType.horizontal ? 200 : 8.0,
                                width: layoutType == LayoutType.horizontal ? 16 : null,
                                margin: const EdgeInsets.all(16)
                              ),
                        gameInfoBar: shouldShowGameInfo
                            ? GameStatusBar(
                                position: _positionManager.currentTrainingPosition,
                                appSkin: currentSkin,
                                layoutType: layoutType,
                              )
                            : null,
                        board: GameBoardContainer(
                          position: _currentPosition,
                          trainingPosition: _positionManager.currentTrainingPosition,
                          appSkin: currentSkin,
                          layoutType: layoutType,
                          showFeedbackOverlay: _showFeedbackOverlay,
                          sequenceLength: _currentSequenceLength,
                          sequenceDisplayMode: _currentSequenceDisplayMode,
                          viewMode: _currentViewMode,
                          ownershipDisplayMode: _currentOwnershipDisplayMode,
                          positionType: _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
                          showMoveNumbers: _currentConfig?.showMoveNumbers ?? true,
                          feedbackWidget: _showFeedbackOverlay ? _buildFeedbackWidget() : null,
                        ),
                        buttons: _buildButtons(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showWelcomeOverlay)
              WelcomeOverlay(
                onDismiss: _onWelcomeDismiss,
                onDontShowAgain: _onWelcomeDontShowAgain,
                appSkin: currentSkin,
                layoutType: layoutType,
              ),
          ],
        ),
      );
    } else {
      // Vertical layout with horizontal app bar at the top
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AdaptiveAppBar.getHorizontalHeight()),
          child: AdaptiveAppBar(
            layoutType: layoutType,
            title: _dynamicTitle,
            onInfoPressed: _navigateToInfo,
            onSettingsPressed: _navigateToConfig,
          ),
        ),
        body: Stack(
          children: [
            KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: _handleKeyEvent,
              autofocus: true,
              child: SafeArea(
                child: AdaptiveLayout(
                  layoutType: layoutType,
                  timerBar: (_timerRunning && isTimerEnabled && !_showWelcomeOverlay)
                      ? TimerBar(
                          duration: Duration(seconds: _currentConfig?.timePerProblemSeconds ?? 30),
                          onComplete: _onTimerComplete,
                          timerType: timerType,
                          appSkin: currentSkin,
                          layoutType: layoutType,
                          barThickness: layoutType == LayoutType.horizontal ? 16.0 : 8.0,
                          segmentGap: layoutType == LayoutType.horizontal ? 4.0 : 2.0,
                        )
                      : Container(
                          height: layoutType == LayoutType.horizontal ? 200 : 8.0,
                          width: layoutType == LayoutType.horizontal ? 16 : null,
                          margin: const EdgeInsets.all(16)
                        ),
                  gameInfoBar: shouldShowGameInfo
                      ? GameStatusBar(
                          position: _positionManager.currentTrainingPosition,
                          appSkin: currentSkin,
                          layoutType: layoutType,
                        )
                      : null,
                  board: GameBoardContainer(
                    position: _currentPosition,
                    trainingPosition: _positionManager.currentTrainingPosition,
                    appSkin: currentSkin,
                    layoutType: layoutType,
                    showFeedbackOverlay: _showFeedbackOverlay,
                    sequenceLength: _currentSequenceLength,
                    sequenceDisplayMode: _currentSequenceDisplayMode,
                    viewMode: _currentViewMode,
                    ownershipDisplayMode: _currentOwnershipDisplayMode,
                    positionType: _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
                    showMoveNumbers: _currentConfig?.showMoveNumbers ?? true,
                    feedbackWidget: _showFeedbackOverlay ? _buildFeedbackWidget() : null,
                  ),
                  buttons: _buildButtons(),
                ),
              ),
            ),
            if (_showWelcomeOverlay)
              WelcomeOverlay(
                onDismiss: _onWelcomeDismiss,
                onDontShowAgain: _onWelcomeDontShowAgain,
                appSkin: currentSkin,
                layoutType: layoutType,
              ),
          ],
        ),
      );
    }
  }
}