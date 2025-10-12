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

      // Reset the singleton
      CustomDatasetManager.resetInstance();

      // Initialize fresh manager
      manager = await CustomDatasetManager.getInstance();
    });

    tearDown(() async {
      await manager.clearAllCustomDatasets();
      CustomDatasetManager.resetInstance();
    });

    test('should initialize with default datasets for all types', () {
      final allDatasets = manager.getAllDatasets();

      // Should have exactly 4 default datasets (one for each visible DatasetType)
      expect(allDatasets.length, 4);

      // Check that we have one dataset for each visible type (4 types)
      final visibleTypes = [DatasetType.final9x9, DatasetType.final13x13, DatasetType.final19x19, DatasetType.midgame19x19];
      for (final type in visibleTypes) {
        final datasetsOfType = allDatasets.where((d) => d.baseDatasetType == type);
        expect(datasetsOfType.length, 1, reason: 'Should have exactly one default dataset for $type');

        final dataset = datasetsOfType.first;
        expect(dataset.id, 'builtin_${type.value}');
        expect(dataset.name, isNotEmpty);
      }
    });

    test('should create additional datasets successfully', () async {
      final initialCount = manager.getAllDatasets().length;

      final dataset = await manager.createCustomDataset(
        name: 'My Custom 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(dataset.name, 'My Custom 9x9');
      expect(dataset.baseDatasetType, DatasetType.final9x9);
      expect(dataset.id.length, 36); // UUID v4 length
      expect(dataset.id, isNot(startsWith('default_')));

      final allDatasets = manager.getAllDatasets();
      expect(allDatasets.length, initialCount + 1);

      final createdDataset = allDatasets.firstWhere((d) => d.id == dataset.id);
      expect(createdDataset.name, 'My Custom 9x9');
    });

    test('should update any dataset (including defaults)', () async {
      // Get a default dataset
      final defaultDataset = manager.getDefaultDataset(DatasetType.final9x9);
      expect(defaultDataset, isNotNull);

      // Update the default dataset
      final updatedDataset = await manager.updateCustomDataset(
        id: defaultDataset!.id,
        name: 'Updated Default Name',
      );

      expect(updatedDataset.name, 'Updated Default Name');
      expect(updatedDataset.id, defaultDataset.id);
      expect(updatedDataset.baseDatasetType, DatasetType.final9x9);

      // Verify it's updated in the list
      final allDatasets = manager.getAllDatasets();
      final found = allDatasets.firstWhere((d) => d.id == defaultDataset.id);
      expect(found.name, 'Updated Default Name');
    });

    test('should delete any dataset except the last one', () async {
      final initialCount = manager.getAllDatasets().length;

      // Create an additional dataset
      final customDataset = await manager.createCustomDataset(
        name: 'To Be Deleted',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(manager.getAllDatasets().length, initialCount + 1);

      // Delete the custom dataset
      final deleted = await manager.deleteCustomDataset(customDataset.id);
      expect(deleted, isTrue);
      expect(manager.getAllDatasets().length, initialCount);

      // Try to delete all but one dataset
      final datasets = manager.getAllDatasets();
      for (int i = 0; i < datasets.length - 1; i++) {
        final success = await manager.deleteCustomDataset(datasets[i].id);
        expect(success, isTrue);
      }

      expect(manager.getAllDatasets().length, 1);

      // Trying to delete the last dataset should throw an error
      final lastDataset = manager.getAllDatasets().first;
      expect(
        () async => await manager.deleteCustomDataset(lastDataset.id),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should prevent duplicate names', () async {
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

    test('should handle dataset selection', () async {
      final datasets = manager.getAllDatasets();
      final firstDataset = datasets.first;

      await manager.setSelectedDataset(firstDataset.id);
      final selected = manager.getSelectedDataset();

      expect(selected, isNotNull);
      expect(selected!.id, firstDataset.id);
    });

    test('should migrate from legacy system', () async {
      // Reset and simulate legacy data
      await manager.clearAllCustomDatasets();
      CustomDatasetManager.resetInstance();

      SharedPreferences.setMockInitialValues({
        'custom_datasets': '[{"id":"legacy-1","name":"Legacy Dataset","baseDatasetType":"final-9x9","configuration":{"timeLimit":30000,"scoreThreshold":5},"createdAt":1640995200000}]',
        'dataset_migration_completed': false,
      });

      // Create new manager instance which should trigger migration
      final newManager = await CustomDatasetManager.getInstance();

      final allDatasets = newManager.getAllDatasets();

      // Should have 4 defaults + 1 migrated legacy dataset
      expect(allDatasets.length, 5);

      // Find the migrated dataset
      final legacyDataset = allDatasets.firstWhere((d) => d.id == 'legacy-1');
      expect(legacyDataset.name, 'Legacy Dataset');
      expect(legacyDataset.baseDatasetType, DatasetType.final9x9);
    });

    test('should group datasets by type correctly', () async {
      // Create additional datasets of different types
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

      final grouped = manager.getDatasetsByBaseType();

      // Should have datasets for each type (4 total types)
      expect(grouped.keys.length, equals(4));

      // 9x9 should have 3 datasets (1 default + 2 custom)
      final final9x9Datasets = grouped[DatasetType.final9x9];
      expect(final9x9Datasets, isNotNull);
      expect(final9x9Datasets!.length, 3);

      // Default should be first (starts with 'builtin_')
      expect(final9x9Datasets.first.id, startsWith('builtin_'));

      // 19x19 should have 2 datasets (1 default + 1 custom)
      final final19x19Datasets = grouped[DatasetType.final19x19];
      expect(final19x19Datasets, isNotNull);
      expect(final19x19Datasets!.length, 2);
    });

    test('should validate dataset IDs', () {
      final validDataset = manager.getDatasetById('builtin_final-9x9');
      expect(validDataset, isNotNull);

      final invalidDataset = manager.getDatasetById('non-existent-id');
      expect(invalidDataset, isNull);
    });

    test('should handle name availability correctly', () async {
      await manager.createCustomDataset(
        name: 'Taken Name',
        baseDatasetType: DatasetType.final9x9,
      );

      expect(manager.isNameAvailable('Taken Name'), isFalse);
      expect(manager.isNameAvailable('taken name'), isFalse); // Case insensitive
      expect(manager.isNameAvailable('Available Name'), isTrue);
    });
  });
}