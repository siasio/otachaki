import 'dart:async';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/custom_dataset.dart';
import 'base_service_manager.dart';
import 'json_service_mixin.dart';
import 'logger_service.dart';

/// Enhanced ConfigurationManager that supports both legacy DatasetType and custom dataset configurations
class EnhancedConfigurationManager extends BaseServiceManager<Map<String, DatasetConfiguration>>
    with JsonServiceMixin {

  // Legacy configurations by DatasetType (for backward compatibility)
  final Map<DatasetType, DatasetConfiguration> _legacyConfigurations = {};

  // New configurations by custom dataset ID
  final Map<String, DatasetConfiguration> _customConfigurations = {};

  @override
  String get preferencesKey => 'enhanced_dataset_configurations';

  /// Get singleton instance
  static Future<EnhancedConfigurationManager> getInstance() async {
    return BaseServiceManager.getInstance<EnhancedConfigurationManager>(() => EnhancedConfigurationManager._());
  }

  EnhancedConfigurationManager._();

  @override
  Future<void> loadData() async {
    final configMap = await loadJsonFromPreferences(preferencesKey);

    if (configMap != null) {
      _loadConfigurationsFromMap(configMap);
    } else {
      // Try to migrate from legacy configuration manager
      await _migrateLegacyConfigurations();
      _initializeDefaults();
    }
  }

  @override
  Future<void> handleInitializationError(dynamic error) async {
    LoggerService.warning('Falling back to default configurations due to loading error',
      error: error, context: serviceName);
    _initializeDefaults();
  }

  /// Migrate from legacy ConfigurationManager
  Future<void> _migrateLegacyConfigurations() async {
    try {
      final legacyConfigMap = await loadJsonFromPreferences('dataset_configurations');
      if (legacyConfigMap != null) {
        LoggerService.info('Migrating legacy configurations', context: serviceName);

        for (final type in DatasetType.values) {
          final typeConfig = legacyConfigMap[type.value];
          if (typeConfig != null) {
            try {
              final config = DatasetConfiguration.fromJson(typeConfig as Map<String, dynamic>);
              _legacyConfigurations[type] = config;
              // Also store as custom configuration with built-in ID
              _customConfigurations['builtin_${type.value}'] = config;
            } catch (e) {
              LoggerService.warning('Failed to migrate configuration for ${type.value}',
                error: e, context: serviceName);
              final defaultConfig = DatasetConfiguration.getDefaultFor(type);
              _legacyConfigurations[type] = defaultConfig;
              _customConfigurations['builtin_${type.value}'] = defaultConfig;
            }
          }
        }

        // Save the migrated configurations
        await _saveConfigurations();
        LoggerService.info('Legacy configuration migration completed', context: serviceName);
      }
    } catch (e) {
      LoggerService.warning('Failed to migrate legacy configurations',
        error: e, context: serviceName);
    }
  }

  void _loadConfigurationsFromMap(Map<String, dynamic> configMap) {
    // Load legacy configurations
    final legacyMap = configMap['legacy'] as Map<String, dynamic>? ?? {};
    for (final type in DatasetType.values) {
      final typeConfig = legacyMap[type.value];
      if (typeConfig != null) {
        try {
          _legacyConfigurations[type] = DatasetConfiguration.fromJson(
            typeConfig as Map<String, dynamic>
          );
        } catch (e) {
          LoggerService.warning('Failed to load legacy configuration for ${type.value}',
            error: e, context: serviceName);
          _legacyConfigurations[type] = DatasetConfiguration.getDefaultFor(type);
        }
      } else {
        _legacyConfigurations[type] = DatasetConfiguration.getDefaultFor(type);
      }
    }

    // Load custom configurations
    final customMap = configMap['custom'] as Map<String, dynamic>? ?? {};
    _customConfigurations.clear();
    for (final entry in customMap.entries) {
      try {
        _customConfigurations[entry.key] = DatasetConfiguration.fromJson(
          entry.value as Map<String, dynamic>
        );
      } catch (e) {
        LoggerService.warning('Failed to load custom configuration for ${entry.key}',
          error: e, context: serviceName);
      }
    }

    // Ensure built-in configurations exist in custom map
    for (final type in DatasetType.values) {
      final builtinId = 'builtin_${type.value}';
      if (!_customConfigurations.containsKey(builtinId)) {
        _customConfigurations[builtinId] = _legacyConfigurations[type]!;
      }
    }
  }

  void _initializeDefaults() {
    _legacyConfigurations.clear();
    _customConfigurations.clear();

    for (final type in DatasetType.values) {
      final defaultConfig = DatasetConfiguration.getDefaultFor(type);
      _legacyConfigurations[type] = defaultConfig;
      _customConfigurations['builtin_${type.value}'] = defaultConfig;
    }
    LoggerService.info('Initialized default configurations for all dataset types',
      context: serviceName);
  }

  Future<void> _saveConfigurations() async {
    final configMap = <String, dynamic>{
      'legacy': <String, dynamic>{},
      'custom': <String, dynamic>{},
    };

    // Save legacy configurations
    for (final entry in _legacyConfigurations.entries) {
      configMap['legacy'][entry.key.value] = entry.value.toJson();
    }

    // Save custom configurations
    for (final entry in _customConfigurations.entries) {
      configMap['custom'][entry.key] = entry.value.toJson();
    }

    await saveJsonToPreferences(preferencesKey, configMap);
  }

  /// Get configuration for a legacy dataset type
  DatasetConfiguration getConfiguration(DatasetType datasetType) {
    return _legacyConfigurations[datasetType] ??
           DatasetConfiguration.getDefaultFor(datasetType);
  }

  /// Get configuration for a custom dataset by ID
  DatasetConfiguration getConfigurationById(String datasetId) {
    return _customConfigurations[datasetId] ??
           _getDefaultConfigurationForId(datasetId);
  }

  /// Get configuration for a custom dataset object
  DatasetConfiguration getConfigurationForDataset(CustomDataset dataset) {
    return getConfigurationById(dataset.id);
  }

  DatasetConfiguration _getDefaultConfigurationForId(String datasetId) {
    if (datasetId.startsWith('builtin_')) {
      final typeValue = datasetId.substring(8); // Remove 'builtin_' prefix
      final type = DatasetType.fromString(typeValue);
      if (type != null) {
        return DatasetConfiguration.getDefaultFor(type);
      }
    }
    // Fallback to first dataset type default
    return DatasetConfiguration.getDefaultFor(DatasetType.final9x9);
  }

  /// Set configuration for a legacy dataset type
  Future<void> setConfiguration(
    DatasetType datasetType,
    DatasetConfiguration configuration
  ) async {
    if (!configuration.isValidConfiguration()) {
      throw ArgumentError('Invalid configuration: thresholdClose must be >= thresholdGood');
    }

    _legacyConfigurations[datasetType] = configuration;
    // Also update the built-in custom configuration
    _customConfigurations['builtin_${datasetType.value}'] = configuration;

    await _saveConfigurations();

    LoggerService.info('Configuration updated for ${datasetType.value}',
      context: serviceName);
  }

  /// Set configuration for a custom dataset by ID
  Future<void> setConfigurationById(
    String datasetId,
    DatasetConfiguration configuration
  ) async {
    if (!configuration.isValidConfiguration()) {
      throw ArgumentError('Invalid configuration: thresholdClose must be >= thresholdGood');
    }

    _customConfigurations[datasetId] = configuration;

    // If this is a built-in dataset, also update the legacy configuration
    if (datasetId.startsWith('builtin_')) {
      final typeValue = datasetId.substring(8);
      final type = DatasetType.fromString(typeValue);
      if (type != null) {
        _legacyConfigurations[type] = configuration;
      }
    }

    await _saveConfigurations();

    LoggerService.info('Configuration updated for $datasetId', context: serviceName);
  }

  /// Set configuration for a custom dataset object
  Future<void> setConfigurationForDataset(
    CustomDataset dataset,
    DatasetConfiguration configuration
  ) async {
    await setConfigurationById(dataset.id, configuration);
  }

  /// Reset configuration for a legacy dataset type to defaults
  Future<void> resetConfiguration(DatasetType datasetType) async {
    final defaultConfig = DatasetConfiguration.getDefaultFor(datasetType);
    _legacyConfigurations[datasetType] = defaultConfig;
    _customConfigurations['builtin_${datasetType.value}'] = defaultConfig;

    await _saveConfigurations();

    LoggerService.info('Configuration reset to defaults for ${datasetType.value}',
      context: serviceName);
  }

  /// Reset configuration for a custom dataset by ID to defaults
  Future<void> resetConfigurationById(String datasetId) async {
    final defaultConfig = _getDefaultConfigurationForId(datasetId);
    _customConfigurations[datasetId] = defaultConfig;

    // If this is a built-in dataset, also update the legacy configuration
    if (datasetId.startsWith('builtin_')) {
      final typeValue = datasetId.substring(8);
      final type = DatasetType.fromString(typeValue);
      if (type != null) {
        _legacyConfigurations[type] = defaultConfig;
      }
    }

    await _saveConfigurations();

    LoggerService.info('Configuration reset to defaults for $datasetId', context: serviceName);
  }

  /// Reset configuration for a custom dataset object to defaults
  Future<void> resetConfigurationForDataset(CustomDataset dataset) async {
    await resetConfigurationById(dataset.id);
  }

  /// Reset all configurations to defaults
  Future<void> resetAllConfigurations() async {
    _initializeDefaults();
    await _saveConfigurations();

    LoggerService.info('All configurations reset to defaults', context: serviceName);
  }

  /// Get all legacy configurations (read-only)
  Map<DatasetType, DatasetConfiguration> getAllConfigurations() {
    return Map.unmodifiable(_legacyConfigurations);
  }

  /// Get all custom configurations by ID (read-only)
  Map<String, DatasetConfiguration> getAllConfigurationsById() {
    return Map.unmodifiable(_customConfigurations);
  }

  /// Remove configuration for a custom dataset (when dataset is deleted)
  Future<void> removeConfigurationById(String datasetId) async {
    if (datasetId.startsWith('builtin_')) {
      // Don't remove built-in configurations, just reset them
      await resetConfigurationById(datasetId);
    } else {
      _customConfigurations.remove(datasetId);
      await _saveConfigurations();
      LoggerService.info('Configuration removed for $datasetId', context: serviceName);
    }
  }

  /// Create configuration for a new custom dataset based on its base type
  Future<void> createConfigurationForDataset(CustomDataset dataset) async {
    // Use the dataset's current configuration or default from base type
    final config = dataset.configuration;
    _customConfigurations[dataset.id] = config;
    await _saveConfigurations();

    LoggerService.info('Configuration created for custom dataset ${dataset.id}',
      context: serviceName);
  }
}