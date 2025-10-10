import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_dataset.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/dataset_registry.dart';
import 'logger_service.dart';

/// Manages custom user-defined datasets
class CustomDatasetManager {
  static const String _customDatasetsKey = 'custom_datasets';
  static const String _selectedDatasetKey = 'selected_dataset_id';

  static CustomDatasetManager? _instance;
  static SharedPreferences? _prefs;

  final List<CustomDataset> _customDatasets = [];
  final List<CustomDataset> _builtInDatasets = [];
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
    _initializeBuiltInDatasets();
    await _loadCustomDatasets();
    await _loadSelectedDataset();
  }

  /// Initialize built-in datasets using the dataset registry
  void _initializeBuiltInDatasets() {
    _builtInDatasets.clear();

    // Create built-in datasets for all registered dataset types
    for (final datasetType in DatasetRegistry.getAllDatasetTypes()) {
      _builtInDatasets.add(
        CustomDataset.builtIn(
          datasetType: datasetType,
          name: DatasetRegistry.getBuiltInDatasetName(datasetType),
        ),
      );
    }
  }

  /// Load custom datasets from storage
  Future<void> _loadCustomDatasets() async {
    try {
      final datasetsJson = _prefs?.getString(_customDatasetsKey);
      if (datasetsJson != null) {
        final List<dynamic> datasetsList = jsonDecode(datasetsJson);
        _customDatasets.clear();
        for (final datasetData in datasetsList) {
          if (datasetData is Map<String, dynamic>) {
            final dataset = CustomDataset.fromJson(datasetData);
            _customDatasets.add(dataset);
          }
        }
        LoggerService.info('Loaded ${_customDatasets.length} custom datasets',
            context: 'CustomDatasetManager');
      }
    } catch (e) {
      LoggerService.error('Failed to load custom datasets', error: e,
          context: 'CustomDatasetManager');
      _customDatasets.clear();
    }
  }

  /// Save custom datasets to storage
  Future<void> _saveCustomDatasets() async {
    try {
      final datasetsJson = jsonEncode(_customDatasets.map((d) => d.toJson()).toList());
      await _prefs?.setString(_customDatasetsKey, datasetsJson);
      LoggerService.info('Saved ${_customDatasets.length} custom datasets',
          context: 'CustomDatasetManager');
    } catch (e) {
      LoggerService.error('Failed to save custom datasets', error: e,
          context: 'CustomDatasetManager');
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

  /// Create a new custom dataset
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
    if (_getAllDatasets().any((d) => d.name.toLowerCase() == name.toLowerCase())) {
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

    _customDatasets.add(finalDataset);
    await _saveCustomDatasets();

    LoggerService.info('Created custom dataset: ${finalDataset.name} (${finalDataset.id})',
        context: 'CustomDatasetManager');

    return finalDataset;
  }

  /// Update an existing custom dataset
  Future<CustomDataset> updateCustomDataset({
    required String id,
    String? name,
    DatasetConfiguration? configuration,
  }) async {
    final index = _customDatasets.indexWhere((d) => d.id == id);
    if (index == -1) {
      throw ArgumentError('Custom dataset not found: $id');
    }

    // Validate name if provided
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Dataset name cannot be empty');
    }

    // Check for duplicate names (excluding current dataset)
    if (name != null) {
      final trimmedName = name.trim();
      if (_getAllDatasets().any((d) =>
          d.id != id && d.name.toLowerCase() == trimmedName.toLowerCase())) {
        throw ArgumentError('A dataset with this name already exists');
      }
    }

    final updatedDataset = _customDatasets[index].copyWith(
      name: name?.trim(),
      configuration: configuration,
    );

    _customDatasets[index] = updatedDataset;
    await _saveCustomDatasets();

    LoggerService.info('Updated custom dataset: ${updatedDataset.name} (${updatedDataset.id})',
        context: 'CustomDatasetManager');

    return updatedDataset;
  }

  /// Delete a custom dataset
  Future<bool> deleteCustomDataset(String id) async {
    final initialCount = _customDatasets.length;
    _customDatasets.removeWhere((d) => d.id == id);

    if (_customDatasets.length < initialCount) {
      await _saveCustomDatasets();

      // If the deleted dataset was selected, clear the selection
      if (_selectedDatasetId == id) {
        _selectedDatasetId = null;
        await _prefs?.remove(_selectedDatasetKey);
      }

      LoggerService.info('Deleted custom dataset: $id', context: 'CustomDatasetManager');
      return true;
    }
    return false;
  }

  /// Get a dataset by ID (searches both custom and built-in)
  CustomDataset? getDatasetById(String id) {
    // Search custom datasets first
    for (final dataset in _customDatasets) {
      if (dataset.id == id) return dataset;
    }

    // Search built-in datasets
    for (final dataset in _builtInDatasets) {
      if (dataset.id == id) return dataset;
    }

    return null;
  }

  /// Get all datasets (built-in + custom)
  List<CustomDataset> getAllDatasets() {
    return _getAllDatasets();
  }

  List<CustomDataset> _getAllDatasets() {
    return [..._builtInDatasets, ..._customDatasets];
  }

  /// Get only custom datasets
  List<CustomDataset> getCustomDatasets() {
    return List.unmodifiable(_customDatasets);
  }

  /// Get only built-in datasets
  List<CustomDataset> getBuiltInDatasets() {
    return List.unmodifiable(_builtInDatasets);
  }

  /// Get datasets grouped by base type
  Map<DatasetType, List<CustomDataset>> getDatasetsByBaseType() {
    final Map<DatasetType, List<CustomDataset>> grouped = {};

    for (final dataset in _getAllDatasets()) {
      grouped.putIfAbsent(dataset.baseDatasetType, () => []).add(dataset);
    }

    // Sort each group: built-in first, then custom by creation date
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        if (a.isBuiltIn && !b.isBuiltIn) return -1;
        if (!a.isBuiltIn && b.isBuiltIn) return 1;
        if (!a.isBuiltIn && !b.isBuiltIn) {
          return a.createdAt.compareTo(b.createdAt);
        }
        return 0;
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

  /// Get the built-in dataset for a specific DatasetType
  CustomDataset? getBuiltInDataset(DatasetType datasetType) {
    return _builtInDatasets.firstWhere(
      (d) => d.baseDatasetType == datasetType,
      orElse: () => throw StateError('Built-in dataset not found for $datasetType'),
    );
  }

  /// Check if a dataset name is available
  bool isNameAvailable(String name, {String? excludeId}) {
    final trimmedName = name.trim().toLowerCase();
    return !_getAllDatasets().any((d) =>
        d.id != excludeId && d.name.toLowerCase() == trimmedName);
  }

  /// Clear all custom datasets (for testing)
  Future<void> clearAllCustomDatasets() async {
    _customDatasets.clear();
    _selectedDatasetId = null;
    await _prefs?.remove(_customDatasetsKey);
    await _prefs?.remove(_selectedDatasetKey);
  }
}