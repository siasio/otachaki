import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/ownership_display_mode.dart';

void main() {
  group('OwnershipDisplayMode', () {
    test('displayName returns correct names', () {
      expect(OwnershipDisplayMode.none.displayName, 'None');
      expect(OwnershipDisplayMode.squares.displayName, 'Squares');
      expect(OwnershipDisplayMode.overlay.displayName, 'Overlay');
    });

    test('showOwnership returns correct values', () {
      expect(OwnershipDisplayMode.none.showOwnership, false);
      expect(OwnershipDisplayMode.squares.showOwnership, true);
      expect(OwnershipDisplayMode.overlay.showOwnership, true);
    });

    test('useOverlay returns correct values', () {
      expect(OwnershipDisplayMode.none.useOverlay, false);
      expect(OwnershipDisplayMode.squares.useOverlay, false);
      expect(OwnershipDisplayMode.overlay.useOverlay, true);
    });

    test('useSquares returns correct values', () {
      expect(OwnershipDisplayMode.none.useSquares, false);
      expect(OwnershipDisplayMode.squares.useSquares, true);
      expect(OwnershipDisplayMode.overlay.useSquares, false);
    });
  });
}