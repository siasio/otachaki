import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/board_view_mode.dart';
import 'package:countingapp/models/sequence_display_mode.dart';

void main() {
  group('BoardViewMode', () {
    test('displayName returns correct names', () {
      expect(BoardViewMode.problem.displayName, 'Problem View');
      expect(BoardViewMode.review.displayName, 'Review View');
    });

    test('hideSequenceStones returns correct values', () {
      expect(BoardViewMode.problem.hideSequenceStones, true);
      expect(BoardViewMode.review.hideSequenceStones, false);
    });

    test('defaultSequenceDisplayMode returns correct modes', () {
      expect(BoardViewMode.problem.defaultSequenceDisplayMode,
             SequenceDisplayMode.numbersOnly);
      expect(BoardViewMode.review.defaultSequenceDisplayMode,
             SequenceDisplayMode.stonesWithNumbers);
    });

    test('canShowOwnership returns correct values', () {
      expect(BoardViewMode.problem.canShowOwnership, false);
      expect(BoardViewMode.review.canShowOwnership, true);
    });
  });
}