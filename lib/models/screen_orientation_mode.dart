enum ScreenOrientationMode {
  dontSwitch('dontSwitch', "Don't Switch"),
  portraitUp('portraitUp', 'Portrait (Up)'),
  landscapeLeft('landscapeLeft', 'Landscape (Left)'),
  landscapeRight('landscapeRight', 'Landscape (Right)');

  const ScreenOrientationMode(this.value, this.displayName);

  final String value;
  final String displayName;

  static ScreenOrientationMode? fromString(String? value) {
    if (value == null) return null;
    try {
      return ScreenOrientationMode.values.firstWhere((mode) => mode.value == value);
    } catch (_) {
      return null;
    }
  }
}