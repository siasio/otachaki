import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otachaki/models/custom_dataset.dart';
import 'package:otachaki/models/dataset_type.dart';
import 'package:otachaki/services/custom_dataset_manager.dart';

void main() {
  group('CustomDatasetManager', () {
    late CustomDatasetManager manager;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});

      // Reset the singleton to ensure clean state
      CustomDatasetManager.resetInstance();

      manager = await CustomDatasetManager.getInstance();
      // Clear any existing data and reinitialize with defaults
      await manager.clearAllCustomDatasets();
      CustomDatasetManager.resetInstance();
      manager = await CustomDatasetManager.getInstance();
    });

    tearDown(() async {
      await manager.clearAllCustomDatasets();
    });

    test('should initialize with default datasets', () async {
      // Clear and reinitialize to trigger default dataset creation
      await manager.clearAllCustomDatasets();
      CustomDatasetManager.resetInstance();
      manager = await CustomDatasetManager.getInstance();

      final allDatasets = manager.getAllDatasets();

      expect(allDatasets.length, 4); // 4 visible dataset types as defaults

      final final9x9 = allDatasets.firstWhere(
        (d) => d.baseDatasetType == DatasetType.final9x9
      );
      expect(final9x9.name, 'Pocket Quest (9x9)');
      expect(final9x9.id, 'builtin_final-9x9');
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
      expect(allDatasets.length, 5); // 4 defaults + 1 custom

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

      expect(manager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).length, 1);

      final deleted = await manager.deleteCustomDataset(dataset.id);
      expect(deleted, isTrue);
      expect(manager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).length, 0);
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

      expect(groupedDatasets.keys.length, 4); // All visible DatasetType values (4 total)
      expect(groupedDatasets[DatasetType.final9x9]?.length, 3); // 1 built-in + 2 custom
      expect(groupedDatasets[DatasetType.final19x19]?.length, 2); // 1 built-in + 1 custom
      expect(groupedDatasets[DatasetType.midgame19x19]?.length, 1); // 1 built-in only

      // Check that built-in datasets come first
      final final9x9Datasets = groupedDatasets[DatasetType.final9x9]!;
      expect(final9x9Datasets.first.id.startsWith('builtin_'), isTrue);
      expect(final9x9Datasets[1].id.startsWith('builtin_'), isFalse);
      expect(final9x9Datasets[2].id.startsWith('builtin_'), isFalse);
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
      // Create two datasets so we don't try to delete the last one
      final dataset1 = await manager.createCustomDataset(
        name: 'Selected Dataset',
        baseDatasetType: DatasetType.final9x9,
      );
      final dataset2 = await manager.createCustomDataset(
        name: 'Other Dataset',
        baseDatasetType: DatasetType.final19x19,
      );

      await manager.setSelectedDataset(dataset1.id);
      expect(manager.getSelectedDatasetId(), dataset1.id);

      await manager.deleteCustomDataset(dataset1.id);
      // Should auto-select first remaining dataset (could be dataset2 or a builtin)
      expect(manager.getSelectedDatasetId(), isNotNull);
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
      final dataset = manager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).first;
      expect(manager.isNameAvailable('Existing Name', excludeId: dataset.id), isTrue);
    });

    test('should get built-in dataset for specific type', () async {
      // Ensure built-in datasets exist
      await manager.clearAllCustomDatasets();
      CustomDatasetManager.resetInstance();
      manager = await CustomDatasetManager.getInstance();

      final dataset = manager.getDefaultDataset(DatasetType.final19x19);

      expect(dataset, isNotNull);
      expect(dataset!.baseDatasetType, DatasetType.final19x19);
      expect(dataset.id.startsWith('builtin_'), isTrue);
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

      expect(newManager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).length, 2);
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

      expect(manager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).length, 2);
      expect(manager.getAllDatasets().length, 6); // 4 built-in + 2 custom

      await manager.clearAllCustomDatasets();

      expect(manager.getAllDatasets().where((d) => !d.id.startsWith('builtin_')).length, 0);
      expect(manager.getAllDatasets().length, 0); // All datasets cleared (including built-in)
      expect(manager.getSelectedDatasetId(), isNull);
    });
  });
}