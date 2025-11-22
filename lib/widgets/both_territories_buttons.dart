import 'package:flutter/material.dart';
import '../models/both_territories_state.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import 'universal_result_button.dart';

/// Widget that displays two rows of territory buttons for the Both Territories mode.
///
/// Top row: Black territory buttons (B=n format)
/// Bottom row: White territory buttons (W=m format, with komi included)
///
/// Buttons show visual feedback when pressed (darker appearance).
/// User must select one button from each row before answer is submitted.
class BothTerritoriesButtons extends StatelessWidget {
  final BothTerritoriesState state;
  final Function(int) onBlackButtonPressed;
  final Function(int) onWhiteButtonPressed;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const BothTerritoriesButtons({
    super.key,
    required this.state,
    required this.onBlackButtonPressed,
    required this.onWhiteButtonPressed,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Black territory row
        _buildButtonRow(
          buttons: state.blackButtons,
          onPressed: onBlackButtonPressed,
          label: "Black's Territory",
        ),
        const SizedBox(height: 16),
        // White territory row
        _buildButtonRow(
          buttons: state.whiteButtons,
          onPressed: onWhiteButtonPressed,
          label: "White's Territory (with komi)",
        ),
      ],
    );
  }

  Widget _buildButtonRow({
    required List<TerritoryButtonState> buttons,
    required Function(int) onPressed,
    required String label,
  }) {
    final isVertical = layoutType == LayoutType.vertical;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional label for clarity
        if (isVertical) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        // Row of three buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buttons.map((button) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: UniversalResultButton.exactScore(
                  scoreText: button.displayText,
                  onPressed: () => onPressed(button.buttonPosition),
                  isCorrect: button.isCorrect,
                  appSkin: appSkin,
                  layoutType: layoutType,
                  buttonPosition: button.buttonPosition,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Widget for rendering the button group with proper styling
class BothTerritoriesButtonGroup extends StatelessWidget {
  final BothTerritoriesState state;
  final Function(int) onBlackButtonPressed;
  final Function(int) onWhiteButtonPressed;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const BothTerritoriesButtonGroup({
    super.key,
    required this.state,
    required this.onBlackButtonPressed,
    required this.onWhiteButtonPressed,
    this.appSkin = AppSkin.classic,
    this.layoutType = LayoutType.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Black territory row
        _buildButtonRow(
          buttons: state.blackButtons,
          onPressed: onBlackButtonPressed,
        ),
        const SizedBox(height: 12),
        // White territory row  
        _buildButtonRow(
          buttons: state.whiteButtons,
          onPressed: onWhiteButtonPressed,
        ),
      ],
    );
  }

  Widget _buildButtonRow({
    required List<TerritoryButtonState> buttons,
    required Function(int) onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.asMap().entries.map((entry) {
        final button = entry.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildTerritoryButton(button, onPressed),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTerritoryButton(TerritoryButtonState button, Function(int) onPressed) {
    return UniversalResultButton(
      displayText: button.displayText,
      onPressed: () => onPressed(button.buttonPosition),
      isCorrect: button.isCorrect,
      isPressed: button.wasPressed,
      buttonType: UniversalButtonType.exactScore,
      appSkin: appSkin,
      layoutType: layoutType,
      showCorrectnessFeedback: false, // Don't show feedback until both selected
      icon: _getIconForPosition(button.buttonPosition),
    );
  }

  IconData? _getIconForPosition(int position) {
    switch (position) {
      case 0:
        return Icons.arrow_back; // Left
      case 1:
        return Icons.arrow_downward; // Middle
      case 2:
        return Icons.arrow_forward; // Right
      default:
        return null;
    }
  }
}
