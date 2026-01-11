import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/services/media/image_upload_service.dart';
import 'package:shopple/utils/app_logger.dart';

class ProfilePictureService {
  // Get available memoji dynamically by checking for assets 1.png to N.png
  static Future<List<String>> getAvailableMemojis() async {
    // Hardcoded list; Flutter lacks runtime asset enumeration
    List<String> memojiList = [
      'assets/memoji/1.png',
      'assets/memoji/2.png',
      'assets/memoji/3.png',
      'assets/memoji/4.png',
      'assets/memoji/5.png',
      'assets/memoji/6.png',
      'assets/memoji/7.png',
      'assets/memoji/8.png',
      'assets/memoji/9.png',
      'assets/memoji/10.png',
      'assets/memoji/11.png',
      'assets/memoji/12.png',
      'assets/memoji/13.png',
      'assets/memoji/14.png',
      'assets/memoji/15.png',
      'assets/memoji/16.png',
      'assets/memoji/17.png',
      'assets/memoji/18.png',
      'assets/memoji/19.png',
      'assets/memoji/20.png',
      'assets/memoji/21.png',
      'assets/memoji/22.png',
    ];

    return memojiList;
  }

  /// Get user's current profile picture using hybrid system
  static Future<String?> getCurrentProfilePicture() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Use the new hybrid system to determine effective profile picture
          return ImageUploadService.getEffectiveProfilePictureUrl(
            profileImageType: userData['profileImageType'],
            customPhotoURL: userData['customPhotoURL'],
            photoURL: userData['photoURL'],
            defaultImageId:
                userData['defaultImageId'] ?? userData['profilePicture'],
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error getting profile picture', error: e);
    }
    return null;
  }

  /// Update user's profile picture (memoji/default avatars)
  /// This preserves your existing functionality while adding hybrid support
  static Future<bool> updateProfilePicture(String memojiPath) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Remove any existing custom images since user is selecting a memoji
        await ImageUploadService.removeAllCustomProfilePictures();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'profilePicture': memojiPath, // Keep for backward compatibility
              // NEW: Hybrid system fields
              'profileImageType': 'memoji',
              'defaultImageId': memojiPath,
              'customPhotoURL': null, // Clear custom URL
              'photoUpdatedAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        return true;
      }
    } catch (e) {
      AppLogger.e('Error updating profile picture', error: e);
    }
    return false;
  }

  /// Update user's profile with custom uploaded image
  /// NEW: Handle custom image updates in the hybrid system
  static Future<bool> updateCustomProfilePicture(String downloadUrl) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              // NEW: Hybrid system fields
              'profileImageType': 'custom',
              'customPhotoURL': downloadUrl,
              'defaultImageId': null, // Clear default selection
              'photoUpdatedAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
              // Keep backward compatibility
              'photoURL': downloadUrl,
            });
        return true;
      }
    } catch (e) {
      AppLogger.e('Error updating custom profile picture', error: e);
    }
    return false;
  }

  /// Reset to default avatar with user initials
  /// NEW: Handle reset to initial-based avatar
  static Future<bool> resetToDefaultAvatar() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Remove any existing custom images
        await ImageUploadService.removeAllCustomProfilePictures();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              // Clear all profile images to show initials
              'profilePicture': null,
              'photoURL': null,
              // NEW: Hybrid system fields
              'profileImageType': 'default',
              'customPhotoURL': null,
              'defaultImageId': null,
              'photoUpdatedAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        return true;
      }
    } catch (e) {
      AppLogger.e('Error resetting to default avatar', error: e);
    }
    return false;
  }

  /// Get user initial for avatar
  static Future<String> getUserInitial() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // For Google users
          if (userData['signInMethod'] == 'google' &&
              userData['displayName'] != null) {
            return userData['displayName'][0].toUpperCase();
          }

          // For phone/email users - use firstName
          if (userData['firstName'] != null &&
              userData['firstName'].toString().isNotEmpty) {
            return userData['firstName'][0].toUpperCase();
          }

          // Fallback to displayName
          if (userData['displayName'] != null &&
              userData['displayName'].toString().isNotEmpty) {
            return userData['displayName'][0].toUpperCase();
          }
        }
      }
    } catch (e) {
      AppLogger.e('Error getting user initial', error: e);
    }
    return 'U';
  }

  /// Preload memoji assets for faster loading (batched to avoid long frame stalls)
  static Future<void> preloadMemojiAssets(
    BuildContext context, {
    int batchSize = 4,
    Duration batchDelay = const Duration(milliseconds: 30),
  }) async {
    try {
      final memojiList = await getAvailableMemojis();
      for (int i = 0; i < memojiList.length; i += batchSize) {
        if (!context.mounted) break;
        final slice = memojiList.sublist(
          i,
          (i + batchSize).clamp(0, memojiList.length),
        );
        final futures = <Future>[];
        for (final path in slice) {
          futures.add(
            precacheImage(AssetImage(path), context).catchError((_) {}),
          );
        }
        await Future.wait(futures);
        if (i + batchSize < memojiList.length) {
          await Future.delayed(batchDelay); // yield
        }
      }
      AppLogger.d(
        '✅ All ${memojiList.length} memoji assets preloaded (batched)',
      );
    } catch (e) {
      AppLogger.e('❌ Error preloading memoji assets', error: e);
    }
  }

  /// Lazy ensure single memoji cached (call when first displayed)
  static Future<void> ensureMemojiCached(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      await precacheImage(AssetImage(assetPath), context);
    } catch (_) {}
  }
}
