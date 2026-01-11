import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/utils/app_logger.dart';

class ProfileAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track profile picture upload events
  static Future<void> trackProfilePictureUpload({
    required String userId,
    required String imageType, // 'custom', 'google', 'default'
    required String source, // 'camera', 'gallery', 'google', 'memoji'
    int? fileSizeBytes,
    String? compressionLevel,
    Duration? uploadDuration,
  }) async {
    try {
      // Store detailed analytics in Firestore
      await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('picture_events')
          .add({
            'event_type': 'upload',
            'image_type': imageType,
            'source': source,
            'file_size_bytes': fileSizeBytes,
            'compression_level': compressionLevel,
            'upload_duration_ms': uploadDuration?.inMilliseconds,
            'timestamp': FieldValue.serverTimestamp(),
            'device_info': await _getDeviceInfo(),
          });

      // Update user's profile picture stats
      await _updateUserStats(userId, 'upload', imageType);
    } catch (e) {
      AppLogger.e('Error tracking profile picture upload', error: e);
    }
  }

  /// Track profile picture view events
  static Future<void> trackProfilePictureView({
    required String userId,
    required String imageType,
    required String viewContext, // 'profile', 'edit', 'modal', 'list'
    Duration? loadTime,
    bool? fromCache,
  }) async {
    try {
      await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('view_events')
          .add({
            'event_type': 'view',
            'image_type': imageType,
            'view_context': viewContext,
            'load_time_ms': loadTime?.inMilliseconds,
            'from_cache': fromCache ?? false,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.e('Error tracking profile picture view', error: e);
    }
  }

  /// Track profile picture errors
  static Future<void> trackProfilePictureError({
    required String userId,
    required String
    errorType, // 'upload_failed', 'permission_denied', 'compression_failed'
    required String errorMessage,
    String? attemptedAction,
    Map<String, dynamic>? errorContext,
  }) async {
    try {
      // Store error details for debugging
      await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('error_events')
          .add({
            'error_type': errorType,
            'error_message': errorMessage,
            'attempted_action': attemptedAction,
            'error_context': errorContext,
            'timestamp': FieldValue.serverTimestamp(),
            'device_info': await _getDeviceInfo(),
          });

      // Update error stats
      await _updateUserStats(userId, 'error', errorType);
    } catch (e) {
      AppLogger.e('Error tracking profile picture error', error: e);
    }
  }

  /// Track user engagement with profile picture features
  static Future<void> trackProfilePictureEngagement({
    required String userId,
    required String
    action, // 'modal_opened', 'source_selected', 'image_cropped', 'save_clicked'
    String? feature, // 'camera', 'gallery', 'memoji', 'google'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('engagement_events')
          .add({
            'event_type': 'engagement',
            'action': action,
            'feature': feature ?? 'unknown',
            'additional_data': additionalData,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.e('Error tracking profile picture engagement', error: e);
    }
  }

  /// Get user profile picture analytics summary
  static Future<Map<String, dynamic>?> getUserProfileAnalytics(
    String userId,
  ) async {
    try {
      final userStats = await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .get();

      final pictureEvents = await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('picture_events')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final errorEvents = await _firestore
          .collection('profile_analytics')
          .doc(userId)
          .collection('error_events')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      return {
        'stats': userStats.data() ?? {},
        'recent_uploads': pictureEvents.docs.map((doc) => doc.data()).toList(),
        'recent_errors': errorEvents.docs.map((doc) => doc.data()).toList(),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('Error getting user profile analytics', error: e);
      return null;
    }
  }

  /// Update user statistics
  static Future<void> _updateUserStats(
    String userId,
    String eventType,
    String imageType,
  ) async {
    try {
      final userStatsRef = _firestore
          .collection('profile_analytics')
          .doc(userId);

      await userStatsRef.set({
        'total_${eventType}s': FieldValue.increment(1),
        '${imageType}_${eventType}s': FieldValue.increment(1),
        'last_${eventType}_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.e('Error updating user stats', error: e);
    }
  }

  /// Get device info for analytics
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Minimal device metadata
    return {
      'platform': 'mobile',
      'app_version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Track profile picture preferences
  static Future<void> trackProfilePicturePreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _firestore.collection('profile_analytics').doc(userId).set({
        'preferences': preferences,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.e('Error tracking profile picture preferences', error: e);
    }
  }

  /// Get global profile picture usage statistics (admin/insights)
  static Future<Map<String, dynamic>?> getGlobalProfilePictureStats() async {
    try {
      // This would require admin privileges in real-world scenario
      final analytics = await _firestore
          .collection('global_profile_analytics')
          .doc('summary')
          .get();

      return analytics.data();
    } catch (e) {
      AppLogger.e('Error getting global profile picture stats', error: e);
      return null;
    }
  }
}
