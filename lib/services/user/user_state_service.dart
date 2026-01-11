import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/models/app_user.dart';
import 'package:shopple/utils/app_logger.dart';

class UserStateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the current user has completed the onboarding flow
  /// Returns true if user has completed workspace setup, false otherwise
  static Future<bool> hasCompletedOnboarding() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d("UserStateService: No authenticated user found");
        }
        return false;
      }

      // Check user's onboarding status in Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: User document doesn't exist for ${currentUser.email}",
          );
        }
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      bool hasCompletedOnboarding = userData['hasCompletedOnboarding'] ?? false;

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: User ${currentUser.email} onboarding status = $hasCompletedOnboarding",
        );
      }

      return hasCompletedOnboarding;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error checking onboarding status = $e");
      }
      return false;
    }
  }

  /// Mark the current user as having completed onboarding
  static Future<void> markOnboardingComplete() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot mark onboarding complete - no authenticated user",
          );
        }
        return;
      }

      // Create or update user document with onboarding completion
      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': currentUser.email,
        'hasCompletedOnboarding': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Marked onboarding complete for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error marking onboarding complete = $e");
      }
    }
  }

  /// Initialize user document when they first sign up
  static Future<void> initializeUserDocument() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot initialize user document - no authenticated user",
          );
        }
        return;
      }

      // Check if user document already exists
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        // Determine sign-in method based on available data
        String signInMethod = 'email'; // default
        if (currentUser.phoneNumber != null) {
          signInMethod = 'phone';
        } else if (currentUser.providerData.any(
          (info) => info.providerId == 'google.com',
        )) {
          signInMethod = 'google';
        }

        // Create initial user document for new users
        await _firestore.collection('users').doc(currentUser.uid).set({
          'email': currentUser.email ?? '',
          'phoneNumber': currentUser.phoneNumber,
          'signInMethod':
              signInMethod, // CRITICAL: Set the correct sign-in method
          'hasCompletedOnboarding': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Initialized user document for ${currentUser.email ?? currentUser.phoneNumber} with signInMethod: $signInMethod",
          );
        }
      } else {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: User document already exists for ${currentUser.email}",
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error initializing user document = $e");
      }
    }
  }

  /// Reset user onboarding status (for testing or admin purposes)
  static Future<void> resetOnboardingStatus() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot reset onboarding - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'hasCompletedOnboarding': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Reset onboarding status for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error resetting onboarding status = $e");
      }
    }
  }

  // ========================================
  // ENHANCED USER DATA MANAGEMENT
  // ========================================

  /// Get current user as AppUser model
  static Future<AppUser?> getCurrentAppUser() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d("UserStateService: No authenticated user found");
        }
        return null;
      }

      // Get user document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: User document doesn't exist for ${currentUser.email}",
          );
        }
        return null;
      }

      // Create AppUser from Firebase user and Firestore data
      return AppUser.fromFirebaseAndFirestore(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName,
        photoURL: currentUser.photoURL,
        phoneNumber: currentUser.phoneNumber,
        emailVerified: currentUser.emailVerified,
        firestoreData: userDoc.data() as Map<String, dynamic>?,
      );
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error getting current app user = $e");
      }
      return null;
    }
  }

  /// Update user profile with enhanced data
  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? phoneNumber,
    String? email,
    bool? profileCompleted,
    bool markProfileComplete = false,
  }) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot update profile - no authenticated user",
          );
        }
        return;
      }

      Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (email != null) updateData['email'] = email;

      if (markProfileComplete || profileCompleted == true) {
        updateData['profileCompleted'] = true;
        updateData['profileCompletedAt'] = FieldValue.serverTimestamp();
      } else if (profileCompleted == false) {
        updateData['profileCompleted'] = false;
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(updateData, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Updated profile for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error updating user profile = $e");
      }
      rethrow;
    }
  }

  /// Mark email as verified
  static Future<void> markEmailVerified() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot mark email verified - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).set({
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Marked email verified for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error marking email verified = $e");
      }
    }
  }

  /// Mark phone as verified
  static Future<void> markPhoneVerified(String phoneNumber) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot mark phone verified - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).set({
        'phoneNumber': phoneNumber,
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'signInMethod': 'phone', // CRITICAL: Fix signInMethod for phone users
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Marked phone verified for ${currentUser.email}: $phoneNumber and fixed signInMethod to 'phone'",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error marking phone verified = $e");
      }
    }
  }

  /// Fix existing user's signInMethod based on their auth provider (one-time fix)
  static Future<void> fixUserSignInMethod() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot fix signInMethod - no authenticated user",
          );
        }
        return;
      }

      // Determine correct sign-in method
      String correctSignInMethod = 'email'; // default
      if (currentUser.phoneNumber != null) {
        correctSignInMethod = 'phone';
      } else if (currentUser.providerData.any(
        (info) => info.providerId == 'google.com',
      )) {
        correctSignInMethod = 'google';
      }

      // Update the signInMethod field
      await _firestore.collection('users').doc(currentUser.uid).set({
        'signInMethod': correctSignInMethod,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Fixed signInMethod to '$correctSignInMethod' for user ${currentUser.uid}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error fixing signInMethod = $e");
      }
    }
  }

  /// Check if user needs profile completion
  static Future<bool> needsProfileCompletion() async {
    try {
      AppUser? user = await getCurrentAppUser();
      return user?.needsProfileCompletion ?? true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error checking profile completion status = $e",
        );
      }
      return true;
    }
  }

  /// Check if user needs email verification
  static Future<bool> needsEmailVerification() async {
    try {
      AppUser? user = await getCurrentAppUser();
      return user?.needsEmailVerification ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error checking email verification status = $e",
        );
      }
      return false;
    }
  }

  // ========================================
  // WORKSPACE AND SHOPPING LIST COMPLETION TRACKING
  // ========================================

  /// Mark workspace setup as completed
  static Future<void> markWorkspaceCompleted() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot mark workspace complete - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).set({
        'workspaceCompleted': true,
        'workspaceCompletedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Marked workspace completed for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error marking workspace complete = $e");
      }
      rethrow;
    }
  }

  /// Mark shopping list setup as completed
  static Future<void> markShoppingListCompleted() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot mark shopping list complete - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).set({
        'shoppingListCompleted': true,
        'shoppingListCompletedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Marked shopping list completed for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error marking shopping list complete = $e",
        );
      }
      rethrow;
    }
  }

  /// Check if user needs workspace setup
  static Future<bool> needsWorkspaceSetup() async {
    try {
      AppUser? user = await getCurrentAppUser();
      return user?.needsWorkspaceSetup ?? true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error checking workspace setup status = $e",
        );
      }
      return true;
    }
  }

  /// Check if user needs shopping list setup
  static Future<bool> needsShoppingListSetup() async {
    try {
      AppUser? user = await getCurrentAppUser();
      return user?.needsShoppingListSetup ?? true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error checking shopping list setup status = $e",
        );
      }
      return true;
    }
  }

  /// Check if user has completed all setup steps
  static Future<bool> isCompletelySetUp() async {
    try {
      AppUser? user = await getCurrentAppUser();
      return user?.isCompletelySetUp ?? false;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error checking complete setup status = $e",
        );
      }
      return false;
    }
  }

  /// Reset workspace setup status (for testing or admin purposes)
  static Future<void> resetWorkspaceStatus() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot reset workspace status - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'workspaceCompleted': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Reset workspace status for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("UserStateService: Error resetting workspace status = $e");
      }
    }
  }

  /// Reset shopping list setup status (for testing or admin purposes)
  static Future<void> resetShoppingListStatus() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (kDebugMode) {
          AppLogger.d(
            "UserStateService: Cannot reset shopping list status - no authenticated user",
          );
        }
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'shoppingListCompleted': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        AppLogger.d(
          "UserStateService: Reset shopping list status for ${currentUser.email}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "UserStateService: Error resetting shopping list status = $e",
        );
      }
    }
  }
}
