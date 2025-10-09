import 'dart:async';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import 'base_service_manager.dart';
import 'json_service_mixin.dart';
import 'logger_service.dart';

/// Refactored ConfigurationManager using base service manager pattern
class ConfigurationManager extends BaseServiceManager<Map<DatasetType, DatasetConfiguration>>
    with JsonServiceMixin {

  final Map<DatasetType, DatasetConfiguration> _configurations = {};

  @override
  String get preferencesKey => 'dataset_configurations';

  /// Get singleton instance
  static Future<ConfigurationManager> getInstance() async {
    return BaseServiceManager.getInstance<ConfigurationManager>(() => ConfigurationManager._());
  }

  ConfigurationManager._();

  @override
  Future<void> loadData() async {
    final configMap = await loadJsonFromPreferences(preferencesKey);

    if (configMap != null) {
      _loadConfigurationsFromMap(configMap);
    } else {
      _initializeDefaults();
    }
  }

  @override
  Future<void> handleInitializationError(dynamic error) async {
    LoggerService.warning('Falling back to default configurations due to loading error',
      error: error, context: serviceName);
    _initializeDefaults();
  }

  void _loadConfigurationsFromMap(Map<String, dynamic> configMap) {
    for (final type in DatasetType.values) {
      final typeConfig = configMap[type.value];
      if (typeConfig != null) {
        try {
          _configurations[type] = DatasetConfiguration.fromJson(
            typeConfig as Map<String, dynamic>
          );
        } catch (e) {
          LoggerService.warning('Failed to load configuration for ${type.value}, using default',
            error: e, context: serviceName);
          _configurations[type] = DatasetConfiguration.getDefaultFor(type);
        }
      } else {
        _configurations[type] = DatasetConfiguration.getDefaultFor(type);
      }
    }
  }

  void _initializeDefaults() {
    for (final type in DatasetType.values) {
      _configurations[type] = DatasetConfiguration.getDefaultFor(type);
    }
    LoggerService.info('Initialized default configurations for all dataset types',
      context: serviceName);
  }

  Future<void> _saveConfigurations() async {
    final configMap = <String, dynamic>{};
    for (final entry in _configurations.entries) {
      configMap[entry.key.value] = entry.value.toJson();
    }

    await saveJsonToPreferences(preferencesKey, configMap);
  }

  /// Get configuration for a specific dataset type
  DatasetConfiguration getConfiguration(DatasetType datasetType) {
    return _configurations[datasetType] ??
           DatasetConfiguration.getDefaultFor(datasetType);
  }

  /// Set configuration for a specific dataset type
  Future<void> setConfiguration(
    DatasetType datasetType,
    DatasetConfiguration configuration
  ) async {
    if (!configuration.isValidConfiguration()) {
      throw ArgumentError('Invalid configuration: thresholdClose must be >= thresholdGood');
    }

    _configurations[datasetType] = configuration;
    await _saveConfigurations();

    LoggerService.info('Configuration updated for ${datasetType.value}',
      context: serviceName);
  }

  /// Reset configuration for a specific dataset type to defaults
  Future<void> resetConfiguration(DatasetType datasetType) async {
    _configurations[datasetType] = DatasetConfiguration.getDefaultFor(datasetType);
    await _saveConfigurations();

    LoggerService.info('Configuration reset to defaults for ${datasetType.value}',
      context: serviceName);
  }

  /// Reset all configurations to defaults
  Future<void> resetAllConfigurations() async {
    _initializeDefaults();
    await _saveConfigurations();

    LoggerService.info('All configurations reset to defaults',
      context: serviceName);
  }

  /// Get all configurations (read-only)
  Map<DatasetType, DatasetConfiguration> getAllConfigurations() {
    return Map.unmodifiable(_configurations);
  }
}