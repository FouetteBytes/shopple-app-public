import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/auth_controller.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/values/values.dart';

class UserProfileController extends GetxController {
  static UserProfileController get instance => Get.find();

  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = AuthService(); // Needed for currentUser reload

  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhotoUrl = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to update profile data
    ever(_authController.firebaseUser, _updateProfileData);
    // Initial load
    _updateProfileData(_authController.user);
  }

  void _updateProfileData(User? user) {
    if (user != null) {
      userName.value = user.displayName ?? '';
      userEmail.value = user.email ?? '';
      userPhotoUrl.value = user.photoURL ?? '';
    } else {
      userName.value = '';
      userEmail.value = '';
      userPhotoUrl.value = '';
    }
  }

  String getUserInitials() {
    final user = _authController.user;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      List<String> names = user.displayName!.split(' ');
      String initials = '';
      for (int i = 0; i < names.length && i < 2; i++) {
        if (names[i].isNotEmpty) {
          initials += names[i][0].toUpperCase();
        }
      }
      return initials.isNotEmpty ? initials : 'U';
    }
    return userEmail.value.isNotEmpty ? userEmail.value[0].toUpperCase() : 'U';
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      isLoading.value = true;
      final user = _authController.user;
      if (user != null) {
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoURL != null) await user.updatePhotoURL(photoURL);
        await user.reload();
        
        // Manually refresh local state since reload may not trigger stream immediately
        final freshUser = _authService.currentUser;
        _updateProfileData(freshUser);
        
        Get.snackbar(
          'Profile Updated',
          'Your profile has been updated successfully',
          backgroundColor: AppColors.primaryAccentColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Helper getter for display name with fallback
  String get displayName => userName.value.isNotEmpty 
      ? userName.value 
      : (_authController.user?.displayName ?? 'User');
}
