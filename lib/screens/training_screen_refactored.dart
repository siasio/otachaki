import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_result_option.dart';
import '../models/rough_lead_button_state.dart';
import '../models/prediction_type.dart';
import '../models/auto_advance_mode.dart';
import '../models/layout_type.dart';
import '../models/scoring_config.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/training/training_app_bar.dart';
import '../widgets/training/training_board_section.dart';
import '../widgets/training/training_controls_section.dart';
import '../widgets/training/training_status_section.dart';
import '../widgets/training/training_state_manager.dart';
import '../services/logger_service.dart';
import '../core/game_result_parser.dart';
import './info_screen.dart';
import './config_screen.dart';

/// Refactored TrainingScreen using component-based architecture
/// Reduced from 1,144 lines to a much more manageable size
class TrainingScreen extends StatefulWidget {
  final VoidCallback? onConfigurationChanged;

  const TrainingScreen({super.key, this.onConfigurationChanged});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TrainingStateManager _stateManager = TrainingStateManager();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeApplication();
    _setupKeyboardFocus();
  }

  Future<void> _initializeApplication() async {
    try {
      await _stateManager.initializeConfiguration();
      await _stateManager.loadInitialPosition();
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize training screen',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load training data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupKeyboardFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _stateManager.dispose();
    super.dispose();
  }

  // Navigation handlers
  Future<void> _navigateToInfo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const InfoScreen()),
    );
    _focusNode.requestFocus();
  }

  Future<void> _navigateToConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
    widget.onConfigurationChanged?.call();
    _focusNode.requestFocus();
  }

  // Answer handling
  void _onResultOptionSelected(GameResultOption option) {
    final result = GameResultParser.parseGameResultOption(
      option,
      _stateManager.currentPosition!,
      _stateManager.trainingPosition!,
    );
    _onResultSelected(result);
  }

  void _onResultSelected(GameResult result) {
    if (_stateManager.hasAnswered) return;

    final isCorrect = _evaluateAnswer(result);
    _stateManager.showFeedback(isCorrect);
    _stateManager.recordStatistics(isCorrect);
    _handlePostAnswerFlow(isCorrect);

    setState(() {});
  }

  bool _evaluateAnswer(GameResult result) {
    // TODO: Implement actual answer evaluation logic
    return true; // Placeholder
  }

  void _handlePostAnswerFlow(bool isCorrect) {
    final autoAdvanceMode = _stateManager.globalConfig?.autoAdvanceMode ?? AutoAdvanceMode.always;

    if (autoAdvanceMode == AutoAdvanceMode.always ||
        (autoAdvanceMode == AutoAdvanceMode.onCorrectOnly && isCorrect)) {

      final markDisplayTime = _stateManager.globalConfig?.markDisplayTime ?? 1.0;
      Future.delayed(Duration(milliseconds: (markDisplayTime * 1000).round()), () {
        if (mounted) {
          _onNextPressed();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _stateManager.setWaitingForNext(true);
          setState(() {});
        }
      });
    }
  }

  // Control handlers
  void _onPausePressed() {
    _stateManager.onPausePressed();
    setState(() {});
  }

  void _onNextPressed() {
    _loadNextPosition();
  }

  Future<void> _loadNextPosition() async {
    try {
      await _stateManager.loadNextPosition();
      setState(() {});
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load next position',
        error: e, stackTrace: stackTrace, context: 'TrainingScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load next position. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Specific input handlers
  void _onExactScoreButtonPressed(int buttonPosition) {
    // TODO: Implement exact score button logic
    LoggerService.debug('Exact score button pressed: position $buttonPosition');
  }

  void _onRoughLeadButtonPressed(RoughLeadButtonType buttonType) {
    // TODO: Implement rough lead button logic
    LoggerService.debug('Rough lead button pressed: $buttonType');
  }

  // Keyboard handling
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Handle waiting for next state
    if (_stateManager.waitingForNext) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _onNextPressed();
      }
      return;
    }

    // Handle space key during feedback
    if (_stateManager.showFeedbackOverlay && event.logicalKey == LogicalKeyboardKey.space) {
      if (!_stateManager.pausePressed) {
        _onPausePressed();
      }
      return;
    }

    // Handle prediction type specific keys
    final predictionType = _stateManager.currentConfig?.predictionType ?? PredictionType.winnerPrediction;
    _handlePredictionTypeKeys(event, predictionType);
  }

  void _handlePredictionTypeKeys(KeyEvent event, PredictionType predictionType) {
    // TODO: Implement prediction type specific keyboard handling
    LoggerService.debug('Key pressed: ${event.logicalKey} for prediction type: $predictionType');
  }

  @override
  Widget build(BuildContext context) {
    if (_stateManager.loading || _stateManager.currentPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TrainingAppBar(
            globalConfig: _stateManager.globalConfig,
            onInfoPressed: _navigateToInfo,
            onConfigPressed: _navigateToConfig,
          ),
        ),
        body: AdaptiveLayout(
          layoutType: _stateManager.globalConfig?.layoutType ?? LayoutType.vertical,
          timerBar: TrainingStatusSection(
            globalConfig: _stateManager.globalConfig,
            currentConfig: _stateManager.currentConfig,
            timerRunning: _stateManager.timerRunning,
            loading: _stateManager.loading,
            onTimerComplete: () {
              _stateManager.onTimerComplete();
              setState(() {});
            },
          ),
          board: TrainingBoardSection(
            currentPosition: _stateManager.currentPosition!,
            trainingPosition: _stateManager.trainingPosition,
            globalConfig: _stateManager.globalConfig,
            currentConfig: _stateManager.currentConfig,
            showFeedbackOverlay: _stateManager.showFeedbackOverlay,
            isCorrectAnswer: _stateManager.isCorrectAnswer,
          ),
          buttons: TrainingControlsSection(
            globalConfig: _stateManager.globalConfig,
            currentConfig: _stateManager.currentConfig,
            currentScoreOptions: _stateManager.currentScoreOptions,
            currentRoughLeadState: _stateManager.currentRoughLeadState,
            showFeedbackOverlay: _stateManager.showFeedbackOverlay,
            isCorrectAnswer: _stateManager.isCorrectAnswer,
            hasAnswered: _stateManager.hasAnswered,
            pausePressed: _stateManager.pausePressed,
            waitingForNext: _stateManager.waitingForNext,
            onResultOptionSelected: _onResultOptionSelected,
            onExactScoreButtonPressed: _onExactScoreButtonPressed,
            onRoughLeadButtonPressed: _onRoughLeadButtonPressed,
            onPausePressed: _onPausePressed,
            onNextPressed: _onNextPressed,
          ),
        ),
      ),
    );
  }
}