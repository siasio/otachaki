import 'game_result_option.dart';

/// Button types for rough lead prediction mode.
/// Maps to the three buttons: White, Close, Black.
enum RoughLeadButtonType { white, close, black }

/// Represents the state of a single button in rough lead prediction mode.
///
/// Each button has a type (white/close/black), display text, correctness flag,
/// and whether it was pressed by the user.
class RoughLeadButtonState {
  final RoughLeadButtonType buttonType;
  final String displayText;
  final bool isCorrect;
  final bool wasPressed;

  const RoughLeadButtonState({
    required this.buttonType,
    required this.displayText,
    required this.isCorrect,
    this.wasPressed = false,
  });

  RoughLeadButtonState copyWith({
    RoughLeadButtonType? buttonType,
    String? displayText,
    bool? isCorrect,
    bool? wasPressed,
  }) {
    return RoughLeadButtonState(
      buttonType: buttonType ?? this.buttonType,
      displayText: displayText ?? this.displayText,
      isCorrect: isCorrect ?? this.isCorrect,
      wasPressed: wasPressed ?? this.wasPressed,
    );
  }
}

/// Manages the complete state for rough lead prediction mode.
///
/// Contains all three button states (white, close, black) and tracks
/// whether the user has answered and which button was selected.
///
/// Key features:
/// - Multiple buttons can be correct simultaneously
/// - Visual feedback shows both pressed button result and other correct options
/// - Uses custom thresholds for determining correctness
class RoughLeadPredictionState {
  final List<RoughLeadButtonState> buttons;
  final bool hasAnswered;
  final RoughLeadButtonType? selectedButton;

  const RoughLeadPredictionState({
    required this.buttons,
    this.hasAnswered = false,
    this.selectedButton,
  });

  /// Generates the initial state for rough lead prediction based on actual score and thresholds.
  ///
  /// Logic:
  /// - White button: correct if score < 0 AND abs(score) > thresholdGood
  /// - Close button: correct if abs(score) <= thresholdClose
  /// - Black button: correct if score > 0 AND abs(score) > thresholdGood
  static RoughLeadPredictionState generate({
    required double actualScore,
    required double thresholdGood,
    required double thresholdClose,
  }) {
    final options = GameResultOption.generateRoughLeadOptions(
      actualScore,
      thresholdGood,
      thresholdClose,
    );

    final buttons = options.map((option) {
      RoughLeadButtonType buttonType;
      switch (option.buttonType) {
        case ButtonType.whiteWins:
          buttonType = RoughLeadButtonType.white;
          break;
        case ButtonType.draw:
          buttonType = RoughLeadButtonType.close;
          break;
        case ButtonType.blackWins:
          buttonType = RoughLeadButtonType.black;
          break;
      }

      return RoughLeadButtonState(
        buttonType: buttonType,
        displayText: option.displayText,
        isCorrect: option.isCorrect,
      );
    }).toList();

    return RoughLeadPredictionState(buttons: buttons);
  }

  RoughLeadPredictionState copyWith({
    List<RoughLeadButtonState>? buttons,
    bool? hasAnswered,
    RoughLeadButtonType? selectedButton,
  }) {
    return RoughLeadPredictionState(
      buttons: buttons ?? this.buttons,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      selectedButton: selectedButton ?? this.selectedButton,
    );
  }

  /// Marks a specific button as pressed and updates the state accordingly.
  ///
  /// Returns a new state with the selected button marked as pressed
  /// and the hasAnswered flag set to true.
  RoughLeadPredictionState markButtonPressed(RoughLeadButtonType buttonType) {
    final updatedButtons = buttons.map((button) {
      if (button.buttonType == buttonType) {
        return button.copyWith(wasPressed: true);
      }
      return button;
    }).toList();

    return copyWith(
      buttons: updatedButtons,
      hasAnswered: true,
      selectedButton: buttonType,
    );
  }

  /// Returns true if the user's answer was correct.
  ///
  /// An answer is correct if the pressed button has isCorrect = true.
  bool get wasAnswerCorrect {
    if (!hasAnswered || selectedButton == null) return false;

    final selectedButtonState = buttons.firstWhere(
      (button) => button.buttonType == selectedButton,
    );

    return selectedButtonState.isCorrect;
  }
}