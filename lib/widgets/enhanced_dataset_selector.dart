import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/custom_dataset.dart';
import '../models/app_skin.dart';
import '../models/dataset_registry.dart';
import '../services/custom_dataset_manager.dart';
import '../services/position_loader.dart';
import 'dataset_creation_dialog.dart';
import 'common/dataset_theme_utils.dart';

class EnhancedDatasetSelector extends StatefulWidget {
  final VoidCallback? onDatasetChanged;
  final Function(CustomDataset)? onDatasetSelected;
  final AppSkin appSkin;

  const EnhancedDatasetSelector({
    super.key,
    this.onDatasetChanged,
    this.onDatasetSelected,
    this.appSkin = AppSkin.classic,
  });

  @override
  State<EnhancedDatasetSelector> createState() => _EnhancedDatasetSelectorState();
}

class _EnhancedDatasetSelectorState extends State<EnhancedDatasetSelector> {
  CustomDatasetManager? _datasetManager;
  CustomDataset? _selectedDataset;
  bool _loading = true;
  Map<DatasetType, List<CustomDataset>> _groupedDatasets = {};

  @override
  void initState() {
    super.initState();
    _initializeDatasets();
  }

  Future<void> _initializeDatasets() async {
    try {
      _datasetManager = await CustomDatasetManager.getInstance();
      await _loadDatasets();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading datasets: $e')),
        );
      }
    }
  }

  Future<void> _loadDatasets() async {
    if (_datasetManager == null) return;

    setState(() {
      _loading = true;
    });

    try {
      // Get all datasets grouped by base type
      _groupedDatasets = _datasetManager!.getDatasetsByBaseType();

      // Load the currently selected dataset
      _selectedDataset = _datasetManager!.getSelectedDataset();

      // If no dataset is selected, default to the first dataset
      if (_selectedDataset == null && _groupedDatasets.isNotEmpty) {
        final firstType = _groupedDatasets.keys.first;
        final firstDataset = _groupedDatasets[firstType]?.first;
        if (firstDataset != null) {
          await _selectDataset(firstDataset);
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading datasets: $e')),
        );
      }
    }
  }

  Future<void> _selectDataset(CustomDataset dataset) async {
    if (_selectedDataset?.id == dataset.id) return;

    setState(() {
      _loading = true;
    });

    try {
      // Load the dataset file
      PositionLoader.setDatasetFile(dataset.datasetFilePath.replaceFirst('assets/', ''));
      await PositionLoader.preloadDataset();

      // Save the selection
      await _datasetManager?.setSelectedDataset(dataset.id);

      setState(() {
        _selectedDataset = dataset;
        _loading = false;
      });

      // Notify parent components
      widget.onDatasetChanged?.call();
      widget.onDatasetSelected?.call(dataset);
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

  Future<void> _createCustomDataset(DatasetType baseType) async {
    if (_datasetManager == null) return;

    final result = await showDialog<CustomDataset>(
      context: context,
      builder: (context) => DatasetCreationDialog(
        baseDatasetType: baseType,
        datasetManager: _datasetManager!,
      ),
    );

    if (result != null) {
      // Reload datasets to include the new one
      await _loadDatasets();

      // Automatically select the new dataset
      await _selectDataset(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom dataset "${result.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editCustomDataset(CustomDataset dataset) async {
    if (_datasetManager == null) return;

    final result = await showDialog<CustomDataset>(
      context: context,
      builder: (context) => DatasetCreationDialog(
        baseDatasetType: dataset.baseDatasetType,
        datasetManager: _datasetManager!,
        editingDataset: dataset,
      ),
    );

    if (result != null) {
      await _loadDatasets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dataset "${result.name}" updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomDataset(CustomDataset dataset) async {
    if (_datasetManager == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Dataset'),
        content: Text(
          'Are you sure you want to delete "${dataset.name}"?\n\nThis action cannot be undone and all performance statistics for this dataset will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _datasetManager!.deleteCustomDataset(dataset.id);
        if (success) {
          await _loadDatasets();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Dataset "${dataset.name}" deleted successfully'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot delete dataset: ${e.toString().replaceFirst('ArgumentError: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDatasetTypeDisplayName(DatasetType type) {
    return DatasetRegistry.getBaseDisplayName(type);
  }


  Widget _buildDatasetButton(CustomDataset dataset, {bool showActions = true}) {
    final isSelected = _selectedDataset?.id == dataset.id;
    final color = DatasetThemeUtils.getDatasetTypeColor(dataset.baseDatasetType, widget.appSkin);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : () => _selectDataset(dataset),
              icon: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              label: Row(
                children: [
                  Expanded(
                    child: Text(
                      dataset.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? DatasetThemeUtils.getSelectedBackgroundColor(dataset.baseDatasetType, widget.appSkin)
                    : null,
                foregroundColor: isSelected
                    ? DatasetThemeUtils.getSelectedForegroundColor(dataset.baseDatasetType, widget.appSkin)
                    : null,
                side: isSelected
                    ? BorderSide(
                        color: DatasetThemeUtils.getSelectedBorderColor(dataset.baseDatasetType, widget.appSkin),
                        width: 2,
                      )
                    : null,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    _editCustomDataset(dataset);
                    break;
                  case 'delete':
                    _deleteCustomDataset(dataset);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatasetTypeSection(DatasetType type, List<CustomDataset> datasets) {
    final color = DatasetThemeUtils.getDatasetTypeColor(type, widget.appSkin);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDatasetTypeDisplayName(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => _createCustomDataset(type),
                  icon: const Icon(Icons.add),
                  tooltip: 'Create custom dataset based on ${_getDatasetTypeDisplayName(type)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...datasets.map((dataset) => _buildDatasetButton(dataset)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading datasets...'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Dataset Selection',
                  style: TextStyle(
                    fontSize: 18,
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
          ),
        ),
        const SizedBox(height: 8),


        // Dataset type sections
        ..._groupedDatasets.entries.map((entry) =>
          _buildDatasetTypeSection(entry.key, entry.value)
        ),

        // Help text
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tips',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Built-in datasets provide default training positions'),
                Text('• Create custom datasets to save your preferred settings'),
                Text('• Use the + button to create variations of any base dataset'),
                Text('• Custom datasets can be edited or deleted using the menu'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}