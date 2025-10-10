import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dataset_type.dart';
import '../models/dataset_configuration.dart';
import '../models/custom_dataset.dart';
import '../models/global_configuration.dart';
import '../models/timer_type.dart';
import '../models/layout_type.dart';
import '../models/app_skin.dart';
import '../models/ownership_display_mode.dart';
import '../models/prediction_type.dart';
import '../models/position_type.dart';
import '../services/enhanced_configuration_manager.dart';
import '../services/global_configuration_manager.dart';
import '../widgets/enhanced_dataset_selector.dart';
import '../themes/app_theme.dart';

class EnhancedConfigScreen extends StatefulWidget {
  const EnhancedConfigScreen({super.key});

  @override
  State<EnhancedConfigScreen> createState() => _EnhancedConfigScreenState();
}

class _EnhancedConfigScreenState extends State<EnhancedConfigScreen> {
  EnhancedConfigurationManager? _configManager;
  GlobalConfigurationManager? _globalConfigManager;
  DatasetConfiguration? _currentDatasetConfig;
  GlobalConfiguration? _globalConfig;
  bool _loading = true;
  CustomDataset? _currentDataset;

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
      _configManager = await EnhancedConfigurationManager.getInstance();
      _globalConfigManager = await GlobalConfigurationManager.getInstance();
      _globalConfig = _globalConfigManager!.getConfiguration();
      _markDisplayController.text = _globalConfig!.markDisplayTimeSeconds.toString();

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

  void _onDatasetSelected(CustomDataset dataset) {
    setState(() {
      _currentDataset = dataset;
    });
    _loadDatasetConfiguration(dataset);
  }

  void _loadDatasetConfiguration(CustomDataset dataset) {
    if (_configManager == null) return;

    final config = _configManager!.getConfigurationForDataset(dataset);

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
    if (_currentDatasetConfig == null || _currentDataset == null) return;

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
    if (_configManager == null || _currentDataset == null) return;

    try {
      await _configManager!.setConfigurationForDataset(_currentDataset!, newConfig);
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
    if (_configManager == null || _currentDataset == null) return;

    try {
      await _configManager!.resetConfigurationForDataset(_currentDataset!);
      _loadDatasetConfiguration(_currentDataset!);

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

  /// Check if current dataset type is a final dataset that supports position types
  bool _isFinalDataset() {
    if (_currentDataset == null) return false;
    return _currentDataset!.baseDatasetType == DatasetType.final9x9 ||
           _currentDataset!.baseDatasetType == DatasetType.final13x13 ||
           _currentDataset!.baseDatasetType == DatasetType.final19x19;
  }

  /// Get available ownership display modes based on position type
  List<OwnershipDisplayMode> _getAvailableOwnershipModes() {
    if (!_isFinalDataset()) {
      return OwnershipDisplayMode.values;
    }

    final positionType = _currentDatasetConfig?.positionType ?? PositionType.withFilledNeutralPoints;
    if (positionType == PositionType.beforeFillingNeutralPoints) {
      // Only squares mode for "before filling" mode
      return [OwnershipDisplayMode.none, OwnershipDisplayMode.squares];
    }

    return OwnershipDisplayMode.values;
  }

  /// Get a compatible ownership mode when position type changes
  OwnershipDisplayMode _getCompatibleOwnershipMode(PositionType positionType) {
    // For "Before filling neutral points" mode, always use none (no ownership display)
    if (positionType == PositionType.beforeFillingNeutralPoints) {
      return OwnershipDisplayMode.none;
    }

    // For other modes, preserve current setting if valid
    final currentMode = _currentDatasetConfig?.ownershipDisplayMode ?? OwnershipDisplayMode.none;
    return currentMode;
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
              // Enhanced Dataset Selection
              EnhancedDatasetSelector(
                onDatasetChanged: () {
                  // Dataset was changed, reload configuration if we have a selected dataset
                  if (_currentDataset != null) {
                    _loadDatasetConfiguration(_currentDataset!);
                  }
                },
                onDatasetSelected: _onDatasetSelected,
                appSkin: currentSkin,
              ),
              const SizedBox(height: 24),

              // Dataset Settings Section
              if (_currentDataset != null) ...[
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
                        Text(
                          'Configuration for: ${_currentDataset!.name}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_currentDatasetConfig != null) ...[
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
                              if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
                                final newConfig = _currentDatasetConfig!.copyWith(
                                  predictionType: value,
                                );
                                _autoSaveDatasetConfiguration(newConfig);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Threshold fields (only show if rough lead prediction is selected)
                          if (_currentDatasetConfig!.predictionType == PredictionType.roughLeadPrediction) ...[
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
                          ],

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
                                    if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
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

                          // Position Type (only for final datasets)
                          if (_isFinalDataset()) ...[
                            DropdownButtonFormField<PositionType>(
                              value: _currentDatasetConfig!.positionType,
                              decoration: const InputDecoration(
                                labelText: 'Position Type',
                                border: OutlineInputBorder(),
                              ),
                              items: PositionType.values.map((type) {
                                return DropdownMenuItem<PositionType>(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                              onChanged: (PositionType? value) {
                                if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
                                  final newConfig = _currentDatasetConfig!.copyWith(
                                    positionType: value,
                                    // Reset ownership mode if not compatible
                                    ownershipDisplayMode: _getCompatibleOwnershipMode(value),
                                  );
                                  _autoSaveDatasetConfiguration(newConfig);
                                }
                              },
                            ),
                            const SizedBox(height: 8),

                            // Explanation text for position type
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Text(
                                _currentDatasetConfig!.positionType.explanationText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Sequence Length (hide for "with filled neutral points" mode)
                          if (!_isFinalDataset() || _currentDatasetConfig!.positionType == PositionType.beforeFillingNeutralPoints) ...[
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

                            // Show Move Numbers checkbox (only for "Before filling neutral points" mode)
                            if (_isFinalDataset() && _currentDatasetConfig!.positionType == PositionType.beforeFillingNeutralPoints) ...[
                              CheckboxListTile(
                                title: const Text('Show Move Numbers'),
                                subtitle: const Text(
                                  'Display numbers on move sequence intersections (uncheck to leave intersections empty)',
                                ),
                                value: _currentDatasetConfig!.showMoveNumbers,
                                onChanged: (bool? value) {
                                  if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
                                    final newConfig = _currentDatasetConfig!.copyWith(
                                      showMoveNumbers: value,
                                    );
                                    _autoSaveDatasetConfiguration(newConfig);
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],

                          // Ownership Display Mode (hide for "Before filling neutral points" mode)
                          if (!_isFinalDataset() || _currentDatasetConfig!.positionType != PositionType.beforeFillingNeutralPoints) ...[
                            DropdownButtonFormField<OwnershipDisplayMode>(
                            value: _currentDatasetConfig!.ownershipDisplayMode,
                            decoration: const InputDecoration(
                              labelText: 'Ownership Display Mode',
                              helperText: 'How ownership information is shown in review view',
                              border: OutlineInputBorder(),
                            ),
                            items: _getAvailableOwnershipModes().map((mode) {
                              return DropdownMenuItem<OwnershipDisplayMode>(
                                value: mode,
                                child: Text(mode.displayName),
                              );
                            }).toList(),
                            onChanged: (OwnershipDisplayMode? value) {
                              if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
                                final newConfig = _currentDatasetConfig!.copyWith(
                                  ownershipDisplayMode: value,
                                );
                                _autoSaveDatasetConfiguration(newConfig);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ],

                          // Hide Game Info Bar (hide for final datasets - controlled by position type)
                          if (!_isFinalDataset()) ...[
                            CheckboxListTile(
                              title: const Text('Hide Game Info Bar'),
                              subtitle: const Text(
                                'Hide the bar showing captured stones and komi',
                              ),
                              value: _currentDatasetConfig!.hideGameInfoBar,
                              onChanged: (bool? value) {
                                if (value != null && _currentDatasetConfig != null && _currentDataset != null) {
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Help Section
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Row(
              //           children: [
              //             const Icon(Icons.help, size: 20),
              //             const SizedBox(width: 8),
              //             const Text(
              //               'Configuration Help',
              //               style: TextStyle(
              //                 fontSize: 16,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //           ],
              //         ),
              //         const SizedBox(height: 12),
              //         const Text('• Global settings apply to the entire app'),
              //         const Text('• Dataset settings apply only to the currently selected dataset'),
              //         const Text('• Create custom datasets to save different configuration combinations'),
              //         const Text('• Changes are saved automatically as you type'),
              //         const Text('• Use refresh buttons to reset sections to default values'),
              //         const SizedBox(height: 12),
              //         Text(
              //           'Note: Dataset settings automatically update when you switch datasets.',
              //           style: TextStyle(
              //             color: (currentSkin == AppSkin.eink)
              //                 ? Colors.black
              //                 : Colors.orange[700],
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}