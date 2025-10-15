enum AutoAdvanceMode {
  always('always'),
  never('never'),
  onCorrectOnly('on_correct_only');

  const AutoAdvanceMode(this.value);
  final String value;

  static AutoAdvanceMode fromString(String? value) {
    switch (value) {
      case 'always':
        return AutoAdvanceMode.always;
      case 'never':
        return AutoAdvanceMode.never;
      case 'on_correct_only':
        return AutoAdvanceMode.onCorrectOnly;
      default:
        return AutoAdvanceMode.always;
    }
  }

  String get displayName {
    switch (this) {
      case AutoAdvanceMode.always:
        return 'Auto-advance to the next problem';
      case AutoAdvanceMode.never:
        return 'Pause to review the problem';
      case AutoAdvanceMode.onCorrectOnly:
        return 'Pause on mistakes';
    }
  }
}