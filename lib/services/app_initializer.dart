import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shopple/services/user/user_status_service.dart';
import 'presence/presence_service.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/config/env_config.dart';
import 'package:shopple/utils/app_logger.dart';

class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize all services after user authentication.
  static Future<void> initializeUserServices() async {
    if (_isInitialized) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.w('Cannot initialize services: User not authenticated');
        return;
      }

      AppLogger.d('Initializing user services...');

      // Initialize environment config.
      await EnvConfig.instance.initialize();

      // Configure presence to rely on RTDB for real-time flips and avoid extra Firestore writes.
      PresenceService.configure(
        disableHeartbeatWhenRtdb: true,
        // Keep Firestore-only heartbeat short to approximate presence when RTDB is unavailable.
        heartbeatWhenFsOnly: Duration(minutes: 1),
        debugLogging: true,
      );

      // Initialize presence detection.
      await PresenceService.initialize();

      // Initialize User Status Service (Ban/Logout monitoring).
      Get.put(UserStatusService());

      // Initialize chat session if controller is registered.
      try {
        final chatController = ChatSessionController.instance;
        await chatController.connectUser();
        AppLogger.d('Chat service initialized');
      } catch (e) {
        AppLogger.w('Chat service not available: $e');
      }

      AppLogger.d('All user services initialized successfully');
      _isInitialized = true;
    } catch (e) {
      AppLogger.e('Error initializing user services: $e', error: e);
      rethrow;
    }
  }

  /// Cleanup all services (call on logout).
  static Future<void> cleanup() async {
    try {
      AppLogger.d('Cleaning up user services...');

      // Disconnect from chat service.
      try {
        final chatController = ChatSessionController.instance;
        await chatController.disconnectUser();
        AppLogger.d('Chat service disconnected');
      } catch (e) {
        AppLogger.w('Chat service cleanup failed: $e');
      }

      // Set user offline.
      await PresenceService.setOffline();

      // Dispose presence listeners.
      await PresenceService.dispose();

      _isInitialized = false;
      AppLogger.d('User services cleaned up');
    } catch (e) {
      AppLogger.e('Error cleaning up services: $e', error: e);
    }
  }

  /// Reset initialization state (useful for testing).
  static void reset() {
    _isInitialized = false;
  }
}
