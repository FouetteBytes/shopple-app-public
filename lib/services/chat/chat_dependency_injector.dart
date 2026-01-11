import 'package:get/get.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:shopple/services/chat/i_chat_repository.dart';
import 'package:shopple/services/chat/chat_repository.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/config/env_config.dart';
import 'package:shopple/utils/app_logger.dart';

/// Dependency injection setup for chat services
class ChatDependencyInjector {
  static bool _isInitialized = false;

  /// Observable to track if chat services are ready
  static final RxBool isChatReady = false.obs;

  /// Initialize all chat dependencies
  static Future<void> initializeChat() async {
    if (_isInitialized) return;

    try {
      // Initialize environment config first
      await EnvConfig.instance.initialize();

      // Initialize Stream Chat Client
      final client = stream.StreamChatClient(
        EnvConfig.instance.streamChatApiKey,
        logLevel: stream.Level.INFO,
      );

      // Register Stream Chat Client
      Get.put<stream.StreamChatClient>(client, permanent: true);

      // Register Auth Service (should already be registered)
      if (!Get.isRegistered<AuthService>()) {
        Get.put<AuthService>(AuthService(), permanent: true);
      }

      // Register Chat Repository
      Get.put<IChatRepository>(
        ChatRepository(Get.find<AuthService>(), client),
        permanent: true,
      );

      // Register Chat Controllers
      Get.put<ChatSessionController>(
        ChatSessionController(Get.find<IChatRepository>()),
        permanent: true,
      );

      Get.put<ChatManagementController>(
        ChatManagementController(Get.find<IChatRepository>()),
        permanent: true,
      );

      _isInitialized = true;
      isChatReady.value = true;
      AppLogger.d('Chat dependencies initialized successfully');

      // Auto-connect user to chat immediately for real-time updates
      _autoConnectUser();
    } catch (e) {
      AppLogger.e('Error initializing chat dependencies: $e', error: e);
      isChatReady.value = false;
      // Do not rethrow to prevent app crash, UI will handle uninitialized state
    }
  }

  /// Auto-connect the current user to chat for immediate real-time updates
  static Future<void> _autoConnectUser() async {
    try {
      // Ensure controller is registered before using
      if (Get.isRegistered<ChatSessionController>()) {
        final chatSession = Get.find<ChatSessionController>();
        await chatSession.connectUser();
        AppLogger.d('Chat user auto-connected successfully');
      }
    } catch (e) {
      AppLogger.e('Auto-connect failed: $e', error: e);
      // Don't rethrow - this is optional background initialization
    }
  }

  /// Cleanup chat dependencies
  static Future<void> cleanup() async {
    try {
      isChatReady.value = false;

      // Disconnect chat controllers
      if (Get.isRegistered<ChatSessionController>()) {
        await Get.find<ChatSessionController>().disconnectUser();
      }

      // Remove chat-specific dependencies
      Get.deleteAll(force: true);

      _isInitialized = false;
      AppLogger.d('Chat dependencies cleaned up');
    } catch (e) {
      AppLogger.e('Error cleaning up chat dependencies: $e', error: e);
    }
  }

  /// Check if chat is initialized
  static bool get isInitialized => _isInitialized;
}
