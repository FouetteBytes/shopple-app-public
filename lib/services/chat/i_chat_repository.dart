import 'package:fpdart/fpdart.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;

// Type alias to resolve Unit conflict
typedef ChatUnit = Unit;

/// Enum for different types of chat failures
enum ChatFailureEnum {
  connectionFailure,
  serverError,
  channelCreateFailure,
  imageUploadFailure,
  permissionDenied,
  userNotFound,
  networkError,
}

/// Interface for chat repository operations
abstract class IChatRepository {
  /// Stream of chat user authentication state changes
  Stream<ChatUserModel> get chatAuthStateChanges;

  /// Stream of channels where the current user is a member
  Stream<List<stream.Channel>> get channelsThatTheUserIsIncluded;

  /// Connect the current authenticated user to chat
  Future<Either<ChatFailureEnum, ChatUnit>> connectTheCurrentUser();

  /// Disconnect the current user from chat
  Future<Either<ChatFailureEnum, ChatUnit>> disconnectUser();

  /// Create a new chat channel/conversation
  Future<Either<ChatFailureEnum, ChatUnit>> createNewChannel({
    required List<String> listOfMemberIDs,
    required String channelName,
    required String channelImageUrl,
  });

  /// Create a direct message channel with a friend
  Future<Either<ChatFailureEnum, stream.Channel>>
  createDirectMessageWithFriend({required String friendUserId});

  /// Send a photo message to a channel
  Future<Either<ChatFailureEnum, ChatUnit>>
  sendPhotoAsMessageToTheSelectedUser({
    required String channelId,
    required int sizeOfTheTakenPhoto,
    required String pathOfTheTakenPhoto,
  });

  /// Get or create a direct message channel with a user
  Future<Either<ChatFailureEnum, stream.Channel>> getOrCreateDirectChannel({
    required String otherUserId,
  });

  /// Search for users to start a chat with
  Future<Either<ChatFailureEnum, List<ChatUserModel>>> searchUsers({
    required String query,
  });

  /// Mark a channel as read
  Future<Either<ChatFailureEnum, ChatUnit>> markChannelAsRead({
    required String channelId,
  });

  /// Get channel by ID
  Future<Either<ChatFailureEnum, stream.Channel?>> getChannelById({
    required String channelId,
  });
}
