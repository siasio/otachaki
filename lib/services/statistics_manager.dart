import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/problem_attempt.dart';
import '../models/daily_statistics.dart';
import '../models/dataset_type.dart';

/// Manages user performance statistics with persistent storage
class StatisticsManager {
  static const String _attemptsKey = 'problem_attempts';
  static const String _dailyStatsKey = 'daily_statistics';
  static StatisticsManager? _instance;
  static SharedPreferences? _prefs;

  List<ProblemAttempt> _attempts = [];
  Map<String, DailyStatistics> _dailyStats = {};

  StatisticsManager._();

  /// Get singleton instance
  static Future<StatisticsManager> getInstance() async {
    if (_instance == null) {
      _instance = StatisticsManager._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  /// Initialize the manager and load existing data
  Future<void> _initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadAttempts();
    await _loadDailyStatistics();
  }

  /// Get the current "app day" considering 2AM reset
  DateTime getCurrentAppDay([DateTime? now]) {
    now ??= DateTime.now();

    // If it's before 2 AM, consider it the previous day
    if (now.hour < 2) {
      return DateTime(now.year, now.month, now.day - 1);
    } else {
      return DateTime(now.year, now.month, now.day);
    }
  }

  /// Record a problem attempt
  Future<void> recordAttempt({
    required DatasetType datasetType,
    required bool isCorrect,
    required int timeSpentMs,
    bool wasTimeout = false,
  }) async {
    final attempt = ProblemAttempt(
      datasetType: datasetType,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
      timestamp: DateTime.now(),
      wasTimeout: wasTimeout,
    );

    _attempts.add(attempt);

    // Update daily statistics for the current app day
    final currentDay = getCurrentAppDay();
    _updateDailyStatistics(currentDay);

    // Persist to storage
    await _saveAttempts();
    await _saveDailyStatistics();
  }

  /// Get today's statistics for all dataset types
  DailyStatistics getTodayStatistics() {
    final today = getCurrentAppDay();
    return _dailyStats[_formatDateKey(today)] ??
           DailyStatistics(date: today, datasetStats: {});
  }

  /// Get statistics for a specific dataset type for today
  DailyDatasetStatistics? getTodayStatsForDataset(DatasetType datasetType) {
    return getTodayStatistics().getStatsForDataset(datasetType);
  }

  /// Get historical statistics for a dataset type over the last N days
  List<DailyDatasetStatistics> getHistoricalStats(
    DatasetType datasetType,
    int days,
  ) {
    final List<DailyDatasetStatistics> stats = [];
    final currentDay = getCurrentAppDay();

    for (int i = 0; i < days; i++) {
      final date = currentDay.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);
      final dailyStats = _dailyStats[dateKey];
      final datasetStats = dailyStats?.getStatsForDataset(datasetType);

      if (datasetStats != null) {
        stats.add(datasetStats);
      } else {
        // Add empty stats for this day
        stats.add(DailyDatasetStatistics(
          datasetType: datasetType,
          date: date,
          totalAttempts: 0,
          correctAttempts: 0,
          totalTimeSeconds: 0.0,
          attempts: [],
        ));
      }
    }

    return stats.reversed.toList(); // Return in chronological order
  }

  /// Get all available dataset types that have been used
  Set<DatasetType> getAvailableDatasetTypes() {
    final Set<DatasetType> types = {};
    for (final stats in _dailyStats.values) {
      types.addAll(stats.activeDatasetTypes);
    }
    return types;
  }

  /// Clear all statistics (useful for testing)
  Future<void> clearAllStatistics() async {
    _attempts.clear();
    _dailyStats.clear();
    await _prefs!.remove(_attemptsKey);
    await _prefs!.remove(_dailyStatsKey);
  }

  /// Update daily statistics for a specific date
  void _updateDailyStatistics(DateTime date) {
    final dateKey = _formatDateKey(date);
    _dailyStats[dateKey] = DailyStatistics.fromAttempts(date, _attempts);
  }

  /// Load attempts from persistent storage
  Future<void> _loadAttempts() async {
    final attemptsJson = _prefs!.getString(_attemptsKey);
    if (attemptsJson != null) {
      try {
        final List<dynamic> attemptsList = json.decode(attemptsJson);
        _attempts = attemptsList
            .map((json) => ProblemAttempt.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error loading attempts: $e');
        _attempts = [];
      }
    }
  }

  /// Save attempts to persistent storage
  Future<void> _saveAttempts() async {
    try {
      final attemptsJson = json.encode(_attempts.map((a) => a.toJson()).toList());
      await _prefs!.setString(_attemptsKey, attemptsJson);
    } catch (e) {
      print('Error saving attempts: $e');
    }
  }

  /// Load daily statistics from persistent storage
  Future<void> _loadDailyStatistics() async {
    final statsJson = _prefs!.getString(_dailyStatsKey);
    if (statsJson != null) {
      try {
        final Map<String, dynamic> statsMap = json.decode(statsJson);
        _dailyStats = statsMap.map(
          (key, value) => MapEntry(
            key,
            DailyStatistics.fromJson(value as Map<String, dynamic>)
          )
        );
      } catch (e) {
        print('Error loading daily statistics: $e');
        _dailyStats = {};
        // Rebuild from attempts if available
        _rebuildDailyStatistics();
      }
    } else {
      // Build daily statistics from attempts
      _rebuildDailyStatistics();
    }
  }

  /// Save daily statistics to persistent storage
  Future<void> _saveDailyStatistics() async {
    try {
      final statsMap = _dailyStats.map(
        (key, value) => MapEntry(key, value.toJson())
      );
      final statsJson = json.encode(statsMap);
      await _prefs!.setString(_dailyStatsKey, statsJson);
    } catch (e) {
      print('Error saving daily statistics: $e');
    }
  }

  /// Rebuild daily statistics from attempts (used when loading fails)
  void _rebuildDailyStatistics() {
    _dailyStats.clear();

    // Group attempts by date
    final Map<String, List<ProblemAttempt>> attemptsByDate = {};
    for (final attempt in _attempts) {
      final appDay = getCurrentAppDay(attempt.timestamp);
      final dateKey = _formatDateKey(appDay);
      attemptsByDate.putIfAbsent(dateKey, () => []).add(attempt);
    }

    // Create daily statistics for each date
    for (final entry in attemptsByDate.entries) {
      final dateKey = entry.key;
      final attempts = entry.value;
      final date = _parseDateKey(dateKey);
      _dailyStats[dateKey] = DailyStatistics.fromAttempts(date, attempts);
    }
  }

  /// Format date as a string key for storage
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse date key back to DateTime
  DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Get total attempts count for debugging
  int get totalAttemptsCount => _attempts.length;

  /// Get daily statistics count for debugging
  int get dailyStatsCount => _dailyStats.length;
}