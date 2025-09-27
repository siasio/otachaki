import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/global_configuration.dart';
import 'package:countingapp/models/timer_type.dart';
import 'package:countingapp/models/layout_type.dart';
import 'package:countingapp/models/app_skin.dart';
import 'package:countingapp/models/auto_advance_mode.dart';

void main() {
  group('GlobalConfiguration', () {
    test('should have correct default values', () {
      const config = GlobalConfiguration.defaultConfig;

      expect(config.markDisplayTimeSeconds, 1.5);
      expect(config.timerType, TimerType.smooth);
      expect(config.layoutType, LayoutType.vertical);
      expect(config.appSkin, AppSkin.classic);
      expect(config.autoAdvanceMode, AutoAdvanceMode.always);
      expect(config.useColoredBackgroundForScores, false);
    });

    test('should create valid configuration', () {
      const config = GlobalConfiguration(
        markDisplayTimeSeconds: 2.0,
        timerType: TimerType.segmented,
        layoutType: LayoutType.horizontal,
        appSkin: AppSkin.eink,
        autoAdvanceMode: AutoAdvanceMode.never,
        useColoredBackgroundForScores: true,
      );

      expect(config.markDisplayTimeSeconds, 2.0);
      expect(config.timerType, TimerType.segmented);
      expect(config.layoutType, LayoutType.horizontal);
      expect(config.appSkin, AppSkin.eink);
      expect(config.autoAdvanceMode, AutoAdvanceMode.never);
      expect(config.useColoredBackgroundForScores, true);
    });

    test('copyWith should preserve unchanged values', () {
      const original = GlobalConfiguration.defaultConfig;

      final modified = original.copyWith(
        markDisplayTimeSeconds: 3.0,
      );

      expect(modified.markDisplayTimeSeconds, 3.0);
      expect(modified.timerType, original.timerType);
      expect(modified.layoutType, original.layoutType);
      expect(modified.appSkin, original.appSkin);
      expect(modified.autoAdvanceMode, original.autoAdvanceMode);
      expect(modified.useColoredBackgroundForScores, original.useColoredBackgroundForScores);
    });

    test('should serialize to JSON correctly', () {
      const config = GlobalConfiguration(
        markDisplayTimeSeconds: 2.5,
        timerType: TimerType.segmented,
        layoutType: LayoutType.horizontal,
        appSkin: AppSkin.modern,
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
        useColoredBackgroundForScores: true,
      );

      final json = config.toJson();

      expect(json['markDisplayTimeSeconds'], 2.5);
      expect(json['timerType'], 'segmented');
      expect(json['layoutType'], 'horizontal');
      expect(json['appSkin'], 'modern');
      expect(json['autoAdvanceMode'], 'on_correct_only');
      expect(json['useColoredBackgroundForScores'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'markDisplayTimeSeconds': 3.0,
        'timerType': 'segmented',
        'layoutType': 'horizontal',
        'appSkin': 'ocean',
        'autoAdvanceMode': 'never',
        'useColoredBackgroundForScores': false,
      };

      final config = GlobalConfiguration.fromJson(json);

      expect(config.markDisplayTimeSeconds, 3.0);
      expect(config.timerType, TimerType.segmented);
      expect(config.layoutType, LayoutType.horizontal);
      expect(config.appSkin, AppSkin.ocean);
      expect(config.autoAdvanceMode, AutoAdvanceMode.never);
      expect(config.useColoredBackgroundForScores, false);
    });

    test('should use defaults for missing JSON fields', () {
      final json = <String, dynamic>{};

      final config = GlobalConfiguration.fromJson(json);

      expect(config.markDisplayTimeSeconds, GlobalConfiguration.defaultConfig.markDisplayTimeSeconds);
      expect(config.timerType, GlobalConfiguration.defaultConfig.timerType);
      expect(config.layoutType, GlobalConfiguration.defaultConfig.layoutType);
      expect(config.appSkin, GlobalConfiguration.defaultConfig.appSkin);
      expect(config.autoAdvanceMode, GlobalConfiguration.defaultConfig.autoAdvanceMode);
      expect(config.useColoredBackgroundForScores, GlobalConfiguration.defaultConfig.useColoredBackgroundForScores);
    });

    test('isValidConfiguration should validate mark display time', () {
      const validConfig = GlobalConfiguration(
        markDisplayTimeSeconds: 1.0,
        timerType: TimerType.smooth,
        layoutType: LayoutType.vertical,
        appSkin: AppSkin.classic,
        autoAdvanceMode: AutoAdvanceMode.always,
        useColoredBackgroundForScores: false,
      );

      const invalidConfig = GlobalConfiguration(
        markDisplayTimeSeconds: -1.0,
        timerType: TimerType.smooth,
        layoutType: LayoutType.vertical,
        appSkin: AppSkin.classic,
        autoAdvanceMode: AutoAdvanceMode.always,
        useColoredBackgroundForScores: false,
      );

      expect(validConfig.isValidConfiguration(), isTrue);
      expect(invalidConfig.isValidConfiguration(), isFalse);
    });
  });
}