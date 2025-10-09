enum LogLevel { debug, info, warning, error }

/// Centralized logging service for consistent error handling and debugging
class LoggerService {
  static bool _isDebugMode = true; // Set to false for production

  /// Log a message with specified level
  static void log(String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    if (!_isDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}] $timestamp';
    final contextPrefix = context != null ? '[$context] ' : '';

    print('$prefix $contextPrefix$message');
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('Stack trace: $stackTrace');
  }

  /// Log debug message (only in debug mode)
  static void debug(String message, {String? context}) =>
    log(message, level: LogLevel.debug, context: context);

  /// Log info message
  static void info(String message, {String? context}) =>
    log(message, level: LogLevel.info, context: context);

  /// Log warning message
  static void warning(String message, {Object? error, String? context}) =>
    log(message, level: LogLevel.warning, error: error, context: context);

  /// Log error message with optional error object and stack trace
  static void error(String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context
  }) => log(message, level: LogLevel.error, error: error, stackTrace: stackTrace, context: context);

  /// Set debug mode (call this in main.dart based on build mode)
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }
}