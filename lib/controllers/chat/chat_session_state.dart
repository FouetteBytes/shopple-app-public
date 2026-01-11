import 'package:equatable/equatable.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

class ChatSessionState extends Equatable {
  final ChatUserModel chatUser;
  final stream.ConnectionStatus webSocketConnectionStatus;
  final bool isUserCheckedFromChatService;
  final bool isLoading;
  final String? errorMessage;

  const ChatSessionState({
    required this.chatUser,
    required this.webSocketConnectionStatus,
    required this.isUserCheckedFromChatService,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    chatUser,
    webSocketConnectionStatus,
    isUserCheckedFromChatService,
    isLoading,
    errorMessage,
  ];

  ChatSessionState copyWith({
    ChatUserModel? chatUser,
    stream.ConnectionStatus? webSocketConnectionStatus,
    bool? isUserCheckedFromChatService,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatSessionState(
      chatUser: chatUser ?? this.chatUser,
      webSocketConnectionStatus:
          webSocketConnectionStatus ?? this.webSocketConnectionStatus,
      isUserCheckedFromChatService:
          isUserCheckedFromChatService ?? this.isUserCheckedFromChatService,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory ChatSessionState.empty() {
    return ChatSessionState(
      chatUser: ChatUserModel.empty(),
      webSocketConnectionStatus: stream.ConnectionStatus.disconnected,
      isUserCheckedFromChatService: false,
      isLoading: false,
    );
  }

  bool get isChatUserConnected =>
      chatUser != ChatUserModel.empty() && chatUser.isConnected;
  bool get isConnected =>
      webSocketConnectionStatus == stream.ConnectionStatus.connected;
  bool get hasError => errorMessage != null;
}
