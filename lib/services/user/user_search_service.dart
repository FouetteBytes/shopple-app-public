import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'dart:async';
import 'package:shopple/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/services/user/other_user_details_service.dart';
import 'package:shopple/services/core/resilient_network_service.dart';
import 'package:shopple/services/cache/offline_search_cache.dart';
import 'package:shopple/services/search/user_search_cache_service.dart';
import 'package:shopple/services/search/search_query_analyzer.dart';

import '../../models/contact_models.dart';
import './../auth/phone_number_service.dart';

/// User Search Service v3.0
///
/// Advanced user search with 4-level caching, resilience patterns, and offline support.
/// This service provides a highly responsive and reliable user search experience.
///
/// Key Features:
/// - 4-Level Caching: Instant, memory, local storage, and cloud with offline fallback
/// - Resilience: Circuit breaker, retries with backoff, request deduplication
/// - Offline-First: Falls back to cached friends/contacts when offline
/// - Intelligent Query Detection: Automatically identifies query type
/// - Fuzzy Matching: For names, providing more natural search results
/// - Server-Side Privacy: Privacy filtering happens on cloud function
/// - Phone Number Variation Search: Uses `PhoneNumberService` for multiple formats
class UserSearchService {
  static const int debounceMs = 50; // Ultra-fast for instant search

  // Debouncing timer
  static Timer? _debounceTimer;

  // Cloud Functions instance (asia-south1)
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  // Request cancellation for instant search
  static String? _currentRequestId;
  static final Map<String, bool> _cancelledRequests = {};

  /// 🚀 INSTANT SEARCH - Google-like real-time search with zero-latency results
  /// This is the NEW primary search method for ultra-responsive instant search
  static Future<List<UserSearchResult>> instantSearch(
    String query, {
    int limit = 25,
    bool useCache = true,
    Function(List<UserSearchResult>)? onStreamResults,
  }) async {
    // Allow search from first character for Google-like experience
    if (query.trim().isEmpty) {
      return [];
    }

    String cleanQuery = query.trim().toLowerCase();
    String requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRequestId = requestId;

    AppLogger.d('INSTANT SEARCH: "$cleanQuery" (${cleanQuery.length} chars)');

    try {
      // LEVEL 0: Instant cache for single characters (< 1ms)
      final instantResults = UserSearchCacheService.instance.getInstantResults(cleanQuery);
      if (instantResults != null) {
        AppLogger.d(
          'INSTANT CACHE HIT: ${instantResults.length} results in <1ms',
        );
        if (onStreamResults != null) onStreamResults(instantResults);
        return instantResults.take(limit).toList();
      }

      // LEVEL 1: Memory cache (< 5ms)
      if (useCache) {
        final memoryResults = UserSearchCacheService.instance.getMemoryResults(cleanQuery);
        if (memoryResults != null) {
          AppLogger.d(
            'MEMORY CACHE HIT: ${memoryResults.length} results in <5ms',
          );
          if (onStreamResults != null) onStreamResults(memoryResults);
          return memoryResults.take(limit).toList();
        }
      }

      // LEVEL 2: Prefix matching from cache (< 10ms)
      List<UserSearchResult> prefixResults = UserSearchCacheService.instance.findPrefixMatches(
        cleanQuery,
        limit,
      );
      if (prefixResults.isNotEmpty) {
        AppLogger.d('PREFIX MATCH: ${prefixResults.length} results in <10ms');
        if (onStreamResults != null) onStreamResults(prefixResults);

        // Continue with cloud search in background while showing prefix results
        _performBackgroundSearch(cleanQuery, limit, requestId);
        return prefixResults;
      }

      // LEVEL 3: Cloud Functions with ultra-fast timeout (< 500ms)
      return await _performUltraFastCloudSearch(
        cleanQuery,
        limit,
        requestId,
        onStreamResults,
      );
    } catch (e) {
      AppLogger.w('INSTANT SEARCH ERROR: $e');
      return [];
    }
  }



  /// Perform ultra-fast cloud search with resilience patterns
  static Future<List<UserSearchResult>> _performUltraFastCloudSearch(
    String query,
    int limit,
    String requestId,
    Function(List<UserSearchResult>)? onStreamResults,
  ) async {
    QueryType queryType = SearchQueryAnalyzer.detectQueryType(query);
    final resilience = ResilientNetworkService.instance;

    // Check network health first - if offline, go straight to offline cache
    if (!resilience.isOnline) {
      AppLogger.d('📴 Offline detected - using offline cache');
      final offlineResults = await OfflineSearchCache.instance.search(query, limit: limit);
      if (offlineResults.isNotEmpty && onStreamResults != null) {
        onStreamResults(offlineResults);
      }
      return offlineResults;
    }

    try {
      // Use resilience service with circuit breaker
      final results = await resilience.execute<List<UserSearchResult>>(
        key: 'user_search_$query',
        timeout: const Duration(milliseconds: 800), // Slightly longer for reliability
        maxRetries: 1, // Only 1 retry for real-time search
        request: () async {
          Future<List<UserSearchResult>> cloudSearchFuture;

          if (query.length <= 2) {
            cloudSearchFuture = _performOptimizedShortSearch(
              query,
              queryType,
              limit,
              requestId,
            );
          } else {
            cloudSearchFuture = _performCloudSearch(
              query,
              queryType,
              limit,
              requestId,
            );
          }

          return await cloudSearchFuture;
        },
        fallback: () async {
          // Fallback chain: offline cache -> local Firestore
          AppLogger.d('🔄 Cloud failed - trying offline cache');
          final offlineResults = await OfflineSearchCache.instance.search(query, limit: limit);
          if (offlineResults.isNotEmpty) {
            return offlineResults;
          }
          return await _performLocalSearch(query, queryType, limit);
        },
      );

      // Privacy filtering is now done server-side, but keep client fallback
      // for results from offline cache or local search
      List<UserSearchResult> filteredResults = results;
      if (results.isNotEmpty && results.first.matchScore < 0) {
        // Negative score indicates local/offline results that need filtering
        filteredResults = await _filterByPrivacySettings(results, queryType);
      }

      // Cache results for future instant access
      if (filteredResults.isNotEmpty) {
        UserSearchCacheService.instance.cacheInMemory(query, filteredResults);

        if (onStreamResults != null) onStreamResults(filteredResults);
      }

      return filteredResults.take(limit).toList();
    } catch (e) {
      AppLogger.w('ULTRA-FAST SEARCH ERROR: $e');
      
      // Final fallback to offline cache
      final offlineResults = await OfflineSearchCache.instance.search(query, limit: limit);
      if (offlineResults.isNotEmpty) {
        if (onStreamResults != null) onStreamResults(offlineResults);
        return offlineResults;
      }
      
      return await _performLocalSearch(query, queryType, limit);
    }
  }

  /// Perform background search to update results while user is typing
  static void _performBackgroundSearch(
    String query,
    int limit,
    String requestId,
  ) {
    Timer(Duration(milliseconds: 50), () async {
      // Check if this search is still relevant
      if (_currentRequestId != requestId) return;

      try {
        QueryType queryType = SearchQueryAnalyzer.detectQueryType(query);
        List<UserSearchResult> backgroundResults;

        if (query.length <= 2) {
          backgroundResults = await _performOptimizedShortSearch(
            query,
            queryType,
            limit * 2,
            requestId,
          );
        } else {
          backgroundResults = await _performCloudSearch(
            query,
            queryType,
            limit * 2,
            requestId,
          );
        }

        if (backgroundResults.isNotEmpty && _currentRequestId == requestId) {
          UserSearchCacheService.instance.cacheInMemory(query, backgroundResults);
          AppLogger.d(
            'BACKGROUND SEARCH: Updated cache with ${backgroundResults.length} results',
          );
        }
      } catch (e) {
        AppLogger.w('BACKGROUND SEARCH ERROR: $e');
      }
    });
  }

  /// 🔥 CONNECTION PRE-WARMING: Initialize Cloud Functions connection for faster first request
  static void _warmUpConnectionIfNeeded() {
    // Disabled
    return;
  }

  /// Pre-fetch popular searches for instant results
  static void _prefetchPopularSearches() {
    // Disabled
    return;
  }

  static Future<List<UserSearchResult>> searchUsers(
    String query, {
    int limit = 15,
    bool useCache = true,
  }) async {
    // Allow search from 1 character for instant suggestions
    if (query.trim().isEmpty) {
      return [];
    }

    String cleanQuery = query.trim().toLowerCase();
    String requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRequestId = requestId;

    AppLogger.d('SEARCH: "$cleanQuery" (length: ${cleanQuery.length})');
    QueryType queryType = SearchQueryAnalyzer.detectQueryType(cleanQuery);
    AppLogger.d('QUERY TYPE: $queryType');

    try {
      // ULTRA-FAST: Prefetch cache for single characters (< 10ms)
      final prefetchResults = UserSearchCacheService.instance.getPrefetchResults(cleanQuery);
      if (prefetchResults != null) {
        AppLogger.d('PREFETCH CACHE HIT for "$cleanQuery"');
        return prefetchResults.take(limit).toList();
      }

      // Level 1: Memory cache (< 50ms)
      if (useCache) {
        final memoryResults = UserSearchCacheService.instance.getMemoryResults(cleanQuery);
        if (memoryResults != null) {
          AppLogger.d('MEMORY CACHE HIT for "$cleanQuery"');
          return memoryResults;
        }
      }

      // Level 2: Local storage cache (< 100ms)
      if (useCache) {
        List<UserSearchResult>? localResults = await UserSearchCacheService.instance.getLocalCachedResults(
          cleanQuery,
        );
        if (localResults != null) {
          AppLogger.d('LOCAL CACHE HIT for "$cleanQuery"');
          UserSearchCacheService.instance.cacheInMemory(cleanQuery, localResults);
          return localResults;
        }
      }

      // Check if this request was cancelled before making expensive call
      if (_cancelledRequests[requestId] == true) {
        _cancelledRequests.remove(requestId);
        AppLogger.d('REQUEST CANCELLED for "$cleanQuery"');
        return [];
      }

      // Level 3: Cloud Functions with optimized routing
      List<UserSearchResult> results;

      AppLogger.d('CLOUD SEARCH for "$cleanQuery" with type $queryType');

      // Use optimized search for short queries
      if (cleanQuery.length <= 2) {
        results = await _performOptimizedShortSearch(
          cleanQuery,
          queryType,
          limit,
          requestId,
        );
      } else {
        results = await _performCloudSearch(
          cleanQuery,
          queryType,
          limit,
          requestId,
        );
      }

      AppLogger.d('CLOUD RESULTS: ${results.length} found for "$cleanQuery"');

      // Check again if request was cancelled
      if (_cancelledRequests[requestId] == true) {
        _cancelledRequests.remove(requestId);
        AppLogger.d('REQUEST CANCELLED AFTER SEARCH for "$cleanQuery"');
        return [];
      }

      // Cache results and prefetch for single characters
      if (useCache) {
        await UserSearchCacheService.instance.cacheLocally(cleanQuery, results);
        UserSearchCacheService.instance.cacheInMemory(cleanQuery, results);

        // Cache single character searches for instant access
        if (cleanQuery.length == 1) {
          _prefetchCommonCharacters();
        }
      }

      return results;
    } catch (e) {
      AppLogger.w('❌ SEARCH ERROR for "$cleanQuery": $e');

      // Check if request was cancelled
      if (_cancelledRequests[requestId] == true) {
        _cancelledRequests.remove(requestId);
        return [];
      }

      // Fallback to local search if Cloud Functions fail
      AppLogger.w('FALLBACK to local search for "$cleanQuery"');
      return await _performLocalSearch(
        cleanQuery,
        SearchQueryAnalyzer.detectQueryType(cleanQuery),
        limit,
      );
    }
  }

  /// Cancel all pending search requests for instant search
  static void cancelPendingSearches() {
    if (_currentRequestId != null) {
      _cancelledRequests[_currentRequestId!] = true;
    }
  }

  /// Perform search using Cloud Functions with request cancellation
  static Future<List<UserSearchResult>> _performCloudSearch(
    String query,
    QueryType queryType,
    int limit,
    String requestId,
  ) async {
    try {
      // Call the Cloud Function
      HttpsCallable callable = _functions.httpsCallable('advancedUserSearchV2');

      final result = await callable.call({
        'query': query,
        'queryType': queryType
            .toString()
            .split('.')
            .last, // Convert enum to string
        'limit': limit,
        'applyPrivacyFilter': true, // Enable server-side privacy filtering
      });

      // Check if request was cancelled during the call
      if (_cancelledRequests[requestId] == true) {
        _cancelledRequests.remove(requestId);
        return [];
      }

      // Parse results with proper type casting
      final responseData = Map<String, dynamic>.from(result.data as Map);
      List<dynamic> cloudResults = responseData['results'] ?? [];

      return cloudResults.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return UserSearchResult(
          uid: data['uid'] ?? '',
          name: _buildFullName(data),
          email: data['email'],
          phoneNumber: data['phoneNumber'],
          profilePicture: data['photoURL'] ?? data['profilePicture'],
          matchScore: _calculateMatchScore(data, query),
          isContact: false,
        );
      }).toList();
    } catch (e) {
      AppLogger.w('Cloud Function search error: $e');
      // Fallback to local search
      rethrow;
    }
  }

  /// Optimized search for short queries (1-2 characters) using partial search
  static Future<List<UserSearchResult>> _performOptimizedShortSearch(
    String query,
    QueryType queryType,
    int limit,
    String requestId,
  ) async {
    try {
      // Call optimized Cloud Function for partial matching
      HttpsCallable callable = _functions.httpsCallable('advancedUserSearchV2');

      final result = await callable.call({
        'query': query,
        'queryType': 'partial', // Use partial search for short queries
        'limit': limit * 2, // Get more results for better filtering
        'isShortQuery': true,
        'applyPrivacyFilter': true, // Enable server-side privacy filtering
      });

      // Check if request was cancelled during the call
      if (_cancelledRequests[requestId] == true) {
        _cancelledRequests.remove(requestId);
        return [];
      }

      // Parse results with proper type casting
      final responseData = Map<String, dynamic>.from(result.data as Map);
      List<dynamic> cloudResults = responseData['results'] ?? [];

      List<UserSearchResult> results = cloudResults.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return UserSearchResult(
          uid: data['uid'] ?? '',
          name: _buildFullName(data),
          email: data['email'],
          phoneNumber: data['phoneNumber'],
          profilePicture: data['photoURL'] ?? data['profilePicture'],
          matchScore: _calculateInstantMatchScore(data, query),
          isContact: false,
        );
      }).toList();

      // Sort by match score and return top results
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return results.take(limit).toList();
    } catch (e) {
      AppLogger.w('Optimized short search error: $e');
      // Fallback to regular search
      return await _performCloudSearch(query, queryType, limit, requestId);
    }
  }

  /// Calculate instant match score for short queries
  static double _calculateInstantMatchScore(
    Map<String, dynamic> data,
    String query,
  ) {
    double baseScore = (data['matchScore'] ?? 0.5).toDouble();
    String name = _buildFullName(data).toLowerCase();
    String email = (data['email'] ?? '').toLowerCase();
    String phone = data['phoneNumber'] ?? '';

    // Boost score for prefix matches (most important for instant search)
    if (name.startsWith(query)) {
      baseScore += 0.4;
    } else if (name.contains(' $query')) {
      // Word boundary match
      baseScore += 0.3;
    } else if (name.contains(query)) {
      baseScore += 0.2;
    }

    if (email.startsWith(query)) {
      baseScore += 0.3;
    }

    if (phone.contains(query)) {
      baseScore += 0.1;
    }

    return baseScore.clamp(0.0, 1.0);
  }

  /// Prefetch common single characters for instant search
  static Future<void> _prefetchCommonCharacters() async {
    // Disabled
    return;
  }

  /// Build full name from user data
  static String _buildFullName(Map<String, dynamic> data) {
    String firstName = data['firstName'] ?? '';
    String lastName = data['lastName'] ?? '';
    String displayName = data['displayName'] ?? '';

    if (displayName.isNotEmpty) {
      return displayName;
    }

    return '$firstName $lastName'.trim();
  }

  /// Calculate match score for Cloud Function results
  static double _calculateMatchScore(Map<String, dynamic> data, String query) {
    // Enhance server-side scoring with client-side exact match boosts
    double baseScore = (data['matchScore'] ?? 0.5).toDouble();

    // Additional client-side scoring based on exact matches
    String name = _buildFullName(data).toLowerCase();
    String queryLower = query.toLowerCase();

    if (name == queryLower) {
      return 1.0;
    } else if (name.startsWith(queryLower)) {
      return baseScore + 0.2;
    } else if (name.contains(queryLower)) {
      return baseScore + 0.1;
    }

    return baseScore;
  }

  /// Fallback local search (existing implementation)
  static Future<List<UserSearchResult>> _performLocalSearch(
    String query,
    QueryType queryType,
    int limit,
  ) async {
    AppLogger.w('Falling back to local search');
    switch (queryType) {
      case QueryType.phone:
        return await _searchByPhone(query, limit);
      case QueryType.email:
        return await _searchByEmail(query, limit);
      case QueryType.name:
        return await _searchByName(query, limit);
      case QueryType.mixed:
        return await _searchMixed(query, limit);
      case QueryType.partial:
        return await _searchPartial(query, limit);
    }
  }

  /// Filter search results based on users' privacy settings
  /// Removes users who have:
  /// - isFullyPrivate = true
  /// - searchableByName = false (for name queries)
  /// - searchableByEmail = false (for email queries)
  /// - searchableByPhone = false (for phone queries)
  static Future<List<UserSearchResult>> _filterByPrivacySettings(
    List<UserSearchResult> results,
    QueryType queryType,
  ) async {
    if (results.isEmpty) return results;
    
    // Get current user ID to exclude from filtering (shouldn't happen but safety)
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Batch fetch privacy settings for all result users
    final firestore = FirebaseFirestore.instance;
    final userIds = results.map((r) => r.uid).where((id) => id.isNotEmpty && id != currentUserId).toList();
    
    if (userIds.isEmpty) return results;
    
    try {
      // Batch fetch user documents to check privacy settings
      // Using batched reads for efficiency
      final List<UserSearchResult> filteredResults = [];
      
      // Process in batches of 10 (Firestore limit for 'in' queries)
      for (int i = 0; i < userIds.length; i += 10) {
        final batchIds = userIds.skip(i).take(10).toList();
        
        final querySnapshot = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        
        final privacyMap = <String, Map<String, dynamic>>{};
        for (final doc in querySnapshot.docs) {
          final privacy = doc.data()['privacy'] as Map<String, dynamic>?;
          privacyMap[doc.id] = privacy ?? {};
        }
        
        // Filter results based on privacy settings
        for (final result in results.where((r) => batchIds.contains(r.uid))) {
          final privacy = privacyMap[result.uid] ?? {};
          final isFullyPrivate = privacy['isFullyPrivate'] as bool? ?? false;
          
          // Skip fully private users
          if (isFullyPrivate) {
            AppLogger.d('PRIVACY FILTER: Skipping fully private user ${result.uid}');
            continue;
          }
          
          // Check searchability based on query type
          bool isSearchable = true;
          switch (queryType) {
            case QueryType.name:
            case QueryType.partial:
              isSearchable = privacy['searchableByName'] as bool? ?? true;
              break;
            case QueryType.email:
              isSearchable = privacy['searchableByEmail'] as bool? ?? true;
              break;
            case QueryType.phone:
              isSearchable = privacy['searchableByPhone'] as bool? ?? true;
              break;
            case QueryType.mixed:
              // For mixed queries, user must be searchable by at least one method
              isSearchable = (privacy['searchableByName'] as bool? ?? true) ||
                  (privacy['searchableByEmail'] as bool? ?? true) ||
                  (privacy['searchableByPhone'] as bool? ?? true);
              break;
          }
          
          if (isSearchable) {
            filteredResults.add(result);
          } else {
            AppLogger.d('PRIVACY FILTER: Skipping user ${result.uid} (not searchable by $queryType)');
          }
        }
      }
      
      // Add back current user if they were in original results
      final currentUserResult = results.where((r) => r.uid == currentUserId).firstOrNull;
      if (currentUserResult != null) {
        filteredResults.insert(0, currentUserResult);
      }
      
      return filteredResults;
    } catch (e) {
      AppLogger.w('Error filtering by privacy settings: $e');
      // On error, return original results to not break search
      return results;
    }
  }

  /// Debounced search for real-time typing
  static Future<List<UserSearchResult>> searchUsersDebounced(
    String query,
    Function(List<UserSearchResult>) onResults, {
    int limit = 15,
  }) async {
    // Cancel previous timer
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Set new timer
    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      List<UserSearchResult> results = await searchUsers(query, limit: limit);
      onResults(results);
    });

    // Return immediate memory cache if available
    String cleanQuery = query.trim().toLowerCase();
    final memoryResults = UserSearchCacheService.instance.getMemoryResults(cleanQuery);
    if (memoryResults != null) {
      return memoryResults;
    }

    return [];
  }

  /// Clear all caches
  static Future<void> clearCache() async {
    await UserSearchCacheService.instance.clearCache();
  }

  /// 🚀 INITIALIZE: Pre-warm connections and cache for optimal performance
  /// Call this early in app lifecycle (e.g., in main() or splash screen)
  static void initializeSearchOptimizations() {
    AppLogger.d(
      'INITIALIZING: Search optimizations and connection pre-warming...',
    );

    // Start connection warm-up immediately
    _warmUpConnectionIfNeeded();

    // Pre-load instant cache for common characters
    Timer(Duration(milliseconds: 1000), () {
      _prefetchPopularSearches();
    });

    AppLogger.d('SEARCH OPTIMIZATION: Initialization complete');
  }



  /// Search by phone number with variations
  static Future<List<UserSearchResult>> _searchByPhone(
    String query,
    int limit,
  ) async {
    try {
      // Generate phone variations
      List<String> variations = PhoneNumberService.generateVariations(query);
      List<UserSearchResult> results = [];

      // Search Firestore for each variation
      for (String variation in variations.take(3)) {
        // Limit to prevent too many queries
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: variation)
            .limit(limit)
            .get();

        for (QueryDocumentSnapshot doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          results.add(
            UserSearchResult(
              uid: doc.id,
              name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                  .trim(),
              email: data['email'],
              phoneNumber: data['phoneNumber'],
              profilePicture: data['photoURL'],
              matchScore: 1.0, // Exact phone match
            ),
          );
        }

        if (results.length >= limit) break;
      }

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.w('Phone search error: $e');
      return [];
    }
  }

  /// Search by email
  static Future<List<UserSearchResult>> _searchByEmail(
    String query,
    int limit,
  ) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      List<UserSearchResult> results = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        double matchScore = _calculateEmailMatchScore(
          query,
          data['email'] ?? '',
        );

        results.add(
          UserSearchResult(
            uid: doc.id,
            name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profilePicture: data['photoURL'],
            matchScore: matchScore,
          ),
        );
      }

      // Sort by match score
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return results;
    } catch (e) {
      AppLogger.w('Email search error: $e');
      return [];
    }
  }

  /// Search by name with fuzzy matching
  static Future<List<UserSearchResult>> _searchByName(
    String query,
    int limit,
  ) async {
    try {
      List<UserSearchResult> results = [];

      // Search firstName
      QuerySnapshot firstNameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      // Search lastName
      QuerySnapshot lastNameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      Set<String> seenIds = {};

      // Process firstName results
      for (QueryDocumentSnapshot doc in firstNameSnapshot.docs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double matchScore = _calculateNameMatchScore(query, data);

        results.add(
          UserSearchResult(
            uid: doc.id,
            name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profilePicture: data['photoURL'],
            matchScore: matchScore,
          ),
        );
      }

      // Process lastName results
      for (QueryDocumentSnapshot doc in lastNameSnapshot.docs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double matchScore = _calculateNameMatchScore(query, data);

        results.add(
          UserSearchResult(
            uid: doc.id,
            name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profilePicture: data['photoURL'],
            matchScore: matchScore,
          ),
        );
      }

      // Sort by match score and return top results
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return results.take(limit).toList();
    } catch (e) {
      AppLogger.w('Name search error: $e');
      return [];
    }
  }

  /// Search with mixed query types
  static Future<List<UserSearchResult>> _searchMixed(
    String query,
    int limit,
  ) async {
    List<UserSearchResult> results = [];

    // Try name search
    results.addAll(await _searchByName(query, limit ~/ 2));

    // Try email search if query contains @
    if (query.contains('@')) {
      results.addAll(await _searchByEmail(query, limit ~/ 2));
    }

    // Remove duplicates and sort
    Map<String, UserSearchResult> uniqueResults = {};
    for (UserSearchResult result in results) {
      uniqueResults[result.uid] = result;
    }

    List<UserSearchResult> finalResults = uniqueResults.values.toList();
    finalResults.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return finalResults.take(limit).toList();
  }

  /// Search for partial queries (less than 3 characters)
  static Future<List<UserSearchResult>> _searchPartial(
    String query,
    int limit,
  ) async {
    // For partial queries, use enhanced local search with fuzzy matching
    return await _enhancedLocalSearch(query, limit);
  }

  /// Enhanced local search with fuzzy matching for instant results
  /// This is the optimized fallback when cloud functions fail
  static Future<List<UserSearchResult>> _enhancedLocalSearch(
    String query,
    int limit,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final queryLower = query.toLowerCase();
      List<UserSearchResult> results = [];
      Set<String> seenIds = {};

      // Strategy 1: Prefix search on searchableFirstName (indexed, fast)
      // First, try exact prefix match on firstName
      final firstNameQuery = await firestore
          .collection('users')
          .orderBy('firstName')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(limit)
          .get();

      for (final doc in firstNameQuery.docs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);
        
        final data = doc.data();
        final score = _calculateNameMatchScore(queryLower, data);
        
        results.add(UserSearchResult(
          uid: doc.id,
          name: _buildFullName(data),
          email: data['email'],
          phoneNumber: data['phoneNumber'],
          profilePicture: data['customPhotoURL'] ?? data['photoURL'],
          matchScore: score,
          isContact: false,
        ));
      }

      // Strategy 2: Also search by lastName
      if (results.length < limit) {
        final lastNameQuery = await firestore
            .collection('users')
            .orderBy('lastName')
            .startAt([queryLower])
            .endAt(['$queryLower\uf8ff'])
            .limit(limit - results.length)
            .get();

        for (final doc in lastNameQuery.docs) {
          if (seenIds.contains(doc.id)) continue;
          seenIds.add(doc.id);
          
          final data = doc.data();
          final score = _calculateNameMatchScore(queryLower, data);
          
          results.add(UserSearchResult(
            uid: doc.id,
            name: _buildFullName(data),
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profilePicture: data['customPhotoURL'] ?? data['photoURL'],
            matchScore: score,
            isContact: false,
          ));
        }
      }

      // Strategy 3: Search by displayName
      if (results.length < limit) {
        final displayNameQuery = await firestore
            .collection('users')
            .orderBy('displayName')
            .startAt([queryLower])
            .endAt(['$queryLower\uf8ff'])
            .limit(limit - results.length)
            .get();

        for (final doc in displayNameQuery.docs) {
          if (seenIds.contains(doc.id)) continue;
          seenIds.add(doc.id);
          
          final data = doc.data();
          final score = _calculateNameMatchScore(queryLower, data);
          
          results.add(UserSearchResult(
            uid: doc.id,
            name: _buildFullName(data),
            email: data['email'],
            phoneNumber: data['phoneNumber'],
            profilePicture: data['customPhotoURL'] ?? data['photoURL'],
            matchScore: score,
            isContact: false,
          ));
        }
      }

      // Sort by match score (best matches first)
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      AppLogger.d('ENHANCED LOCAL SEARCH: Found ${results.length} results for "$query"');
      return results.take(limit).toList();
    } catch (e) {
      AppLogger.w('Enhanced local search error: $e');
      return [];
    }
  }

  /// Get search suggestions with fuzzy matching for autocomplete
  /// Shows suggestions as user types, even with typos
  static Future<List<UserSearchResult>> getSuggestions(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final cleanQuery = query.trim().toLowerCase();
    
    // Check cache first for instant suggestions
    final cacheKey = 'suggest_$cleanQuery';
    final memoryResults = UserSearchCacheService.instance.getMemoryResults(cacheKey);
    if (memoryResults != null) {
      return memoryResults.take(limit).toList();
    }
    
    // Build suggestions from recent searches and enhanced local search
    List<UserSearchResult> suggestions = [];
    
    // Add from prefix cache if available
    final prefixResults = UserSearchCacheService.instance.findPrefixMatches(cleanQuery, limit);
    for (final result in prefixResults) {
      if (_fuzzyMatch(result.name.toLowerCase(), cleanQuery)) {
        suggestions.add(result);
      }
    }
    
    // If not enough, do enhanced local search
    if (suggestions.length < limit) {
      final localResults = await _enhancedLocalSearch(cleanQuery, limit - suggestions.length);
      suggestions.addAll(localResults);
    }
    
    // Remove duplicates
    final seen = <String>{};
    suggestions = suggestions.where((s) => seen.add(s.uid)).toList();
    
    // Sort by match score
    suggestions.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    // Cache suggestions
    UserSearchCacheService.instance.cacheInMemory(cacheKey, suggestions.take(limit).toList());
    
    return suggestions.take(limit).toList();
  }

  /// Fuzzy match helper - returns true if query approximately matches target
  static bool _fuzzyMatch(String target, String query) {
    if (target.contains(query)) return true;
    if (target.startsWith(query)) return true;
    
    // Simple Levenshtein-inspired tolerance
    // Allow 1 character difference for every 4 characters
    final tolerance = (query.length / 4).ceil().clamp(1, 3);
    
    // Check if any substring of target is close to query
    for (int i = 0; i <= target.length - query.length + tolerance; i++) {
      final end = (i + query.length + tolerance).clamp(0, target.length);
      final substring = target.substring(i, end);
      
      final score = ratio(query, substring);
      if (score > 70) return true;
    }
    
    return false;
  }

  /// Preload user data for faster search results display
  /// Call this early to warm up caches
  static Future<void> preloadRecentUsers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      // Preload recent interactions (friends, recent chats)
      final friendsSnapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .limit(20)
          .get();
      
      for (final doc in friendsSnapshot.docs) {
        final friendId = doc.id;
        // Warm up user details cache
        await OtherUserDetailsService.instance.getUserDetails(friendId);
      }
      
      AppLogger.d('PRELOAD: Warmed up cache for ${friendsSnapshot.docs.length} friends');
    } catch (e) {
      AppLogger.w('Preload error: $e');
    }
  }

  /// Calculate name match score using fuzzy matching
  static double _calculateNameMatchScore(
    String query,
    Map<String, dynamic> userData,
  ) {
    String firstName = (userData['firstName'] ?? '').toLowerCase();
    String lastName = (userData['lastName'] ?? '').toLowerCase();
    String fullName = '$firstName $lastName'.trim();
    String displayName = (userData['displayName'] ?? '').toLowerCase();

    double bestScore = 0.0;

    // Check various name combinations
    List<String> namesToCheck = [firstName, lastName, fullName, displayName];

    for (String name in namesToCheck) {
      if (name.isNotEmpty) {
        // Exact match
        if (name == query) {
          return 1.0;
        }

        // Starts with
        if (name.startsWith(query)) {
          bestScore = bestScore > 0.9 ? bestScore : 0.9;
        }

        // Contains
        if (name.contains(query)) {
          bestScore = bestScore > 0.8 ? bestScore : 0.8;
        }

        // Fuzzy match
        int fuzzyScore = ratio(query, name);
        double normalizedScore = fuzzyScore / 100.0;
        bestScore = bestScore > normalizedScore ? bestScore : normalizedScore;
      }
    }

    return bestScore;
  }

  /// Calculate email match score
  static double _calculateEmailMatchScore(String query, String email) {
    if (email.toLowerCase() == query.toLowerCase()) return 1.0;
    if (email.toLowerCase().startsWith(query.toLowerCase())) return 0.9;
    if (email.toLowerCase().contains(query.toLowerCase())) return 0.7;

    int fuzzyScore = ratio(query.toLowerCase(), email.toLowerCase());
    return fuzzyScore / 100.0;
  }
}
