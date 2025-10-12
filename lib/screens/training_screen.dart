import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/go_position.dart';
import '../models/scoring_config.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/position_type.dart';
import '../services/position_manager.dart';
import '../services/position_loader.dart';
import '../services/configuration_manager.dart';
import '../services/custom_dataset_manager.dart';
import '../models/custom_dataset.dart';
import '../models/dataset_registry.dart';
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
import '../models/problem_feedback_type.dart';
// REMOVED: GameStatusBar import - GameInfo functionality has been removed
// import '../widgets/game_status_bar.dart';
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
import '../models/training_state.dart';
import '../services/training_state_manager.dart';
import '../services/device_orientation_service.dart';

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
  final PositionManager _positionManager = PositionManager();
  final TrainingStateManager _stateManager = TrainingStateManager();
  bool _showWelcomeOverlay = false;
  PositionedScoreOptions? _currentScoreOptions;
  RoughLeadPredictionState? _currentRoughLeadState; // State for rough lead prediction mode
  final FocusNode _focusNode = FocusNode();
  ConfigurationManager? _configManager;
  CustomDatasetManager? _datasetManager;
  CustomDataset? _currentDataset;
  DatasetConfiguration? _currentConfig;
  GlobalConfigurationManager? _globalConfigManager;
  GlobalConfiguration? _globalConfig;
  StatisticsManager? _statisticsManager;
  DateTime? _problemStartTime;
  String _dynamicTitle = 'Otachaki';

  @override
  void initState() {
    super.initState();
    _stateManager.onStateChanged = () {
      if (mounted) {
        setState(() {
          // Trigger UI rebuild when state changes
        });
      }
    };
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
      _configManager = await ConfigurationManager.getInstance();
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

      // Apply device settings (orientation and full-screen mode)
      await DeviceOrientationService.applyDeviceSettings(
        orientationMode: _globalConfig!.screenOrientationMode,
        enableFullScreen: _globalConfig!.enableFullScreen,
      );

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
    _stateManager.dispose();
    _focusNode.dispose();
    // Reset device settings when the app is disposed
    DeviceOrientationService.resetDeviceSettings();
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

      if (_stateManager.isWaitingForNext) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onNextPressed();
        }
        return;
      }

      // Handle space key for pause during feedback overlay
      if (_stateManager.shouldShowFeedbackOverlay && event.logicalKey == LogicalKeyboardKey.space) {
        final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
        final buttonStateManager = ButtonStateManager(
          autoAdvanceMode: autoAdvanceMode,
          isAnswerCorrect: _stateManager.isCorrectAnswer,
          hasAnswered: _stateManager.hasAnswered,
          pausePressed: _stateManager.currentState == TrainingState.paused,
        );
        // Only allow pause if the pause button would be visible
        if (buttonStateManager.shouldAutoAdvance() && _stateManager.currentState != TrainingState.paused) {
          _onPausePressed();
        }
        return;
      }

      final isTimerEnabled = _currentConfig?.timerEnabled ?? true;
      if ((!_stateManager.shouldRunTimer && isTimerEnabled) || _stateManager.shouldShowFeedbackOverlay) return;

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
          thresholdGood: _currentConfig?.thresholdGood,
          thresholdClose: _currentConfig?.thresholdClose,
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
    _stateManager.reset();
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

      // Apply device settings in case they changed
      await DeviceOrientationService.applyDeviceSettings(
        orientationMode: _globalConfig!.screenOrientationMode,
        enableFullScreen: _globalConfig!.enableFullScreen,
      );
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
          scoreGranularity: _currentConfig?.scoreGranularity ?? 2,
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
        _currentScoreOptions = scoreOptions;
        _currentRoughLeadState = roughLeadState;
      });

      // Always transition to solving state when position is loaded
      // The welcome overlay (if shown) will be displayed over the game screen
      _stateManager.transitionTo(TrainingState.solving);

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
      });
      _stateManager.transitionTo(TrainingState.solving);
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
    final isCorrect = _checkResultUsingNewSystem(result);
    _recordAttempt(isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    final data = TrainingStateData.answer(isCorrect: isCorrect);

    if (markDisplayEnabled) {
      _stateManager.transitionTo(TrainingState.feedback, data);
    } else {
      _stateManager.transitionTo(TrainingState.review, data);
    }

    _handlePostAnswerFlow(isCorrect);
  }

  void _onResultOptionSelected(GameResultOption option) {
    _recordAttempt(option.isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    final data = TrainingStateData.answer(isCorrect: option.isCorrect);

    if (markDisplayEnabled) {
      _stateManager.transitionTo(TrainingState.feedback, data);
    } else {
      _stateManager.transitionTo(TrainingState.review, data);
    }

    _handlePostAnswerFlow(option.isCorrect);
  }

  void _onExactScoreButtonPressed(int buttonPosition) {
    // Check if the pressed button position is correct
    final isCorrect = buttonPosition == _currentScoreOptions?.correctButtonPosition;

    _recordAttempt(isCorrect, false);

    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    final data = TrainingStateData.answer(isCorrect: isCorrect);

    if (markDisplayEnabled) {
      _stateManager.transitionTo(TrainingState.feedback, data);
    } else {
      _stateManager.transitionTo(TrainingState.review, data);
    }

    _handlePostAnswerFlow(isCorrect);
  }

  /// Handles button presses in rough lead prediction mode.
  ///
  /// Updates the prediction state to mark the pressed button and determines
  /// if the answer was correct based on the rough lead prediction logic.
  void _onRoughLeadButtonPressed(RoughLeadButtonType buttonType) {
    if (_currentRoughLeadState != null) {
      final updatedState = _currentRoughLeadState!.markButtonPressed(buttonType);
      final isCorrect = updatedState.wasAnswerCorrect;

      _recordAttempt(isCorrect, false);

      final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
      final data = TrainingStateData.answer(isCorrect: isCorrect);

      setState(() {
        _currentRoughLeadState = updatedState;
      });

      if (markDisplayEnabled) {
        _stateManager.transitionTo(TrainingState.feedback, data);
      } else {
        _stateManager.transitionTo(TrainingState.review, data);
      }

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
    final data = TrainingStateData.answer(isCorrect: false, wasTimeout: true);

    _recordAttempt(false, true);

    if (markDisplayEnabled) {
      _stateManager.transitionTo(TrainingState.feedback, data);
    } else {
      _stateManager.transitionTo(TrainingState.review, data);
    }

    _handlePostAnswerFlow(false);
  }

  void _handlePostAnswerFlow(bool isCorrect) {
    final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final markDisplayEnabled = _globalConfig?.markDisplayEnabled ?? true;
    final buttonStateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: isCorrect,
      hasAnswered: true,
    );

    if (buttonStateManager.shouldAutoAdvance()) {
      if (markDisplayEnabled && _stateManager.currentState == TrainingState.feedback) {
        final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
        _stateManager.timerManager.scheduleAutoAdvance(
          Duration(milliseconds: (markDisplayTime * 1000).round()),
          () {
            if (mounted && _stateManager.currentState == TrainingState.feedback) {
              _loadNextPosition();
            }
          },
        );
      } else {
        // No mark display - advance immediately
        _stateManager.timerManager.scheduleAutoAdvance(
          const Duration(milliseconds: 50),
          () {
            if (mounted) {
              _loadNextPosition();
            }
          },
        );
      }
    } else {
      if (markDisplayEnabled && _stateManager.currentState == TrainingState.feedback) {
        final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
        _stateManager.timerManager.scheduleAutoAdvance(
          Duration(milliseconds: (markDisplayTime * 1000).round()),
          () {
            if (mounted && _stateManager.currentState == TrainingState.feedback) {
              _stateManager.transitionTo(TrainingState.review);
            }
          },
        );
      } else {
        // Already in review state if no mark display
      }
    }
  }

  void _onNextPressed() {
    _loadNextPosition();
  }

  void _onPausePressed() {
    if (_stateManager.currentState == TrainingState.feedback) {
      _stateManager.transitionTo(TrainingState.paused);
    }
  }

  void _onWelcomeDismiss() {
    setState(() {
      _showWelcomeOverlay = false;
    });
    _stateManager.transitionTo(TrainingState.solving);
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
    });
    _stateManager.transitionTo(TrainingState.solving);
    // Start timing the problem now
    _problemStartTime = DateTime.now();
  }

  Widget _buildButtons() {
    final autoAdvanceMode = _currentConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final buttonStateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: _stateManager.isCorrectAnswer,
      hasAnswered: _stateManager.hasAnswered,
      pausePressed: _stateManager.currentState == TrainingState.paused,
    );

    final displayMode = buttonStateManager.getDisplayMode();
    final predictionType = _currentConfig?.predictionType ?? PredictionType.winnerPrediction;

    if (_stateManager.isWaitingForNext || (displayMode == ButtonDisplayMode.scores && _stateManager.hasAnswered && !_stateManager.shouldShowFeedbackOverlay)) {
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
        datasetType: _positionManager.currentCustomDataset?.baseDatasetType,
      );
    } else {
      final isEnabled = ((_stateManager.shouldRunTimer || !(_currentConfig?.timerEnabled ?? true)) && !_stateManager.hasAnswered && !_showWelcomeOverlay);

      if (predictionType == PredictionType.exactScorePrediction && _positionManager.currentTrainingPosition != null) {
        // Use pre-generated score options (generated once when position was loaded)
        if (_currentScoreOptions == null) {
          // Fallback: generate if not already generated (shouldn't happen in normal flow)
          final positionType = _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints;
          final effectiveResult = _positionManager.currentTrainingPosition!.getResult(positionType);
          _currentScoreOptions = PositionedScoreOptions.generate(
            actualScoreString: effectiveResult,
            scoreGranularity: _currentConfig?.scoreGranularity ?? 2,
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
          thresholdGood: _currentConfig?.thresholdGood,
          thresholdClose: _currentConfig?.thresholdClose,
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
    _stateManager.transitionTo(TrainingState.loading);
    setState(() {
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
          scoreGranularity: _currentConfig?.scoreGranularity ?? 2,
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
        _currentScoreOptions = scoreOptions;
        _currentRoughLeadState = roughLeadState;
      });

      // Always transition to solving state when position is loaded
      // The welcome overlay (if shown) will be displayed over the game screen
      _stateManager.transitionTo(TrainingState.solving);

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
      });
      _stateManager.transitionTo(TrainingState.solving);

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
    final buttonStateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: _stateManager.isCorrectAnswer,
      hasAnswered: _stateManager.hasAnswered,
      pausePressed: _stateManager.currentState == TrainingState.paused,
    );
    final shouldShowPauseButton = buttonStateManager.shouldAutoAdvance() && _stateManager.currentState != TrainingState.paused;

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
                    color: _stateManager.isCorrectAnswer ? correctColor : incorrectColor,
                    shape: BoxShape.circle,
                    boxShadow: currentSkin != AppSkin.eink ? [
                      BoxShadow(
                        color: (_stateManager.isCorrectAnswer ? correctColor : incorrectColor).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ] : [],
                  ),
                  child: Icon(
                    _stateManager.isCorrectAnswer ? Icons.check_rounded : Icons.close_rounded,
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
              color: _stateManager.isCorrectAnswer ? correctColor : incorrectColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: currentSkin == AppSkin.eink ? Colors.black : Colors.transparent,
                width: currentSkin == AppSkin.eink ? 2 : 0,
              ),
            ),
            child: Icon(
              _stateManager.isCorrectAnswer ? Icons.check_rounded : Icons.close_rounded,
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
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : [],
                    ),
                    child: Text(
                      displayResult,
                      textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
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
    // Get base result text
    String baseResult;
    if (result.isEmpty) {
      baseResult = 'UNKNOWN';
    } else if (result.endsWith('+R')) {
      // Handle resignation
      baseResult = result.startsWith('B') ? 'B+R' : 'W+R';
    } else if (result == 'Draw') {
      // Handle draws (0.5 point difference or exact draw)
      baseResult = 'DRAW';
    } else {
      // Return result as-is for normal wins (B+7.5, W+2, etc.)
      baseResult = result;
    }

    // Add timing/speed information based on configuration
    final feedbackType = _currentConfig?.problemFeedbackType ?? ProblemFeedbackType.result;
    if (feedbackType == ProblemFeedbackType.result) {
      return baseResult;
    }

    // Calculate time spent if we have timing data
    if (_problemStartTime != null && _stateManager.hasAnswered) {
      final timeSpentMs = DateTime.now().difference(_problemStartTime!).inMilliseconds;
      final timeSeconds = timeSpentMs / 1000.0;

      if (feedbackType == ProblemFeedbackType.resultWithTime) {
        final formattedTime = timeSeconds >= 4
            ? '${timeSeconds.round()}s'
            : '${timeSeconds.toStringAsFixed(1)}s';
        return '$baseResult\n$formattedTime';
      } else if (feedbackType == ProblemFeedbackType.resultWithSpeed) {
        // Calculate speed if territory data is available
        final currentPosition = _positionManager.currentTrainingPosition;
        if (currentPosition != null && currentPosition.hasTerritoryData && timeSeconds > 0) {
          final totalPoints = (currentPosition.blackTerritory! + currentPosition.whiteTerritory!).toDouble();
          final pointsPerSecond = totalPoints / timeSeconds;
          final formattedSpeed = pointsPerSecond >= 4
              ? '${pointsPerSecond.round()} pts/s'
              : '${pointsPerSecond.toStringAsFixed(1)} pts/s';
          return '$baseResult\n$formattedSpeed';
        } else {
          // Fallback to time if speed can't be calculated
          final formattedTime = timeSeconds >= 4
              ? '${timeSeconds.round()}s'
              : '${timeSeconds.toStringAsFixed(1)}s';
          return '$baseResult\n$formattedTime';
        }
      }
    }

    // Fallback to base result if no timing data available
    return baseResult;
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
        shadowColor: currentSkin == AppSkin.eink ? null : Colors.black.withValues(alpha: 0.3),
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
      textColor: currentSkin == AppSkin.eink ? Colors.black : elementStyle.color!,
      borderColor: containerStyle.borderColor!,
      shadowColor: currentSkin == AppSkin.eink ? null : Colors.black.withValues(alpha: 0.3),
    );
  }

  /// Get the sequence length from current configuration
  int get _currentSequenceLength {
    return _currentConfig?.sequenceLength ?? 0;
  }

  /// Determine if sequence length controls are defined/available for the current dataset
  bool get _isSequenceLengthDefined {
    if (_currentDataset == null || _currentConfig == null) {
      return false;
    }

    final datasetType = _currentDataset!.baseDatasetType;
    final positionType = _currentConfig!.positionType;

    // Sequence length is defined when:
    // 1. It's a midgame dataset, OR
    // 2. It's not a final dataset, OR
    // 3. It's a final dataset with "before filling neutral points" position type
    return DatasetRegistry.isMiddleGameDataset(datasetType) ||
           !DatasetRegistry.isFinalPositionDataset(datasetType) ||
           positionType == PositionType.beforeFillingNeutralPoints;
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
    switch (_stateManager.currentState) {
      case TrainingState.loading:
      case TrainingState.solving:
        return BoardViewMode.problem;
      case TrainingState.feedback:
      case TrainingState.review:
      case TrainingState.paused:
        return BoardViewMode.review;
    }
  }

  /// Get the ownership display mode from current configuration
  OwnershipDisplayMode get _currentOwnershipDisplayMode {
    return _currentConfig?.ownershipDisplayMode ?? OwnershipDisplayMode.none;
  }

  /// Check if move numbers should be shown (always true for midgame datasets)
  bool get _shouldShowMoveNumbers {
    final datasetType = _positionManager.currentDataset?.metadata.datasetType;
    if (datasetType != null && DatasetRegistry.isMiddleGameDataset(datasetType)) {
      return true;  // Always show move numbers for midgame datasets
    }
    return _currentConfig?.showMoveNumbers ?? true;
  }


  @override
  Widget build(BuildContext context) {
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = _globalConfig?.layoutType ?? LayoutType.vertical;

    if (_stateManager.currentState == TrainingState.loading) {
      if (layoutType == LayoutType.horizontal) {
        // Horizontal layout with vertical app bar on the left
        return Scaffold(
          body: Row(
            children: [
              AdaptiveAppBar(
                layoutType: layoutType,
                title: _dynamicTitle,
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
    // REMOVED: GameInfo display logic - GameInfo functionality has been removed
    // bool shouldShowGameInfo = true;
    // if (_currentConfig != null) {
    //   final datasetType = _positionManager.currentDataset?.metadata.datasetType;
    //   final isFinalDataset = datasetType == DatasetType.final9x9 ||
    //                        datasetType == DatasetType.final13x13 ||
    //                        datasetType == DatasetType.final19x19;
    //
    //   if (isFinalDataset) {
    //     // For final datasets, show game info based on position type
    //     final positionType = _currentConfig!.positionType;
    //     shouldShowGameInfo = positionType == PositionType.beforeFillingNeutralPoints;
    //   } else {
    //     // For non-final datasets, use the hideGameInfoBar setting
    //     shouldShowGameInfo = !_currentConfig!.hideGameInfoBar;
    //   }
    // }
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
                  title: _dynamicTitle,
                  onInfoPressed: _navigateToInfo,
                  onSettingsPressed: _navigateToConfig,
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: _focusNode,
                    onKeyEvent: _handleKeyEvent,
                    autofocus: true,
                    child: SafeArea(
                      left: false,
                      right: false,
                      child: AdaptiveLayout(
                        layoutType: layoutType,
                        timerBar: (_stateManager.shouldRunTimer && isTimerEnabled && !_showWelcomeOverlay)
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
                        // REMOVED: GameInfoBar - GameInfo functionality has been removed
                        gameInfoBar: null,
                        board: GameBoardContainer(
                          position: _currentPosition,
                          trainingPosition: _positionManager.currentTrainingPosition,
                          appSkin: currentSkin,
                          layoutType: layoutType,
                          showFeedbackOverlay: _stateManager.shouldShowFeedbackOverlay,
                          sequenceLength: _currentSequenceLength,
                          sequenceDisplayMode: _currentSequenceDisplayMode,
                          viewMode: _currentViewMode,
                          ownershipDisplayMode: _currentOwnershipDisplayMode,
                          positionType: _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
                          showMoveNumbers: _shouldShowMoveNumbers,
                          isSequenceLengthDefined: _isSequenceLengthDefined,
                          feedbackWidget: _stateManager.shouldShowFeedbackOverlay ? _buildFeedbackWidget() : null,
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
                top: false,
                bottom: false,
                child: AdaptiveLayout(
                  layoutType: layoutType,
                  timerBar: (_stateManager.shouldRunTimer && isTimerEnabled && !_showWelcomeOverlay)
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
                  // REMOVED: GameInfoBar - GameInfo functionality has been removed
                  gameInfoBar: null,
                  board: GameBoardContainer(
                    position: _currentPosition,
                    trainingPosition: _positionManager.currentTrainingPosition,
                    appSkin: currentSkin,
                    layoutType: layoutType,
                    showFeedbackOverlay: _stateManager.shouldShowFeedbackOverlay,
                    sequenceLength: _currentSequenceLength,
                    sequenceDisplayMode: _currentSequenceDisplayMode,
                    viewMode: _currentViewMode,
                    ownershipDisplayMode: _currentOwnershipDisplayMode,
                    positionType: _currentConfig?.positionType ?? PositionType.withFilledNeutralPoints,
                    showMoveNumbers: _currentConfig?.showMoveNumbers ?? true,
                    isSequenceLengthDefined: _isSequenceLengthDefined,
                    feedbackWidget: _stateManager.shouldShowFeedbackOverlay ? _buildFeedbackWidget() : null,
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