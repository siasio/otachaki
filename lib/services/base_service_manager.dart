import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// Base class for service managers that use SharedPreferences
/// Eliminates singleton and SharedPreferences boilerplate code
abstract class BaseServiceManager<T> {
  static SharedPreferences? _prefs;
  static final Map<Type, BaseServiceManager> _instances = {};

  /// Get SharedPreferences instance (shared across all service managers)
  static Future<SharedPreferences> get prefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get singleton instance of a specific service manager
  static Future<S> getInstance<S extends BaseServiceManager>(
    S Function() createInstance,
  ) async {
    final type = S;
    if (!_instances.containsKey(type)) {
      final instance = createInstance();
      await instance._initialize();
      _instances[type] = instance;
    }
    return _instances[type] as S;
  }

  /// Initialize the service manager (called once during getInstance)
  Future<void> _initialize() async {
    try {
      await loadData();
      LoggerService.info('Service manager initialized successfully',
        context: runtimeType.toString());
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize service manager',
        error: e, stackTrace: stackTrace, context: runtimeType.toString());
      await handleInitializationError(e);
    }
  }

  /// Load data from SharedPreferences (implement in subclass)
  Future<void> loadData();

  /// Handle initialization errors (implement in subclass if needed)
  Future<void> handleInitializationError(dynamic error) async {
    // Default implementation: continue with defaults
  }

  /// Get the preferences key for this service
  String get preferencesKey;

  /// Get the service name for logging context
  String get serviceName => runtimeType.toString();
}