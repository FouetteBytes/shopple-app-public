import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/models/user_privacy_settings.dart';

/// Centralized service for loading and caching other users' details
/// (display name, email, phone, sign-in method, profile image).
/// 
/// This service provides a single source of truth for user information
/// across the app: Friends list, Shopping List collaborators, Chat, etc.
class OtherUserDetailsService {
  OtherUserDetailsService._();
  static OtherUserDetailsService instance = OtherUserDetailsService._();
  
  /// Firestore instance - can be overridden for testing (lazy loaded)
  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  set firestore(FirebaseFirestore value) => _firestore = value;
  
  // In-memory cache for user details
  final Map<String, OtherUserDetails> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<OtherUserDetails?>> _inFlight = {};
  
  // Cache validity: 5 minutes
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get user details from cache or fetch from Firestore
  Future<OtherUserDetails?> getUserDetails(String userId) async {
    if (userId.isEmpty) return null;
    
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
      return _inFlight[userId];
    }
    
    // Fetch from Firestore
    final future = _fetchUserDetails(userId);
    _inFlight[userId] = future;
    
    try {
      final result = await future;
      return result;
    } finally {
      _inFlight.remove(userId);
    }
  }

  /// Get cached details immediately (may return null if not cached)
  OtherUserDetails? getCached(String userId) {
    return _cache[userId];
  }

  /// Prefetch multiple users' details
  Future<void> prefetch(Iterable<String> userIds) async {
    final missing = userIds.where((id) => 
      id.isNotEmpty && 
      !_cache.containsKey(id) && 
      !_inFlight.containsKey(id)
    ).toList();
    
    if (missing.isEmpty) return;
    
    await Future.wait(missing.map(getUserDetails));
  }

  /// Get a stream of user details (useful for real-time updates)
  Stream<OtherUserDetails?> watchUserDetails(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          
          final data = snapshot.data() as Map<String, dynamic>;
          final details = OtherUserDetails.fromFirestore(userId, data);
          
          // Update cache
          _cache[userId] = details;
          _cacheTimestamps[userId] = DateTime.now();
          
          return details;
        });
  }

  Future<OtherUserDetails?> _fetchUserDetails(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        AppLogger.w('User document not found for userId: $userId');
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final details = OtherUserDetails.fromFirestore(userId, data);
      
      // Update cache
      _cache[userId] = details;
      _cacheTimestamps[userId] = DateTime.now();
      
      return details;
    } catch (e) {
      AppLogger.e('Error fetching user details for $userId: $e');
      return _cache[userId]; // Return stale cache on error
    }
  }

  /// Update cache with fresh data (called after friend acceptance, etc.)
  void updateCache(String userId, OtherUserDetails details) {
    _cache[userId] = details;
    _cacheTimestamps[userId] = DateTime.now();
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
}

/// Model class for other users' details
class OtherUserDetails {
  final String userId;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? signInMethod; // 'phone', 'email', 'google'
  final String? firstName;
  final String? lastName;
  final UserPrivacySettings? privacySettings;

  const OtherUserDetails({
    required this.userId,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.signInMethod,
    this.firstName,
    this.lastName,
    this.privacySettings,
  });

  factory OtherUserDetails.fromFirestore(String userId, Map<String, dynamic> data) {
    // Build display name from available fields
    final firstName = data['firstName'] as String?;
    final lastName = data['lastName'] as String?;
    final fullName = data['fullName'] as String?;
    final displayName = data['displayName'] as String?;
    
    String resolvedDisplayName;
    if (fullName != null && fullName.isNotEmpty) {
      resolvedDisplayName = fullName;
    } else if (firstName != null && firstName.isNotEmpty) {
      resolvedDisplayName = lastName != null && lastName.isNotEmpty
          ? '$firstName $lastName'
          : firstName;
    } else if (displayName != null && displayName.isNotEmpty) {
      resolvedDisplayName = displayName;
    } else {
      resolvedDisplayName = 'User';
    }

    // Get profile image URL (prefer custom, then Google, then default)
    String? profileImageUrl = data['customPhotoURL'] as String?;
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      profileImageUrl = data['photoURL'] as String?;
    }

    return OtherUserDetails(
      userId: userId,
      displayName: resolvedDisplayName,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      profileImageUrl: profileImageUrl,
      signInMethod: data['signInMethod'] as String?,
      firstName: firstName,
      lastName: lastName,
      privacySettings: null, // Privacy is loaded separately
    );
  }

  /// Create a copy with privacy settings applied
  OtherUserDetails withPrivacySettings(UserPrivacySettings settings) {
    return OtherUserDetails(
      userId: userId,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      signInMethod: signInMethod,
      firstName: firstName,
      lastName: lastName,
      privacySettings: settings,
    );
  }

  /// Get the display name with privacy applied
  String getDisplayName({UserPrivacySettings? privacy}) {
    final settings = privacy ?? privacySettings ?? UserPrivacySettings.defaultSettings;
    return ContactMasker.applyVisibility(displayName, settings.nameVisibility, ContactType.name) ?? 'User';
  }

  /// Get the email with privacy applied
  String? getEmail({UserPrivacySettings? privacy}) {
    final settings = privacy ?? privacySettings ?? UserPrivacySettings.defaultSettings;
    return ContactMasker.applyVisibility(email, settings.emailVisibility, ContactType.email);
  }

  /// Get the phone with privacy applied
  String? getPhone({UserPrivacySettings? privacy}) {
    final settings = privacy ?? privacySettings ?? UserPrivacySettings.defaultSettings;
    return ContactMasker.applyVisibility(phoneNumber, settings.phoneVisibility, ContactType.phone);
  }

  /// Get the primary contact info based on sign-in method (raw, no privacy)
  String? get primaryContact {
    final method = signInMethod ?? 'email';
    
    if (method == 'phone') {
      return phoneNumber?.isNotEmpty == true ? phoneNumber : email;
    } else {
      return email?.isNotEmpty == true ? email : phoneNumber;
    }
  }

  /// Get primary contact with privacy applied
  String? getPrimaryContactWithPrivacy({UserPrivacySettings? privacy}) {
    final settings = privacy ?? privacySettings ?? UserPrivacySettings.defaultSettings;
    final method = signInMethod ?? 'email';
    
    if (method == 'phone') {
      final phone = getPhone(privacy: settings);
      return phone ?? getEmail(privacy: settings);
    } else {
      final email = getEmail(privacy: settings);
      return email ?? getPhone(privacy: settings);
    }
  }

  /// Get the secondary contact info (raw, no privacy)
  String? get secondaryContact {
    final method = signInMethod ?? 'email';
    
    if (method == 'phone') {
      return email?.isNotEmpty == true ? email : null;
    } else {
      return phoneNumber?.isNotEmpty == true ? phoneNumber : null;
    }
  }

  /// Get a formatted "last seen" text for display
  String getContactDisplay() {
    final primary = primaryContact;
    if (primary != null && primary.isNotEmpty) {
      return primary;
    }
    return 'No contact info';
  }

  @override
  String toString() {
    return 'OtherUserDetails(userId: $userId, displayName: $displayName, '
           'email: $email, phoneNumber: $phoneNumber, signInMethod: $signInMethod)';
  }
}
