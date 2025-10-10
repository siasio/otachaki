import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/custom_dataset.dart';
import '../../lib/models/dataset_type.dart';
import '../../lib/models/dataset_configuration.dart';
import '../../lib/models/auto_advance_mode.dart';
import '../../lib/services/custom_dataset_manager.dart';
import '../../lib/services/enhanced_configuration_manager.dart';

void main() {
  group('Auto-Advance Dataset Independence Tests', () {
    late CustomDatasetManager datasetManager;
    late EnhancedConfigurationManager configManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      datasetManager = await CustomDatasetManager.getInstance();
      configManager = await EnhancedConfigurationManager.getInstance();
    });

    testWidgets('Different custom datasets can have different auto-advance modes', (tester) async {
      // Create two custom datasets based on the same type
      final alwaysAutoDataset = await datasetManager.createCustomDataset(
        name: 'Always Auto-Advance',
        baseDatasetType: DatasetType.final9x9,
      );

      final neverAutoDataset = await datasetManager.createCustomDataset(
        name: 'Never Auto-Advance',
        baseDatasetType: DatasetType.final9x9,
      );

      // Configure them with different auto-advance modes
      final alwaysConfig = configManager.getConfigurationForDataset(alwaysAutoDataset);
      final neverConfig = configManager.getConfigurationForDataset(neverAutoDataset);

      final modifiedAlwaysConfig = alwaysConfig.copyWith(
        autoAdvanceMode: AutoAdvanceMode.always,
      );
      final modifiedNeverConfig = neverConfig.copyWith(
        autoAdvanceMode: AutoAdvanceMode.never,
      );

      await configManager.setConfigurationForDataset(alwaysAutoDataset, modifiedAlwaysConfig);
      await configManager.setConfigurationForDataset(neverAutoDataset, modifiedNeverConfig);

      // Verify they have different auto-advance modes
      final finalAlwaysConfig = configManager.getConfigurationForDataset(alwaysAutoDataset);
      final finalNeverConfig = configManager.getConfigurationForDataset(neverAutoDataset);

      expect(finalAlwaysConfig.autoAdvanceMode, equals(AutoAdvanceMode.always),
          reason: 'Always-auto dataset should have always mode');
      expect(finalNeverConfig.autoAdvanceMode, equals(AutoAdvanceMode.never),
          reason: 'Never-auto dataset should have never mode');
      expect(finalAlwaysConfig.autoAdvanceMode, isNot(equals(finalNeverConfig.autoAdvanceMode)),
          reason: 'Datasets should have different auto-advance modes');

      print('✅ Different custom datasets can have different auto-advance modes!');
    });

    testWidgets('Auto-advance is independent between custom and built-in datasets', (tester) async {
      // Create a custom dataset
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Custom Auto-Advance Test',
        baseDatasetType: DatasetType.final9x9,
      );

      // Get the built-in dataset of the same type
      final defaultDataset = datasetManager.getDefaultDataset(DatasetType.final9x9)!;

      // Set different auto-advance modes
      final customConfig = configManager.getConfigurationForDataset(customDataset);
      final defaultConfig = configManager.getConfigurationForDataset(defaultDataset);

      final modifiedCustomConfig = customConfig.copyWith(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
      );
      final modifiedBuiltInConfig = defaultConfig.copyWith(
        autoAdvanceMode: AutoAdvanceMode.always,
      );

      await configManager.setConfigurationForDataset(customDataset, modifiedCustomConfig);
      await configManager.setConfigurationForDataset(defaultDataset, modifiedBuiltInConfig);

      // Verify they have different auto-advance modes
      final finalCustomConfig = configManager.getConfigurationForDataset(customDataset);
      final finalBuiltInConfig = configManager.getConfigurationForDataset(defaultDataset);

      expect(finalCustomConfig.autoAdvanceMode, equals(AutoAdvanceMode.onCorrectOnly),
          reason: 'Custom dataset should have onCorrectOnly mode');
      expect(finalBuiltInConfig.autoAdvanceMode, equals(AutoAdvanceMode.always),
          reason: 'Built-in dataset should have always mode');
      expect(finalCustomConfig.autoAdvanceMode, isNot(equals(finalBuiltInConfig.autoAdvanceMode)),
          reason: 'Custom and built-in datasets should have different auto-advance modes');

      print('✅ Auto-advance is independent between custom and built-in datasets!');
    });

    testWidgets('Auto-advance configuration persists across app restarts', (tester) async {
      // Create a custom dataset with specific auto-advance mode
      final customDataset = await datasetManager.createCustomDataset(
        name: 'Persistent Auto-Advance',
        baseDatasetType: DatasetType.final19x19,
      );

      final config = configManager.getConfigurationForDataset(customDataset);
      final modifiedConfig = config.copyWith(
        autoAdvanceMode: AutoAdvanceMode.onCorrectOnly,
      );

      await configManager.setConfigurationForDataset(customDataset, modifiedConfig);

      // Simulate app restart by creating new manager instances
      final newConfigManager = await EnhancedConfigurationManager.getInstance();
      final newDatasetManager = await CustomDatasetManager.getInstance();

      // Get the dataset again
      final persistedDataset = newDatasetManager.getAllDatasets()
          .firstWhere((d) => d.name == 'Persistent Auto-Advance');

      // Verify the auto-advance mode is still correct
      final persistedConfig = newConfigManager.getConfigurationForDataset(persistedDataset);

      expect(persistedConfig.autoAdvanceMode, equals(AutoAdvanceMode.onCorrectOnly),
          reason: 'Auto-advance mode should persist across app restarts');

      print('✅ Auto-advance configuration persists across app restarts!');
    });

    testWidgets('Auto-advance default values are correct for different dataset types', (tester) async {
      // Create custom datasets for different base types
      final dataset9x9 = await datasetManager.createCustomDataset(
        name: 'Test 9x9',
        baseDatasetType: DatasetType.final9x9,
      );

      final dataset19x19 = await datasetManager.createCustomDataset(
        name: 'Test 19x19',
        baseDatasetType: DatasetType.final19x19,
      );

      final datasetMidgame = await datasetManager.createCustomDataset(
        name: 'Test Midgame',
        baseDatasetType: DatasetType.midgame19x19,
      );

      // Verify they all have the default auto-advance mode
      final config9x9 = configManager.getConfigurationForDataset(dataset9x9);
      final config19x19 = configManager.getConfigurationForDataset(dataset19x19);
      final configMidgame = configManager.getConfigurationForDataset(datasetMidgame);

      expect(config9x9.autoAdvanceMode, equals(AutoAdvanceMode.always),
          reason: '9x9 dataset should have default auto-advance mode');
      expect(config19x19.autoAdvanceMode, equals(AutoAdvanceMode.always),
          reason: '19x19 dataset should have default auto-advance mode');
      expect(configMidgame.autoAdvanceMode, equals(AutoAdvanceMode.always),
          reason: 'Midgame dataset should have default auto-advance mode');

      print('✅ Auto-advance default values are correct for different dataset types!');
    });

    testWidgets('All auto-advance modes can be set and retrieved correctly', (tester) async {
      // Create a test dataset
      final testDataset = await datasetManager.createCustomDataset(
        name: 'Auto-Advance Mode Test',
        baseDatasetType: DatasetType.final9x9,
      );

      // Test all auto-advance modes
      for (final mode in AutoAdvanceMode.values) {
        final config = configManager.getConfigurationForDataset(testDataset);
        final modifiedConfig = config.copyWith(autoAdvanceMode: mode);

        await configManager.setConfigurationForDataset(testDataset, modifiedConfig);

        final retrievedConfig = configManager.getConfigurationForDataset(testDataset);
        expect(retrievedConfig.autoAdvanceMode, equals(mode),
            reason: 'Should be able to set and retrieve $mode');
      }

      print('✅ All auto-advance modes can be set and retrieved correctly!');
    });
  });
}