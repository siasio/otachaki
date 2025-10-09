import 'package:flutter/material.dart';
import '../../models/global_configuration.dart';
import '../../models/dataset_configuration.dart';
import '../../models/app_skin.dart';
import '../../models/layout_type.dart';
import '../../widgets/timer_bar.dart';
import '../../widgets/game_status_bar.dart';

/// Status section component for the training screen
/// Contains timer bar and game status information
class TrainingStatusSection extends StatelessWidget {
  final GlobalConfiguration? globalConfig;
  final DatasetConfiguration? currentConfig;
  final bool timerRunning;
  final bool loading;
  final VoidCallback onTimerComplete;

  const TrainingStatusSection({
    super.key,
    required this.globalConfig,
    required this.currentConfig,
    required this.timerRunning,
    required this.loading,
    required this.onTimerComplete,
  });

  @override
  Widget build(BuildContext context) {
    final currentSkin = globalConfig?.appSkin ?? AppSkin.classic;
    final layoutType = globalConfig?.layoutType ?? LayoutType.vertical;

    return Column(
      children: [
        // Timer bar (if enabled)
        if (currentConfig?.timerEnabled == true)
          TimerBar(
            timerType: currentConfig?.timerType,
            duration: currentConfig?.timerDurationSeconds,
            isRunning: timerRunning,
            onTimerComplete: onTimerComplete,
            appSkin: currentSkin,
            layoutType: layoutType,
          ),

        const SizedBox(height: 8),

        // Game status bar
        if (!loading)
          GameStatusBar(
            appSkin: currentSkin,
            layoutType: layoutType,
          ),
      ],
    );
  }
}