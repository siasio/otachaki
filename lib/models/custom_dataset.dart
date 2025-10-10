import 'dataset_type.dart';
import 'dataset_configuration.dart';
import 'dataset_registry.dart';

/// Represents a user-defined dataset with custom configuration
class CustomDataset {
  /// Unique identifier for this custom dataset
  final String id;

  /// User-given name for this dataset
  final String name;

  /// The base dataset type this custom dataset is based on
  final DatasetType baseDatasetType;

  /// Custom configuration for this dataset
  final DatasetConfiguration configuration;

  /// When this dataset was created
  final DateTime createdAt;

  const CustomDataset({
    required this.id,
    required this.name,
    required this.baseDatasetType,
    required this.configuration,
    required this.createdAt,
  });

  /// Create a new custom dataset based on a base dataset type
  /// Configuration will be inherited from the base type's defaults
  factory CustomDataset.fromBaseType({
    required String id,
    required String name,
    required DatasetType baseDatasetType,
    DateTime? createdAt,
  }) {
    return CustomDataset(
      id: id,
      name: name,
      baseDatasetType: baseDatasetType,
      configuration: DatasetConfiguration.getDefaultFor(baseDatasetType),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create a default dataset for a given type with registry name
  factory CustomDataset.defaultFor({
    required DatasetType datasetType,
    required String name,
    String? customId,
  }) {
    return CustomDataset(
      id: customId ?? 'default_${datasetType.value}',
      name: name,
      baseDatasetType: datasetType,
      configuration: DatasetConfiguration.getDefaultFor(datasetType),
      createdAt: DateTime(2024, 1, 1), // Fixed date for defaults
    );
  }

  /// Copy this dataset with updated values
  CustomDataset copyWith({
    String? id,
    String? name,
    DatasetType? baseDatasetType,
    DatasetConfiguration? configuration,
    DateTime? createdAt,
  }) {
    return CustomDataset(
      id: id ?? this.id,
      name: name ?? this.name,
      baseDatasetType: baseDatasetType ?? this.baseDatasetType,
      configuration: configuration ?? this.configuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseDatasetType': baseDatasetType.value,
      'configuration': configuration.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  static CustomDataset fromJson(Map<String, dynamic> json) {
    return CustomDataset(
      id: json['id'] as String,
      name: json['name'] as String,
      baseDatasetType: DatasetType.fromString(json['baseDatasetType'] as String)!,
      configuration: DatasetConfiguration.fromJson(json['configuration'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  /// Get display name (just the dataset name)
  String get displayName => name;

  /// Get the JSON file path for the base dataset type
  String get datasetFilePath {
    return DatasetRegistry.getAssetsPath(baseDatasetType);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomDataset &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomDataset(id: $id, name: $name, baseType: ${baseDatasetType.value})';
}