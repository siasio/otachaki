import 'package:flutter/material.dart';
import '../models/app_skin.dart';

/// A widget that displays an icon styled to look like a 3D keyboard key.
/// 
/// This provides a visual hint that the icon represents a keyboard shortcut,
/// making it more intuitive for users than a plain arrow icon.
/// 
/// The widget uses a dual-rectangle design to create a 3D appearance:
/// - Outer rectangle: the key base/frame
/// - Inner rectangle: the key top surface (offset upward)
/// - Connecting lines at corners to suggest depth/perspective
class KeyboardKeyIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final AppSkin appSkin;

  const KeyboardKeyIcon({
    super.key,
    required this.icon,
    this.size = 20,
    required this.color,
    this.appSkin = AppSkin.classic,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions based on icon size
    final keySize = size * 1.8;
    final iconSize = size * 0.9;
    
    // Offset for 3D effect - inner rect is moved up
    final verticalOffset = keySize * 0.12;
    
    return SizedBox(
      width: keySize,
      height: keySize,
      child: CustomPaint(
        painter: _KeyboardKey3DPainter(
          color: color,
          appSkin: appSkin,
          verticalOffset: verticalOffset,
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -verticalOffset / 2),
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for 3D keyboard key effect
class _KeyboardKey3DPainter extends CustomPainter {
  final Color color;
  final AppSkin appSkin;
  final double verticalOffset;

  _KeyboardKey3DPainter({
    required this.color,
    required this.appSkin,
    required this.verticalOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isEink = appSkin == AppSkin.eink;
    
    // Define rectangles
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    
    // Inner rectangle is smaller and offset upward
    final innerPadding = size.width * 0.08;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        innerPadding,
        innerPadding - verticalOffset,
        size.width - innerPadding * 2,
        size.height - innerPadding * 2,
      ),
      const Radius.circular(4),
    );

    // For eink: use simple outlines
    // For others: use fills and subtle connecting lines
    if (isEink) {
      // Draw outer rectangle (base)
      final outerPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(outerRect, outerPaint);
      
      // Draw inner rectangle (top surface)
      final innerPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(innerRect, innerPaint);
    } else {
      // Draw outer rectangle with fill (base/shadow)
      final outerPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(outerRect, outerPaint);
      
      // Draw outer border
      final outerBorderPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(outerRect, outerBorderPaint);
      
      // Draw connecting lines at corners for 3D depth
      final connectionPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 1;
      
      // Top-left corner connection
      canvas.drawLine(
        Offset(innerPadding, innerPadding - verticalOffset),
        Offset(innerPadding, innerPadding),
        connectionPaint,
      );
      
      // Top-right corner connection
      canvas.drawLine(
        Offset(size.width - innerPadding, innerPadding - verticalOffset),
        Offset(size.width - innerPadding, innerPadding),
        connectionPaint,
      );
      
      // Draw inner rectangle with lighter fill (top surface)
      final innerFillPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(innerRect, innerFillPaint);
      
      // Draw inner border (more prominent)
      final innerBorderPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(innerRect, innerBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_KeyboardKey3DPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.appSkin != appSkin ||
        oldDelegate.verticalOffset != verticalOffset;
  }
}

/// A widget that displays text (like a number) styled to look like a 3D keyboard key.
/// Similar to KeyboardKeyIcon but displays text instead of an icon.
class KeyboardKeyText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final AppSkin appSkin;

  const KeyboardKeyText({
    super.key,
    required this.text,
    this.size = 20,
    required this.color,
    this.appSkin = AppSkin.classic,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions based on size
    final keySize = size * 1.8;
    final fontSize = size * 0.8;
    
    // Offset for 3D effect - inner rect is moved up
    final verticalOffset = keySize * 0.12;
    
    return SizedBox(
      width: keySize,
      height: keySize,
      child: CustomPaint(
        painter: _KeyboardKey3DPainter(
          color: color,
          appSkin: appSkin,
          verticalOffset: verticalOffset,
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -verticalOffset / 2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
