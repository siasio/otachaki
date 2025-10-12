import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/screen_orientation_mode.dart';
import 'logger_service.dart';

/// Service to handle device orientation and full-screen mode
class DeviceOrientationService {
  static const String _serviceName = 'DeviceOrientationService';

  /// Apply screen orientation settings
  static Future<void> applyScreenOrientation(ScreenOrientationMode mode) async {
    // Only apply on Android platform
    if (defaultTargetPlatform != TargetPlatform.android) {
      LoggerService.info('Screen orientation changes only supported on Android',
        context: _serviceName);
      return;
    }

    try {
      switch (mode) {
        case ScreenOrientationMode.dontSwitch:
          // Don't force any orientation, let the system handle it
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          break;
        case ScreenOrientationMode.portraitUp:
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          break;
        case ScreenOrientationMode.landscapeLeft:
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
          ]);
          break;
        case ScreenOrientationMode.landscapeRight:
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
          ]);
          break;
      }

      LoggerService.info('Applied screen orientation: ${mode.displayName}',
        context: _serviceName);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to apply screen orientation: ${mode.displayName}',
        error: e, stackTrace: stackTrace, context: _serviceName);
    }
  }

  /// Apply full-screen mode settings
  static Future<void> applyFullScreenMode(bool enableFullScreen) async {
    // Only apply on Android platform
    if (defaultTargetPlatform != TargetPlatform.android) {
      LoggerService.info('Full-screen mode changes only supported on Android',
        context: _serviceName);
      return;
    }

    try {
      if (enableFullScreen) {
        // Hide system UI overlays (status bar, navigation bar)
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [],
        );
        LoggerService.info('Full-screen mode enabled', context: _serviceName);
      } else {
        // Show system UI overlays
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        LoggerService.info('Full-screen mode disabled', context: _serviceName);
      }
    } catch (e, stackTrace) {
      LoggerService.error('Failed to apply full-screen mode: $enableFullScreen',
        error: e, stackTrace: stackTrace, context: _serviceName);
    }
  }

  /// Apply both orientation and full-screen settings from global configuration
  static Future<void> applyDeviceSettings({
    required ScreenOrientationMode orientationMode,
    required bool enableFullScreen,
  }) async {
    await Future.wait([
      applyScreenOrientation(orientationMode),
      applyFullScreenMode(enableFullScreen),
    ]);
  }

  /// Reset orientation to allow all orientations (useful when exiting the app)
  static Future<void> resetOrientation() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      LoggerService.info('Screen orientation reset to default', context: _serviceName);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to reset screen orientation',
        error: e, stackTrace: stackTrace, context: _serviceName);
    }
  }

  /// Reset full-screen mode to show system UI
  static Future<void> resetFullScreenMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      LoggerService.info('Full-screen mode reset to default', context: _serviceName);
    } catch (e, stackTrace) {
      LoggerService.error('Failed to reset full-screen mode',
        error: e, stackTrace: stackTrace, context: _serviceName);
    }
  }

  /// Reset both orientation and full-screen mode to defaults
  static Future<void> resetDeviceSettings() async {
    await Future.wait([
      resetOrientation(),
      resetFullScreenMode(),
    ]);
  }
}