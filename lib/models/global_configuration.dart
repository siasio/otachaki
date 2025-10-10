import 'timer_type.dart';
import 'layout_type.dart';
import 'app_skin.dart';
import 'sequence_display_mode.dart';
import 'ownership_display_mode.dart';

class GlobalConfiguration {
  final double markDisplayTimeSeconds;
  final TimerType timerType;
  final LayoutType layoutType;
  final AppSkin appSkin;
  final bool markDisplayEnabled;
  final SequenceDisplayMode sequenceDisplayMode;
  final OwnershipDisplayMode ownershipDisplayMode;
  final bool showMoveNumbers;
  final bool showWelcomeScreen;
  final String customTitle;

  /// Convenience getter for compatibility with refactored code
  double get markDisplayTime => markDisplayTimeSeconds;

  const GlobalConfiguration({
    required this.markDisplayTimeSeconds,
    required this.timerType,
    required this.layoutType,
    required this.appSkin,
    this.markDisplayEnabled = true,
    this.sequenceDisplayMode = SequenceDisplayMode.numbersOnly,
    this.ownershipDisplayMode = OwnershipDisplayMode.none,
    this.showMoveNumbers = true,
    this.showWelcomeScreen = true,
    this.customTitle = 'Go Position Training',
  });

  static const GlobalConfiguration defaultConfig = GlobalConfiguration(
    markDisplayTimeSeconds: 1.5,
    timerType: TimerType.smooth,
    layoutType: LayoutType.vertical,
    appSkin: AppSkin.classic,
  );

  GlobalConfiguration copyWith({
    double? markDisplayTimeSeconds,
    TimerType? timerType,
    LayoutType? layoutType,
    AppSkin? appSkin,
    bool? markDisplayEnabled,
    SequenceDisplayMode? sequenceDisplayMode,
    OwnershipDisplayMode? ownershipDisplayMode,
    bool? showMoveNumbers,
    bool? showWelcomeScreen,
    String? customTitle,
  }) {
    return GlobalConfiguration(
      markDisplayTimeSeconds: markDisplayTimeSeconds ?? this.markDisplayTimeSeconds,
      timerType: timerType ?? this.timerType,
      layoutType: layoutType ?? this.layoutType,
      appSkin: appSkin ?? this.appSkin,
      markDisplayEnabled: markDisplayEnabled ?? this.markDisplayEnabled,
      sequenceDisplayMode: sequenceDisplayMode ?? this.sequenceDisplayMode,
      ownershipDisplayMode: ownershipDisplayMode ?? this.ownershipDisplayMode,
      showMoveNumbers: showMoveNumbers ?? this.showMoveNumbers,
      showWelcomeScreen: showWelcomeScreen ?? this.showWelcomeScreen,
      customTitle: customTitle ?? this.customTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'markDisplayTimeSeconds': markDisplayTimeSeconds,
      'timerType': timerType.value,
      'layoutType': layoutType.value,
      'appSkin': appSkin.value,
      'markDisplayEnabled': markDisplayEnabled,
      'sequenceDisplayMode': sequenceDisplayMode.name,
      'ownershipDisplayMode': ownershipDisplayMode.name,
      'showMoveNumbers': showMoveNumbers,
      'showWelcomeScreen': showWelcomeScreen,
      'customTitle': customTitle,
    };
  }

  static GlobalConfiguration fromJson(Map<String, dynamic> json) {
    return GlobalConfiguration(
      markDisplayTimeSeconds: (json['markDisplayTimeSeconds'] as num?)?.toDouble() ?? defaultConfig.markDisplayTimeSeconds,
      timerType: TimerType.fromString(json['timerType'] as String?) ?? defaultConfig.timerType,
      layoutType: LayoutType.fromString(json['layoutType'] as String?) ?? defaultConfig.layoutType,
      appSkin: AppSkin.fromString(json['appSkin'] as String?) ?? defaultConfig.appSkin,
      markDisplayEnabled: json['markDisplayEnabled'] as bool? ?? true,
      sequenceDisplayMode: _parseSequenceDisplayMode(json['sequenceDisplayMode'] as String?),
      ownershipDisplayMode: _parseOwnershipDisplayMode(json['ownershipDisplayMode'] as String?),
      showMoveNumbers: json['showMoveNumbers'] as bool? ?? true,
      showWelcomeScreen: json['showWelcomeScreen'] as bool? ?? true,
      customTitle: json['customTitle'] as String? ?? defaultConfig.customTitle,
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