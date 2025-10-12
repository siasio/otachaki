import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/themes/unified_theme_provider.dart';
import 'package:countingapp/themes/element_registry.dart';
import 'package:countingapp/models/app_skin.dart';
import 'package:countingapp/models/layout_type.dart';

void main() {
  group('UnifiedThemeProvider', () {
    late UnifiedThemeProvider classicProvider;
    late UnifiedThemeProvider modernProvider;
    late UnifiedThemeProvider einkProvider;

    setUp(() {
      classicProvider = const UnifiedThemeProvider(
        skin: AppSkin.classic,
        layoutType: LayoutType.vertical,
      );
      modernProvider = const UnifiedThemeProvider(
        skin: AppSkin.modern,
        layoutType: LayoutType.vertical,
      );
        layoutType: LayoutType.vertical,
      );
      einkProvider = const UnifiedThemeProvider(
        skin: AppSkin.eink,
        layoutType: LayoutType.vertical,
      );
    });

    group('Board Elements', () {
      test('should return correct board background colors', () {
        expect(classicProvider.getElementStyle(UIElement.boardBackground).backgroundColor,
            const Color(0xFFDEB887));
        expect(modernProvider.getElementStyle(UIElement.boardBackground).backgroundColor,
            const Color(0xFF424242));
            const Color(0xFFD2B48C));
        expect(einkProvider.getElementStyle(UIElement.boardBackground).backgroundColor,
            Colors.white);
      });

      test('should return black for grid lines and star points', () {
          expect(provider.getElementStyle(UIElement.boardGridLines).color, Colors.black);
          expect(provider.getElementStyle(UIElement.boardStarPoints).color, Colors.black);
        }
      });

      test('should return correct stone colors', () {
          expect(provider.getElementStyle(UIElement.stoneBlack).color, Colors.black);
          expect(provider.getElementStyle(UIElement.stoneWhite).color, Colors.white);
        }
      });

      test('should return transparent focus overlay for e-ink', () {
        expect(einkProvider.getElementStyle(UIElement.focusOverlay).color,
            Colors.transparent);

        // Non-e-ink should have semi-transparent grey
        expect(classicProvider.getElementStyle(UIElement.focusOverlay).color,
            Colors.grey.withOpacity(0.6));
      });
    });

    group('Button Elements', () {
      test('should return correct button background colors', () {
        // White button - same for all skins
          expect(provider.getElementStyle(UIElement.buttonResultWhite).backgroundColor,
              Colors.white);
        }

        // Black button - skin specific
        expect(classicProvider.getElementStyle(UIElement.buttonResultBlack).backgroundColor,
            Colors.black87);
        expect(modernProvider.getElementStyle(UIElement.buttonResultBlack).backgroundColor,
            const Color(0xFF1A1A1A));
            const Color(0xFF0D47A1));
        expect(einkProvider.getElementStyle(UIElement.buttonResultBlack).backgroundColor,
            Colors.black);

        // Draw button - skin specific
        expect(classicProvider.getElementStyle(UIElement.buttonResultDraw).backgroundColor,
            const Color(0xFFD4B896));
        expect(modernProvider.getElementStyle(UIElement.buttonResultDraw).backgroundColor,
            const Color(0xFF424242));
            const Color(0xFF42A5F5));
        expect(einkProvider.getElementStyle(UIElement.buttonResultDraw).backgroundColor,
            Colors.grey.shade400);
      });

      test('should return correct button text colors', () {
        // White button - black text for all
          expect(provider.getElementStyle(UIElement.buttonResultWhite).color, Colors.black);
        }

        // Black button - white text for all
          expect(provider.getElementStyle(UIElement.buttonResultBlack).color, Colors.white);
        }

        // Draw button - skin specific
        expect(classicProvider.getElementStyle(UIElement.buttonResultDraw).color,
            const Color(0xFF5D4037));
        expect(modernProvider.getElementStyle(UIElement.buttonResultDraw).color, Colors.white);
        expect(einkProvider.getElementStyle(UIElement.buttonResultDraw).color, Colors.black);
      });

      test('should return correct next button colors', () {
        // Next button color
        expect(classicProvider.getElementStyle(UIElement.buttonNext).backgroundColor,
            Colors.green);
        expect(modernProvider.getElementStyle(UIElement.buttonNext).backgroundColor,
            Colors.green);
            Colors.green);
        expect(einkProvider.getElementStyle(UIElement.buttonNext).backgroundColor,
            Colors.grey.shade400);

        // Next button text - black for all
          expect(provider.getElementStyle(UIElement.buttonNext).color, Colors.black);
        }
      });
    });

    group('Text Elements', () {
      test('should return correct general text colors', () {
        expect(classicProvider.getElementStyle(UIElement.textBody).color,
            const Color(0xFF3E2723));
        expect(modernProvider.getElementStyle(UIElement.textBody).color, Colors.white);
            const Color(0xFF0D47A1));
        expect(einkProvider.getElementStyle(UIElement.textBody).color, Colors.black);
      });

      test('should return correct font sizes for different layouts', () {
        final horizontalProvider = const UnifiedThemeProvider(
          skin: AppSkin.classic,
          layoutType: LayoutType.horizontal,
        );

        expect(classicProvider.getElementStyle(UIElement.textHeading).fontSize, 20);
        expect(horizontalProvider.getElementStyle(UIElement.textHeading).fontSize, 24);

        expect(classicProvider.getElementStyle(UIElement.textBody).fontSize, 16);
        expect(horizontalProvider.getElementStyle(UIElement.textBody).fontSize, 18);
      });

      test('should return bold font weight for headings and button labels', () {
        expect(classicProvider.getElementStyle(UIElement.textHeading).fontWeight,
            FontWeight.bold);
        expect(classicProvider.getElementStyle(UIElement.textButtonLabel).fontWeight,
            FontWeight.bold);
        expect(classicProvider.getElementStyle(UIElement.textGameInfo).fontWeight,
            FontWeight.bold);
      });
    });

    group('Interactive Elements', () {
      test('should return correct feedback colors', () {
        // Correct indicator
        expect(classicProvider.getElementStyle(UIElement.correctIndicator).color, Colors.green);
        expect(modernProvider.getElementStyle(UIElement.correctIndicator).color, const Color(0xFF81C784));
        expect(einkProvider.getElementStyle(UIElement.correctIndicator).color, Colors.black);

        // Incorrect indicator
        expect(classicProvider.getElementStyle(UIElement.incorrectIndicator).color, Colors.red);
        expect(modernProvider.getElementStyle(UIElement.incorrectIndicator).color, const Color(0xFFE57373));
        expect(einkProvider.getElementStyle(UIElement.incorrectIndicator).color, Colors.black);
      });
    });

    group('Animation Settings', () {
      test('should disable animations for e-ink skin', () {
        expect(einkProvider.getElementStyle(UIElement.correctIndicator).hasAnimation, false);
        expect(einkProvider.getElementStyle(UIElement.gameStatusBar).hasAnimation, false);
      });

      test('should enable animations for non-e-ink skins', () {
          expect(provider.getElementStyle(UIElement.correctIndicator).hasAnimation, true);
          expect(provider.getElementStyle(UIElement.gameStatusBar).hasAnimation, true);
        }
      });
    });

    group('Elevation Settings', () {
      test('should return zero elevation for e-ink skin', () {
        expect(einkProvider.getElementStyle(UIElement.buttonResultWhite).elevation, 0);
        expect(einkProvider.getElementStyle(UIElement.gameStatusBar).elevation, 0);
        expect(einkProvider.getElementStyle(UIElement.boardBackground).elevation, 0);
      });

      test('should return positive elevation for non-e-ink skins', () {
          expect(provider.getElementStyle(UIElement.buttonResultWhite).elevation,
              greaterThan(0));
          expect(provider.getElementStyle(UIElement.boardBackground).elevation,
              greaterThan(0));
        }
      });
    });

    group('Convenience Methods', () {
      test('should create correct TextStyle', () {
        final textStyle = classicProvider.getTextStyle(UIElement.textHeading);

        expect(textStyle.color, const Color(0xFF3E2723));
        expect(textStyle.fontSize, 20);
        expect(textStyle.fontWeight, FontWeight.bold);
      });

      test('should create correct BoxDecoration', () {
        final decoration = classicProvider.getContainerDecoration(UIElement.gameStatusBar);

        expect(decoration.color, isNotNull);
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNotNull);
      });

      test('should create correct ButtonStyle', () {
        final buttonStyle = classicProvider.getButtonStyle(UIElement.buttonResultWhite);

        expect(buttonStyle.backgroundColor?.resolve({}), Colors.white);
        expect(buttonStyle.foregroundColor?.resolve({}), Colors.black);
      });
    });

    group('Border Colors', () {
      test('should return correct border colors for each skin', () {
        expect(classicProvider.getElementStyle(UIElement.buttonResultWhite).borderColor,
            const Color(0xFF8B4513));
        expect(modernProvider.getElementStyle(UIElement.buttonResultWhite).borderColor,
            const Color(0xFF424242));
            const Color(0xFF1565C0));
        expect(einkProvider.getElementStyle(UIElement.buttonResultWhite).borderColor,
            Colors.black);
      });
    });

    group('Progress Bar Colors', () {
      test('should return correct progress bar colors', () {
        expect(classicProvider.getElementStyle(UIElement.timerBarProgress).backgroundColor,
            Colors.green);
        expect(modernProvider.getElementStyle(UIElement.timerBarProgress).backgroundColor,
            Colors.indigo);
            Colors.blue);
        expect(einkProvider.getElementStyle(UIElement.timerBarProgress).backgroundColor,
            Colors.black);
      });

      test('should return correct progress bar background colors', () {
        expect(classicProvider.getElementStyle(UIElement.timerBarContainer).backgroundColor,
            Colors.grey[300]!);
        expect(modernProvider.getElementStyle(UIElement.timerBarContainer).backgroundColor,
            const Color(0xFF2D2D2D));
            const Color(0xFFBBDEFB));
        expect(einkProvider.getElementStyle(UIElement.timerBarContainer).backgroundColor,
            Colors.grey.shade200);
      });
    });
  });
}