import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:countingapp/models/custom_dataset.dart';
import 'package:countingapp/models/dataset_type.dart';
import 'package:countingapp/services/custom_dataset_manager.dart';

void main() {
  group('CustomDatasetManager', () {
    late CustomDatasetManager manager;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      manager = await CustomDatasetManager.getInstance();
      // Clear any existing data
      await manager.clearAllCustomDatasets();
    });

    tearDown(() async {
      await manager.clearAllCustomDatasets();
    });

    test('should initialize with default datasets', () {
      final allDatasets = manager.getAllDatasets();

      expect(allDatasets.length, 5); // All DatasetType values as defaults

      final final9x9 = allDatasets.firstWhere(
        (d) => d.baseDatasetType == DatasetType.final9x9
      );
      expect(final9x9.name, 'GoQuest Arena (9x9)');
      expect(final9x9.id, 'default_final-9x9');
    });

    test('should create custom dataset successfully', () async {
      final dataset = await manager.createCustomDataset(
        name: 'My Custom 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(dataset.name, 'My Custom 9x9');
      expect(dataset.baseDatasetType, DatasetType.final9x9);
      expect(dataset.id.length, 36); // UUID v4 length

      final allDatasets = manager.getAllDatasets();
      expect(allDatasets.length, 6); // 5 defaults + 1 custom

      final customDataset = allDatasets.firstWhere((d) => d.id == dataset.id);
      expect(customDataset.name, 'My Custom 9x9');
    });

    test('should throw error for empty dataset name', () async {
      expect(
        () async => await manager.createCustomDataset(
          name: '',
          baseDatasetType: DatasetType.final9x9,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () async => await manager.createCustomDataset(
          name: '   ', // Only whitespace
          baseDatasetType: DatasetType.final9x9,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error for duplicate dataset names', () async {
      await manager.createCustomDataset(
        name: 'Duplicate Name',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(
        () async => await manager.createCustomDataset(
          name: 'Duplicate Name',
          baseDatasetType: DatasetType.final19x19,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Case-insensitive check
      expect(
        () async => await manager.createCustomDataset(
          name: 'duplicate name',
          baseDatasetType: DatasetType.final19x19,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should update custom dataset successfully', () async {
      final originalDataset = await manager.createCustomDataset(
        name: 'Original Name',
        baseDatasetType: DatasetType.final9x9,
      );

      final updatedDataset = await manager.updateCustomDataset(
        id: originalDataset.id,
        name: 'Updated Name',
      );

      expect(updatedDataset.name, 'Updated Name');
      expect(updatedDataset.id, originalDataset.id);
      expect(updatedDataset.baseDatasetType, originalDataset.baseDatasetType);

      final retrievedDataset = manager.getDatasetById(originalDataset.id);
      expect(retrievedDataset?.name, 'Updated Name');
    });

    test('should throw error when updating non-existent dataset', () async {
      expect(
        () async => await manager.updateCustomDataset(
          id: 'non-existent-id',
          name: 'New Name',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should delete custom dataset successfully', () async {
      final dataset = await manager.createCustomDataset(
        name: 'To Be Deleted',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(manager.getCustomDatasets().length, 1);

      final deleted = await manager.deleteCustomDataset(dataset.id);
      expect(deleted, isTrue);
      expect(manager.getCustomDatasets().length, 0);
      expect(manager.getDatasetById(dataset.id), isNull);
    });

    test('should return false when deleting non-existent dataset', () async {
      final deleted = await manager.deleteCustomDataset('non-existent-id');
      expect(deleted, isFalse);
    });

    test('should group datasets by base type correctly', () async {
      await manager.createCustomDataset(
        name: 'Custom 9x9 #1',
        baseDatasetType: DatasetType.final9x9,
      );
      await manager.createCustomDataset(
        name: 'Custom 9x9 #2',
        baseDatasetType: DatasetType.final9x9,
      );
      await manager.createCustomDataset(
        name: 'Custom 19x19',
        baseDatasetType: DatasetType.final19x19,
      );

      final groupedDatasets = manager.getDatasetsByBaseType();

      expect(groupedDatasets.keys.length, 5); // All DatasetType values
      expect(groupedDatasets[DatasetType.final9x9]?.length, 3); // 1 built-in + 2 custom
      expect(groupedDatasets[DatasetType.final19x19]?.length, 2); // 1 built-in + 1 custom
      expect(groupedDatasets[DatasetType.midgame19x19]?.length, 1); // 1 built-in only

      // Check that built-in datasets come first
      final final9x9Datasets = groupedDatasets[DatasetType.final9x9]!;
      expect(final9x9Datasets.first.isBuiltIn, isTrue);
      expect(final9x9Datasets[1].isBuiltIn, isFalse);
      expect(final9x9Datasets[2].isBuiltIn, isFalse);
    });

    test('should manage dataset selection correctly', () async {
      expect(manager.getSelectedDataset(), isNull);
      expect(manager.getSelectedDatasetId(), isNull);

      final dataset = await manager.createCustomDataset(
        name: 'Selected Dataset',
        baseDatasetType: DatasetType.final9x9,
      );

      await manager.setSelectedDataset(dataset.id);

      expect(manager.getSelectedDatasetId(), dataset.id);
      expect(manager.getSelectedDataset()?.id, dataset.id);
    });

    test('should throw error when selecting non-existent dataset', () async {
      expect(
        () async => await manager.setSelectedDataset('non-existent-id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should clear selection when deleting selected dataset', () async {
      final dataset = await manager.createCustomDataset(
        name: 'Selected Dataset',
        baseDatasetType: DatasetType.final9x9,
      );

      await manager.setSelectedDataset(dataset.id);
      expect(manager.getSelectedDatasetId(), dataset.id);

      await manager.deleteCustomDataset(dataset.id);
      expect(manager.getSelectedDatasetId(), isNull);
    });

    test('should validate name availability correctly', () async {
      await manager.createCustomDataset(
        name: 'Existing Name',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(manager.isNameAvailable('New Name'), isTrue);
      expect(manager.isNameAvailable('Existing Name'), isFalse);
      expect(manager.isNameAvailable('existing name'), isFalse); // Case-insensitive

      // Should allow same name when excluding the dataset that has it
      final dataset = manager.getCustomDatasets().first;
      expect(manager.isNameAvailable('Existing Name', excludeId: dataset.id), isTrue);
    });

    test('should get built-in dataset for specific type', () {
      final dataset = manager.getDefaultDataset(DatasetType.final19x19);

      expect(dataset, isNotNull);
      expect(dataset!.baseDatasetType, DatasetType.final19x19);
      expect(dataset.isBuiltIn, isTrue);
      expect(dataset.id, 'builtin_final-19x19');
    });

    test('should persist and restore custom datasets', () async {
      // Create some custom datasets
      final dataset1 = await manager.createCustomDataset(
        name: 'Dataset 1',
        baseDatasetType: DatasetType.final9x9,
      );

      final dataset2 = await manager.createCustomDataset(
        name: 'Dataset 2',
        baseDatasetType: DatasetType.final19x19,
      );

      await manager.setSelectedDataset(dataset2.id);

      // Create a new instance (simulating app restart)
      final newManager = await CustomDatasetManager.getInstance();

      expect(newManager.getCustomDatasets().length, 2);
      expect(newManager.getSelectedDatasetId(), dataset2.id);

      final retrievedDataset1 = newManager.getDatasetById(dataset1.id);
      expect(retrievedDataset1?.name, 'Dataset 1');
      expect(retrievedDataset1?.baseDatasetType, DatasetType.final9x9);
    });

    test('should handle clear all custom datasets', () async {
      await manager.createCustomDataset(
        name: 'Dataset 1',
        baseDatasetType: DatasetType.final9x9,
      );

      await manager.createCustomDataset(
        name: 'Dataset 2',
        baseDatasetType: DatasetType.final19x19,
      );

      expect(manager.getCustomDatasets().length, 2);
      expect(manager.getAllDatasets().length, 7); // 5 built-in + 2 custom

      await manager.clearAllCustomDatasets();

      expect(manager.getCustomDatasets().length, 0);
      expect(manager.getAllDatasets().length, 5); // Only built-in remain
      expect(manager.getSelectedDatasetId(), isNull);
    });
  });
}