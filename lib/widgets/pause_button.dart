import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../themes/app_theme.dart';

/// A pause button widget that appears during auto-advance feedback overlay
/// to allow users to interrupt the automatic progression to the next problem.
class PauseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AppSkin appSkin;

  const PauseButton({
    super.key,
    required this.onPressed,
    this.appSkin = AppSkin.classic,
  });

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = SkinConfig.shouldAnimate(appSkin);
    final buttonColor = _getButtonColor();
    final iconColor = _getIconColor();

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
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            border: appSkin == AppSkin.eink
                ? Border.all(color: Colors.black, width: 2)
                : null,
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
      width: 24,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 20,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 20,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor() {
    switch (appSkin) {
      case AppSkin.classic:
        return Colors.orange.shade600;
      case AppSkin.modern:
        return Colors.grey.shade700;
      case AppSkin.eink:
        return Colors.white;
      case AppSkin.ocean:
        return Colors.blue.shade600;
    }
  }

  Color _getIconColor() {
    switch (appSkin) {
      case AppSkin.classic:
        return Colors.white;
      case AppSkin.modern:
        return Colors.white;
      case AppSkin.eink:
        return Colors.black;
      case AppSkin.ocean:
        return Colors.white;
    }
  }
}