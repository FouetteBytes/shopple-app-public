import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/models/user_privacy_settings.dart';
import 'package:shopple/utils/app_logger.dart';

/// Service for managing user privacy settings
/// Provides caching and real-time updates for privacy settings
class PrivacySettingsService {
  PrivacySettingsService._();
  static final PrivacySettingsService instance = PrivacySettingsService._();

  // Allow override for testing
  FirebaseFirestore? _firestoreOverride;
  FirebaseAuth? _authOverride;
  
  /// Get Firestore instance (lazy-loaded to support testing)
  FirebaseFirestore get _firestore => 
      _firestoreOverride ?? FirebaseFirestore.instance;
  
  /// Get Auth instance (lazy-loaded to support testing)
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  
  /// Set Firestore instance for testing
  set firestore(FirebaseFirestore? value) => _firestoreOverride = value;
  
  /// Set Auth instance for testing
  set auth(FirebaseAuth? value) => _authOverride = value;

  // Cache for privacy settings
  final Map<String, UserPrivacySettings> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 10);

  // In-flight requests to avoid duplicate fetches
  final Map<String, Future<UserPrivacySettings>> _inFlight = {};

  /// Get current user's privacy settings
  Future<UserPrivacySettings> getCurrentUserSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return UserPrivacySettings.defaultSettings;
    return getUserSettings(userId);
  }

  /// Get privacy settings for a specific user
  Future<UserPrivacySettings> getUserSettings(String userId) async {
    if (userId.isEmpty) return UserPrivacySettings.defaultSettings;

    // Check cache first
    final cached = _cache[userId];
    final timestamp = _cacheTimestamps[userId];
    if (cached != null && timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age < _cacheTimeout) {
        return cached;
      }
    }

    // Check if already fetching
    if (_inFlight.containsKey(userId)) {
      return _inFlight[userId]!;
    }

    // Fetch from Firestore
    final future = _fetchSettings(userId);
    _inFlight[userId] = future;

    try {
      return await future;
    } finally {
      _inFlight.remove(userId);
    }
  }

  Future<UserPrivacySettings> _fetchSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .get();

      final settings = doc.exists
          ? UserPrivacySettings.fromFirestore(doc.data())
          : UserPrivacySettings.defaultSettings;

      // Update cache
      _cache[userId] = settings;
      _cacheTimestamps[userId] = DateTime.now();

      AppLogger.d('Loaded privacy settings for $userId: $settings');
      return settings;
    } catch (e) {
      AppLogger.e('Error fetching privacy settings for $userId: $e');
      return _cache[userId] ?? UserPrivacySettings.defaultSettings;
    }
  }

  /// Get cached settings immediately (may return default if not cached)
  UserPrivacySettings getCached(String userId) {
    return _cache[userId] ?? UserPrivacySettings.defaultSettings;
  }

  /// Watch privacy settings for a specific user
  Stream<UserPrivacySettings> watchUserSettings(String userId) {
    if (userId.isEmpty) {
      return Stream.value(UserPrivacySettings.defaultSettings);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('privacy')
        .snapshots()
        .map((snapshot) {
      final settings = snapshot.exists
          ? UserPrivacySettings.fromFirestore(snapshot.data())
          : UserPrivacySettings.defaultSettings;

      // Update cache
      _cache[userId] = settings;
      _cacheTimestamps[userId] = DateTime.now();

      return settings;
    });
  }

  /// Watch current user's privacy settings
  Stream<UserPrivacySettings> watchCurrentUserSettings() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(UserPrivacySettings.defaultSettings);
    }
    return watchUserSettings(userId);
  }

  /// Save privacy settings for current user
  Future<void> saveSettings(UserPrivacySettings settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .set(settings.toFirestore(), SetOptions(merge: true));

      // Update cache
      _cache[userId] = settings;
      _cacheTimestamps[userId] = DateTime.now();

      // Also update the main user document with searchability flags
      // This allows the search service to filter users efficiently
      await _firestore.collection('users').doc(userId).update({
        'privacy': {
          'searchableByName': settings.searchableByName,
          'searchableByEmail': settings.searchableByEmail,
          'searchableByPhone': settings.searchableByPhone,
          'isFullyPrivate': settings.isFullyPrivate,
        },
      });

      AppLogger.d('Saved privacy settings for $userId: $settings');
    } catch (e) {
      AppLogger.e('Error saving privacy settings: $e');
      rethrow;
    }
  }

  /// Update a single setting
  Future<void> updateSetting({
    bool? searchableByName,
    bool? searchableByEmail,
    bool? searchableByPhone,
    bool? isFullyPrivate,
    ContactVisibility? emailVisibility,
    ContactVisibility? phoneVisibility,
    ContactVisibility? nameVisibility,
  }) async {
    final currentSettings = await getCurrentUserSettings();
    final newSettings = currentSettings.copyWith(
      searchableByName: searchableByName,
      searchableByEmail: searchableByEmail,
      searchableByPhone: searchableByPhone,
      isFullyPrivate: isFullyPrivate,
      emailVisibility: emailVisibility,
      phoneVisibility: phoneVisibility,
      nameVisibility: nameVisibility,
    );
    await saveSettings(newSettings);
  }

  /// Clear cache for a specific user
  void clearUser(String userId) {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if a user is searchable by the query type
  Future<bool> isUserSearchable(
    String userId, {
    bool byName = false,
    bool byEmail = false,
    bool byPhone = false,
  }) async {
    final settings = await getUserSettings(userId);
    
    if (settings.isFullyPrivate) return false;
    
    if (byName && settings.searchableByName) return true;
    if (byEmail && settings.searchableByEmail) return true;
    if (byPhone && settings.searchableByPhone) return true;
    
    return false;
  }
}
