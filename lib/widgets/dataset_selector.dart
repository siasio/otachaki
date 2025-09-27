import 'package:flutter/material.dart';
import '../services/position_loader.dart';
import '../services/dataset_preference_manager.dart';
import '../models/dataset_type.dart';
import '../models/app_skin.dart';

class DatasetSelector extends StatefulWidget {
  final VoidCallback? onDatasetChanged;
  final Function(DatasetType)? onDatasetTypeChanged;
  final AppSkin appSkin;

  const DatasetSelector({
    super.key,
    this.onDatasetChanged,
    this.onDatasetTypeChanged,
    this.appSkin = AppSkin.classic,
  });

  @override
  State<DatasetSelector> createState() => _DatasetSelectorState();
}

class _DatasetSelectorState extends State<DatasetSelector> {
  DatasetType? _currentDatasetType;
  bool _loading = false;
  DatasetPreferenceManager? _preferenceManager;

  // Predefined mapping of dataset types to their files
  final Map<DatasetType, Map<String, String>> _datasetTypeToFile = {
    DatasetType.final9x9Area: {
      'filename': 'final_9x9_katago.json',
      'displayName': '9x9 Final Positions',
    },
    DatasetType.midgame19x19Estimation: {
      'filename': 'fox_mid150_19x19.json',
      'displayName': '19x19 Midgame Estimation',
    },
    // Add more mappings as needed
    // DatasetType.final19x19Area: {
    //   'filename': 'final_19x19_katago.json',
    //   'displayName': '19x19 Final Positions',
    // },
  };

  @override
  void initState() {
    super.initState();
    _initializeDataset();
  }

  Future<void> _initializeDataset() async {
    _preferenceManager = await DatasetPreferenceManager.getInstance();
    await _loadCurrentDatasetType();
  }

  Future<void> _loadCurrentDatasetType() async {
    try {
      // Get current dataset from PositionLoader
      final stats = await PositionLoader.getStatistics();
      final datasetTypeString = stats['dataset_type'] as String?;
      if (datasetTypeString != null) {
        final detectedType = DatasetType.fromString(datasetTypeString);
        if (detectedType != null) {
          setState(() {
            _currentDatasetType = detectedType;
          });
          // Notify parent of the initial dataset type
          widget.onDatasetTypeChanged?.call(detectedType);
          return;
        }
      }

      // Fallback to first available dataset
      final defaultType = _datasetTypeToFile.keys.first;
      setState(() {
        _currentDatasetType = defaultType;
      });
      // Notify parent of the default dataset type
      widget.onDatasetTypeChanged?.call(defaultType);
    } catch (e) {
      // If no dataset is loaded, default to first available
      final defaultType = _datasetTypeToFile.keys.first;
      setState(() {
        _currentDatasetType = defaultType;
      });
      // Notify parent of the default dataset type
      widget.onDatasetTypeChanged?.call(defaultType);
    }
  }

  Future<void> _selectDatasetType(DatasetType datasetType) async {
    if (_currentDatasetType == datasetType) return;

    setState(() {
      _loading = true;
    });

    try {
      final fileInfo = _datasetTypeToFile[datasetType];
      if (fileInfo != null) {
        final filename = fileInfo['filename']!;

        // Load the dataset file
        PositionLoader.setDatasetFile(filename);
        await PositionLoader.preloadDataset();

        // Save the preference
        await _preferenceManager?.setSelectedDataset('assets/$filename');

        setState(() {
          _currentDatasetType = datasetType;
          _loading = false;
        });

        // Notify parent about the change
        widget.onDatasetChanged?.call();
        widget.onDatasetTypeChanged?.call(datasetType);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${fileInfo['displayName']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dataset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDatasetTypeDisplayName(DatasetType type) {
    final fileInfo = _datasetTypeToFile[type];
    return fileInfo?['displayName'] ?? type.value;
  }

  Color _getDatasetTypeColor(DatasetType type) {
    if (widget.appSkin == AppSkin.eink) {
      // E-ink theme uses only black/white/grays
      switch (type) {
        case DatasetType.final9x9Area:
        case DatasetType.final9x9AreaVars:
          return Colors.black;
        case DatasetType.final19x19Area:
          return Colors.grey.shade700;
        case DatasetType.midgame19x19Estimation:
          return Colors.grey.shade500;
        case DatasetType.partialArea:
          return Colors.grey.shade300;
      }
    }

    // Other themes use original colors
    switch (type) {
      case DatasetType.final9x9Area:
      case DatasetType.final9x9AreaVars:
        return Colors.green;
      case DatasetType.final19x19Area:
        return Colors.blue;
      case DatasetType.midgame19x19Estimation:
        return Colors.orange;
      case DatasetType.partialArea:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Dataset Selection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_currentDatasetType != null)
              Text(
                'Current: ${_getDatasetTypeDisplayName(_currentDatasetType!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 16),

            // Dataset type buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _datasetTypeToFile.keys.map((datasetType) {
                final isSelected = _currentDatasetType == datasetType;
                final displayName = _getDatasetTypeDisplayName(datasetType);
                final color = _getDatasetTypeColor(datasetType);

                return ElevatedButton.icon(
                  onPressed: _loading ? null : () => _selectDatasetType(datasetType),
                  icon: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(displayName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? (widget.appSkin == AppSkin.eink
                            ? Colors.grey.shade200
                            : color.withOpacity(0.2))
                        : null,
                    foregroundColor: isSelected
                        ? (widget.appSkin == AppSkin.eink
                            ? Colors.black
                            : color.withOpacity(0.8))
                        : null,
                    side: isSelected
                        ? BorderSide(
                            color: widget.appSkin == AppSkin.eink
                                ? Colors.black
                                : color,
                            width: 2,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Text(
              'Select a dataset type to train on. Each type focuses on different aspects of Go territory evaluation.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}