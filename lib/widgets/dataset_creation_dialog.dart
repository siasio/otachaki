import 'package:flutter/material.dart';
import '../models/dataset_type.dart';
import '../models/custom_dataset.dart';
import '../models/dataset_registry.dart';
import '../services/custom_dataset_manager.dart';

class DatasetCreationDialog extends StatefulWidget {
  final DatasetType baseDatasetType;
  final CustomDatasetManager datasetManager;
  final CustomDataset? editingDataset;
  final bool allowBaseTypeSelection;

  const DatasetCreationDialog({
    super.key,
    required this.baseDatasetType,
    required this.datasetManager,
    this.editingDataset,
    this.allowBaseTypeSelection = false,
  });

  @override
  State<DatasetCreationDialog> createState() => _DatasetCreationDialogState();
}

class _DatasetCreationDialogState extends State<DatasetCreationDialog> {
  late TextEditingController _nameController;
  late DatasetType _selectedBaseType;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedBaseType = widget.baseDatasetType;
    _nameController = TextEditingController(
      text: widget.editingDataset?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.editingDataset != null;

  String _getDatasetTypeDisplayName(DatasetType type) {
    return DatasetRegistry.getBaseDisplayName(type);
  }

  String _getDatasetTypeDescription(DatasetType type) {
    switch (type) {
      case DatasetType.final9x9:
        return 'Territory scoring practice on smaller boards. Quick games for learning basics.';
      case DatasetType.final13x13:
        return 'Medium-sized board play. Balance between speed and complexity.';
      case DatasetType.final19x19:
        return 'Full-board territory evaluation. Complex positions from professional games.';
      case DatasetType.midgame19x19:
        return 'Score estimation during gameplay. Develop your reading skills mid-game.';
      case DatasetType.partialPositions:
        // This should not appear in UI, but handling it for safety
        return 'Partial board positions (hidden from UI).';
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a dataset name';
    }

    final trimmedName = value.trim();
    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedName.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(trimmedName)) {
      return 'Name contains invalid characters';
    }

    // Check if name is available (excluding current dataset when editing)
    final excludeId = _isEditing ? widget.editingDataset!.id : null;
    if (!widget.datasetManager.isNameAvailable(trimmedName, excludeId: excludeId)) {
      return 'A dataset with this name already exists';
    }

    return null;
  }

  Future<void> _createOrUpdateDataset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();

      CustomDataset result;
      if (_isEditing) {
        // Update existing dataset
        result = await widget.datasetManager.updateCustomDataset(
          id: widget.editingDataset!.id,
          name: name,
        );
      } else {
        // Create new dataset
        result = await widget.datasetManager.createCustomDataset(
          name: name,
          baseDatasetType: _selectedBaseType,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Custom Dataset' : 'Create Custom Dataset',
        style: const TextStyle(fontSize: 20),
      ),
      content: Container(
        width: isWideScreen ? 500 : double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.7,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Base Dataset Type Selection (only for new datasets when allowed)
                if (!_isEditing && widget.allowBaseTypeSelection) ...[
                  const Text(
                    'Base Dataset Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DatasetType>(
                    value: _selectedBaseType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      helperText: 'Choose which dataset type to base your custom settings on',
                    ),
                    items: DatasetRegistry.getAllDatasetTypes().map((type) {
                      return DropdownMenuItem<DatasetType>(
                        value: type,
                        child: Tooltip(
                          message: _getDatasetTypeDescription(type),
                          child: Text(
                            _getDatasetTypeDisplayName(type),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (DatasetType? value) {
                      if (value != null) {
                        setState(() {
                          _selectedBaseType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // Show description for selected base type
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getDatasetTypeDescription(_selectedBaseType),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Show base type info for editing
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Based on: ${_getDatasetTypeDisplayName(widget.editingDataset!.baseDatasetType)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Base dataset type cannot be changed when editing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Dataset Name
                const Text(
                  'Dataset Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter a descriptive name for your dataset',
                    helperText: 'This name will appear in the dataset selector',
                    errorText: _errorMessage,
                  ),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) => _createOrUpdateDataset(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createOrUpdateDataset,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create Dataset'),
        ),
      ],
    );
  }
}