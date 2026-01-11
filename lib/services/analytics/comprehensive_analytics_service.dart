// Cloud analytics disabled to save costs
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/utils/app_logger.dart';

/// 🎯 COMPREHENSIVE USER BEHAVIOR ANALYTICS SERVICE
///
/// Based on industry research from:
/// - Amazon Product Analytics (2023)
/// - Google Analytics Enhanced E-commerce
/// - Netflix Recommendation Systems
/// - Shopify Analytics Best Practices
///
/// Tracks:
/// - Search behavior and patterns
/// - Product viewing patterns (dwell time, interactions)
/// - Category and brand preferences
/// - Purchase intent scoring
/// - Temporal shopping patterns
/// - User segmentation and personas
class ComprehensiveAnalyticsService {
  // static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final String _sessionId = const Uuid().v4();
  static DateTime? _sessionStart;

  /// Initialize session tracking
  static void initializeSession() {
    _sessionStart = DateTime.now();
    if (kDebugMode) {
      AppLogger.d('🎯 [COMPREHENSIVE_ANALYTICS] Session started');
      AppLogger.d('   Session ID: $_sessionId');
      AppLogger.d('   Start Time: $_sessionStart');
    }
  }

  /// Track comprehensive user behavior event
  static Future<bool> trackUserBehavior({
    required String eventType,
    String? productId,
    String? searchQuery,
    int? timeSpent,
    Map<String, dynamic>? interactionData,
  }) async {
    // Disabled: return false
    if (kDebugMode) {
      AppLogger.d('🎯 [COMPREHENSIVE_ANALYTICS] (disabled) $eventType');
    }
    return false;
  }

  /// Track search behavior
  static Future<bool> trackSearch({
    required String query,
    int? resultCount,
    Map<String, dynamic>? filters,
  }) async {
    return await trackUserBehavior(
      eventType: 'search',
      searchQuery: query,
      interactionData: {
        'resultCount': resultCount,
        'filters': filters,
        'searchTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track product view with detailed metrics
  static Future<bool> trackProductView({
    required String productId,
    required int timeSpent,
    String? category,
    String? brand,
    String? searchQuery,
    Map<String, dynamic>? additionalData,
  }) async {
    return await trackUserBehavior(
      eventType: 'product_view',
      productId: productId,
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
    Map<String, dynamic>? interactionData,
  }) async {
    return await trackUserBehavior(
      eventType: 'product_interaction',
      productId: productId,
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

  /// Track add to cart behavior
  static Future<bool> trackAddToCart({
    required String productId,
    int? quantity,
    double? price,
    String? supermarket,
  }) async {
    return await trackUserBehavior(
      eventType: 'add_to_cart',
      productId: productId,
      interactionData: {
        'quantity': quantity,
        'price': price,
        'supermarket': supermarket,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track category browsing
  static Future<bool> trackCategoryBrowse({
    required String category,
    int? timeSpent,
    int? productsViewed,
  }) async {
    return await trackUserBehavior(
      eventType: 'category_browse',
      interactionData: {
        'category': category,
        'timeSpent': timeSpent,
        'productsViewed': productsViewed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track filter usage
  static Future<bool> trackFilterUsage({
    required Map<String, dynamic> filters,
    int? resultCount,
    String? searchQuery,
  }) async {
    return await trackUserBehavior(
      eventType: 'filter_usage',
      searchQuery: searchQuery,
      interactionData: {
        'filters': filters,
        'resultCount': resultCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track app session metrics
  static Future<bool> trackSessionEnd() async {
    if (_sessionStart == null) return false;

    final sessionDuration = DateTime.now().difference(_sessionStart!).inSeconds;

    return await trackUserBehavior(
      eventType: 'session_end',
      timeSpent: sessionDuration,
      interactionData: {
        'sessionStart': _sessionStart!.toIso8601String(),
        'sessionEnd': DateTime.now().toIso8601String(),
        'sessionDuration': sessionDuration,
      },
    );
  }

  /// Get personalized content for default screen
  static Future<PersonalizedDefaults?> getPersonalizedDefaults({
    int limit = 20,
  }) async {
    // Disabled
    return null;
  }

  /// 🎯 SPECIALIZED TRACKING METHODS

  /// Track user scroll behavior on product lists
  static Future<bool> trackScrollBehavior({
    required String screenType,
    required int totalItems,
    required int viewedItems,
    required int scrollDepth,
    int? timeSpent,
  }) async {
    return await trackUserBehavior(
      eventType: 'scroll_behavior',
      timeSpent: timeSpent,
      interactionData: {
        'screenType': screenType,
        'totalItems': totalItems,
        'viewedItems': viewedItems,
        'scrollDepth': scrollDepth,
        'scrollPercentage': (scrollDepth / totalItems * 100).round(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track search refinement behavior
  static Future<bool> trackSearchRefinement({
    required String originalQuery,
    required String refinedQuery,
    int? originalResults,
    int? refinedResults,
  }) async {
    return await trackUserBehavior(
      eventType: 'search_refinement',
      searchQuery: refinedQuery,
      interactionData: {
        'originalQuery': originalQuery,
        'refinedQuery': refinedQuery,
        'originalResults': originalResults,
        'refinedResults': refinedResults,
        'refinementType': _determineRefinementType(originalQuery, refinedQuery),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track comparison behavior
  static Future<bool> trackProductComparison({
    required List<String> productIds,
    String? comparisonType,
    int? timeSpent,
  }) async {
    return await trackUserBehavior(
      eventType: 'product_comparison',
      timeSpent: timeSpent,
      interactionData: {
        'productIds': productIds,
        'comparisonType': comparisonType,
        'productCount': productIds.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track wishlist behavior
  static Future<bool> trackWishlistAction({
    required String productId,
    required String action, // 'add', 'remove', 'view'
  }) async {
    return await trackUserBehavior(
      eventType: 'wishlist_action',
      productId: productId,
      interactionData: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track error events for UX improvement
  static Future<bool> trackError({
    required String errorType,
    String? errorMessage,
    String? screenName,
    Map<String, dynamic>? context,
  }) async {
    return await trackUserBehavior(
      eventType: 'error_event',
      interactionData: {
        'errorType': errorType,
        'errorMessage': errorMessage,
        'screenName': screenName,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 🔧 HELPER METHODS

  static String _determineRefinementType(String original, String refined) {
    if (refined.length > original.length) {
      return 'expansion';
    } else if (refined.length < original.length) {
      return 'reduction';
    } else if (refined != original) {
      return 'modification';
    }
    return 'same';
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

/// 📊 DATA MODELS FOR PERSONALIZED CONTENT

class PersonalizedDefaults {
  final List<RecentSearch> recentHighIntentSearches;
  final List<ContinueViewingProduct> continueViewing;
  final List<RecommendedCategory> recommendedCategories;
  final List<RecommendedBrand> recommendedBrands;
  final List<TrendingProduct> trendingInInterests;
  final List<PriceAlert> priceAlerts;
  final List<QuickAction> quickActions;
  final PersonalizationMetadata personalizationMetadata;

  PersonalizedDefaults({
    required this.recentHighIntentSearches,
    required this.continueViewing,
    required this.recommendedCategories,
    required this.recommendedBrands,
    required this.trendingInInterests,
    required this.priceAlerts,
    required this.quickActions,
    required this.personalizationMetadata,
  });

  factory PersonalizedDefaults.fromMap(Map<String, dynamic> map) {
    return PersonalizedDefaults(
      recentHighIntentSearches: (map['recentHighIntentSearches'] as List? ?? [])
          .map((e) => RecentSearch.fromMap(e))
          .toList(),
      continueViewing: (map['continueViewing'] as List? ?? [])
          .map((e) => ContinueViewingProduct.fromMap(e))
          .toList(),
      recommendedCategories: (map['recommendedCategories'] as List? ?? [])
          .map((e) => RecommendedCategory.fromMap(e))
          .toList(),
      recommendedBrands: (map['recommendedBrands'] as List? ?? [])
          .map((e) => RecommendedBrand.fromMap(e))
          .toList(),
      trendingInInterests: (map['trendingInInterests'] as List? ?? [])
          .map((e) => TrendingProduct.fromMap(e))
          .toList(),
      priceAlerts: (map['priceAlerts'] as List? ?? [])
          .map((e) => PriceAlert.fromMap(e))
          .toList(),
      quickActions: (map['quickActions'] as List? ?? [])
          .map((e) => QuickAction.fromMap(e))
          .toList(),
      personalizationMetadata: PersonalizationMetadata.fromMap(
        map['personalizationMetadata'] ?? {},
      ),
    );
  }
}

class RecentSearch {
  final String query;
  final int count;
  final String? lastSearched;
  final double avgResultClicks;
  final int recency;

  RecentSearch({
    required this.query,
    required this.count,
    this.lastSearched,
    required this.avgResultClicks,
    required this.recency,
  });

  factory RecentSearch.fromMap(Map<String, dynamic> map) {
    return RecentSearch(
      query: map['query'] ?? '',
      count: map['count'] ?? 0,
      lastSearched: map['lastSearched'],
      avgResultClicks: (map['avgResultClicks'] ?? 0).toDouble(),
      recency: map['recency'] ?? 0,
    );
  }
}

class ContinueViewingProduct {
  final String productId;
  final int viewCount;
  final int totalTimeSpent;
  final String? lastViewed;
  final String? category;
  final String? brand;
  final int intentScore;
  final int recency;

  ContinueViewingProduct({
    required this.productId,
    required this.viewCount,
    required this.totalTimeSpent,
    this.lastViewed,
    this.category,
    this.brand,
    required this.intentScore,
    required this.recency,
  });

  factory ContinueViewingProduct.fromMap(Map<String, dynamic> map) {
    return ContinueViewingProduct(
      productId: map['productId'] ?? '',
      viewCount: map['viewCount'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
      lastViewed: map['lastViewed'],
      category: map['category'],
      brand: map['brand'],
      intentScore: map['intentScore'] ?? 0,
      recency: map['recency'] ?? 0,
    );
  }
}

class RecommendedCategory {
  final String category;
  final double affinityScore;

  RecommendedCategory({required this.category, required this.affinityScore});

  factory RecommendedCategory.fromMap(Map<String, dynamic> map) {
    return RecommendedCategory(
      category: map['category'] ?? '',
      affinityScore: (map['affinityScore'] ?? 0).toDouble(),
    );
  }
}

class RecommendedBrand {
  final String brand;
  final double loyaltyScore;

  RecommendedBrand({required this.brand, required this.loyaltyScore});

  factory RecommendedBrand.fromMap(Map<String, dynamic> map) {
    return RecommendedBrand(
      brand: map['brand'] ?? '',
      loyaltyScore: (map['loyaltyScore'] ?? 0).toDouble(),
    );
  }
}

class TrendingProduct {
  final String productId;
  final String name;
  final String? brand;
  final String? category;
  final String reason;

  TrendingProduct({
    required this.productId,
    required this.name,
    this.brand,
    this.category,
    required this.reason,
  });

  factory TrendingProduct.fromMap(Map<String, dynamic> map) {
    return TrendingProduct(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand_name'],
      category: map['category'],
      reason: map['reason'] ?? '',
    );
  }
}

class PriceAlert {
  final String productId;
  final int priceChecks;
  final String suggestedAction;

  PriceAlert({
    required this.productId,
    required this.priceChecks,
    required this.suggestedAction,
  });

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      productId: map['productId'] ?? '',
      priceChecks: map['priceChecks'] ?? 0,
      suggestedAction: map['suggestedAction'] ?? '',
    );
  }
}

class QuickAction {
  final String action;
  final String title;
  final String icon;

  QuickAction({required this.action, required this.title, required this.icon});

  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      action: map['action'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'] ?? '',
    );
  }
}

class PersonalizationMetadata {
  final String shoppingPersona;
  final List<String> primaryInterests;
  final String activityLevel;

  PersonalizationMetadata({
    required this.shoppingPersona,
    required this.primaryInterests,
    required this.activityLevel,
  });

  factory PersonalizationMetadata.fromMap(Map<String, dynamic> map) {
    return PersonalizationMetadata(
      shoppingPersona: map['shoppingPersona'] ?? 'new_user',
      primaryInterests: List<String>.from(map['primaryInterests'] ?? []),
      activityLevel: map['activityLevel'] ?? 'low',
    );
  }
}
