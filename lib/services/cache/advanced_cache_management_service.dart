import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shopple/utils/app_logger.dart';

class AdvancedCacheManagementService {
  static const String _cacheMetadataKey = 'shopple_profile_cache_metadata';
  static const Duration _defaultCacheDuration = Duration(days: 7);

  /// Cache a profile picture with metadata
  static Future<void> cacheProfilePicture({
    required String userId,
    required String imageUrl,
    String? imageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final cacheKey = _generateCacheKey(userId, imageUrl);

      // Store metadata
      await _storeCacheMetadata(cacheKey, {
        'userId': userId,
        'imageUrl': imageUrl,
        'imageType': imageType,
        'cachedAt': DateTime.now().toIso8601String(),
        'lastAccessed': DateTime.now().toIso8601String(),
        'metadata': metadata,
      });

      AppLogger.d('Cached profile picture metadata for user: $userId');
    } catch (e) {
      AppLogger.e('Error caching profile picture', error: e);
    }
  }

  /// Check if profile picture is cached (using cached_network_image's cache)
  static Future<bool> isProfilePictureCached({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      final cacheKey = _generateCacheKey(userId, imageUrl);
      final metadata = await _getAllCacheMetadata();

      if (metadata.containsKey(cacheKey)) {
        final cachedAt = DateTime.parse(metadata[cacheKey]['cachedAt']);
        final isExpired =
            DateTime.now().difference(cachedAt) > _defaultCacheDuration;

        if (isExpired) {
          await _removeCacheMetadata(cacheKey);
          return false;
        }

        // Update last accessed time
        await _updateLastAccessed(cacheKey);
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.e('Error checking cache status', error: e);
      return false;
    }
  }

  /// Track image access for analytics
  static Future<void> trackImageAccess({
    required String userId,
    required String imageUrl,
    required String context,
  }) async {
    try {
      final cacheKey = _generateCacheKey(userId, imageUrl);
      await _updateAccessMetadata(cacheKey, {
        'lastAccessed': DateTime.now().toIso8601String(),
        'accessContext': context,
      });
    } catch (e) {
      AppLogger.e('Error tracking image access', error: e);
    }
  }

  /// Clear cache for specific user
  static Future<void> clearUserCache(String userId) async {
    try {
      final metadata = await _getAllCacheMetadata();
      final updatedMetadata = <String, dynamic>{};

      for (String key in metadata.keys) {
        final meta = metadata[key];
        if (meta['userId'] != userId) {
          updatedMetadata[key] = meta;
        }
      }

      await _saveAllCacheMetadata(updatedMetadata);
      AppLogger.d('Cleared cache metadata for user: $userId');
    } catch (e) {
      AppLogger.e('Error clearing user cache', error: e);
    }
  }

  /// Clear old cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final metadata = await _getAllCacheMetadata();
      final updatedMetadata = <String, dynamic>{};
      final now = DateTime.now();

      for (String key in metadata.keys) {
        final meta = metadata[key];
        final cachedAt = DateTime.parse(meta['cachedAt']);

        if (now.difference(cachedAt) <= _defaultCacheDuration) {
          updatedMetadata[key] = meta;
        }
      }

      await _saveAllCacheMetadata(updatedMetadata);
      AppLogger.d('Cleared expired cache entries');
    } catch (e) {
      AppLogger.e('Error clearing expired cache', error: e);
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final metadata = await _getAllCacheMetadata();

      int totalEntries = metadata.length;
      int expiredEntries = 0;
      final now = DateTime.now();

      for (var meta in metadata.values) {
        final cachedAt = DateTime.parse(meta['cachedAt']);
        if (now.difference(cachedAt) > _defaultCacheDuration) {
          expiredEntries++;
        }
      }

      return {
        'totalEntries': totalEntries,
        'activeEntries': totalEntries - expiredEntries,
        'expiredEntries': expiredEntries,
        'lastChecked': DateTime.now().toIso8601String(),
        'cacheEfficiency': totalEntries > 0
            ? ((totalEntries - expiredEntries) / totalEntries * 100)
                  .toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      AppLogger.e('Error getting cache statistics', error: e);
      return {};
    }
  }

  /// Get user's cache usage
  static Future<Map<String, dynamic>> getUserCacheUsage(String userId) async {
    try {
      final metadata = await _getAllCacheMetadata();
      final userEntries = <Map<String, dynamic>>[];

      for (var entry in metadata.entries) {
        if (entry.value['userId'] == userId) {
          userEntries.add({
            'key': entry.key,
            'imageUrl': entry.value['imageUrl'],
            'imageType': entry.value['imageType'],
            'cachedAt': entry.value['cachedAt'],
            'lastAccessed': entry.value['lastAccessed'],
          });
        }
      }

      return {
        'userId': userId,
        'totalCachedImages': userEntries.length,
        'cacheEntries': userEntries,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('Error getting user cache usage', error: e);
      return {'userId': userId, 'totalCachedImages': 0, 'cacheEntries': []};
    }
  }

  /// Clear all profile picture cache metadata
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheMetadataKey);
      AppLogger.d('Cleared all profile picture cache metadata');
    } catch (e) {
      AppLogger.e('Error clearing all cache', error: e);
    }
  }

  /// Generate unique cache key (simple hash-like approach)
  static String _generateCacheKey(String userId, String imageUrl) {
    final combined = '$userId:$imageUrl';
    return 'profile_${combined.hashCode.abs()}';
  }

  /// Store cache metadata
  static Future<void> _storeCacheMetadata(
    String key,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final allMetadata = await _getAllCacheMetadata();
      allMetadata[key] = metadata;
      await _saveAllCacheMetadata(allMetadata);
    } catch (e) {
      AppLogger.e('Error storing cache metadata', error: e);
    }
  }

  /// Get all cache metadata
  static Future<Map<String, dynamic>> _getAllCacheMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_cacheMetadataKey);

      if (metadataJson != null) {
        return Map<String, dynamic>.from(jsonDecode(metadataJson));
      }
    } catch (e) {
      AppLogger.e('Error getting cache metadata', error: e);
    }
    return {};
  }

  /// Save all cache metadata
  static Future<void> _saveAllCacheMetadata(
    Map<String, dynamic> metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheMetadataKey, jsonEncode(metadata));
    } catch (e) {
      AppLogger.e('Error saving cache metadata', error: e);
    }
  }

  /// Remove cache metadata
  static Future<void> _removeCacheMetadata(String key) async {
    try {
      final allMetadata = await _getAllCacheMetadata();
      allMetadata.remove(key);
      await _saveAllCacheMetadata(allMetadata);
    } catch (e) {
      AppLogger.e('Error removing cache metadata', error: e);
    }
  }

  /// Update last accessed time
  static Future<void> _updateLastAccessed(String key) async {
    try {
      final allMetadata = await _getAllCacheMetadata();
      if (allMetadata.containsKey(key)) {
        allMetadata[key]['lastAccessed'] = DateTime.now().toIso8601String();
        await _saveAllCacheMetadata(allMetadata);
      }
    } catch (e) {
      AppLogger.e('Error updating last accessed', error: e);
    }
  }

  /// Update access metadata
  static Future<void> _updateAccessMetadata(
    String key,
    Map<String, dynamic> updates,
  ) async {
    try {
      final allMetadata = await _getAllCacheMetadata();
      if (allMetadata.containsKey(key)) {
        allMetadata[key].addAll(updates);
        await _saveAllCacheMetadata(allMetadata);
      }
    } catch (e) {
      AppLogger.e('Error updating access metadata', error: e);
    }
  }
}
