import 'dart:async';
import 'package:get/get.dart';
import 'package:shopple/controllers/chat/chat_session_state.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:shopple/services/chat/i_chat_repository.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:shopple/utils/app_logger.dart';

/// Controller for managing chat session state using GetX
/// Integrates with Stream Chat for real-time messaging
class ChatSessionController extends GetxController {
  static ChatSessionController get instance => Get.find();

  final IChatRepository _chatRepository;

  ChatSessionController(this._chatRepository);

  // Reactive observables
  final Rx<ChatSessionState> _state = ChatSessionState.empty().obs;

  StreamSubscription<ChatUserModel>? _chatUserSubscription;
  Timer? _connectionCheckTimer;

  // Getters
  ChatSessionState get state => _state.value;
  bool get isChatUserConnected => state.isChatUserConnected;
  bool get isConnected => state.isConnected;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  ChatUserModel get chatUser => state.chatUser;

  @override
  void onInit() {
    super.onInit();
    _initializeSubscriptions();
  }

  @override
  void onClose() {
    _chatUserSubscription?.cancel();
    _connectionCheckTimer?.cancel();
    super.onClose();
  }

  /// Initialize subscriptions and listeners
  void _initializeSubscriptions() {
    _chatUserSubscription = _chatRepository.chatAuthStateChanges.listen(
      _listenChatUserAuthStateChangesStream,
      onError: (error) {
        AppLogger.e('Chat user auth state error', error: error);
        _updateState(
          state.copyWith(
            errorMessage: 'Chat connection error',
            isLoading: false,
          ),
        );
      },
    );

    // Setup periodic connection check
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectionStatus();
    });
  }

  /// Connect user to chat service
  Future<void> connectUser() async {
    if (state.isLoading) return;

    _updateState(state.copyWith(isLoading: true, errorMessage: null));

    final result = await _chatRepository.connectTheCurrentUser();

    result.fold(
      (failure) {
        AppLogger.e('Failed to connect to chat', error: failure);
        _updateState(
          state.copyWith(
            isLoading: false,
            errorMessage: _getErrorMessage(failure),
          ),
        );
      },
      (_) {
        AppLogger.d('Successfully connected to chat');
        _updateState(state.copyWith(isLoading: false));
        // Sync with the actual Stream Chat client state
        syncWithClientState();
      },
    );
  }

  /// Disconnect user from chat service
  Future<void> disconnectUser() async {
    final result = await _chatRepository.disconnectUser();

    result.fold(
      (failure) =>
          AppLogger.e('Failed to disconnect from chat', error: failure),
      (_) => AppLogger.d('Successfully disconnected from chat'),
    );

    reset();
  }

  /// Reset chat session to empty state
  void reset() {
    _updateState(ChatSessionState.empty());
  }

  /// Sync with Stream Chat client state
  void syncWithClientState() {
    try {
      final client = Get.find<stream.StreamChatClient>();
      final streamUser = client.state.currentUser;
      final isActuallyConnected = streamUser != null;

      if (isActuallyConnected && !state.isUserCheckedFromChatService) {
        final chatUser = _extractChatUserFromStreamUser(streamUser);
        _updateState(
          state.copyWith(
            chatUser: chatUser,
            isUserCheckedFromChatService: true,
            webSocketConnectionStatus: stream.ConnectionStatus.connected,
          ),
        );
      } else if (!isActuallyConnected && state.isUserCheckedFromChatService) {
        _updateState(
          state.copyWith(
            chatUser: ChatUserModel.empty(),
            isUserCheckedFromChatService: false,
            webSocketConnectionStatus: stream.ConnectionStatus.disconnected,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error syncing with client state', error: e);
      if (state.isUserCheckedFromChatService || state.isChatUserConnected) {
        _updateState(
          state.copyWith(
            chatUser: ChatUserModel.empty(),
            isUserCheckedFromChatService: false,
            webSocketConnectionStatus: stream.ConnectionStatus.disconnected,
          ),
        );
      }
    }
  }

  /// Set connection as disconnected
  void setDisconnected() {
    _updateState(
      state.copyWith(
        chatUser: ChatUserModel.empty(),
        isUserCheckedFromChatService: false,
        webSocketConnectionStatus: stream.ConnectionStatus.disconnected,
      ),
    );
  }

  /// Check connection status periodically
  void _checkConnectionStatus() {
    try {
      final client = Get.find<stream.StreamChatClient>();
      final isClientConnected = client.state.currentUser != null;

      if (isClientConnected != state.isChatUserConnected) {
        syncWithClientState();
      }
    } catch (e) {
      // Ignore errors in periodic connection check
    }
  }

  /// Handle chat user auth state changes
  Future<void> _listenChatUserAuthStateChangesStream(
    ChatUserModel chatUser,
  ) async {
    _updateState(
      state.copyWith(
        chatUser: chatUser,
        isUserCheckedFromChatService: true,
        webSocketConnectionStatus: stream.ConnectionStatus.connected,
      ),
    );
  }

  /// Extract ChatUserModel from Stream User
  ChatUserModel _extractChatUserFromStreamUser(stream.User streamUser) {
    final createdAt =
        streamUser.createdAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    final extraData = streamUser.extraData;
    final isUserBanned = extraData['banned'] as bool? ?? false;

    return ChatUserModel(
      createdAt: createdAt,
      isUserBanned: isUserBanned,
      userId: streamUser.id,
      displayName: streamUser.name,
      photoUrl: streamUser.image,
    );
  }

  /// Update state and notify observers
  void _updateState(ChatSessionState newState) {
    _state.value = newState;
  }

  /// Get user-friendly error message
  String _getErrorMessage(ChatFailureEnum failure) {
    switch (failure) {
      case ChatFailureEnum.connectionFailure:
        return 'Failed to connect to chat service';
      case ChatFailureEnum.serverError:
        return 'Chat server error';
      case ChatFailureEnum.networkError:
        return 'Network connection error';
      case ChatFailureEnum.permissionDenied:
        return 'Permission denied';
      default:
        return 'An error occurred';
    }
  }
}
