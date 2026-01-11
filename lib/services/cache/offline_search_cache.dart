import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import '../../models/contact_models.dart';

/// 🗄️ OFFLINE SEARCH CACHE
/// 
/// Provides offline-capable search functionality by maintaining a local
/// cache of friends, contacts, and recent searches that can be queried
/// without network access.
/// 
/// Features:
/// - Automatic sync of friends list on app start
/// - SQLite-like search across cached users
/// - Fuzzy matching for typo tolerance
/// - Recent search history with smart suggestions
/// - Periodic background refresh
class OfflineSearchCache {
  OfflineSearchCache._();
  static final OfflineSearchCache instance = OfflineSearchCache._();
  
  static const String _friendsCacheKey = 'offline_friends_cache_v1';
  static const String _contactsCacheKey = 'offline_contacts_cache_v1';
  static const String _recentSearchesKey = 'offline_recent_searches_v1';
  static const String _lastSyncKey = 'offline_cache_last_sync';
  
  // In-memory cache for ultra-fast access
  List<CachedUser> _friendsCache = [];
  List<CachedUser> _contactsCache = [];
  List<String> _recentSearches = [];
  DateTime? _lastSyncTime;
  
  bool _isInitialized = false;
  
  /// Initialize the offline cache
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadFromLocalStorage();
      _isInitialized = true;
      
      // Check if sync is needed
      if (_shouldSync()) {
        // Sync in background, don't block initialization
        _syncFromFirestore();
      }
      
      AppLogger.d('✅ OfflineSearchCache initialized with ${_friendsCache.length} friends');
    } catch (e) {
      AppLogger.w('⚠️ Error initializing offline cache: $e');
      _isInitialized = true; // Still mark as initialized to prevent repeated attempts
    }
  }
  
  /// Search offline cache with fuzzy matching
  Future<List<UserSearchResult>> search(String query, {int limit = 20}) async {
    if (!_isInitialized) await initialize();
    
    if (query.trim().isEmpty) return [];
    
    final queryLower = query.toLowerCase().trim();
    final results = <_ScoredResult>[];
    
    // Search friends first (higher priority)
    for (final friend in _friendsCache) {
      final score = _calculateMatchScore(friend, queryLower);
      if (score > 0.3) {
        results.add(_ScoredResult(
          user: UserSearchResult(
            uid: friend.uid,
            name: friend.name,
            email: friend.email,
            phoneNumber: friend.phoneNumber,
            profilePicture: friend.profilePicture,
            matchScore: score,
            isContact: false,
          ),
          score: score + 0.2, // Boost friends
        ));
      }
    }
    
    // Search contacts
    for (final contact in _contactsCache) {
      final score = _calculateMatchScore(contact, queryLower);
      if (score > 0.3) {
        // Avoid duplicates (same user in both friends and contacts)
        if (!results.any((r) => r.user.uid == contact.uid)) {
          results.add(_ScoredResult(
            user: UserSearchResult(
              uid: contact.uid,
              name: contact.name,
              email: contact.email,
              phoneNumber: contact.phoneNumber,
              profilePicture: contact.profilePicture,
              matchScore: score,
              isContact: true,
            ),
            score: score,
          ));
        }
      }
    }
    
    // Sort by score and return top results
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).map((r) => r.user).toList();
  }
  
  /// Get smart suggestions based on query and recent searches
  Future<List<String>> getSuggestions(String query, {int limit = 5}) async {
    if (!_isInitialized) await initialize();
    
    final queryLower = query.toLowerCase().trim();
    final suggestions = <_ScoredSuggestion>[];
    
    // Recent searches that match
    for (final recent in _recentSearches) {
      if (recent.toLowerCase().startsWith(queryLower)) {
        suggestions.add(_ScoredSuggestion(
          text: recent,
          score: 1.0,
          isRecent: true,
        ));
      }
    }
    
    // Names from cache that match
    final allUsers = [..._friendsCache, ..._contactsCache];
    final seenNames = <String>{};
    
    for (final user in allUsers) {
      final nameLower = user.name.toLowerCase();
      if (nameLower.startsWith(queryLower) && !seenNames.contains(nameLower)) {
        seenNames.add(nameLower);
        suggestions.add(_ScoredSuggestion(
          text: user.name,
          score: 0.8,
          isRecent: false,
        ));
      }
    }
    
    // Sort and deduplicate
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(limit).map((s) => s.text).toList();
  }
  
  /// Add a search to recent searches
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    _recentSearches.remove(query); // Remove if exists
    _recentSearches.insert(0, query); // Add to front
    
    // Keep only last 20 searches
    if (_recentSearches.length > 20) {
      _recentSearches = _recentSearches.take(20).toList();
    }
    
    await _saveToLocalStorage();
  }
  
  /// Force sync from Firestore
  Future<void> forceSync() async {
    await _syncFromFirestore();
  }
  
  /// Calculate match score using fuzzy matching
  double _calculateMatchScore(CachedUser user, String query) {
    double maxScore = 0.0;
    
    // Name matching (highest priority)
    if (user.name.isNotEmpty) {
      final nameLower = user.name.toLowerCase();
      
      // Exact prefix match
      if (nameLower.startsWith(query)) {
        maxScore = 1.0;
      }
      // Contains match
      else if (nameLower.contains(query)) {
        maxScore = 0.8;
      }
      // Fuzzy match
      else {
        final fuzzyScore = ratio(query, nameLower) / 100.0;
        if (fuzzyScore > maxScore) maxScore = fuzzyScore;
      }
    }
    
    // Email matching
    if (user.email != null && user.email!.isNotEmpty) {
      final emailLower = user.email!.toLowerCase();
      if (emailLower.startsWith(query)) {
        maxScore = maxScore > 0.9 ? maxScore : 0.9;
      } else if (emailLower.contains(query)) {
        maxScore = maxScore > 0.7 ? maxScore : 0.7;
      }
    }
    
    // Phone matching
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      final cleanQuery = query.replaceAll(RegExp(r'[^\d]'), '');
      final cleanPhone = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanQuery.isNotEmpty && cleanPhone.contains(cleanQuery)) {
        maxScore = maxScore > 0.85 ? maxScore : 0.85;
      }
    }
    
    return maxScore;
  }
  
  bool _shouldSync() {
    if (_lastSyncTime == null) return true;
    
    // Sync if last sync was more than 30 minutes ago
    final elapsed = DateTime.now().difference(_lastSyncTime!);
    return elapsed.inMinutes > 30;
  }
  
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load friends
      final friendsJson = prefs.getString(_friendsCacheKey);
      if (friendsJson != null) {
        final friendsList = jsonDecode(friendsJson) as List;
        _friendsCache = friendsList.map((j) => CachedUser.fromJson(j)).toList();
      }
      
      // Load contacts
      final contactsJson = prefs.getString(_contactsCacheKey);
      if (contactsJson != null) {
        final contactsList = jsonDecode(contactsJson) as List;
        _contactsCache = contactsList.map((j) => CachedUser.fromJson(j)).toList();
      }
      
      // Load recent searches
      final recentJson = prefs.getString(_recentSearchesKey);
      if (recentJson != null) {
        _recentSearches = List<String>.from(jsonDecode(recentJson));
      }
      
      // Load last sync time
      final lastSyncMs = prefs.getInt(_lastSyncKey);
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }
      
    } catch (e) {
      AppLogger.w('Error loading offline cache: $e');
    }
  }
  
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_friendsCacheKey, 
          jsonEncode(_friendsCache.map((u) => u.toJson()).toList()));
      await prefs.setString(_contactsCacheKey, 
          jsonEncode(_contactsCache.map((u) => u.toJson()).toList()));
      await prefs.setString(_recentSearchesKey, jsonEncode(_recentSearches));
      
      if (_lastSyncTime != null) {
        await prefs.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      AppLogger.w('Error saving offline cache: $e');
    }
  }
  
  Future<void> _syncFromFirestore() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      AppLogger.d('🔄 Syncing offline cache from Firestore...');
      
      // Fetch friends
      final friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .limit(500) // Reasonable limit
          .get();
      
      final friendIds = friendsSnapshot.docs.map((d) => d.id).toList();
      
      if (friendIds.isNotEmpty) {
        // Fetch friend details in batches
        final friendDetails = <CachedUser>[];
        
        for (int i = 0; i < friendIds.length; i += 10) {
          final batchIds = friendIds.skip(i).take(10).toList();
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          
          for (final doc in usersSnapshot.docs) {
            final data = doc.data();
            friendDetails.add(CachedUser(
              uid: doc.id,
              name: _buildDisplayName(data),
              email: data['email'] as String?,
              phoneNumber: data['phoneNumber'] as String?,
              profilePicture: data['customPhotoURL'] as String? ?? 
                             data['photoURL'] as String?,
            ));
          }
        }
        
        _friendsCache = friendDetails;
      }
      
      // Fetch matched contacts
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('user_contacts')
          .doc(currentUser.uid)
          .get();
      
      if (contactsSnapshot.exists) {
        final matches = contactsSnapshot.data()?['matches'] as List? ?? [];
        _contactsCache = matches.map((m) => CachedUser(
          uid: m['uid'] as String? ?? '',
          name: m['name'] as String? ?? '',
          email: m['email'] as String?,
          phoneNumber: m['phoneNumber'] as String?,
          profilePicture: m['profilePicture'] as String?,
        )).where((u) => u.uid.isNotEmpty).toList();
      }
      
      _lastSyncTime = DateTime.now();
      await _saveToLocalStorage();
      
      AppLogger.d('✅ Offline cache synced: ${_friendsCache.length} friends, ${_contactsCache.length} contacts');
      
    } catch (e) {
      AppLogger.w('⚠️ Error syncing offline cache: $e');
    }
  }
  
  String _buildDisplayName(Map<String, dynamic> data) {
    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    final displayName = data['displayName'] as String? ?? '';
    final fullName = data['fullName'] as String? ?? '';
    
    if (fullName.isNotEmpty) return fullName;
    if (firstName.isNotEmpty) {
      return lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    }
    if (displayName.isNotEmpty) return displayName;
    return 'User';
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'friendsCount': _friendsCache.length,
      'contactsCount': _contactsCache.length,
      'recentSearchesCount': _recentSearches.length,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
    };
  }
}

/// Cached user model for local storage
class CachedUser {
  final String uid;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? profilePicture;
  
  const CachedUser({
    required this.uid,
    required this.name,
    this.email,
    this.phoneNumber,
    this.profilePicture,
  });
  
  factory CachedUser.fromJson(Map<String, dynamic> json) {
    return CachedUser(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
    };
  }
}

class _ScoredResult {
  final UserSearchResult user;
  final double score;
  
  const _ScoredResult({required this.user, required this.score});
}

class _ScoredSuggestion {
  final String text;
  final double score;
  final bool isRecent;
  
  const _ScoredSuggestion({
    required this.text,
    required this.score,
    required this.isRecent,
  });
}
