import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/models/app_user.dart';
import 'package:shopple/services/media/image_upload_service.dart';
import '../../utils/app_logger.dart';

/// Service extension for handling enhanced profile picture system
/// Provides migration and compatibility methods for existing users
class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate existing user to enhanced profile picture system
  /// This ensures backward compatibility with existing users
  static Future<void> migrateUserToEnhancedProfileSystem() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      // Check if user already has enhanced profile system fields
      if (data.containsKey('profileImageType')) {
        AppLogger.d('✅ User already migrated to enhanced profile system');
        return;
      }

      AppLogger.d('🔄 Migrating user to enhanced profile system...');

      // Prepare migration data
      Map<String, dynamic> migrationData = {
        'profileImageType': null,
        'customPhotoURL': null,
        'defaultImageId': null,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      };

      // Determine profile image type based on existing data
      if (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) {
        final String photoURL = data['photoURL'];

        if (photoURL.contains('firebasestorage.googleapis.com')) {
          // It's a custom uploaded image
          migrationData['profileImageType'] = 'custom';
          migrationData['customPhotoURL'] = photoURL;
        } else if (photoURL.contains('googleusercontent.com')) {
          // It's a Google profile image
          migrationData['profileImageType'] = 'google';
        } else {
          // It might be a default avatar or asset
          migrationData['profileImageType'] = 'default';
          migrationData['defaultImageId'] = photoURL;
        }
      }

      // Check for profilePicture field (memoji)
      if (data['profilePicture'] != null &&
          data['profilePicture'].toString().isNotEmpty) {
        migrationData['profileImageType'] = 'memoji';
        migrationData['defaultImageId'] = data['profilePicture'];
      }

      // If no profile image found, set to default
      if (migrationData['profileImageType'] == null) {
        migrationData['profileImageType'] = 'default';
      }

      await _firestore.collection('users').doc(user.uid).update(migrationData);

      AppLogger.d('✅ User migrated to enhanced profile system');
    } catch (e) {
      AppLogger.e(
        '❌ Error migrating user to enhanced profile system',
        error: e,
      );
    }
  }

  /// Get enhanced user profile with hybrid system support
  static Future<AppUser?> getEnhancedUserProfile(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      return AppUser.fromFirestore(userDoc);
    } catch (e, st) {
      AppLogger.e(
        'Error getting enhanced user profile',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Update user profile image with hybrid system
  static Future<bool> updateUserProfileImage(AppUser userData) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(userData.toFirestore());
      AppLogger.d('✅ User profile image updated successfully');
      return true;
    } catch (e) {
      AppLogger.e('❌ Error updating user profile image', error: e);
      return false;
    }
  }

  /// Get effective profile picture URL for display
  /// Wrapper method for easy access
  static Future<String?> getEffectiveProfilePictureUrl(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      return ImageUploadService.getEffectiveProfilePictureUrl(
        profileImageType: data['profileImageType'],
        customPhotoURL: data['customPhotoURL'],
        photoURL: data['photoURL'],
        defaultImageId: data['defaultImageId'] ?? data['profilePicture'],
      );
    } catch (e, st) {
      AppLogger.e(
        'Error getting effective profile picture URL',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Check if user has a custom uploaded image
  static Future<bool> hasCustomProfileImage(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return data['profileImageType'] == 'custom' &&
          data['customPhotoURL'] != null &&
          data['customPhotoURL'].toString().isNotEmpty;
    } catch (e, st) {
      AppLogger.e(
        'Error checking custom profile image',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get profile image type for a user
  static Future<String?> getProfileImageType(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return data['profileImageType'];
    } catch (e, st) {
      AppLogger.e('Error getting profile image type', error: e, stackTrace: st);
      return null;
    }
  }
}
