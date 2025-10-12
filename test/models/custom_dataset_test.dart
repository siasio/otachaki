import 'package:flutter_test/flutter_test.dart';
import 'package:otachaki/models/custom_dataset.dart';
import 'package:otachaki/models/dataset_type.dart';
import 'package:otachaki/models/dataset_configuration.dart';

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
      expect(dataset.configuration.timePerProblemSeconds, 20); // Default for 9x9
    });

    test('should create default dataset', () {
      final dataset = CustomDataset.defaultFor(
        datasetType: DatasetType.final19x19,
        name: '19x19 Final Positions',
      );

      expect(dataset.id, 'default_final-19x19');
      expect(dataset.name, '19x19 Final Positions');
      expect(dataset.baseDatasetType, DatasetType.final19x19);
      expect(dataset.configuration.timePerProblemSeconds, 90); // Default for 19x19
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
      );

      expect(modified.id, 'test-123');
      expect(modified.name, 'Modified Name');
      expect(modified.baseDatasetType, DatasetType.final9x9);
      expect(modified.createdAt, testDate);
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
        ),
        createdAt: testDate,
      );

      final json = dataset.toJson();

      expect(json['id'], 'test-456');
      expect(json['name'], 'Test Dataset');
      expect(json['baseDatasetType'], 'midgame-19x19');
      expect(json['createdAt'], testDate.millisecondsSinceEpoch);
      expect(json['configuration'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-789',
        'name': 'Deserialized Dataset',
        'baseDatasetType': 'final-9x9',
        'configuration': {
          'thresholdGood': 1.0,
          'thresholdClose': 2.0,
          'timePerProblemSeconds': 20,
        },
        'createdAt': testDate.millisecondsSinceEpoch,
      };

      final dataset = CustomDataset.fromJson(json);

      expect(dataset.id, 'test-789');
      expect(dataset.name, 'Deserialized Dataset');
      expect(dataset.baseDatasetType, DatasetType.final9x9);
      expect(dataset.createdAt, testDate);
      expect(dataset.configuration.thresholdGood, 1.0);
      expect(dataset.configuration.timePerProblemSeconds, 20);
    });

    test('displayName should return dataset name', () {
      final customDataset = CustomDataset.fromBaseType(
        id: 'custom-1',
        name: 'My Custom Set',
        baseDatasetType: DatasetType.final9x9,
      );

      final defaultDataset = CustomDataset.defaultFor(
        datasetType: DatasetType.final19x19,
        name: '19x19 Finals',
      );

      expect(customDataset.displayName, 'My Custom Set');
      expect(defaultDataset.displayName, '19x19 Finals');
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
      expect(toString, contains('final-9x9'));
    });
  });
}