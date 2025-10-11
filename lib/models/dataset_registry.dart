import 'dataset_type.dart';
import 'prediction_type.dart';

/// Comprehensive metadata for a dataset type including all configuration constraints
class DatasetTypeInfo {
  /// The dataset type enum value
  final DatasetType type;

  /// Display name shown in base type dropdown (e.g., "9x9 final positions")
  final String baseDisplayName;

  /// Name of the pre-defined built-in dataset (e.g., "GoQuest Arena (9x9)")
  final String builtInDatasetName;

  /// JSON file path for this dataset type
  final String jsonFilePath;

  /// Prediction types allowed for this dataset type
  final List<PredictionType> allowedPredictionTypes;

  /// Whether this is a final position dataset (affects UI options)
  final bool isFinalPositionDataset;

  /// Whether this is a middle game dataset (affects UI options)
  final bool isMiddleGameDataset;

  /// Whether this is a partial position dataset (affects UI options)
  final bool isPartialPositionDataset;

  const DatasetTypeInfo({
    required this.type,
    required this.baseDisplayName,
    required this.builtInDatasetName,
    required this.jsonFilePath,
    required this.allowedPredictionTypes,
    this.isFinalPositionDataset = false,
    this.isMiddleGameDataset = false,
    this.isPartialPositionDataset = false,
  });

  /// Convenience getter for assets path
  String get assetsPath => 'assets/$jsonFilePath';
}

/// Central registry for all dataset type metadata
/// This is the single source of truth for dataset information
class DatasetRegistry {
  static const Map<DatasetType, DatasetTypeInfo> _registry = {
    DatasetType.final9x9: DatasetTypeInfo(
      type: DatasetType.final9x9,
      baseDisplayName: '9x9 final positions',
      builtInDatasetName: 'GoQuest Arena (9x9)',
      jsonFilePath: 'final_9x9_katago.json',
      allowedPredictionTypes: [
        PredictionType.exactScorePrediction,
        PredictionType.winnerPrediction,
      ],
      isFinalPositionDataset: true,
    ),

    DatasetType.final13x13: DatasetTypeInfo(
      type: DatasetType.final13x13,
      baseDisplayName: '13x13 final positions',
      builtInDatasetName: 'Middle Ground (13x13)',
      jsonFilePath: 'final_13x13_katago.json',
      allowedPredictionTypes: [
        PredictionType.exactScorePrediction,
        PredictionType.winnerPrediction,
      ],
      isFinalPositionDataset: true,
    ),

    DatasetType.final19x19: DatasetTypeInfo(
      type: DatasetType.final19x19,
      baseDisplayName: '19x19 final positions',
      builtInDatasetName: 'Overtime Rush (19x19)',
      jsonFilePath: 'final_19x19_katago.json',
      allowedPredictionTypes: [
        PredictionType.exactScorePrediction,
        PredictionType.winnerPrediction,
      ],
      isFinalPositionDataset: true,
    ),

    DatasetType.midgame19x19: DatasetTypeInfo(
      type: DatasetType.midgame19x19,
      baseDisplayName: '19x19 middle game',
      builtInDatasetName: 'Midgame Judgment (19x19)',
      jsonFilePath: 'mid_fox_19x19.json',
      allowedPredictionTypes: [
        PredictionType.roughLeadPrediction,
        PredictionType.exactScorePrediction,
      ],
      isMiddleGameDataset: true,
    ),

    // NOTE: DatasetType.partialPositions is kept in enum but removed from registry
    // to hide it from UI while preserving code structure for future development
  };

  /// Get metadata for a specific dataset type
  static DatasetTypeInfo getInfo(DatasetType type) {
    final info = _registry[type];
    if (info == null) {
      throw ArgumentError('No metadata found for dataset type: $type');
    }
    return info;
  }

  /// Get all available dataset types (excluding hidden types)
  static List<DatasetType> getAllDatasetTypes() {
    return _registry.keys.toList();
  }

  /// Get all dataset type metadata
  static List<DatasetTypeInfo> getAllDatasetInfo() {
    return _registry.values.toList();
  }

  /// Get allowed prediction types for a dataset type
  static List<PredictionType> getAllowedPredictionTypes(DatasetType type) {
    return getInfo(type).allowedPredictionTypes;
  }

  /// Check if a prediction type is allowed for a dataset type
  static bool isPredictionTypeAllowed(DatasetType datasetType, PredictionType predictionType) {
    return getAllowedPredictionTypes(datasetType).contains(predictionType);
  }

  /// Get base display name for dropdown
  static String getBaseDisplayName(DatasetType type) {
    return getInfo(type).baseDisplayName;
  }

  /// Get built-in dataset name
  static String getBuiltInDatasetName(DatasetType type) {
    return getInfo(type).builtInDatasetName;
  }

  /// Get JSON file path
  static String getJsonFilePath(DatasetType type) {
    return getInfo(type).jsonFilePath;
  }

  /// Get assets path
  static String getAssetsPath(DatasetType type) {
    return getInfo(type).assetsPath;
  }

  /// Check if dataset type is a final position dataset
  static bool isFinalPositionDataset(DatasetType type) {
    return getInfo(type).isFinalPositionDataset;
  }

  /// Check if dataset type is a middle game dataset
  static bool isMiddleGameDataset(DatasetType type) {
    return getInfo(type).isMiddleGameDataset;
  }

  /// Check if dataset type is a partial position dataset
  static bool isPartialPositionDataset(DatasetType type) {
    return getInfo(type).isPartialPositionDataset;
  }

  /// Get all final position dataset types
  static List<DatasetType> getFinalPositionDatasetTypes() {
    return _registry.values
        .where((info) => info.isFinalPositionDataset)
        .map((info) => info.type)
        .toList();
  }

  /// Get all middle game dataset types
  static List<DatasetType> getMiddleGameDatasetTypes() {
    return _registry.values
        .where((info) => info.isMiddleGameDataset)
        .map((info) => info.type)
        .toList();
  }

  /// Get all partial position dataset types
  static List<DatasetType> getPartialPositionDatasetTypes() {
    return _registry.values
        .where((info) => info.isPartialPositionDataset)
        .map((info) => info.type)
        .toList();
  }
}