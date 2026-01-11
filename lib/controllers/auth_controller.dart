import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/services/app_initializer.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/screens/onboarding/onboarding_carousel.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final AuthService _authService = AuthService();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;

  User? get user => firebaseUser.value;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_authService.authStateChanges);
    ever(firebaseUser, _handleAuthChanged);
  }

  void _handleAuthChanged(User? user) {
    isAuthenticated.value = user != null;
    
    if (user != null) {
      try {
        ShoppingListCache.instance.onAuthChanged(user);
      } catch (_) {}
    } else {
      try {
        ShoppingListCache.instance.onAuthChanged(null);
      } catch (_) {}
      try {
        // ignore: discarded_futures
        RecentlyViewedService.clear();
      } catch (_) {}
    }
  }

  Future<bool> loginWithEmailPassword(String email, String password) async {
    try {
      isLoading.value = true;
      final userCredential = await _authService.signInWithEmailPassword(email, password);
      if (userCredential != null) {
        LiquidSnack.show(
          title: 'Welcome Back!',
          message: 'Successfully logged in',
          accentColor: AppColors.primaryAccentColor,
          icon: Icons.waving_hand_rounded,
        );
        return true;
      }
      return false;
    } catch (e) {
      LiquidSnack.error(
        title: 'Login Failed',
        message: _getErrorMessage(e),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        LiquidSnack.show(
          title: 'Welcome!',
          message: 'Successfully signed in with Google',
          accentColor: AppColors.primaryAccentColor,
          icon: Icons.g_mobiledata_rounded,
        );
        return true;
      }
      return false;
    } catch (e) {
      LiquidSnack.error(
        title: 'Google Sign-In Failed',
        message: _getErrorMessage(e),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUpWithEmailPassword(String email, String password, String name) async {
    try {
      isLoading.value = true;
      final userCredential = await _authService.signUpWithEmailPassword(email, password, name);
      if (userCredential != null) {
        LiquidSnack.success(
          title: 'Account Created!',
          message: 'Welcome to Shopple, $name!',
        );
        return true;
      }
      return false;
    } catch (e) {
      LiquidSnack.error(
        title: 'Sign Up Failed',
        message: _getErrorMessage(e),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      // Clear session data (moved from UserController, but AuthController should handle cleanup)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_activity');

      try {
        await AppInitializer.cleanup();
      } catch (e) {
        if (kDebugMode) {
          AppLogger.w('Error cleaning up user services: $e');
        }
      }

      await _authService.signOut();
      Get.offAll(() => OnboardingCarousel());
    } catch (e) {
      LiquidSnack.error(
        title: 'Error',
        message: 'Failed to sign out: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'No account found with this email';
        case 'wrong-password': return 'Incorrect password';
        case 'email-already-in-use': return 'Email is already registered';
        case 'weak-password': return 'Password is too weak';
        case 'invalid-email': return 'Invalid email address';
        case 'too-many-requests': return 'Too many attempts. Please try again later';
        case 'network-request-failed': return 'Network error. Check your connection';
        default: return error.message ?? 'Authentication failed';
      }
    }
    return error.toString();
  }
}
