import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/dataset_configuration.dart';
import 'package:otachaki/models/dataset_type.dart';
import 'package:otachaki/models/problem_feedback_type.dart';

void main() {
  group('DatasetConfiguration', () {
    test('should have correct defaults for final9x9', () {
      final config = DatasetConfiguration.getDefaultFor(DatasetType.final9x9);

      expect(config.thresholdGood, 0.0);
      expect(config.thresholdClose, 0.0);
      expect(config.timePerProblemSeconds, 20);
      expect(config.predictionType.value, 'winner_prediction');
      expect(config.positionType.value, 'with-filled-neutral-points');
      expect(config.ownershipDisplayMode.name, 'squares');
      expect(config.autoAdvanceMode.value, 'on_correct_only');
      expect(config.problemFeedbackType, ProblemFeedbackType.result);
    });

    test('should have correct defaults for midgame19x19', () {
      final config = DatasetConfiguration.getDefaultFor(DatasetType.midgame19x19);

      expect(config.thresholdGood, 3.0);
      expect(config.thresholdClose, 7.0);
      expect(config.timePerProblemSeconds, 30);
      expect(config.predictionType.value, 'rough_lead_prediction');
      expect(config.sequenceLength, 5);
      expect(config.ownershipDisplayMode.name, 'squares');
      expect(config.gameStage.value, 'all');
      expect(config.autoAdvanceMode.value, 'always');
      expect(config.problemFeedbackType, ProblemFeedbackType.result);
    });


    test('copyWith should preserve unchanged values', () {
      const original = DatasetConfiguration(
        thresholdGood: 1.0,
        thresholdClose: 2.0,
        timePerProblemSeconds: 30,
        timerEnabled: false,
      );

      final modified = original.copyWith(
        thresholdGood: 1.5,
        timerEnabled: true,
      );

      expect(modified.thresholdGood, 1.5);
      expect(modified.thresholdClose, 2.0);
      expect(modified.timePerProblemSeconds, 30);
      expect(modified.timerEnabled, isTrue);
    });

    test('should serialize to JSON correctly', () {
      const config = DatasetConfiguration(
        thresholdGood: 1.5,
        thresholdClose: 3.0,
        timePerProblemSeconds: 20,
        timerEnabled: true,
      );

      final json = config.toJson();

      expect(json['thresholdGood'], 1.5);
      expect(json['thresholdClose'], 3.0);
      expect(json['timePerProblemSeconds'], 20);
      expect(json['timerEnabled'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'thresholdGood': 2.0,
        'thresholdClose': 4.0,
        'timePerProblemSeconds': 25,
        'timerEnabled': true,
      };

      final config = DatasetConfiguration.fromJson(json);

      expect(config.thresholdGood, 2.0);
      expect(config.thresholdClose, 4.0);
      expect(config.timePerProblemSeconds, 25);
      expect(config.timerEnabled, isTrue);
    });

    test('should use defaults for missing JSON fields', () {
      final json = <String, dynamic>{};

      final config = DatasetConfiguration.fromJson(json);

      expect(config.thresholdGood, 0.0);
      expect(config.thresholdClose, 0.0);
      expect(config.timePerProblemSeconds, 30);
      expect(config.timerEnabled, isTrue);
    });

    test('isValidConfiguration should validate thresholds and time', () {
      const validConfig = DatasetConfiguration(
        thresholdGood: 1.0,
        thresholdClose: 2.0,
        timePerProblemSeconds: 30,
        timerEnabled: false,
      );

      const invalidThresholdConfig = DatasetConfiguration(
        thresholdGood: 3.0,
        thresholdClose: 2.0, // Close < Good is invalid
        timePerProblemSeconds: 30,
        timerEnabled: false,
      );

      const invalidTimeConfig = DatasetConfiguration(
        thresholdGood: 1.0,
        thresholdClose: 2.0,
        timePerProblemSeconds: 0, // Time <= 0 is invalid
        timerEnabled: false,
      );

      expect(validConfig.isValidConfiguration(), isTrue);
      expect(invalidThresholdConfig.isValidConfiguration(), isFalse);
      expect(invalidTimeConfig.isValidConfiguration(), isFalse);
    });

    test('should have correct problem feedback defaults for all dataset types', () {
      // 9x9 and midgame should default to Result
      expect(DatasetConfiguration.getDefaultFor(DatasetType.final9x9).problemFeedbackType,
             ProblemFeedbackType.result);
      expect(DatasetConfiguration.getDefaultFor(DatasetType.midgame19x19).problemFeedbackType,
             ProblemFeedbackType.result);
      expect(DatasetConfiguration.getDefaultFor(DatasetType.partialPositions).problemFeedbackType,
             ProblemFeedbackType.result);

      // 13x13 should default to Result + Time
      expect(DatasetConfiguration.getDefaultFor(DatasetType.final13x13).problemFeedbackType,
             ProblemFeedbackType.resultWithTime);

      // 19x19 should default to Result + Speed
      expect(DatasetConfiguration.getDefaultFor(DatasetType.final19x19).problemFeedbackType,
             ProblemFeedbackType.resultWithSpeed);
    });

    test('copyWith should update problemFeedbackType correctly', () {
      const original = DatasetConfiguration(
        thresholdGood: 1.0,
        thresholdClose: 2.0,
        timePerProblemSeconds: 30,
        problemFeedbackType: ProblemFeedbackType.result,
      );

      final modified = original.copyWith(
        problemFeedbackType: ProblemFeedbackType.resultWithTime,
      );

      expect(modified.problemFeedbackType, ProblemFeedbackType.resultWithTime);
      expect(modified.thresholdGood, 1.0); // Should preserve other values
    });

    test('should serialize problemFeedbackType to JSON correctly', () {
      const config = DatasetConfiguration(
        thresholdGood: 1.5,
        thresholdClose: 3.0,
        timePerProblemSeconds: 20,
        problemFeedbackType: ProblemFeedbackType.resultWithSpeed,
      );

      final json = config.toJson();
      expect(json['problemFeedbackType'], 'result_with_speed');
    });

    test('should deserialize problemFeedbackType from JSON correctly', () {
      final json = {
        'thresholdGood': 2.0,
        'thresholdClose': 4.0,
        'timePerProblemSeconds': 25,
        'problemFeedbackType': 'result_with_time',
      };

      final config = DatasetConfiguration.fromJson(json);
      expect(config.problemFeedbackType, ProblemFeedbackType.resultWithTime);
    });

    test('should use default problemFeedbackType for missing JSON field', () {
      final json = {
        'thresholdGood': 2.0,
        'thresholdClose': 4.0,
        'timePerProblemSeconds': 25,
        // Missing problemFeedbackType
      };

      final config = DatasetConfiguration.fromJson(json);
      expect(config.problemFeedbackType, ProblemFeedbackType.result);
    });

    test('should use default problemFeedbackType for invalid JSON value', () {
      final json = {
        'thresholdGood': 2.0,
        'thresholdClose': 4.0,
        'timePerProblemSeconds': 25,
        'problemFeedbackType': 'invalid_value',
      };

      final config = DatasetConfiguration.fromJson(json);
      expect(config.problemFeedbackType, ProblemFeedbackType.result);
    });
  });
}