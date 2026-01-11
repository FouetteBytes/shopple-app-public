import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/controllers/auth_controller.dart';
import 'package:shopple/screens/onboarding/onboarding_carousel.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dialogs/session_expired_dialog.dart';

class SessionController extends GetxController {
  static SessionController get instance => Get.find();

  final AuthController _authController = Get.find<AuthController>();

  // Session configuration (in minutes)
  static const int sessionTimeout = 60; // 1 hour max session
  static const int idleTimeout = 30; // 30 minutes idle
  static const int warningTime = 5; // Warn 5 minutes before logout

  // Reactive state
  final RxBool autoLogoutEnabled = true.obs;
  final RxString sessionStatus = 'active'.obs;
  final RxInt sessionRemainingMinutes = 60.obs;
  final RxBool sessionExpired = false.obs;

  Timer? _sessionTimer;
  Timer? _idleTimer;
  DateTime? _lastActivity;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to initialize/clear session
    ever(_authController.firebaseUser, (user) {
      if (user != null) {
        _loadSettings().then((_) => _initializeSession());
      } else {
        _clearSession();
      }
    });
    
    // Initial load if already logged in
    if (_authController.user != null) {
      _loadSettings().then((_) => _initializeSession());
    }
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    _idleTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeSession() async {
    sessionExpired.value = false;

    if (!autoLogoutEnabled.value) {
      _clearSession();
      return;
    }

    _lastActivity = DateTime.now();
    sessionStatus.value = 'active';
    _startSessionTimers();
    
    // Defer save
    Future.microtask(() => _saveSessionData());
  }

  void _startSessionTimers() {
    _sessionTimer?.cancel();
    _idleTimer?.cancel();

    if (!autoLogoutEnabled.value || !_authController.isAuthenticated.value) return;

    // Absolute session timeout
    _sessionTimer = Timer(Duration(minutes: sessionTimeout), () {
      _handleSessionTimeout('Maximum session time reached');
    });

    _resetIdleTimer();

    // Update remaining time every minute
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (!_authController.isAuthenticated.value) {
        timer.cancel();
        return;
      }
      _updateRemainingTime();
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _lastActivity = DateTime.now();

    if (!autoLogoutEnabled.value || !_authController.isAuthenticated.value) return;

    _idleTimer = Timer(Duration(minutes: idleTimeout), () {
      _handleSessionTimeout('Idle timeout - no activity detected');
    });
  }

  void recordActivity() {
    if (_authController.isAuthenticated.value && autoLogoutEnabled.value) {
      _resetIdleTimer();
      Future.microtask(() => _saveSessionData());
    }
  }

  void _handleSessionTimeout(String reason) {
    if (kDebugMode) {
      AppLogger.w('Session timeout: $reason');
    }

    sessionExpired.value = true;
    _clearSession();

    if (Get.context != null) {
      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => SessionExpiredDialog(
          reason: reason,
          onLoginAgain: () async {
            Navigator.of(context).pop();
            await _authController.signOut();
            Get.offAll(() => OnboardingCarousel());
          },
        ),
      );
    }
  }

  void _updateRemainingTime() {
    if (_lastActivity == null) return;

    final now = DateTime.now();
    final sessionElapsed = now.difference(_lastActivity!).inMinutes;
    final remaining = sessionTimeout - sessionElapsed;

    sessionRemainingMinutes.value = remaining.clamp(0, sessionTimeout);

    if (remaining <= warningTime && remaining > 0) {
      Get.snackbar(
        'Session Warning',
        'Your session will expire in $remaining minutes',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _saveSessionData() async {
    if (!_authController.isAuthenticated.value) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_activity', DateTime.now().toIso8601String());
    await prefs.setBool('auto_logout_enabled', autoLogoutEnabled.value);

    try {
      final user = _authController.user;
      if (user?.uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
          {
            'settings': {
              'autoLogoutEnabled': autoLogoutEnabled.value,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      AppLogger.w('Failed to sync session settings to Firestore: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final user = _authController.user;
      if (user?.uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (doc.exists && doc.data()?['settings'] != null) {
          final settings = doc.data()!['settings'] as Map<String, dynamic>;
          autoLogoutEnabled.value = settings['autoLogoutEnabled'] ?? true;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auto_logout_enabled', autoLogoutEnabled.value);
          return;
        }
      }
    } catch (e) {
      AppLogger.w('Failed to load settings from Firestore: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    autoLogoutEnabled.value = prefs.getBool('auto_logout_enabled') ?? true;
  }

  Future<void> checkSessionValidity() async {
    if (sessionExpired.value) {
      await _authController.signOut();
      Get.offAll(() => OnboardingCarousel());
      return;
    }

    if (!_authController.isAuthenticated.value || !autoLogoutEnabled.value) return;

    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString('last_activity');

    if (lastActivityStr != null) {
      final lastActivity = DateTime.parse(lastActivityStr);
      final timeSinceLastActivity = DateTime.now().difference(lastActivity).inMinutes;

      if (timeSinceLastActivity > idleTimeout) {
        _handleSessionTimeout('Session expired while app was closed');
        return;
      } else {
        _lastActivity = lastActivity;
        _startSessionTimers();
      }
    }
  }

  void _clearSession() {
    _sessionTimer?.cancel();
    _idleTimer?.cancel();
    sessionStatus.value = 'inactive';
    sessionRemainingMinutes.value = 0;
    _lastActivity = null;
  }

  Future<void> toggleAutoLogout() async {
    autoLogoutEnabled.value = !autoLogoutEnabled.value;

    if (autoLogoutEnabled.value && _authController.isAuthenticated.value) {
      await _initializeSession();
    } else {
      _clearSession();
    }

    await _saveSessionData();

    LiquidSnack.show(
      title: 'Security Settings',
      message: autoLogoutEnabled.value
          ? 'Auto logout enabled'
          : 'Auto logout disabled',
      accentColor: AppColors.primaryAccentColor,
      icon: autoLogoutEnabled.value
          ? Icons.shield_rounded
          : Icons.remove_moderator_rounded,
    );
  }
}
