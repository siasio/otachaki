import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/global_configuration.dart';
import '../models/timer_type.dart';
import '../models/layout_type.dart';
import '../models/app_skin.dart';
import '../models/auto_advance_mode.dart';
import '../models/ownership_display_mode.dart';
import '../models/prediction_type.dart';
import '../services/configuration_manager.dart';
import '../services/global_configuration_manager.dart';
import '../services/position_loader.dart';
import '../widgets/dataset_selector.dart';
import '../themes/app_theme.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  ConfigurationManager? _configManager;
  GlobalConfigurationManager? _globalConfigManager;
  DatasetConfiguration? _currentDatasetConfig;
  GlobalConfiguration? _globalConfig;
  bool _loading = true;
  DatasetType? _currentDatasetType;

  // Global config controllers
  late TextEditingController _markDisplayController;

  // Dataset config controllers
  late TextEditingController _thresholdGoodController;
  late TextEditingController _thresholdCloseController;
  late TextEditingController _timeProblemController;
  late TextEditingController _sequenceLengthController;
  late TextEditingController _scoreGranularityController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadManagers();
  }

  void _initializeControllers() {
    // Global config controllers
    _markDisplayController = TextEditingController();
    _markDisplayController.addListener(_onGlobalConfigurationChanged);

    // Dataset config controllers
    _thresholdGoodController = TextEditingController();
    _thresholdCloseController = TextEditingController();
    _timeProblemController = TextEditingController();
    _sequenceLengthController = TextEditingController();
    _scoreGranularityController = TextEditingController();

    _thresholdGoodController.addListener(_onDatasetConfigurationChanged);
    _thresholdCloseController.addListener(_onDatasetConfigurationChanged);
    _timeProblemController.addListener(_onDatasetConfigurationChanged);
    _sequenceLengthController.addListener(_onDatasetConfigurationChanged);
    _scoreGranularityController.addListener(_onDatasetConfigurationChanged);
  }

  @override
  void dispose() {
    _markDisplayController.dispose();
    _thresholdGoodController.dispose();
    _thresholdCloseController.dispose();
    _timeProblemController.dispose();
    _sequenceLengthController.dispose();
    _scoreGranularityController.dispose();
    super.dispose();
  }

  Future<void> _loadManagers() async {
    try {
      _configManager = await ConfigurationManager.getInstance();
      _globalConfigManager = await GlobalConfigurationManager.getInstance();
      _globalConfig = _globalConfigManager!.getConfiguration();
      _markDisplayController.text = _globalConfig!.markDisplayTimeSeconds.toString();
      await _loadCurrentDatasetType();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading configuration: $e')),
        );
      }
    }
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
          if (_configManager != null) {
            _loadDatasetConfiguration(detectedType);
          }
          return;
        }
      }

      // If no dataset type in stats, fallback to first available
      final defaultType = DatasetType.final9x9Area;
      setState(() {
        _currentDatasetType = defaultType;
      });
      if (_configManager != null) {
        _loadDatasetConfiguration(defaultType);
      }
    } catch (e) {
      // Fallback to default dataset type
      final defaultType = DatasetType.final9x9Area;
      setState(() {
        _currentDatasetType = defaultType;
      });
      if (_configManager != null) {
        _loadDatasetConfiguration(defaultType);
      }
    }
  }

  void _loadDatasetConfiguration(DatasetType type) {
    if (_configManager == null) return;

    final config = _configManager!.getConfiguration(type);

    // Temporarily remove listeners to avoid triggering auto-save during loading
    _thresholdGoodController.removeListener(_onDatasetConfigurationChanged);
    _thresholdCloseController.removeListener(_onDatasetConfigurationChanged);
    _timeProblemController.removeListener(_onDatasetConfigurationChanged);
    _sequenceLengthController.removeListener(_onDatasetConfigurationChanged);
    _scoreGranularityController.removeListener(_onDatasetConfigurationChanged);

    setState(() {
      _currentDatasetConfig = config;
      _thresholdGoodController.text = config.thresholdGood.toString();
      _thresholdCloseController.text = config.thresholdClose.toString();
      _timeProblemController.text = config.timePerProblemSeconds.toString();
      _sequenceLengthController.text = config.sequenceLength.toString();
      _scoreGranularityController.text = config.scoreGranularity.toString();
    });


    // Re-add listeners after loading is complete
    _thresholdGoodController.addListener(_onDatasetConfigurationChanged);
    _thresholdCloseController.addListener(_onDatasetConfigurationChanged);
    _timeProblemController.addListener(_onDatasetConfigurationChanged);
    _sequenceLengthController.addListener(_onDatasetConfigurationChanged);
    _scoreGranularityController.addListener(_onDatasetConfigurationChanged);
  }

  void _onGlobalConfigurationChanged() {
    if (_globalConfig == null) return;

    final value = double.tryParse(_markDisplayController.text);
    if (value != null && (!_globalConfig!.markDisplayEnabled || value >= 0)) {
      final newConfig = _globalConfig!.copyWith(
        markDisplayTimeSeconds: value,
      );
      _autoSaveGlobalConfiguration(newConfig);
    }
  }

  void _onDatasetConfigurationChanged() {
    if (_currentDatasetConfig == null || _currentDatasetType == null) return;

    final thresholdGood = double.tryParse(_thresholdGoodController.text);
    final thresholdClose = double.tryParse(_thresholdCloseController.text);
    final timeProblem = int.tryParse(_timeProblemController.text);
    final sequenceLength = int.tryParse(_sequenceLengthController.text);
    final scoreGranularity = int.tryParse(_scoreGranularityController.text);

    if (thresholdGood != null &&
        thresholdClose != null &&
        timeProblem != null &&
        sequenceLength != null &&
        scoreGranularity != null &&
        thresholdClose >= thresholdGood &&
        (!_currentDatasetConfig!.timerEnabled || timeProblem > 0) &&
        sequenceLength >= 0 &&
        sequenceLength <= 50 &&
        scoreGranularity > 0) {

      final newConfig = _currentDatasetConfig!.copyWith(
        thresholdGood: thresholdGood,
        thresholdClose: thresholdClose,
        timePerProblemSeconds: timeProblem,
        sequenceLength: sequenceLength,
        scoreGranularity: scoreGranularity,
      );

      _autoSaveDatasetConfiguration(newConfig);
    }
  }

  Future<void> _autoSaveGlobalConfiguration(GlobalConfiguration newConfig) async {
    if (_globalConfigManager == null) return;

    try {
      await _globalConfigManager!.setConfiguration(newConfig);
      setState(() {
        _globalConfig = newConfig;
      });
    } catch (e) {
      _showError('Error saving global configuration: $e');
    }
  }

  Future<void> _autoSaveDatasetConfiguration(DatasetConfiguration newConfig) async {
    if (_configManager == null || _currentDatasetType == null) return;

    try {
      await _configManager!.setConfiguration(_currentDatasetType!, newConfig);
      setState(() {
        _currentDatasetConfig = newConfig;
      });
    } catch (e) {
      // Silently handle validation errors during typing
    }
  }

  Future<void> _resetGlobalConfiguration() async {
    if (_globalConfigManager == null) return;

    try {
      await _globalConfigManager!.resetConfiguration();
      final resetConfig = GlobalConfiguration.defaultConfig;
      setState(() {
        _globalConfig = resetConfig;
        _markDisplayController.text = resetConfig.markDisplayTimeSeconds.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Global configuration reset to defaults')),
        );
      }
    } catch (e) {
      _showError('Error resetting global configuration: $e');
    }
  }

  Future<void> _resetDatasetConfiguration() async {
    if (_configManager == null || _currentDatasetType == null) return;

    try {
      await _configManager!.resetConfiguration(_currentDatasetType!);
      _loadDatasetConfiguration(_currentDatasetType!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dataset configuration reset to defaults')),
        );
      }
    } catch (e) {
      _showError('Error resetting dataset configuration: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _onDatasetChanged() async {
    // Reload current dataset type when dataset is changed
    await _loadCurrentDatasetType();
  }

  void _onDatasetTypeChanged(DatasetType datasetType) {
    // Directly update dataset type when notified by selector
    setState(() {
      _currentDatasetType = datasetType;
    });
    // Immediately load dataset configuration
    if (_configManager != null) {
      _loadDatasetConfiguration(datasetType);
    }
  }

  String _getTimerTypeDisplayName(TimerType type) {
    switch (type) {
      case TimerType.smooth:
        return 'Smooth Progress Bar';
      case TimerType.segmented:
        return 'Segmented Bar';
    }
  }

  String _getLayoutTypeDisplayName(LayoutType type) {
    switch (type) {
      case LayoutType.vertical:
        return 'Vertical Layout';
      case LayoutType.horizontal:
        return 'Horizontal Layout';
    }
  }

  String _getAppSkinDisplayName(AppSkin skin) {
    switch (skin) {
      case AppSkin.classic:
        return 'Classic Wood';
      case AppSkin.modern:
        return 'Modern Dark';
      case AppSkin.ocean:
        return 'Ocean Blue';
      case AppSkin.eink:
        return 'E-ink Minimalist';
    }
  }

  String _getAutoAdvanceModeDisplayName(AutoAdvanceMode mode) {
    return mode.displayName;
  }

  String _getDatasetDisplayName(DatasetType type) {
    switch (type) {
      case DatasetType.final9x9Area:
        return 'Final 9x9 Area';
      case DatasetType.final19x19Area:
        return 'Final 19x19 Area';
      case DatasetType.midgame19x19Estimation:
        return 'Midgame 19x19 Estimation';
      case DatasetType.final9x9AreaVars:
        return 'Final 9x9 Area Variations';
      case DatasetType.partialArea:
        return 'Partial Area';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply current theme
    final currentSkin = _globalConfig?.appSkin ?? AppSkin.classic;
    final currentTheme = AppTheme.getTheme(currentSkin);

    if (_loading) {
      return Theme(
        data: currentTheme,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dataset Selection
              DatasetSelector(
                onDatasetChanged: _onDatasetChanged,
                onDatasetTypeChanged: _onDatasetTypeChanged,
                appSkin: currentSkin,
              ),
              const SizedBox(height: 24),

              // Dataset Settings Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Dataset Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _resetDatasetConfiguration,
                            tooltip: 'Reset to defaults',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_currentDatasetType != null)
                        Text(
                          'Configuration for: ${_getDatasetDisplayName(_currentDatasetType!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 16),

                      if (_currentDatasetConfig != null) ...[
                        // Threshold Good
                        TextFormField(
                          controller: _thresholdGoodController,
                          decoration: const InputDecoration(
                            labelText: 'Threshold for Good Position',
                            helperText: 'Score difference to consider position as good for one color',
                            border: OutlineInputBorder(),
                            suffix: Text('points'),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Threshold Close
                        TextFormField(
                          controller: _thresholdCloseController,
                          decoration: const InputDecoration(
                            labelText: 'Threshold for Close Position',
                            helperText: 'Score difference to consider position as close (must be ≥ good threshold)',
                            border: OutlineInputBorder(),
                            suffix: Text('points'),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Time per Problem with enable checkbox
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _timeProblemController,
                                enabled: _currentDatasetConfig!.timerEnabled,
                                decoration: InputDecoration(
                                  labelText: 'Time per Problem (uncheck to disable)',
                                  helperText: 'Time allowed to solve one problem',
                                  border: const OutlineInputBorder(),
                                  suffix: const Text('seconds'),
                                  filled: !_currentDatasetConfig!.timerEnabled,
                                  fillColor: !_currentDatasetConfig!.timerEnabled ? Colors.grey[100] : null,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56, // Match the height of the TextFormField
                              child: Checkbox(
                                value: _currentDatasetConfig!.timerEnabled,
                                onChanged: (bool? value) {
                                  if (value != null && _currentDatasetConfig != null && _currentDatasetType != null) {
                                    final newConfig = _currentDatasetConfig!.copyWith(
                                      timerEnabled: value,
                                    );
                                    _autoSaveDatasetConfiguration(newConfig);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sequence Length
                        TextFormField(
                          controller: _sequenceLengthController,
                          decoration: const InputDecoration(
                            labelText: 'Move Sequence Length',
                            helperText: 'Number of recent moves to show as numbered sequence (0-50, 0 = disabled)',
                            border: OutlineInputBorder(),
                            suffix: Text('moves'),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Prediction Type
                        DropdownButtonFormField<PredictionType>(
                          value: _currentDatasetConfig!.predictionType,
                          decoration: const InputDecoration(
                            labelText: 'Button Type',
                            helperText: 'Type of buttons to display for answers',
                            border: OutlineInputBorder(),
                          ),
                          items: PredictionType.values.map((type) {
                            return DropdownMenuItem<PredictionType>(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (PredictionType? value) {
                            if (value != null && _currentDatasetConfig != null && _currentDatasetType != null) {
                              final newConfig = _currentDatasetConfig!.copyWith(
                                predictionType: value,
                              );
                              _autoSaveDatasetConfiguration(newConfig);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Score Granularity (only show if exact score prediction is selected)
                        if (_currentDatasetConfig!.predictionType == PredictionType.exactScorePrediction) ...[
                          TextFormField(
                            controller: _scoreGranularityController,
                            decoration: const InputDecoration(
                              labelText: 'Score Granularity',
                              helperText: 'Point difference between score options',
                              border: OutlineInputBorder(),
                              suffix: Text('points'),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ownership Display Mode
                        DropdownButtonFormField<OwnershipDisplayMode>(
                          value: _currentDatasetConfig!.ownershipDisplayMode,
                          decoration: const InputDecoration(
                            labelText: 'Ownership Display Mode',
                            helperText: 'How ownership information is shown in review view',
                            border: OutlineInputBorder(),
                          ),
                          items: OwnershipDisplayMode.values.map((mode) {
                            return DropdownMenuItem<OwnershipDisplayMode>(
                              value: mode,
                              child: Text(mode.displayName),
                            );
                          }).toList(),
                          onChanged: (OwnershipDisplayMode? value) {
                            if (value != null && _currentDatasetConfig != null && _currentDatasetType != null) {
                              final newConfig = _currentDatasetConfig!.copyWith(
                                ownershipDisplayMode: value,
                              );
                              _autoSaveDatasetConfiguration(newConfig);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Hide Game Info Bar
                        CheckboxListTile(
                          title: const Text('Hide Game Info Bar'),
                          subtitle: const Text(
                            'Hide the bar showing captured stones and komi',
                          ),
                          value: _currentDatasetConfig!.hideGameInfoBar,
                          onChanged: (bool? value) {
                            if (value != null && _currentDatasetConfig != null && _currentDatasetType != null) {
                              final newConfig = _currentDatasetConfig!.copyWith(
                                hideGameInfoBar: value,
                              );
                              _autoSaveDatasetConfiguration(newConfig);
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Global Settings Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Global Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _resetGlobalConfiguration,
                            tooltip: 'Reset to defaults',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mark Display Time with enable checkbox
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _markDisplayController,
                              enabled: _globalConfig!.markDisplayEnabled,
                              decoration: InputDecoration(
                                labelText: 'Mark Display Time (uncheck to disable)',
                                helperText: 'Time to show result before next problem',
                                border: const OutlineInputBorder(),
                                suffix: const Text('seconds'),
                                filled: !_globalConfig!.markDisplayEnabled,
                                fillColor: !_globalConfig!.markDisplayEnabled ? Colors.grey[100] : null,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56, // Match the height of the TextFormField
                            child: Checkbox(
                              value: _globalConfig!.markDisplayEnabled,
                              onChanged: (bool? value) {
                                if (value != null && _globalConfig != null) {
                                  final newConfig = _globalConfig!.copyWith(
                                    markDisplayEnabled: value,
                                  );
                                  _autoSaveGlobalConfiguration(newConfig);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Timer Type
                      DropdownButtonFormField<TimerType>(
                        initialValue: _globalConfig?.timerType,
                        decoration: const InputDecoration(
                          labelText: 'Timer Type',
                          border: OutlineInputBorder(),
                        ),
                        items: TimerType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTimerTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (TimerType? newType) {
                          if (newType != null && _globalConfig != null) {
                            final newConfig = _globalConfig!.copyWith(timerType: newType);
                            _autoSaveGlobalConfiguration(newConfig);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Layout Type
                      DropdownButtonFormField<LayoutType>(
                        initialValue: _globalConfig?.layoutType,
                        decoration: const InputDecoration(
                          labelText: 'Layout Type',
                          border: OutlineInputBorder(),
                        ),
                        items: LayoutType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getLayoutTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (LayoutType? newType) {
                          if (newType != null && _globalConfig != null) {
                            final newConfig = _globalConfig!.copyWith(layoutType: newType);
                            _autoSaveGlobalConfiguration(newConfig);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // App Skin
                      DropdownButtonFormField<AppSkin>(
                        initialValue: _globalConfig?.appSkin,
                        decoration: const InputDecoration(
                          labelText: 'App Skin',
                          border: OutlineInputBorder(),
                        ),
                        items: AppSkin.values.map((skin) {
                          return DropdownMenuItem(
                            value: skin,
                            child: Text(_getAppSkinDisplayName(skin)),
                          );
                        }).toList(),
                        onChanged: (AppSkin? newSkin) {
                          if (newSkin != null && _globalConfig != null) {
                            final newConfig = _globalConfig!.copyWith(appSkin: newSkin);
                            _autoSaveGlobalConfiguration(newConfig);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto Advance Mode
                      DropdownButtonFormField<AutoAdvanceMode>(
                        initialValue: _globalConfig?.autoAdvanceMode,
                        decoration: const InputDecoration(
                          labelText: 'Auto Advance Mode',
                          helperText: 'When to auto-advance to the next problem',
                          border: OutlineInputBorder(),
                        ),
                        items: AutoAdvanceMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(_getAutoAdvanceModeDisplayName(mode)),
                          );
                        }).toList(),
                        onChanged: (AutoAdvanceMode? newMode) {
                          if (newMode != null && _globalConfig != null) {
                            final newConfig = _globalConfig!.copyWith(autoAdvanceMode: newMode);
                            _autoSaveGlobalConfiguration(newConfig);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Help Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.help, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Configuration Help',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('• Global settings apply to the entire app'),
                      const Text('• Dataset settings apply only to the currently selected dataset'),
                      const Text('• Changes are saved automatically as you type'),
                      const Text('• Use refresh buttons to reset sections to default values'),
                      const SizedBox(height: 12),
                      Text(
                        'Note: Dataset settings automatically update when you switch datasets.',
                        style: TextStyle(
                          color: (currentSkin == AppSkin.eink)
                              ? Colors.black
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}