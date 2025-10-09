import 'dart:convert';
import 'base_service_manager.dart';
import 'logger_service.dart';

/// Mixin for services that need JSON serialization to SharedPreferences
mixin JsonServiceMixin {
  /// Save JSON data to SharedPreferences
  Future<void> saveJsonToPreferences(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await BaseServiceManager.prefs;
      final jsonString = jsonEncode(data);
      await prefs.setString(key, jsonString);
      LoggerService.debug('Saved JSON data to preferences',
        context: '$runtimeType.$key');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to save JSON to preferences',
        error: e, stackTrace: stackTrace, context: '$runtimeType.$key');
      rethrow;
    }
  }

  /// Load JSON data from SharedPreferences
  Future<Map<String, dynamic>?> loadJsonFromPreferences(String key) async {
    try {
      final prefs = await BaseServiceManager.prefs;
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        LoggerService.debug('No data found in preferences',
          context: '$runtimeType.$key');
        return null;
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      LoggerService.debug('Loaded JSON data from preferences',
        context: '$runtimeType.$key');
      return data;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load JSON from preferences',
        error: e, stackTrace: stackTrace, context: '$runtimeType.$key');
      return null;
    }
  }

  /// Save a list of JSON objects to SharedPreferences
  Future<void> saveJsonListToPreferences(String key, List<Map<String, dynamic>> dataList) async {
    try {
      final prefs = await BaseServiceManager.prefs;
      final jsonString = jsonEncode(dataList);
      await prefs.setString(key, jsonString);
      LoggerService.debug('Saved JSON list to preferences (${dataList.length} items)',
        context: '$runtimeType.$key');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to save JSON list to preferences',
        error: e, stackTrace: stackTrace, context: '$runtimeType.$key');
      rethrow;
    }
  }

  /// Load a list of JSON objects from SharedPreferences
  Future<List<Map<String, dynamic>>?> loadJsonListFromPreferences(String key) async {
    try {
      final prefs = await BaseServiceManager.prefs;
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        LoggerService.debug('No list data found in preferences',
          context: '$runtimeType.$key');
        return null;
      }

      final dataList = (jsonDecode(jsonString) as List)
          .cast<Map<String, dynamic>>();
      LoggerService.debug('Loaded JSON list from preferences (${dataList.length} items)',
        context: '$runtimeType.$key');
      return dataList;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to load JSON list from preferences',
        error: e, stackTrace: stackTrace, context: '$runtimeType.$key');
      return null;
    }
  }

  /// Clear data from SharedPreferences
  Future<void> clearPreferences(String key) async {
    try {
      final prefs = await BaseServiceManager.prefs;
      await prefs.remove(key);
      LoggerService.debug('Cleared preferences data',
        context: '$runtimeType.$key');
    } catch (e, stackTrace) {
      LoggerService.error('Failed to clear preferences',
        error: e, stackTrace: stackTrace, context: '$runtimeType.$key');
      rethrow;
    }
  }
}