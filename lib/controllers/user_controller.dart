import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/auth_controller.dart';
import 'package:shopple/controllers/contacts_controller.dart';
import 'package:shopple/controllers/session_controller.dart';
import 'package:shopple/controllers/user_profile_controller.dart';
import 'package:shopple/models/app_user.dart';
import 'package:shopple/screens/auth/email_verification.dart';
import 'package:shopple/screens/auth/new_workspace.dart';
import 'package:shopple/screens/auth/profile_completion.dart';
import 'package:shopple/screens/dashboard/timeline.dart';
import 'package:shopple/services/ai/quick_prompt_service.dart';
import 'package:shopple/services/app_initializer.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/services/user/user_state_service.dart';
import 'package:shopple/services/user/user_tracking_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/values/values.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  // Dependencies
  final AuthController _authController = Get.find<AuthController>();
  final SessionController _sessionController = Get.find<SessionController>();
  final UserProfileController _profileController = Get.find<UserProfileController>();
  final AuthService _authService = AuthService();

  // Phone authentication state
  final RxString _verificationId = ''.obs;
  final RxString _phoneNumber = ''.obs;
  final RxBool _isOtpSent = false.obs;
  final RxInt _otpCountdown = 0.obs;
  Timer? _otpCountdownTimer;

  // Getters (Delegated)
  User? get user => _authController.user;
  String get userName => _profileController.displayName;
  String get userEmail => _profileController.userEmail.value;
  String get userPhotoUrl => _profileController.userPhotoUrl.value;
  bool get isLoggedIn => _authController.isAuthenticated.value && !_sessionController.sessionExpired.value;
  bool get isLoading => _authController.isLoading.value || _profileController.isLoading.value;
  
  // Session Getters
  bool get autoLogoutEnabled => _sessionController.autoLogoutEnabled.value;
  String get sessionStatus => _sessionController.sessionStatus.value;
  int get sessionRemainingMinutes => _sessionController.sessionRemainingMinutes.value;
  bool get sessionExpired => _sessionController.sessionExpired.value;

  // Phone authentication getters
  String get verificationId => _verificationId.value;
  String get phoneNumber => _phoneNumber.value;
  bool get isOtpSent => _isOtpSent.value;
  int get otpCountdown => _otpCountdown.value;

  @override
  void onClose() {
    _otpCountdownTimer?.cancel();
    super.onClose();
  }

  // Session Methods (Delegated)
  Future<void> checkSessionValidity() => _sessionController.checkSessionValidity();
  Future<void> toggleAutoLogout() => _sessionController.toggleAutoLogout();
  void recordActivity() => _sessionController.recordActivity();

  // Auth Methods (Delegated)
  Future<bool> loginWithEmailPassword(String email, String password) => 
      _authController.loginWithEmailPassword(email, password);

  Future<bool> loginWithGoogle() => _authController.loginWithGoogle();

  Future<bool> signUpWithEmailPassword(String email, String password, String name) => 
      _authController.signUpWithEmailPassword(email, password, name);

  Future<void> signOut() => _authController.signOut();

  // Profile Methods (Delegated)
  String getUserInitials() => _profileController.getUserInitials();

  Future<void> updateUserProfile({String? displayName, String? photoURL}) => 
      _profileController.updateUserProfile(displayName: displayName, photoURL: photoURL);

  // ========================================
  // USER NAVIGATION & ONBOARDING TRACKING
  // ========================================

  Future<bool> shouldShowOnboarding() async {
    if (!isLoggedIn) return false;
    bool hasCompleted = await UserTrackingService.hasCompletedOnboarding();
    return !hasCompleted;
  }

  Future<void> navigateAfterAuth() async {
    try {
      _authController.isLoading.value = true;

      await UserStateService.fixUserSignInMethod();
      AppUser? appUser = await UserStateService.getCurrentAppUser();

      if (appUser == null) {
        Get.offAll(() => NewWorkSpace(), transition: Transition.fadeIn);
        return;
      }

      if (appUser.isCompletelySetUp) {
        try {
          await _initializeUserServices();
        } catch (e) {
          if (kDebugMode) AppLogger.w('UserController: Error initializing user services: $e');
        }
        QuickPromptService.warmCacheForCurrentUser();
        Get.offAll(() => Timeline(), transition: Transition.fadeIn);
        Future.microtask(() {
          try {
            ContactsController.instance.triggerDeferredSyncIfNeeded();
          } catch (_) {}
        });
        return;
      }

      if (appUser.needsProfileCompletion) {
        Get.offAll(() => ProfileCompletionScreen(), transition: Transition.fadeIn);
        return;
      }

      if (appUser.needsEmailVerification) {
        Get.offAll(() => EmailVerificationScreen(email: appUser.email), transition: Transition.fadeIn);
        return;
      }

      if (appUser.needsWorkspaceSetup) {
        Get.offAll(() => NewWorkSpace(), transition: Transition.fadeIn);
        return;
      }

      if (appUser.needsShoppingListSetup) {
        QuickPromptService.warmCacheForCurrentUser();
        Get.offAll(() => Timeline(), transition: Transition.fadeIn);
        Future.microtask(() {
          try {
            ContactsController.instance.triggerDeferredSyncIfNeeded();
          } catch (_) {}
        });
        return;
      }

      QuickPromptService.warmCacheForCurrentUser();
      Get.offAll(() => Timeline(), transition: Transition.fadeIn);
      Future.microtask(() {
        try {
          ContactsController.instance.triggerDeferredSyncIfNeeded();
        } catch (_) {}
      });
    } catch (e) {
      if (kDebugMode) AppLogger.w('UserController: Error in navigateAfterAuth: $e');
      Get.offAll(() => NewWorkSpace(), transition: Transition.fadeIn);
    } finally {
      _authController.isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> getSetupStatus() async {
    try {
      AppUser? appUser = await UserStateService.getCurrentAppUser();
      if (appUser == null) {
        return {
          'isCompletelySetUp': false,
          'needsProfileCompletion': true,
          'needsEmailVerification': false,
          'needsWorkspaceSetup': true,
          'needsShoppingListSetup': true,
          'error': 'No user found',
        };
      }
      return {
        'isCompletelySetUp': appUser.isCompletelySetUp,
        'needsProfileCompletion': appUser.needsProfileCompletion,
        'needsEmailVerification': appUser.needsEmailVerification,
        'needsWorkspaceSetup': appUser.needsWorkspaceSetup,
        'needsShoppingListSetup': appUser.needsShoppingListSetup,
        'signInMethod': appUser.signInMethod,
        'email': appUser.email,
        'firstName': appUser.firstName,
        'lastName': appUser.lastName,
      };
    } catch (e) {
      return {'isCompletelySetUp': false, 'error': e.toString()};
    }
  }

  Future<void> printSetupStatus() async {
    Map<String, dynamic> status = await getSetupStatus();
    if (kDebugMode) {
      AppLogger.d('=== USER SETUP STATUS ===');
      status.forEach((key, value) => AppLogger.d('$key: $value'));
      AppLogger.d('=========================');
    }
  }

  Future<void> debugFirestoreData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (kDebugMode) {
        AppLogger.d('Document exists: ${doc.exists}');
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          AppLogger.d('Firestore Document Data:');
          data.forEach((key, value) => AppLogger.d('  $key: $value'));
        }
      }
    } catch (e) {
      if (kDebugMode) AppLogger.w('DEBUG: Error checking Firestore data: $e');
    }
  }

  Future<void> initializeUserTracking() async {
    try {
      await UserTrackingService.initializeUserOnSignIn();
    } catch (e) {
      if (kDebugMode) AppLogger.w('UserController: Error initializing user tracking: $e');
    }
  }

  void initializeUserTrackingAsync() {
    Future.microtask(() async {
      try {
        await UserTrackingService.initializeUserOnSignIn();
      } catch (e) {
        if (kDebugMode) AppLogger.w('UserController: Error in background user tracking: $e');
      }
    });
  }

  Future<void> sendEmailVerification() async {
    try {
      _authController.isLoading.value = true;
      await _authService.sendEmailVerification();
      Get.snackbar(
        'Verification Sent',
        'Please check your email for verification link',
        backgroundColor: AppColors.primaryAccentColor,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Verification Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _authController.isLoading.value = false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      return await _authService.isEmailVerified();
    } catch (e) {
      if (kDebugMode) AppLogger.w('UserController: Error checking email verification: $e');
      return false;
    }
  }

  // ========================================
  // PHONE AUTHENTICATION METHODS
  // ========================================

  Future<void> sendOtpToPhone(String phoneNumber) async {
    try {
      _authController.isLoading.value = true;
      _phoneNumber.value = phoneNumber;

      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          _authController.isLoading.value = false;
          Get.snackbar(
            'Verification Failed',
            e.message ?? 'Verification failed',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId.value = verificationId;
          _isOtpSent.value = true;
          _authController.isLoading.value = false;
          _startOtpCountdown();
          Get.snackbar(
            'OTP Sent',
            'Verification code sent to $phoneNumber',
            backgroundColor: AppColors.primaryAccentColor,
            colorText: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId.value = verificationId;
        },
      );
    } catch (e) {
      _authController.isLoading.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> verifyOtpCode(String otpCode) async {
    try {
      _authController.isLoading.value = true;
      PhoneAuthCredential credential = _authService.createPhoneCredential(
        verificationId: _verificationId.value,
        smsCode: otpCode,
      );
      await _signInWithPhoneCredential(credential, _phoneNumber.value);
    } catch (e) {
      _authController.isLoading.value = false;
      Get.snackbar(
        'Verification Failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> resendOtp() async {
    if (_phoneNumber.value.isNotEmpty) {
      await sendOtpToPhone(_phoneNumber.value);
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential, String phoneNumber) async {
    try {
      UserCredential? userCredential = await _authService.signInWithPhoneCredential(
        credential: credential,
        phoneNumber: phoneNumber,
      );

      if (userCredential != null) {
        _authController.isLoading.value = false;
        _resetPhoneAuthState();
        await initializeUserTracking();
        Get.snackbar(
          'Success',
          'Phone verification successful!',
          backgroundColor: AppColors.primaryAccentColor,
          colorText: Colors.white,
        );
        await Future.delayed(Duration(milliseconds: 500));
        await navigateAfterAuth();
      }
    } catch (e) {
      _authController.isLoading.value = false;
      rethrow;
    }
  }

  void _startOtpCountdown() {
    _otpCountdown.value = 60;
    _otpCountdownTimer?.cancel();
    _otpCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_otpCountdown.value > 0) {
        _otpCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _resetPhoneAuthState() {
    _verificationId.value = '';
    _phoneNumber.value = '';
    _isOtpSent.value = false;
    _otpCountdown.value = 0;
    _otpCountdownTimer?.cancel();
  }

  Future<void> _initializeUserServices() async {
    try {
      await AppInitializer.initializeUserServices();
    } catch (e) {
      if (kDebugMode) AppLogger.w('Failed to initialize user services: $e');
      rethrow;
    }
  }
}
