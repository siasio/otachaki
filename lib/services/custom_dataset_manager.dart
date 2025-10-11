import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_dataset.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/dataset_registry.dart';
import 'logger_service.dart';

/// Manages all datasets (unified architecture)
class CustomDatasetManager {
  static const String _datasetsKey = 'datasets';
  static const String _selectedDatasetKey = 'selected_dataset_id';
  static const String _legacyCustomDatasetsKey = 'custom_datasets';
  static const String _migrationCompletedKey = 'dataset_migration_completed';

  static CustomDatasetManager? _instance;
  static SharedPreferences? _prefs;

  final List<CustomDataset> _datasets = [];
  String? _selectedDatasetId;

  static const _uuid = Uuid();

  CustomDatasetManager._();

  /// Get singleton instance
  static Future<CustomDatasetManager> getInstance() async {
    if (_instance == null) {
      _instance = CustomDatasetManager._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Initialize the manager
  Future<void> _initialize() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Check if migration is needed
    final migrationCompleted = _prefs!.getBool(_migrationCompletedKey) ?? false;

    if (!migrationCompleted) {
      await _performMigration();
    } else {
      await _loadDatasets();
    }

    await _loadSelectedDataset();

    // Ensure we have at least the default datasets
    await _ensureDefaultDatasets();
  }

  /// Perform migration from old system to new unified system
  Future<void> _performMigration() async {
    LoggerService.info('Starting dataset migration', context: 'CustomDatasetManager');

    _datasets.clear();

    // Step 1: Create default datasets for all types
    await _createDefaultDatasets();

    // Step 2: Load any existing custom datasets
    await _loadLegacyCustomDatasets();

    // Step 3: Save the unified dataset list
    await _saveDatasets();

    // Step 4: Mark migration as completed
    await _prefs!.setBool(_migrationCompletedKey, true);

    LoggerService.info('Dataset migration completed. Total datasets: ${_datasets.length}',
        context: 'CustomDatasetManager');
  }

  /// Create default datasets for all registered types
  Future<void> _createDefaultDatasets() async {
    for (final datasetType in DatasetRegistry.getAllDatasetTypes()) {
      final defaultDataset = CustomDataset.defaultFor(
        datasetType: datasetType,
        name: DatasetRegistry.getBuiltInDatasetName(datasetType),
        customId: 'default_${datasetType.value}',
      );
      _datasets.add(defaultDataset);
    }
  }

  /// Load legacy custom datasets and convert them
  Future<void> _loadLegacyCustomDatasets() async {
    try {
      final legacyJson = _prefs?.getString(_legacyCustomDatasetsKey);
      if (legacyJson != null) {
        final List<dynamic> legacyList = jsonDecode(legacyJson);
        for (final datasetData in legacyList) {
          if (datasetData is Map<String, dynamic>) {
            final dataset = CustomDataset.fromJson(datasetData);
            _datasets.add(dataset);
          }
        }
        LoggerService.info('Migrated ${legacyList.length} legacy custom datasets',
            context: 'CustomDatasetManager');
      }
    } catch (e) {
      LoggerService.error('Failed to load legacy custom datasets', error: e,
          context: 'CustomDatasetManager');
    }
  }

  /// Load datasets from storage
  Future<void> _loadDatasets() async {
    try {
      final datasetsJson = _prefs?.getString(_datasetsKey);
      if (datasetsJson != null) {
        final List<dynamic> datasetsList = jsonDecode(datasetsJson);
        _datasets.clear();
        for (final datasetData in datasetsList) {
          if (datasetData is Map<String, dynamic>) {
            final dataset = CustomDataset.fromJson(datasetData);
            _datasets.add(dataset);
          }
        }
        LoggerService.info('Loaded ${_datasets.length} datasets',
            context: 'CustomDatasetManager');
      }
    } catch (e) {
      LoggerService.error('Failed to load datasets', error: e,
          context: 'CustomDatasetManager');
      _datasets.clear();
    }
  }

  /// Save all datasets to storage
  Future<void> _saveDatasets() async {
    try {
      final datasetsJson = jsonEncode(_datasets.map((d) => d.toJson()).toList());
      await _prefs?.setString(_datasetsKey, datasetsJson);
      LoggerService.info('Saved ${_datasets.length} datasets',
          context: 'CustomDatasetManager');
    } catch (e) {
      LoggerService.error('Failed to save datasets', error: e,
          context: 'CustomDatasetManager');
    }
  }

  /// Ensure we have at least the default datasets
  Future<void> _ensureDefaultDatasets() async {
    bool needsDefaults = false;

    // Check if we have at least one dataset for each type
    for (final datasetType in DatasetRegistry.getAllDatasetTypes()) {
      final hasDatasetForType = _datasets.any((d) => d.baseDatasetType == datasetType);
      if (!hasDatasetForType) {
        final defaultDataset = CustomDataset.defaultFor(
          datasetType: datasetType,
          name: DatasetRegistry.getBuiltInDatasetName(datasetType),
          customId: 'default_${datasetType.value}',
        );
        _datasets.add(defaultDataset);
        needsDefaults = true;
      }
    }

    if (needsDefaults) {
      await _saveDatasets();
      LoggerService.info('Added missing default datasets', context: 'CustomDatasetManager');
    }
  }

  /// Load selected dataset ID
  Future<void> _loadSelectedDataset() async {
    _selectedDatasetId = _prefs?.getString(_selectedDatasetKey);
  }

  /// Save selected dataset ID
  Future<void> _saveSelectedDataset() async {
    if (_selectedDatasetId != null) {
      await _prefs?.setString(_selectedDatasetKey, _selectedDatasetId!);
    }
  }

  /// Create a new dataset
  Future<CustomDataset> createCustomDataset({
    required String name,
    required DatasetType baseDatasetType,
    DatasetConfiguration? customConfiguration,
  }) async {
    // Validate name
    if (name.trim().isEmpty) {
      throw ArgumentError('Dataset name cannot be empty');
    }

    // Check for duplicate names
    if (_datasets.any((d) => d.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('A dataset with this name already exists');
    }

    final dataset = CustomDataset.fromBaseType(
      id: _uuid.v4(),
      name: name.trim(),
      baseDatasetType: baseDatasetType,
    );

    // Apply custom configuration if provided
    final finalDataset = customConfiguration != null
        ? dataset.copyWith(configuration: customConfiguration)
        : dataset;

    _datasets.add(finalDataset);
    await _saveDatasets();

    LoggerService.info('Created dataset: ${finalDataset.name} (${finalDataset.id})',
        context: 'CustomDatasetManager');

    return finalDataset;
  }

  /// Update an existing dataset
  Future<CustomDataset> updateCustomDataset({
    required String id,
    String? name,
    DatasetConfiguration? configuration,
  }) async {
    final index = _datasets.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Dataset not found: $id');
    }

    // Validate name if provided
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Dataset name cannot be empty');
    }

    // Check for duplicate names (excluding current dataset)
    if (name != null) {
      final trimmedName = name.trim();
      if (_datasets.any((d) =>
          d.id != id && d.name.toLowerCase() == trimmedName.toLowerCase())) {
        throw ArgumentError('A dataset with this name already exists');
      }
    }

    final updatedDataset = _datasets[index].copyWith(
      name: name?.trim(),
      configuration: configuration,
    );

    _datasets[index] = updatedDataset;
    await _saveDatasets();

    LoggerService.info('Updated dataset: ${updatedDataset.name} (${updatedDataset.id})',
        context: 'CustomDatasetManager');

    return updatedDataset;
  }

  /// Delete a dataset
  Future<bool> deleteCustomDataset(String id) async {
    // Check if this would leave us with no datasets
    if (_datasets.length <= 1) {
      throw ArgumentError('Cannot delete the last dataset. At least one dataset must exist.');
    }

    final initialCount = _datasets.length;
    _datasets.removeWhere((d) => d.id == id);

    if (_datasets.length < initialCount) {
      await _saveDatasets();

      // If the deleted dataset was selected, select the first available dataset
      if (_selectedDatasetId == id) {
        if (_datasets.isNotEmpty) {
          await setSelectedDataset(_datasets.first.id);
        } else {
          _selectedDatasetId = null;
          await _prefs?.remove(_selectedDatasetKey);
        }
      }

      LoggerService.info('Deleted dataset: $id', context: 'CustomDatasetManager');
      return true;
    }
    return false;
  }

  /// Get a dataset by ID
  CustomDataset? getDatasetById(String id) {
    try {
      return _datasets.firstWhere((dataset) => dataset.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all datasets (excluding hidden dataset types)
  List<CustomDataset> getAllDatasets() {
    final visibleDatasets = _datasets.where((dataset) {
      // Filter out datasets based on hidden dataset types
      return DatasetRegistry.getAllDatasetTypes().contains(dataset.baseDatasetType);
    }).toList();
    return List.unmodifiable(visibleDatasets);
  }

  /// Get datasets of a specific type (for backwards compatibility)
  List<CustomDataset> getDatasetsOfType(DatasetType type) {
    return _datasets.where((d) => d.baseDatasetType == type).toList();
  }

  /// Get datasets grouped by base type (excluding hidden dataset types)
  Map<DatasetType, List<CustomDataset>> getDatasetsByBaseType() {
    final Map<DatasetType, List<CustomDataset>> grouped = {};
    final visibleDatasetTypes = DatasetRegistry.getAllDatasetTypes();

    for (final dataset in _datasets) {
      // Only include datasets based on visible dataset types
      if (visibleDatasetTypes.contains(dataset.baseDatasetType)) {
        grouped.putIfAbsent(dataset.baseDatasetType, () => []).add(dataset);
      }
    }

    // Sort each group by creation date (defaults first, then by creation time)
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        // Default datasets first (identified by their predictable IDs)
        final aIsDefault = a.id.startsWith('default_');
        final bIsDefault = b.id.startsWith('default_');

        if (aIsDefault && !bIsDefault) return -1;
        if (!aIsDefault && bIsDefault) return 1;

        return a.createdAt.compareTo(b.createdAt);
      });
    }

    return grouped;
  }

  /// Set the currently selected dataset
  Future<void> setSelectedDataset(String datasetId) async {
    if (getDatasetById(datasetId) == null) {
      throw ArgumentError('Dataset not found: $datasetId');
    }

    _selectedDatasetId = datasetId;
    await _saveSelectedDataset();

    LoggerService.info('Selected dataset: $datasetId', context: 'CustomDatasetManager');
  }

  /// Get the currently selected dataset
  CustomDataset? getSelectedDataset() {
    if (_selectedDatasetId == null) return null;
    return getDatasetById(_selectedDatasetId!);
  }

  /// Get the currently selected dataset ID
  String? getSelectedDatasetId() {
    return _selectedDatasetId;
  }

  /// Clear selection
  Future<void> clearSelection() async {
    _selectedDatasetId = null;
    await _prefs?.remove(_selectedDatasetKey);
  }

  /// Get the default dataset for a specific DatasetType
  CustomDataset? getDefaultDataset(DatasetType datasetType) {
    return _datasets.firstWhere(
      (d) => d.baseDatasetType == datasetType && d.id.startsWith('default_'),
      orElse: () => _datasets.firstWhere(
        (d) => d.baseDatasetType == datasetType,
        orElse: () => throw StateError('No dataset found for $datasetType'),
      ),
    );
  }

  /// Check if a dataset name is available
  bool isNameAvailable(String name, {String? excludeId}) {
    final trimmedName = name.trim().toLowerCase();
    return !_datasets.any((d) =>
        d.id != excludeId && d.name.toLowerCase() == trimmedName);
  }

  /// Clear all datasets (for testing)
  Future<void> clearAllCustomDatasets() async {
    _datasets.clear();
    _selectedDatasetId = null;
    await _prefs?.remove(_datasetsKey);
    await _prefs?.remove(_selectedDatasetKey);
    await _prefs?.remove(_migrationCompletedKey);
    await _prefs?.remove(_legacyCustomDatasetsKey);
  }

  /// Reset singleton instance (for testing)
  static void resetInstance() {
    _instance = null;
    _prefs = null;
  }
}