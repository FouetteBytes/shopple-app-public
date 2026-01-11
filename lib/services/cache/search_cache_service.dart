import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/utils/app_logger.dart';

class SearchCacheService {
  static const String _cachePrefixBase = 'search_cache_';
  static const String _queryHistoryKeyBase = 'search_query_history';
  static const Duration _cacheTimeout = Duration(minutes: 30);
  static const int _maxHistoryEntries = 50;

  static String _uid() => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  static String _cachePrefix() => '${_uid()}:$_cachePrefixBase';
  static String _queryHistoryKey() => '${_uid()}:$_queryHistoryKeyBase';
  static Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    // If user-scoped history not present but legacy global exists, migrate then remove legacy
    final legacyKey = _queryHistoryKeyBase;
    if (!prefs.containsKey(_queryHistoryKey()) &&
        prefs.containsKey(legacyKey)) {
      try {
        final legacy = prefs.getString(legacyKey);
        if (legacy != null) {
          await prefs.setString(_queryHistoryKey(), legacy);
        }
        await prefs.remove(legacyKey);
      } catch (_) {}
    }
  }

  // Cache search results using existing SharedPreferences
  static Future<void> cacheSearchResults(
    String query,
    List<Map<String, dynamic>> results,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix() + query.toLowerCase().trim();

      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'results': results,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      AppLogger.e('Error caching search results', error: e);
    }
  }

  // Get cached search results using existing SharedPreferences
  static Future<List<Map<String, dynamic>>?> getCachedSearchResults(
    String query,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix() + query.toLowerCase().trim();

      final cacheString = prefs.getString(cacheKey);
      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        cacheData['timestamp'],
      );

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) > _cacheTimeout) {
        // Remove expired cache
        await prefs.remove(cacheKey);
        return null;
      }

      return List<Map<String, dynamic>>.from(cacheData['results']);
    } catch (e) {
      AppLogger.e('Error getting cached search results', error: e);
      return null;
    }
  }

  // Save search query to history using existing SharedPreferences
  static Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateIfNeeded(prefs);
      final historyString = prefs.getString(_queryHistoryKey());

      List<String> history = [];
      if (historyString != null) {
        history = List<String>.from(jsonDecode(historyString));
      }

      // Remove if already exists
      history.remove(query);

      // Add to beginning
      history.insert(0, query);

      // Limit history size
      if (history.length > _maxHistoryEntries) {
        history = history.take(_maxHistoryEntries).toList();
      }

      // Fire-and-forget to avoid blocking main thread
      // ignore: unawaited_futures
      prefs.setString(_queryHistoryKey(), jsonEncode(history));
    } catch (e) {
      AppLogger.e('Error adding to search history', error: e);
    }
  }

  // Get search history using existing SharedPreferences
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateIfNeeded(prefs);
      final historyString = prefs.getString(_queryHistoryKey());

      if (historyString == null) return [];

      return List<String>.from(jsonDecode(historyString));
    } catch (e) {
      AppLogger.e('Error getting search history', error: e);
      return [];
    }
  }

  // Clear all caches using existing SharedPreferences
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix()) ||
            key == _queryHistoryKey() ||
            // Also clear any legacy keys
            key.startsWith(_cachePrefixBase) ||
            key == _queryHistoryKeyBase) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.e('Error clearing caches', error: e);
    }
  }

  // Get cache statistics for debugging
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int searchCaches = 0;
      int totalSize = 0;

      for (final key in keys) {
        if (key.startsWith(_cachePrefix())) {
          searchCaches++;
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }

      return {
        'searchCaches': searchCaches,
        'totalSizeBytes': totalSize,
        'hasHistory': prefs.containsKey(_queryHistoryKey()),
      };
    } catch (e) {
      AppLogger.e('Error getting cache stats', error: e);
      return {};
    }
  }
}
