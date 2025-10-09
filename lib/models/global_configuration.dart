import 'timer_type.dart';
import 'layout_type.dart';
import 'app_skin.dart';
import 'auto_advance_mode.dart';
import 'sequence_display_mode.dart';
import 'ownership_display_mode.dart';

class GlobalConfiguration {
  final double markDisplayTimeSeconds;
  final TimerType timerType;
  final LayoutType layoutType;
  final AppSkin appSkin;
  final AutoAdvanceMode autoAdvanceMode;
  final bool markDisplayEnabled;
  final SequenceDisplayMode sequenceDisplayMode;
  final OwnershipDisplayMode ownershipDisplayMode;
  final bool showMoveNumbers;

  /// Convenience getter for compatibility with refactored code
  double get markDisplayTime => markDisplayTimeSeconds;

  const GlobalConfiguration({
    required this.markDisplayTimeSeconds,
    required this.timerType,
    required this.layoutType,
    required this.appSkin,
    required this.autoAdvanceMode,
    this.markDisplayEnabled = true,
    this.sequenceDisplayMode = SequenceDisplayMode.numbersOnly,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.showMoveNumbers = true,
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
    SequenceDisplayMode? sequenceDisplayMode,
    OwnershipDisplayMode? ownershipDisplayMode,
    bool? showMoveNumbers,
  }) {
    return GlobalConfiguration(
      markDisplayTimeSeconds: markDisplayTimeSeconds ?? this.markDisplayTimeSeconds,
      timerType: timerType ?? this.timerType,
      layoutType: layoutType ?? this.layoutType,
      appSkin: appSkin ?? this.appSkin,
      autoAdvanceMode: autoAdvanceMode ?? this.autoAdvanceMode,
      markDisplayEnabled: markDisplayEnabled ?? this.markDisplayEnabled,
      sequenceDisplayMode: sequenceDisplayMode ?? this.sequenceDisplayMode,
      ownershipDisplayMode: ownershipDisplayMode ?? this.ownershipDisplayMode,
      showMoveNumbers: showMoveNumbers ?? this.showMoveNumbers,
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
      'sequenceDisplayMode': sequenceDisplayMode.name,
      'ownershipDisplayMode': ownershipDisplayMode.name,
      'showMoveNumbers': showMoveNumbers,
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
      sequenceDisplayMode: _parseSequenceDisplayMode(json['sequenceDisplayMode'] as String?),
      ownershipDisplayMode: _parseOwnershipDisplayMode(json['ownershipDisplayMode'] as String?),
      showMoveNumbers: json['showMoveNumbers'] as bool? ?? true,
    );
  }

  static SequenceDisplayMode _parseSequenceDisplayMode(String? value) {
    switch (value) {
      case 'numbersOnly':
        return SequenceDisplayMode.numbersOnly;
      case 'stonesWithNumbers':
        return SequenceDisplayMode.stonesWithNumbers;
      default:
        return SequenceDisplayMode.numbersOnly;
    }
  }

  static OwnershipDisplayMode _parseOwnershipDisplayMode(String? value) {
    switch (value) {
      case 'none':
        return OwnershipDisplayMode.none;
      case 'squares':
        return OwnershipDisplayMode.squares;
      case 'overlay':
        return OwnershipDisplayMode.overlay;
      default:
        return OwnershipDisplayMode.none;
    }
  }

  bool isValidConfiguration() {
    return markDisplayTimeSeconds >= 0;
  }
}