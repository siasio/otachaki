import 'timer_type.dart';
import 'layout_type.dart';
import 'app_skin.dart';
import 'auto_advance_mode.dart';

class GlobalConfiguration {
  final double markDisplayTimeSeconds;
  final TimerType timerType;
  final LayoutType layoutType;
  final AppSkin appSkin;
  final AutoAdvanceMode autoAdvanceMode;
  final bool markDisplayEnabled;

  const GlobalConfiguration({
    required this.markDisplayTimeSeconds,
    required this.timerType,
    required this.layoutType,
    required this.appSkin,
    required this.autoAdvanceMode,
    this.markDisplayEnabled = true,
  });

  static const GlobalConfiguration defaultConfig = GlobalConfiguration(
    markDisplayTimeSeconds: 1.5,
    timerType: TimerType.smooth,
    layoutType: LayoutType.vertical,
    appSkin: AppSkin.classic,
    autoAdvanceMode: AutoAdvanceMode.always,
  );

  GlobalConfiguration copyWith({
    double? markDisplayTimeSeconds,
    TimerType? timerType,
    LayoutType? layoutType,
    AppSkin? appSkin,
    AutoAdvanceMode? autoAdvanceMode,
    bool? markDisplayEnabled,
  }) {
    return GlobalConfiguration(
      markDisplayTimeSeconds: markDisplayTimeSeconds ?? this.markDisplayTimeSeconds,
      timerType: timerType ?? this.timerType,
      layoutType: layoutType ?? this.layoutType,
      appSkin: appSkin ?? this.appSkin,
      autoAdvanceMode: autoAdvanceMode ?? this.autoAdvanceMode,
      markDisplayEnabled: markDisplayEnabled ?? this.markDisplayEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'markDisplayTimeSeconds': markDisplayTimeSeconds,
      'timerType': timerType.value,
      'layoutType': layoutType.value,
      'appSkin': appSkin.value,
      'autoAdvanceMode': autoAdvanceMode.value,
      'markDisplayEnabled': markDisplayEnabled,
    };
  }

  static GlobalConfiguration fromJson(Map<String, dynamic> json) {
    return GlobalConfiguration(
      markDisplayTimeSeconds: (json['markDisplayTimeSeconds'] as num?)?.toDouble() ?? defaultConfig.markDisplayTimeSeconds,
      timerType: TimerType.fromString(json['timerType'] as String?) ?? defaultConfig.timerType,
      layoutType: LayoutType.fromString(json['layoutType'] as String?) ?? defaultConfig.layoutType,
      appSkin: AppSkin.fromString(json['appSkin'] as String?) ?? defaultConfig.appSkin,
      autoAdvanceMode: AutoAdvanceMode.fromString(json['autoAdvanceMode'] as String?),
      markDisplayEnabled: json['markDisplayEnabled'] as bool? ?? true,
    );
  }

  bool isValidConfiguration() {
    return markDisplayTimeSeconds >= 0;
  }
}