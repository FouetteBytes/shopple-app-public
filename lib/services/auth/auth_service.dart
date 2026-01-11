import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/services/user/user_state_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update the user's display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      // Send email verification
      await sendEmailVerification();

      // Initialize user document for new signup (onboarding not completed)
      await UserStateService.initializeUserDocument();

      if (kDebugMode) {
        AppLogger.d("AuthService: Created new user account for $email");
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Email signup failed - ${e.code}: ${e.message}",
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("AuthService: Email signup failed - Unknown error: $e");
      }
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unknown error occurred',
      );
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unknown error occurred',
      );
    }
  }

  // Sign in with Google - Enhanced with automatic Firestore storage
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Perform Google Sign-In
      // Force account selection to ensure fresh token and avoid stale session issues
      await _googleSignIn.signOut(); 
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 2. Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User firebaseUser = userCredential.user!;

      // 3. Check if user is truly new (first time with Google)
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // 4. Check if user document exists in Firestore
      bool hasFirestoreDocument = await _checkUserDocumentExists(
        firebaseUser.uid,
      );

      if (isNewUser || !hasFirestoreDocument) {
        // NEW USER: Store Google data in Firestore automatically
        await _createGoogleUserInFirestore(firebaseUser);
        if (kDebugMode) {
          AppLogger.d(
            '✅ AuthService: New Google user created with auto-populated data',
          );
        }
      } else {
        // EXISTING USER: Only update login timestamp, preserve existing data
        await _updateLastLoginTime(firebaseUser.uid);
        if (kDebugMode) {
          AppLogger.d(
            '✅ AuthService: Existing Google user, preserved Firestore data',
          );
        }
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.e('❌ AuthService: Google Sign-In Error: $e');
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  // Check if user document exists in Firestore
  Future<bool> _checkUserDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w('AuthService: Error checking user document: $e');
      }
      return false;
    }
  }

  // Create new Google user document in Firestore with auto-populated data
  Future<void> _createGoogleUserInFirestore(User firebaseUser) async {
    try {
      final userData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName, // Auto from Google
        'photoURL': firebaseUser.photoURL, // Auto from Google
        'signInMethod': 'google',
        'emailVerified': firebaseUser.emailVerified,
        'phoneVerified': false,
        'profileCompleted': false, // Still missing age, gender, phone
        'hasCompletedOnboarding': false, // Still needs app onboarding
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        // Missing fields that need collection:
        'firstName': null,
        'lastName': null,
        'age': null,
        'gender': null,
        'phoneNumber': null,
      };

      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w('AuthService: Error creating Google user in Firestore: $e');
      }
      rethrow;
    }
  }

  // Update only login time for existing users
  Future<void> _updateLastLoginTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w('AuthService: Error updating last login time: $e');
      }
      // Don't rethrow - this is not critical
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========================================
  // EMAIL VERIFICATION METHODS
  // ========================================

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in',
        );
      }

      if (user.emailVerified) {
        if (kDebugMode) {
          AppLogger.d("AuthService: Email already verified for ${user.email}");
        }
        return;
      }

      await user.sendEmailVerification();

      if (kDebugMode) {
        AppLogger.d("AuthService: Email verification sent to ${user.email}");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Email verification failed - ${e.code}: ${e.message}",
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Email verification failed - Unknown error: $e",
        );
      }
      throw FirebaseAuthException(
        code: 'email-verification-failed',
        message: 'Failed to send email verification: ${e.toString()}',
      );
    }
  }

  /// Check if current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        return false;
      }

      // Reload user to get latest verification status
      await user.reload();
      user = _auth.currentUser; // Get refreshed user

      bool isVerified = user?.emailVerified ?? false;

      // Update Firestore if email is now verified
      if (isVerified) {
        await UserStateService.markEmailVerified();
      }

      if (kDebugMode) {
        AppLogger.d(
          "AuthService: Email verification status for ${user?.email}: $isVerified",
        );
      }

      return isVerified;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("AuthService: Error checking email verification: $e");
      }
      return false;
    }
  }

  // ========================================
  // PHONE AUTHENTICATION METHODS
  // ========================================

  /// Verify phone number and send OTP
  Future<String> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      if (kDebugMode) {
        AppLogger.d(
          "AuthService: Starting phone verification for $phoneNumber",
        );
      }

      String? verificationId;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          if (kDebugMode) {
            AppLogger.d(
              "AuthService: Phone verification completed automatically",
            );
          }
          verificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            AppLogger.w(
              "AuthService: Phone verification failed - ${e.code}: ${e.message}",
            );
          }
          verificationFailed(e);
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          if (kDebugMode) {
            AppLogger.d(
              "AuthService: OTP sent to $phoneNumber, verificationId: $verId",
            );
          }
          codeSent(verId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verId) {
          if (kDebugMode) {
            AppLogger.d("AuthService: Auto-retrieval timeout for $phoneNumber");
          }
          codeAutoRetrievalTimeout(verId);
        },
        timeout: const Duration(seconds: 60),
      );

      return verificationId ?? '';
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Phone verification setup failed - ${e.code}: ${e.message}",
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Phone verification setup failed - Unknown error: $e",
        );
      }
      throw FirebaseAuthException(
        code: 'phone-verification-failed',
        message: 'Failed to verify phone number: ${e.toString()}',
      );
    }
  }

  /// Create phone auth credential from verification ID and SMS code
  PhoneAuthCredential createPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Sign in with phone credential
  Future<UserCredential?> signInWithPhoneCredential({
    required PhoneAuthCredential credential,
    required String phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        AppLogger.d(
          "AuthService: Signing in with phone credential for $phoneNumber",
        );
      }

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Mark phone as verified and initialize user document if needed
      await UserStateService.markPhoneVerified(phoneNumber);
      await UserStateService.initializeUserDocument();

      if (kDebugMode) {
        AppLogger.d("AuthService: Phone sign-in successful for $phoneNumber");
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Phone sign-in failed - ${e.code}: ${e.message}",
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("AuthService: Phone sign-in failed - Unknown error: $e");
      }
      throw FirebaseAuthException(
        code: 'phone-sign-in-failed',
        message: 'Failed to sign in with phone: ${e.toString()}',
      );
    }
  }

  /// Link phone number to existing account
  Future<UserCredential?> linkPhoneToAccount({
    required PhoneAuthCredential credential,
    required String phoneNumber,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in',
        );
      }

      if (kDebugMode) {
        AppLogger.d(
          "AuthService: Linking phone $phoneNumber to account ${user.email}",
        );
      }

      UserCredential userCredential = await user.linkWithCredential(credential);

      // Mark phone as verified
      await UserStateService.markPhoneVerified(phoneNumber);

      if (kDebugMode) {
        AppLogger.d("AuthService: Phone linking successful for ${user.email}");
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        AppLogger.w(
          "AuthService: Phone linking failed - ${e.code}: ${e.message}",
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("AuthService: Phone linking failed - Unknown error: $e");
      }
      throw FirebaseAuthException(
        code: 'phone-linking-failed',
        message: 'Failed to link phone: ${e.toString()}',
      );
    }
  }
}
