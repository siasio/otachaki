import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/training_position.dart';
import 'package:countingapp/widgets/score_display_buttons.dart';
import 'package:countingapp/models/app_skin.dart';
import 'package:countingapp/models/layout_type.dart';

void main() {
  group('Territory Display Tests', () {
    test('TrainingPosition should parse territory data correctly', () {
      final mockJson = {
        'id': 'test_position',
        'board_size': 19,
        'stones': 'AAAA',  // Empty base64 data for testing
        'score': 5.5,
        'result': 'B+5.5',
        'moves': 'AAAA',
        'number_of_moves': 0,
        'ownership': 'AAAA',
        'blackTerritory': 85,
        'whiteTerritory': 80,
        'ultimate-stones': 'AAAA',
        'game_info': {
          'black_captured': 0,
          'white_captured': 0,
          'komi': 7.5,
        }
      };

      final position = TrainingPosition.fromJson(mockJson);

      expect(position.blackTerritory, equals(85));
      expect(position.whiteTerritory, equals(80));
      expect(position.hasTerritoryData, isTrue);
      expect(position.hasUltimateStones, isTrue);
      expect(position.gameInfo?.komi, equals(7.5));
    });

    test('ScoreDisplayButtons should format territory text correctly', () {
      final scoreDisplay = ScoreDisplayButtons(
        resultString: 'B+5.5',
        onNextPressed: () {},
        appSkin: AppSkin.classic,
        layoutType: LayoutType.vertical,
        useColoredBackground: true,
        blackTerritory: 85,
        whiteTerritory: 80,
        komi: 7.5,
      );

      final scoreInfo = scoreDisplay.parseScoreInfo('B+5.5');

      expect(scoreInfo.blackScore, equals("Black's territory: 85 points"));
      expect(scoreInfo.whiteScore, equals("White's territory: 80 + 7.5 = 87.5 points"));
    });

    test('ScoreDisplayButtons should handle integer komi correctly', () {
      final scoreDisplay = ScoreDisplayButtons(
        resultString: 'W+5',
        onNextPressed: () {},
        appSkin: AppSkin.classic,
        layoutType: LayoutType.vertical,
        useColoredBackground: true,
        blackTerritory: 70,
        whiteTerritory: 75,
        komi: 6.0,
      );

      final scoreInfo = scoreDisplay.parseScoreInfo('W+5');

      expect(scoreInfo.blackScore, equals("Black's territory: 70 points"));
      expect(scoreInfo.whiteScore, equals("White's territory: 75 + 6 = 81 points"));
    });

    test('ScoreDisplayButtons should fall back to old format without territory data', () {
      final scoreDisplay = ScoreDisplayButtons(
        resultString: 'B+7.5',
        onNextPressed: () {},
        appSkin: AppSkin.classic,
        layoutType: LayoutType.vertical,
        useColoredBackground: true,
        // No territory data provided
      );

      final scoreInfo = scoreDisplay.parseScoreInfo('B+7.5');

      expect(scoreInfo.blackScore, equals('B+7.5'));
      expect(scoreInfo.whiteScore, equals('W loses'));
    });
  });
}