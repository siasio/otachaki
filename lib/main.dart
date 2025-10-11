import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/training_screen.dart';
import 'services/position_manager.dart';
import 'services/global_configuration_manager.dart';
import 'services/logger_service.dart';
import 'themes/app_theme.dart';
import 'themes/theme_enforcement.dart';
import 'models/app_skin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logger based on build mode
  LoggerService.setDebugMode(kDebugMode);
  LoggerService.info('Starting Otachaki', context: 'Application');

  ThemeEnforcement.initialize();
  await PositionManager.initialize();
  runApp(const GoCountingApp());
}

class GoCountingApp extends StatefulWidget {
  const GoCountingApp({super.key});

  @override
  State<GoCountingApp> createState() => _GoCountingAppState();
}

class _GoCountingAppState extends State<GoCountingApp> {
  GlobalConfigurationManager? _globalConfigManager;
  AppSkin _currentSkin = AppSkin.classic;

  @override
  void initState() {
    super.initState();
    _loadGlobalConfiguration();
  }

  Future<void> _loadGlobalConfiguration() async {
    try {
      final manager = await GlobalConfigurationManager.getInstance();
      setState(() {
        _globalConfigManager = manager;
        _currentSkin = manager.getConfiguration().appSkin;
      });
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load global configuration in main app',
        error: e, stackTrace: stackTrace, context: 'GoCountingApp');
    }
  }

  void _onConfigurationChanged() {
    if (_globalConfigManager != null) {
      setState(() {
        _currentSkin = _globalConfigManager!.getConfiguration().appSkin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otachaki',
      theme: AppTheme.getTheme(_currentSkin),
      home: TrainingScreen(onConfigurationChanged: _onConfigurationChanged),
      debugShowCheckedModeBanner: false,
    );
  }
}