import 'package:flutter_test/flutter_test.dart';
import 'package:countingapp/models/custom_dataset.dart';
import 'package:countingapp/models/dataset_type.dart';
import 'package:countingapp/models/dataset_configuration.dart';

void main() {
  group('CustomDataset', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    test('should create custom dataset from base type', () {
      final dataset = CustomDataset.fromBaseType(
        id: 'test-123',
        name: 'My Custom 9x9',
        baseDatasetType: DatasetType.final9x9,
        createdAt: testDate,
      );

      expect(dataset.id, 'test-123');
      expect(dataset.name, 'My Custom 9x9');
      expect(dataset.baseDatasetType, DatasetType.final9x9);
      expect(dataset.createdAt, testDate);
      expect(dataset.isBuiltIn, isFalse);
      expect(dataset.configuration.timePerProblemSeconds, 15); // Default for 9x9
    });

    test('should create built-in dataset representation', () {
      final dataset = CustomDataset.builtIn(
        datasetType: DatasetType.final19x19,
        name: '19x19 Final Positions',
      );

      expect(dataset.id, 'builtin_final-19x19-area');
      expect(dataset.name, '19x19 Final Positions');
      expect(dataset.baseDatasetType, DatasetType.final19x19);
      expect(dataset.isBuiltIn, isTrue);
      expect(dataset.configuration.timePerProblemSeconds, 60); // Default for 19x19
    });

    test('copyWith should preserve unchanged values', () {
      final original = CustomDataset.fromBaseType(
        id: 'test-123',
        name: 'Original Name',
        baseDatasetType: DatasetType.final9x9,
        createdAt: testDate,
      );

      final modified = original.copyWith(
        name: 'Modified Name',
        isBuiltIn: true,
      );

      expect(modified.id, 'test-123');
      expect(modified.name, 'Modified Name');
      expect(modified.baseDatasetType, DatasetType.final9x9);
      expect(modified.createdAt, testDate);
      expect(modified.isBuiltIn, isTrue);
    });

    test('should serialize to JSON correctly', () {
      final dataset = CustomDataset(
        id: 'test-456',
        name: 'Test Dataset',
        baseDatasetType: DatasetType.midgame19x19,
        configuration: const DatasetConfiguration(
          thresholdGood: 2.0,
          thresholdClose: 4.0,
          timePerProblemSeconds: 30,
          hideGameInfoBar: true,
        ),
        createdAt: testDate,
        isBuiltIn: false,
      );

      final json = dataset.toJson();

      expect(json['id'], 'test-456');
      expect(json['name'], 'Test Dataset');
      expect(json['baseDatasetType'], 'midgame-19x19-estimation');
      expect(json['createdAt'], testDate.millisecondsSinceEpoch);
      expect(json['isBuiltIn'], isFalse);
      expect(json['configuration'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-789',
        'name': 'Deserialized Dataset',
        'baseDatasetType': 'final-9x9-area',
        'configuration': {
          'thresholdGood': 1.0,
          'thresholdClose': 2.0,
          'timePerProblemSeconds': 20,
          'hideGameInfoBar': false,
        },
        'createdAt': testDate.millisecondsSinceEpoch,
        'isBuiltIn': true,
      };

      final dataset = CustomDataset.fromJson(json);

      expect(dataset.id, 'test-789');
      expect(dataset.name, 'Deserialized Dataset');
      expect(dataset.baseDatasetType, DatasetType.final9x9);
      expect(dataset.createdAt, testDate);
      expect(dataset.isBuiltIn, isTrue);
      expect(dataset.configuration.thresholdGood, 1.0);
      expect(dataset.configuration.timePerProblemSeconds, 20);
    });

    test('displayName should include base type info for custom datasets', () {
      final customDataset = CustomDataset.fromBaseType(
        id: 'custom-1',
        name: 'My Custom Set',
        baseDatasetType: DatasetType.final9x9,
      );

      final builtInDataset = CustomDataset.builtIn(
        datasetType: DatasetType.final19x19,
        name: '19x19 Finals',
      );

      expect(customDataset.displayName, 'My Custom Set (9x9 Final)');
      expect(builtInDataset.displayName, '19x19 Finals');
    });

    test('datasetFilePath should return correct asset path', () {
      final dataset9x9 = CustomDataset.fromBaseType(
        id: 'test',
        name: 'Test',
        baseDatasetType: DatasetType.final9x9,
      );

      final dataset19x19 = CustomDataset.fromBaseType(
        id: 'test',
        name: 'Test',
        baseDatasetType: DatasetType.final19x19,
      );

      final datasetMidgame = CustomDataset.fromBaseType(
        id: 'test',
        name: 'Test',
        baseDatasetType: DatasetType.midgame19x19,
      );

      expect(dataset9x9.datasetFilePath, 'assets/final_9x9_katago.json');
      expect(dataset19x19.datasetFilePath, 'assets/final_19x19_katago.json');
      expect(datasetMidgame.datasetFilePath, 'assets/mid_fox_19x19.json');
    });

    test('equality should be based on ID', () {
      final dataset1 = CustomDataset.fromBaseType(
        id: 'same-id',
        name: 'Dataset 1',
        baseDatasetType: DatasetType.final9x9,
      );

      final dataset2 = CustomDataset.fromBaseType(
        id: 'same-id',
        name: 'Dataset 2', // Different name
        baseDatasetType: DatasetType.final19x19, // Different type
      );

      final dataset3 = CustomDataset.fromBaseType(
        id: 'different-id',
        name: 'Dataset 1',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(dataset1, equals(dataset2)); // Same ID
      expect(dataset1, isNot(equals(dataset3))); // Different ID
      expect(dataset1.hashCode, dataset2.hashCode);
    });

    test('toString should include key information', () {
      final dataset = CustomDataset.fromBaseType(
        id: 'test-123',
        name: 'Test Dataset',
        baseDatasetType: DatasetType.final9x9,
      );

      final toString = dataset.toString();

      expect(toString, contains('test-123'));
      expect(toString, contains('Test Dataset'));
      expect(toString, contains('final-9x9-area'));
    });
  });
}