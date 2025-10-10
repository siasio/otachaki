import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/custom_dataset.dart';
import '../models/app_skin.dart';
import '../services/custom_dataset_manager.dart';
import '../services/position_loader.dart';
import 'dataset_creation_dialog.dart';
import 'common/dataset_theme_utils.dart';

class StreamlinedDatasetSelector extends StatefulWidget {
  final VoidCallback? onDatasetChanged;
  final Function(CustomDataset)? onDatasetSelected;
  final AppSkin appSkin;

  const StreamlinedDatasetSelector({
    super.key,
    this.onDatasetChanged,
    this.onDatasetSelected,
    this.appSkin = AppSkin.classic,
  });

  @override
  State<StreamlinedDatasetSelector> createState() => _StreamlinedDatasetSelectorState();
}

class _StreamlinedDatasetSelectorState extends State<StreamlinedDatasetSelector> {
  CustomDatasetManager? _datasetManager;
  CustomDataset? _selectedDataset;
  bool _loading = true;
  List<CustomDataset> _allDatasets = [];

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
      // Get all datasets (built-in + custom)
      _allDatasets = _datasetManager!.getAllDatasets();

      // Load the currently selected dataset
      _selectedDataset = _datasetManager!.getSelectedDataset();

      // If no dataset is selected, default to the first built-in dataset
      if (_selectedDataset == null && _allDatasets.isNotEmpty) {
        final firstBuiltIn = _allDatasets.firstWhere(
          (dataset) => dataset.isBuiltIn,
          orElse: () => _allDatasets.first,
        );
        await _selectDataset(firstBuiltIn);
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

  Future<void> _createCustomDataset() async {
    if (_datasetManager == null) return;

    final result = await showDialog<CustomDataset>(
      context: context,
      builder: (context) => DatasetCreationDialog(
        baseDatasetType: DatasetType.final9x9, // Default, will be changeable in dialog
        datasetManager: _datasetManager!,
        allowBaseTypeSelection: true, // Enable base type selection
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
    if (_datasetManager == null || dataset.isBuiltIn) return;

    final result = await showDialog<CustomDataset>(
      context: context,
      builder: (context) => DatasetCreationDialog(
        baseDatasetType: dataset.baseDatasetType,
        datasetManager: _datasetManager!,
        editingDataset: dataset,
        allowBaseTypeSelection: false, // Don't allow changing base type when editing
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
    if (_datasetManager == null || dataset.isBuiltIn) return;

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
      final success = await _datasetManager!.deleteCustomDataset(dataset.id);
      if (success) {
        await _loadDatasets();

        // If the deleted dataset was selected, select a default one
        if (_selectedDataset?.id == dataset.id) {
          final defaultDataset = _datasetManager!.getBuiltInDataset(dataset.baseDatasetType);
          if (defaultDataset != null) {
            await _selectDataset(defaultDataset);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dataset "${dataset.name}" deleted successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }


  Widget _buildDatasetChip(CustomDataset dataset) {
    final isSelected = _selectedDataset?.id == dataset.id;
    final color = DatasetThemeUtils.getDatasetTypeColor(dataset.baseDatasetType, widget.appSkin);

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main dataset chip
          FilterChip(
            selected: isSelected,
            onSelected: _loading ? null : (_) => _selectDataset(dataset),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dataset.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (!dataset.isBuiltIn) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: isSelected
                ? DatasetThemeUtils.getSelectedBackgroundColor(dataset.baseDatasetType, widget.appSkin)
                : null,
            selectedColor: DatasetThemeUtils.getSelectedBackgroundColor(dataset.baseDatasetType, widget.appSkin),
            side: isSelected
                ? BorderSide(color: DatasetThemeUtils.getSelectedBorderColor(dataset.baseDatasetType, widget.appSkin), width: 1.5)
                : BorderSide(color: DatasetThemeUtils.getDefaultBorderColor()),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),

          // Context menu for custom datasets
          if (!dataset.isBuiltIn)
            GestureDetector(
              onTap: () => _showDatasetMenu(dataset),
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.more_vert,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDatasetMenu(CustomDataset dataset) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 16),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'edit':
          _editCustomDataset(dataset);
          break;
        case 'delete':
          _deleteCustomDataset(dataset);
          break;
      }
    });
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                // Single + button for creating new datasets
                IconButton(
                  onPressed: _loading ? null : _createCustomDataset,
                  icon: const Icon(Icons.add),
                  tooltip: 'Create custom dataset',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),

            if (_selectedDataset != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Selected: ${_selectedDataset!.name}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // All datasets in a wrapped layout
            Wrap(
              children: _allDatasets.map((dataset) => _buildDatasetChip(dataset)).toList(),
            ),

            const SizedBox(height: 8),

            // Help text
            Text(
              'Tap any dataset to select it. Built-in datasets provide default training positions. Custom datasets (marked with "C") can be edited or deleted.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}