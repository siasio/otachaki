import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/go_position.dart';
import '../models/scoring_config.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../services/position_manager.dart';
import '../services/configuration_manager.dart';
import '../services/global_configuration_manager.dart';
import '../services/statistics_manager.dart';
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
  final FocusNode _focusNode = FocusNode();
  ConfigurationManager? _configManager;
  DatasetConfiguration? _currentConfig;
  GlobalConfigurationManager? _globalConfigManager;
  GlobalConfiguration? _globalConfig;
  StatisticsManager? _statisticsManager;
  DateTime? _problemStartTime;

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
      _configManager = await ConfigurationManager.getInstance();
      _globalConfigManager = await GlobalConfigurationManager.getInstance();
      _globalConfig = _globalConfigManager!.getConfiguration();
      _statisticsManager = await StatisticsManager.getInstance();
      _loadInitialPosition();
    } catch (e) {
      // Gracefully handle configuration manager errors
      debugPrint('Error initializing configuration manager: $e');
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_waitingForNext) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _onNextPressed();
        }
        return;
      }

      // Handle space key for pause during feedback overlay
      if (_showFeedbackOverlay && event.logicalKey == LogicalKeyboardKey.space) {
        final autoAdvanceMode = _globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
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

      if (!_timerRunning || _showFeedbackOverlay) return;

      if (_positionManager.currentDataset != null &&
          _positionManager.currentTrainingPosition != null) {
        final options = GameResultOption.generateOptions(
          _positionManager.currentDataset!.metadata.datasetType,
          ScoringConfig.parseScore(_positionManager.currentTrainingPosition!.result),
          _positionManager.currentTrainingPosition!.result,
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
    }
    // Notify parent app of configuration changes
    widget.onConfigurationChanged?.call();
    // Load fresh position when returning (dataset may have changed)
    _loadNextPosition();
  }

  Future<void> _loadInitialPosition() async {
    try {
      final position = await _positionManager.loadRandomPosition();
      await _updateConfiguration();
      setState(() {
        _currentPosition = position;
        _loading = false;
      });
      // Start timing the problem
      _problemStartTime = DateTime.now();
      // Request focus for keyboard input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } catch (e) {
      debugPrint('Error loading initial position: $e');
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
    if (_configManager == null || _positionManager.currentDataset == null) {
      _currentConfig = DatasetConfiguration.getDefaultFor(DatasetType.final9x9Area);
      return;
    }

    final datasetType = _positionManager.currentDataset!.metadata.datasetType;
    _currentConfig = _configManager!.getConfiguration(datasetType);
  }

  void _onResultSelected(GameResult result) {
    setState(() {
      _timerRunning = false;
      _hasAnswered = true;
    });

    final isCorrect = _checkResultUsingNewSystem(result);
    _recordAttempt(isCorrect, false);

    setState(() {
      _showFeedbackOverlay = true;
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

    setState(() {
      _showFeedbackOverlay = true;
      _isCorrectAnswer = option.isCorrect;
    });

    _handlePostAnswerFlow(option.isCorrect);
  }

  bool _checkResultUsingNewSystem(GameResult selectedResult) {
    final currentTrainingPosition = _positionManager.currentTrainingPosition;
    if (currentTrainingPosition == null) return false;

    // Parse the score from the result string
    final actualScore = ScoringConfig.parseScore(currentTrainingPosition.result);

    // Get all valid results for this score using default config
    final validResults = ScoringConfig.defaultConfig.getValidResults(actualScore);

    // Check if the selected result is among the valid ones
    return validResults.contains(selectedResult);
  }

  void _onTimerComplete() {
    setState(() {
      _timerRunning = false;
      _showFeedbackOverlay = true;
      _isCorrectAnswer = false;
      _hasAnswered = true;
    });

    _recordAttempt(false, true);

    _handlePostAnswerFlow(false);
  }

  void _handlePostAnswerFlow(bool isCorrect) {
    final autoAdvanceMode = _globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: isCorrect,
      hasAnswered: true,
    );

    if (stateManager.shouldAutoAdvance()) {
      final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
      Future.delayed(Duration(milliseconds: (markDisplayTime * 1000).round()), () {
        // Check if pause was pressed during the delay
        if (!_pausePressed && mounted) {
          _loadNextPosition();
        }
      });
    } else {
      final markDisplayTime = _globalConfig?.markDisplayTimeSeconds ?? 1.5;
      Future.delayed(Duration(milliseconds: (markDisplayTime * 1000).round()), () {
        if (mounted) {
          setState(() {
            _showFeedbackOverlay = false;
            _waitingForNext = true;
          });
        }
      });
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

  Widget _buildButtons() {
    final autoAdvanceMode = _globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
    final stateManager = ButtonStateManager(
      autoAdvanceMode: autoAdvanceMode,
      isAnswerCorrect: _isCorrectAnswer,
      hasAnswered: _hasAnswered,
      pausePressed: _pausePressed,
    );

    final displayMode = stateManager.getDisplayMode();

    if (_waitingForNext || (displayMode == ButtonDisplayMode.scores && _hasAnswered && !_showFeedbackOverlay)) {
      return AdaptiveResultButtons.forScores(
        resultString: _positionManager.currentTrainingPosition?.result ?? '',
        onNextPressed: _onNextPressed,
        appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
        layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        useColoredBackgroundForScores: true,
      );
    } else {
      if (_positionManager.currentDataset != null &&
          _positionManager.currentTrainingPosition != null) {
        return AdaptiveResultButtons.forChoices(
          datasetType: _positionManager.currentDataset!.metadata.datasetType,
          actualScore: ScoringConfig.parseScore(_positionManager.currentTrainingPosition!.result),
          resultString: _positionManager.currentTrainingPosition!.result,
          onResultOptionSelected: _timerRunning && !_hasAnswered ? _onResultOptionSelected : (_) {},
          appSkin: _globalConfig?.appSkin ?? AppSkin.classic,
          layoutType: _globalConfig?.layoutType ?? LayoutType.vertical,
        );
      } else {
        return AdaptiveResultButtons.forChoices(
          onResultSelected: _timerRunning && !_hasAnswered ? _onResultSelected : (_) {},
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
    });

    try {
      final position = await _positionManager.loadRandomPosition();
      await _updateConfiguration();
      setState(() {
        _currentPosition = position;
        _timerRunning = true;
        _loading = false;
      });
      // Start timing the new problem
      _problemStartTime = DateTime.now();
      // Request focus for keyboard input
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } catch (e) {
      debugPrint('Error loading next position: $e');
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
        _positionManager.currentDataset == null) {
      return;
    }

    final now = DateTime.now();
    final timeSpentMs = now.difference(_problemStartTime!).inMilliseconds;

    // Cap the time at 15 seconds (15000ms) for timeouts as specified
    final cappedTimeMs = wasTimeout ? 15000 : timeSpentMs;

    try {
      await _statisticsManager!.recordAttempt(
        datasetType: _positionManager.currentDataset!.metadata.datasetType,
        isCorrect: isCorrect,
        timeSpentMs: cappedTimeMs,
        wasTimeout: wasTimeout,
      );
    } catch (e) {
      debugPrint('Error recording attempt: $e');
    }
  }

  Widget _buildFeedbackWidget() {
    final result = _positionManager.currentTrainingPosition?.result ?? '';
    final displayResult = _formatResultText(result);
    final colors = _getResultDisplayColors(result);
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = _globalConfig?.layoutType ?? LayoutType.vertical;
    final themeProvider = UnifiedThemeProvider(skin: currentSkin, layoutType: layoutType);

    final correctColor = themeProvider.getElementStyle(UIElement.correctIndicator).color!;
    final incorrectColor = themeProvider.getElementStyle(UIElement.incorrectIndicator).color!;
    final shouldAnimate = themeProvider.getElementStyle(UIElement.correctIndicator).hasAnimation ?? false;

    // Check if pause button should be shown
    final autoAdvanceMode = _globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;
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
    final shouldShowGameInfo = _currentConfig != null ? !_currentConfig!.hideGameInfoBar : true;

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
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: _handleKeyEvent,
                autofocus: true,
                child: SafeArea(
                  child: AdaptiveLayout(
                    layoutType: layoutType,
                    timerBar: _timerRunning
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
                      feedbackWidget: _showFeedbackOverlay ? _buildFeedbackWidget() : null,
                    ),
                    buttons: _buildButtons(),
                  ),
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
            onInfoPressed: _navigateToInfo,
            onSettingsPressed: _navigateToConfig,
          ),
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          autofocus: true,
          child: SafeArea(
            child: AdaptiveLayout(
              layoutType: layoutType,
              timerBar: _timerRunning
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
                feedbackWidget: _showFeedbackOverlay ? _buildFeedbackWidget() : null,
              ),
              buttons: _buildButtons(),
            ),
          ),
        ),
      );
    }
  }
}