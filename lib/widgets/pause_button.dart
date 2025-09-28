import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../themes/app_theme.dart';

/// A pause button widget that appears during auto-advance feedback overlay
/// to allow users to interrupt the automatic progression to the next problem.
class PauseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AppSkin appSkin;
  final Color? backgroundColor;

  const PauseButton({
    super.key,
    required this.onPressed,
    this.appSkin = AppSkin.classic,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = SkinConfig.shouldAnimate(appSkin);
    final buttonColor = backgroundColor ?? _getDefaultButtonColor();
    final iconColor = _getIconColor(buttonColor);

    if (shouldAnimate) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: _buildButton(buttonColor, iconColor),
          );
        },
      );
    } else {
      return _buildButton(buttonColor, iconColor);
    }
  }

  Widget _buildButton(Color buttonColor, Color iconColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            border: appSkin == AppSkin.eink
                ? Border.all(color: Colors.black, width: 2)
                : Border.all(color: SkinConfig.getResultBorderColor(appSkin), width: 2),
            boxShadow: appSkin != AppSkin.eink
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _buildPauseIcon(iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseIcon(Color iconColor) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 70,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 20,
            height: 70,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDefaultButtonColor() {
    // Fallback colors when no backgroundColor is provided
    return SkinConfig.getResultBackgroundColor(appSkin);
  }

  Color _getIconColor(Color buttonColor) {
    // Create a darker shade of the button color for the icon
    if (appSkin == AppSkin.eink) {
      // For e-ink, use black for contrast
      return Colors.black;
    }
    return Colors.white.withOpacity(0.9);
    // // Create a darker version of the button color
    // final hsl = HSLColor.fromColor(buttonColor);
    // final darkerHsl = hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0));
    // return darkerHsl.toColor();
  }
}