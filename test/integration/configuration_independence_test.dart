import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/custom_dataset.dart';
import '../../lib/models/dataset_type.dart';
import '../../lib/models/dataset_configuration.dart';
import '../../lib/services/custom_dataset_manager.dart';
import '../../lib/services/configuration_manager.dart';

void main() {
  group('Configuration Independence Tests', () {
    late CustomDatasetManager datasetManager;
    late ConfigurationManager configManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      datasetManager = await CustomDatasetManager.getInstance();
      configManager = await ConfigurationManager.getInstance();
    });

    testWidgets('Custom and built-in datasets have independent configurations', (tester) async {
      // Create a custom dataset based on 9x9
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Test Custom 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      // Get the built-in 9x9 dataset for comparison
      final defaultDataset = datasetManager.getDefaultDataset(DatasetType.final9x9)!;

      // Check initial configurations (should be the same defaults)
      final customConfig = configManager.getConfigurationForDataset(customDataset);
      final defaultConfig = configManager.getConfigurationForDataset(defaultDataset);

      expect(customConfig.timePerProblemSeconds, equals(defaultConfig.timePerProblemSeconds),
          reason: 'Initial configurations should be the same');

      // Modify custom dataset configuration
      final newCustomConfig = customConfig.copyWith(
        timePerProblemSeconds: 25, // Change from default
        thresholdGood: 7.5, // Change from default
        thresholdClose: 8.0, // Ensure this is >= thresholdGood
      );

      await configManager.setConfigurationForDataset(customDataset, newCustomConfig);

      // Verify configurations are now independent
      final updatedCustomConfig = configManager.getConfigurationForDataset(customDataset);
      final unchangedBuiltInConfig = configManager.getConfigurationForDataset(defaultDataset);

      expect(updatedCustomConfig.timePerProblemSeconds, equals(25),
          reason: 'Custom dataset should have updated time');
      expect(updatedCustomConfig.thresholdGood, equals(7.5),
          reason: 'Custom dataset should have updated threshold');

      expect(unchangedBuiltInConfig.timePerProblemSeconds, isNot(equals(25)),
          reason: 'Built-in dataset should not be affected by custom dataset changes');
      expect(unchangedBuiltInConfig.thresholdGood, isNot(equals(7.5)),
          reason: 'Built-in dataset should not be affected by custom dataset changes');
      expect(unchangedBuiltInConfig.thresholdClose, isNot(equals(8.0)),
          reason: 'Built-in dataset should not be affected by custom dataset changes');

      print('✅ Custom and built-in datasets have independent configurations!');
    });

    testWidgets('Multiple custom datasets have independent configurations', (tester) async {
      // Create two custom datasets
      final customDataset1 = await datasetManager.createCustomDataset(
        name: 'Test Custom 9x9 #1',
        baseDatasetType: DatasetType.final9x9,
      );

      final customDataset2 = await datasetManager.createCustomDataset(
        name: 'Test Custom 9x9 #2',
        baseDatasetType: DatasetType.final9x9,
      );

      // Configure them differently
      final config1 = configManager.getConfigurationForDataset(customDataset1);
      final config2 = configManager.getConfigurationForDataset(customDataset2);

      final modifiedConfig1 = config1.copyWith(timePerProblemSeconds: 30);
      final modifiedConfig2 = config2.copyWith(timePerProblemSeconds: 45);

      await configManager.setConfigurationForDataset(customDataset1, modifiedConfig1);
      await configManager.setConfigurationForDataset(customDataset2, modifiedConfig2);

      // Verify they remain independent
      final finalConfig1 = configManager.getConfigurationForDataset(customDataset1);
      final finalConfig2 = configManager.getConfigurationForDataset(customDataset2);

      expect(finalConfig1.timePerProblemSeconds, equals(30),
          reason: 'First custom dataset should have its own time setting');
      expect(finalConfig2.timePerProblemSeconds, equals(45),
          reason: 'Second custom dataset should have its own time setting');

      print('✅ Multiple custom datasets have independent configurations!');
    });

    testWidgets('Built-in dataset modifications do not affect custom datasets', (tester) async {
      // Create a custom dataset
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Test Custom 9x9 Independent',
        baseDatasetType: DatasetType.final9x9,
      );

      // Get built-in dataset
      final defaultDataset = datasetManager.getDefaultDataset(DatasetType.final9x9)!;

      // Set custom dataset configuration
      final customConfig = configManager.getConfigurationForDataset(customDataset);
      final modifiedCustomConfig = customConfig.copyWith(timePerProblemSeconds: 40);
      await configManager.setConfigurationForDataset(customDataset, modifiedCustomConfig);

      // Now modify built-in dataset configuration
      final defaultConfig = configManager.getConfigurationForDataset(defaultDataset);
      final modifiedBuiltInConfig = defaultConfig.copyWith(timePerProblemSeconds: 15);
      await configManager.setConfigurationForDataset(defaultDataset, modifiedBuiltInConfig);

      // Verify custom dataset is unaffected
      final finalCustomConfig = configManager.getConfigurationForDataset(customDataset);
      final finalBuiltInConfig = configManager.getConfigurationForDataset(defaultDataset);

      expect(finalCustomConfig.timePerProblemSeconds, equals(40),
          reason: 'Custom dataset should retain its settings');
      expect(finalBuiltInConfig.timePerProblemSeconds, equals(15),
          reason: 'Built-in dataset should have updated settings');

      print('✅ Built-in dataset modifications do not affect custom datasets!');
    });
  });
}