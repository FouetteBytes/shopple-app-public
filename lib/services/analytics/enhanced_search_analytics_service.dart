import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

// Top-level helper so models below can use it without referencing service internals
Map<String, dynamic> coerceToStringKeyedMap(dynamic source) {
  final out = <String, dynamic>{};
  if (source is Map) {
    for (final entry in source.entries) {
      final String key = entry.key?.toString() ?? '';
      if (key.isEmpty) continue;
      final value = entry.value;
      if (value is Map) {
        out[key] = coerceToStringKeyedMap(value);
      } else if (value is List) {
        out[key] = value.map((e) {
          if (e is Map) return coerceToStringKeyedMap(e);
          return e;
        }).toList();
      } else {
        out[key] = value;
      }
    }
  }
  return out;
}

class EnhancedSearchAnalyticsService {
  static const String _personalizedProductsCacheKey =
      'personalized_products_cache';
  static const String _lastPersonalizationUpdate =
      'last_personalization_update';
  static const String _cacheVersionKey = 'personalized_cache_version';
  // Cache version constant retained for compatibility (not used when disabled)

  static final String _sessionId = _generateSessionId();
  static DateTime? _sessionStart;
  // Broadcast personalization updates so UI can react dynamically
  static final StreamController<PersonalizedSearchData>
  _personalizationUpdatesController =
      StreamController<PersonalizedSearchData>.broadcast();

  static Stream<PersonalizedSearchData> get personalizationUpdates =>
      _personalizationUpdatesController.stream;

  // -- Helpers -------------------------------------------------------------
  // Safely coerce any Map with arbitrary key types into a Map<String, dynamic>.
  // Recursively converts nested maps and lists.

  static String _generateSessionId() {
    final random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        random.nextInt(10000).toString();
  }

  // Development fallback when App Check is failing (disabled)

  // ✅ Track search events with intelligent analytics
  static Future<void> trackSearchEvent({
    required String query,
    required int resultCount,
    Map<String, dynamic>? selectedFilters,
  }) async {
    // No-op to avoid cloud costs.
  }

  // ✅ Get user's personalized default products (most searched)
  // Strategy: Cache-first to reduce App Check pressure, then network with fallback
  static Future<PersonalizedSearchData> getUserPersonalizedDefaults() async {
    // Personalization disabled to save costs
    if (kDebugMode) {
      AppLogger.w('🛑 [PERSONALIZATION] Disabled - returning empty defaults');
    }
    return PersonalizedSearchData.empty();
  }

  // Impl disabled

  // Background refresh to update cache without blocking UI or using App Check tokens aggressively
  // Background refresh disabled

  // ✅ Fast Cloud Functions-powered search
  static Future<List<ProductWithPrices>> performCloudSearch({
    required String query,
    Map<String, dynamic> filters = const {},
    int limit = 20,
  }) async {
    // Route to local search only to avoid cloud costs
    final results = await EnhancedProductService.searchProductsWithPrices(
      query,
    );
    if (limit > 0 && results.length > limit) {
      return results.take(limit).toList();
    }
    return results;
  }

  // ✅ Get real-time search suggestions based on user patterns
  static Future<List<String>> getPersonalizedSuggestions(String query) async {
    // Disabled: rely on local autocomplete service elsewhere in the app
    return [];
  }

  // ✅ Cache management for offline support
  // Caching disabled

  // Cache read disabled

  // Force refresh personalized data from Firebase
  static Future<PersonalizedSearchData?> forceRefreshPersonalizedData() async {
    await _clearPersonalizedCache();
    return getUserPersonalizedDefaults();
  }

  static Future<void> _clearPersonalizedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_personalizedProductsCacheKey);
      await prefs.remove(_lastPersonalizationUpdate);
      await prefs.remove(_cacheVersionKey);
    } catch (e, st) {
      AppLogger.e(
        'Error clearing personalized cache',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Public: clear cached personalization so UI reflects latest server state
  static Future<void> clearPersonalizedCache() async {
    await _clearPersonalizedCache();
  }

  // Public: clear cache then fetch fresh personalized defaults
  static Future<PersonalizedSearchData>
  forceRefreshPersonalizedDefaults() async {
    await _clearPersonalizedCache();
    final data = await getUserPersonalizedDefaults();
    // Ensure listeners are updated immediately
    _personalizationUpdatesController.add(data);
    return data;
  }

  // Optional dev helper: reset server-side search analytics for current user
  // Requires a callable function 'clearUserSearchAnalyticsV2' to exist on backend.
  static Future<bool> resetServerSearchAnalyticsForDev() async => false;

  // Clear all user analytics and force fresh recommendations
  static Future<bool> clearAllUserAnalytics() async {
    // Local-only clear; no server interaction
    await _clearPersonalizedCache();
    _personalizationUpdatesController.add(PersonalizedSearchData.empty());
    return true;
  }

  // 🎯 COMPREHENSIVE ANALYTICS METHODS

  /// Initialize session tracking
  static void initializeSession() {
    _sessionStart = DateTime.now();
    AppLogger.d('🎯 Analytics session started: $_sessionId');
  }

  /// Track comprehensive user behavior event
  static Future<bool> trackUserBehavior({
    required String eventType,
    String? productId,
    String? productName,
    String? searchQuery,
    int? timeSpent,
    Map<String, dynamic>? interactionData,
  }) async {
    // Disabled to avoid cloud calls
    return false;
  }

  /// Track product view with detailed metrics
  static Future<bool> trackProductView({
    required String productId,
    required String productName,
    required int timeSpent,
    String? category,
    String? brand,
    String? searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    return await trackUserBehavior(
      eventType: 'product_view',
      productId: productId,
      productName: productName,
      timeSpent: timeSpent,
      searchQuery: searchQuery,
      interactionData: {
        'category': category,
        'brand': brand,
        'viewStartTime': DateTime.now()
            .subtract(Duration(milliseconds: timeSpent))
            .toIso8601String(),
        'viewEndTime': DateTime.now().toIso8601String(),
        ...?additionalData,
      },
    );
  }

  /// Track product interaction (click, scroll, image view, etc.)
  static Future<bool> trackProductInteraction({
    required String productId,
    required String interactionType,
    String? productName,
    Map<String, dynamic>? interactionData,
  }) async {
    return await trackUserBehavior(
      eventType: 'product_interaction',
      productId: productId,
      productName: productName,
      interactionData: {
        'type': interactionType,
        'timestamp': DateTime.now().toIso8601String(),
        'data': interactionData,
      },
    );
  }

  /// Track price checking behavior
  static Future<bool> trackPriceCheck({
    required String productId,
    String? supermarket,
    double? price,
    String? comparisonType,
  }) async {
    return await trackUserBehavior(
      eventType: 'price_check',
      productId: productId,
      interactionData: {
        'supermarket': supermarket,
        'price': price,
        'comparisonType': comparisonType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get session duration in seconds
  static int getSessionDuration() {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  /// Check if user is in active session
  static bool isSessionActive() {
    return _sessionStart != null;
  }
}

// ✅ Data models for personalized search
class PersonalizedSearchData {
  final List<TopQuery> topQueries;
  final List<PersonalizedProduct> recommendations;
  final UserPreferences userPreferences;
  // Indicates where this data came from: 'cloud' | 'cache' | 'dev' | 'empty'
  final String source;

  PersonalizedSearchData({
    required this.topQueries,
    required this.recommendations,
    required this.userPreferences,
    required this.source,
  });

  factory PersonalizedSearchData.empty() {
    return PersonalizedSearchData(
      topQueries: [],
      recommendations: [],
      userPreferences: UserPreferences.empty(),
      source: 'empty',
    );
  }

  factory PersonalizedSearchData.fromFirebaseData(
    Map<String, dynamic> data, {
    String source = 'cloud',
  }) {
    try {
      // Safe casting with null safety
      final topQueriesRaw = data['topQueries'];
      final topQueries = <TopQuery>[];
      if (topQueriesRaw is List) {
        for (final item in topQueriesRaw) {
          if (item is Map) {
            try {
              topQueries.add(TopQuery.fromMap(coerceToStringKeyedMap(item)));
            } catch (e, st) {
              AppLogger.e(
                '⚠️ Failed to parse top query',
                error: e,
                stackTrace: st,
              );
            }
          }
        }
      }

      final recommendationsRaw = data['recommendations'];
      final recommendations = <PersonalizedProduct>[];
      if (recommendationsRaw is List) {
        for (final item in recommendationsRaw) {
          if (item is Map) {
            try {
              recommendations.add(
                PersonalizedProduct.fromMap(coerceToStringKeyedMap(item)),
              );
            } catch (e, st) {
              AppLogger.e(
                '⚠️ Failed to parse recommendation',
                error: e,
                stackTrace: st,
              );
            }
          }
        }
      }

      final userPreferencesRaw = data['userPreferences'];
      UserPreferences userPreferences = UserPreferences.empty();
      if (userPreferencesRaw is Map) {
        try {
          userPreferences = UserPreferences.fromMap(
            coerceToStringKeyedMap(userPreferencesRaw),
          );
        } catch (e, st) {
          AppLogger.e(
            '⚠️ Failed to parse user preferences',
            error: e,
            stackTrace: st,
          );
        }
      }

      return PersonalizedSearchData(
        topQueries: topQueries,
        recommendations: recommendations,
        userPreferences: userPreferences,
        source: source,
      );
    } catch (e, st) {
      AppLogger.e(
        '❌ Error parsing PersonalizedSearchData',
        error: e,
        stackTrace: st,
      );
      return PersonalizedSearchData.empty();
    }
  }

  PersonalizedSearchData copyWith({
    List<TopQuery>? topQueries,
    List<PersonalizedProduct>? recommendations,
    UserPreferences? userPreferences,
    String? source,
  }) {
    return PersonalizedSearchData(
      topQueries: topQueries ?? this.topQueries,
      recommendations: recommendations ?? this.recommendations,
      userPreferences: userPreferences ?? this.userPreferences,
      source: source ?? this.source,
    );
  }

  String toJson() {
    return jsonEncode({
      'topQueries': topQueries.map((q) => q.toMap()).toList(),
      'recommendations': recommendations.map((r) => r.toMap()).toList(),
      'userPreferences': userPreferences.toMap(),
      '__source': source,
    });
  }

  factory PersonalizedSearchData.fromJson(String json) {
    final data = jsonDecode(json);
    final coercedData = coerceToStringKeyedMap(data);
    // Default cached data source
    final parsed = PersonalizedSearchData.fromFirebaseData(
      coercedData,
      source: 'cache',
    );
    // If persisted source exists, prefer that
    final src = (coercedData['__source'] ?? '').toString();
    if (src.isNotEmpty && src != parsed.source) {
      return parsed.copyWith(source: src);
    }
    return parsed;
  }
}

class TopQuery {
  final String query;
  final int frequency;
  final double score;

  TopQuery({required this.query, required this.frequency, required this.score});

  factory TopQuery.fromMap(Map<String, dynamic> map) {
    final freqRaw = map['frequency'];
    final freqNum = (freqRaw is num) ? freqRaw : 0;
    return TopQuery(
      query: map['query'] ?? '',
      frequency: freqNum.toInt(),
      score: (map['score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'query': query, 'frequency': frequency, 'score': score};
  }
}

class PersonalizedProduct {
  final String id;
  final String name;
  final String brandName;
  final String category;
  final String imageUrl;
  final double relevanceScore;
  final String recommendationReason;

  PersonalizedProduct({
    required this.id,
    required this.name,
    required this.brandName,
    required this.category,
    required this.imageUrl,
    required this.relevanceScore,
    required this.recommendationReason,
  });

  factory PersonalizedProduct.fromMap(Map<String, dynamic> map) {
    return PersonalizedProduct(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      brandName: map['brand_name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['image_url'] ?? '',
      relevanceScore: (map['relevanceScore'] ?? 0.0).toDouble(),
      recommendationReason: map['recommendationReason'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand_name': brandName,
      'category': category,
      'image_url': imageUrl,
      'relevanceScore': relevanceScore,
      'recommendationReason': recommendationReason,
    };
  }
}

class UserPreferences {
  final List<Map<String, dynamic>> topCategories;
  final List<Map<String, dynamic>> topBrands;
  final List<int> preferredSearchTimes;

  UserPreferences({
    required this.topCategories,
    required this.topBrands,
    required this.preferredSearchTimes,
  });

  factory UserPreferences.empty() {
    return UserPreferences(
      topCategories: [],
      topBrands: [],
      preferredSearchTimes: [],
    );
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> normalizePairs(dynamic raw) {
      final out = <Map<String, dynamic>>[];
      final list = (raw is List)
          ? raw
          : (raw is Map
                ? coerceToStringKeyedMap(raw).entries
                      .map((e) => {'name': e.key, 'frequency': e.value})
                      .toList()
                : const []);
      for (final item in list) {
        if (item is Map) {
          final m = coerceToStringKeyedMap(item);
          dynamic nameVal;
          dynamic freqVal;
          if (m.containsKey('name') && m.containsKey('frequency')) {
            nameVal = m['name'];
            freqVal = m['frequency'];
          } else if (m.keys.length == 1) {
            final k = m.keys.first;
            nameVal = k;
            freqVal = m[k];
          } else if (m.containsKey('0') && m.containsKey('1')) {
            // array-like map
            nameVal = m['0'];
            freqVal = m['1'];
          }
          final String name = (nameVal ?? '').toString();
          final num freq = (freqVal is num) ? freqVal : 0;
          if (name.isNotEmpty) {
            out.add({'name': name, 'frequency': freq});
          }
        } else if (item is List && item.length >= 2) {
          final String name = (item[0] ?? '').toString();
          final num freq = (item[1] is num) ? item[1] as num : 0;
          if (name.isNotEmpty) out.add({'name': name, 'frequency': freq});
        }
      }
      return out;
    }

    return UserPreferences(
      topCategories: normalizePairs(map['topCategories']),
      topBrands: normalizePairs(map['topBrands']),
      preferredSearchTimes: List<int>.from(map['preferredSearchTimes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topCategories': topCategories,
      'topBrands': topBrands,
      'preferredSearchTimes': preferredSearchTimes,
    };
  }
}
