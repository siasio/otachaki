import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/custom_dataset.dart';
import '../../lib/models/dataset_type.dart';
import '../../lib/models/dataset_configuration.dart';
import '../../lib/services/custom_dataset_manager.dart';
import '../../lib/services/enhanced_configuration_manager.dart';
import '../../lib/services/position_loader.dart';

void main() {
  group('Training Screen Configuration Integration Tests', () {
    late CustomDatasetManager datasetManager;
    late EnhancedConfigurationManager configManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      datasetManager = await CustomDatasetManager.getInstance();
      configManager = await EnhancedConfigurationManager.getInstance();
    });

    testWidgets('Training screen should use custom dataset configuration for game behavior', (tester) async {
      // Create a custom dataset with specific settings
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Test Training Custom 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      // Configure it with specific settings
      final customConfig = configManager.getConfigurationForDataset(customDataset);
      final modifiedConfig = customConfig.copyWith(
        timePerProblemSeconds: 45, // Different from default
        thresholdGood: 6.0, // Different from default
        thresholdClose: 8.0, // Different from default
      );

      await configManager.setConfigurationForDataset(customDataset, modifiedConfig);

      // Select this custom dataset
      await datasetManager.setSelectedDataset(customDataset.id);

      // Verify the dataset is selected
      final selectedDataset = datasetManager.getSelectedDataset();
      expect(selectedDataset?.id, equals(customDataset.id));

      // Verify the custom configuration is different from default
      final defaultDataset = datasetManager.getDefaultDataset(DatasetType.final9x9)!;
      final defaultConfig = configManager.getConfigurationForDataset(defaultDataset);

      expect(modifiedConfig.timePerProblemSeconds, isNot(equals(defaultConfig.timePerProblemSeconds)),
          reason: 'Custom dataset should have different time setting than default');
      expect(modifiedConfig.thresholdGood, isNot(equals(defaultConfig.thresholdGood)),
          reason: 'Custom dataset should have different threshold than default');

      // Verify the correct dataset file is being loaded
      expect(customDataset.datasetFilePath, equals(defaultDataset.datasetFilePath),
          reason: 'Custom dataset should use same file as its base type');

      print('✅ Training screen configuration integration test passed!');
    });

    testWidgets('Different custom datasets should have different configurations', (tester) async {
      // Create two custom datasets
      final customDataset1 = await datasetManager.createCustomDataset(
        name: 'Fast Training 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      final customDataset2 = await datasetManager.createCustomDataset(
        name: 'Slow Training 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      // Configure them differently
      final config1 = configManager.getConfigurationForDataset(customDataset1);
      final config2 = configManager.getConfigurationForDataset(customDataset2);

      final modifiedConfig1 = config1.copyWith(timePerProblemSeconds: 15); // Fast
      final modifiedConfig2 = config2.copyWith(timePerProblemSeconds: 60); // Slow

      await configManager.setConfigurationForDataset(customDataset1, modifiedConfig1);
      await configManager.setConfigurationForDataset(customDataset2, modifiedConfig2);

      // Verify configurations are different
      final finalConfig1 = configManager.getConfigurationForDataset(customDataset1);
      final finalConfig2 = configManager.getConfigurationForDataset(customDataset2);

      expect(finalConfig1.timePerProblemSeconds, equals(15));
      expect(finalConfig2.timePerProblemSeconds, equals(60));
      expect(finalConfig1.timePerProblemSeconds, isNot(equals(finalConfig2.timePerProblemSeconds)));

      print('✅ Multiple custom datasets have different configurations!');
    });

    testWidgets('Dataset selection persistence works correctly', (tester) async {
      // Create and select a custom dataset
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Persistent Dataset',
        baseDatasetType: DatasetType.final19x19,
      );

      await datasetManager.setSelectedDataset(customDataset.id);

      // Simulate app restart by creating new manager instances
      final newDatasetManager = await CustomDatasetManager.getInstance();
      final selectedDataset = newDatasetManager.getSelectedDataset();

      expect(selectedDataset?.id, equals(customDataset.id));
      expect(selectedDataset?.name, equals('Persistent Dataset'));
      expect(selectedDataset?.baseDatasetType, equals(DatasetType.final19x19));

      print('✅ Dataset selection persistence works correctly!');
    });
  });
}