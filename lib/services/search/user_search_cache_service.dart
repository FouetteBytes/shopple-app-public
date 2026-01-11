import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/utils/app_logger.dart';
import '../../models/contact_models.dart';

class CachedSearchResult {
  final List<UserSearchResult> results;
  final DateTime timestamp;

  CachedSearchResult({
    required this.results,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class UserSearchCacheService {
  static const String searchCacheKey = 'user_search_cache_v3';
  static const Duration cacheDuration = Duration(minutes: 5);

  // In-memory cache for ultra-fast repeat queries
  final Map<String, CachedSearchResult> _memoryCache = {};

  // Instant cache for single-character searches (Google-like instant results)
  final Map<String, List<UserSearchResult>> _instantCache = {};

  // Prefetch cache for common single-character searches
  final Map<String, List<UserSearchResult>> _prefetchCache = {};

  // Singleton instance
  static final UserSearchCacheService _instance = UserSearchCacheService._internal();
  static UserSearchCacheService get instance => _instance;
  UserSearchCacheService._internal();

  /// Get results from instant cache (single character)
  List<UserSearchResult>? getInstantResults(String query) {
    if (query.length == 1 && _instantCache.containsKey(query)) {
      return _instantCache[query];
    }
    return null;
  }

  /// Get results from memory cache
  List<UserSearchResult>? getMemoryResults(String query) {
    if (_memoryCache.containsKey(query)) {
      CachedSearchResult cached = _memoryCache[query]!;
      if (!cached.isExpired) {
        return cached.results;
      } else {
        _memoryCache.remove(query);
      }
    }
    return null;
  }

  /// Get results from prefetch cache
  List<UserSearchResult>? getPrefetchResults(String query) {
    if (query.length == 1 && _prefetchCache.containsKey(query)) {
      return _prefetchCache[query];
    }
    return null;
  }

  /// Find prefix matches from existing cache for instant results
  List<UserSearchResult> findPrefixMatches(String query, int limit) {
    List<UserSearchResult> matches = [];

    // Search through memory cache for partial matches
    for (String cachedQuery in _memoryCache.keys) {
      if (cachedQuery.length > query.length && cachedQuery.startsWith(query)) {
        CachedSearchResult cached = _memoryCache[cachedQuery]!;
        if (!cached.isExpired) {
          for (UserSearchResult result in cached.results) {
            // Check if this result matches our current query
            if (_resultMatchesQuery(result, query)) {
              matches.add(result);
              if (matches.length >= limit) break;
            }
          }
        }
        if (matches.length >= limit) break;
      }
    }

    return matches;
  }

  /// Check if a search result matches the given query
  bool _resultMatchesQuery(UserSearchResult result, String query) {
    String queryLower = query.toLowerCase();
    return result.name.toLowerCase().contains(queryLower) ||
        (result.email?.toLowerCase().contains(queryLower) ?? false) ||
        (result.phoneNumber?.contains(query) ?? false);
  }

  /// Cache results in memory
  void cacheInMemory(String query, List<UserSearchResult> results) {
    _memoryCache[query] = CachedSearchResult(
      results: results,
      timestamp: DateTime.now(),
    );

    // Limit memory cache size
    if (_memoryCache.length > 50) {
      String oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    // Special caching for single characters
    if (query.length == 1) {
      _instantCache[query] = results.take(50).toList();
      _prefetchCache[query] = results;
    }
  }

  /// Cache results locally
  Future<void> cacheLocally(
    String query,
    List<UserSearchResult> results,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${searchCacheKey}_${query.hashCode}';

      Map<String, dynamic> cacheData = {
        'results': results.map((r) => r.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, jsonEncode(cacheData));
    } catch (e) {
      AppLogger.w('Error caching search results: $e');
    }
  }

  /// Get locally cached results
  Future<List<UserSearchResult>?> getLocalCachedResults(
    String query,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = '${searchCacheKey}_${query.hashCode}';
      String? cached = prefs.getString(key);

      if (cached != null) {
        Map<String, dynamic> cacheData = jsonDecode(cached);
        DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(
          cacheData['timestamp'],
        );

        // Check if cache is still valid
        if (DateTime.now().difference(timestamp) < cacheDuration) {
          List<dynamic> resultsJson = cacheData['results'];
          return resultsJson
              .map((json) => UserSearchResult.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.w('Error getting cached search results: $e');
    }

    return null;
  }

  /// Clear all caches
  Future<void> clearCache() async {
    _memoryCache.clear();
    _prefetchCache.clear();
    _instantCache.clear();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> keys = prefs
          .getKeys()
          .where((key) => key.startsWith(searchCacheKey))
          .toList();
      for (String key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      AppLogger.w('Error clearing search cache: $e');
    }
  }
}
