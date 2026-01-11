import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/utils/app_logger.dart';

class UserTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // New user - create initial document
        await _createUserDocument(user);
        return false;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return userData['onboardingCompleted'] ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error checking onboarding status',
          error: e,
        );
      }
      return false;
    }
  }

  // Create initial user document
  static Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'signInMethod': _getSignInMethod(user),
      });

      if (kDebugMode) {
        AppLogger.d(
          'UserTrackingService: Created user document for ${user.email}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error creating user document',
          error: e,
        );
      }
    }
  }

  // Save workspace settings
  static Future<void> saveWorkspaceSettings({
    required String workspaceName,
    required int selectedColorIndex,
    String? workspaceImage,
    String? householdSize,
    String? familyEmail,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      Map<String, dynamic> updateData = {
        'workspaceName': workspaceName,
        'selectedColorIndex': selectedColorIndex,
        'workspaceSetupAt': FieldValue.serverTimestamp(),
      };

      if (workspaceImage != null) updateData['workspaceImage'] = workspaceImage;
      if (householdSize != null) updateData['householdSize'] = householdSize;
      if (familyEmail != null && familyEmail.isNotEmpty) {
        updateData['familyEmail'] = familyEmail;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

      if (kDebugMode) {
        AppLogger.d(
          'UserTrackingService: Saved workspace settings for ${user.email}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error saving workspace settings',
          error: e,
        );
      }
    }
  }

  // Save subscription choice
  static Future<void> saveSubscriptionChoice({
    required String planType, // 'free' or 'premium'
    required bool multipleAssignees,
    required bool customLabels,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionPlan': planType,
        'features': {
          'multipleAssignees': multipleAssignees,
          'customLabels': customLabels,
        },
        'hasCompletedOnboarding':
            true, // Use consistent field name with AppUser model
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        AppLogger.d(
          'UserTrackingService: Completed onboarding for ${user.email} with plan: $planType',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error saving subscription choice',
          error: e,
        );
      }
    }
  }

  // Get user workspace settings
  static Future<Map<String, dynamic>?> getUserWorkspaceSettings() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error getting user settings',
          error: e,
        );
      }
      return null;
    }
  }

  // Detect sign-in method
  static String _getSignInMethod(User user) {
    if (user.providerData.isEmpty) return 'anonymous';

    for (UserInfo provider in user.providerData) {
      switch (provider.providerId) {
        case 'google.com':
          return 'google';
        case 'password':
          return 'email';
        case 'apple.com':
          return 'apple';
        default:
          return provider.providerId;
      }
    }
    return 'unknown';
  }

  // Reset onboarding status (for testing)
  static Future<void> resetOnboardingStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'onboardingCompleted': false,
      });

      if (kDebugMode) {
        AppLogger.d(
          'UserTrackingService: Reset onboarding status for ${user.email}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e(
          'UserTrackingService: Error resetting onboarding',
          error: e,
        );
      }
    }
  }

  // Initialize user on first sign-in (call from auth service)
  // OPTIMIZED: Non-blocking version for better startup performance
  static Future<void> initializeUserOnSignIn() async {
    // Optimistic: return immediately, do Firestore work in background
    User? user = _auth.currentUser;
    if (user == null) return;

    // Background task - doesn't block navigation
    _initializeUserDocumentInBackground(user);
  }

  /// Background initialization - doesn't block UI thread
  static void _initializeUserDocumentInBackground(User user) {
    // Use microtask to ensure this runs after navigation
    Future.microtask(() async {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          await _createUserDocument(user);
        } else {
          // Update last sign-in time for existing users
          await _firestore.collection('users').doc(user.uid).update({
            'lastSignInAt': FieldValue.serverTimestamp(),
          });
        }
        if (kDebugMode) {
          AppLogger.d(
            'UserTrackingService: Background initialization complete for ${user.email}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.e(
            'UserTrackingService: Error in background initialization',
            error: e,
          );
        }
      }
    });
  }
}
