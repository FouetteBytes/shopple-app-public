import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:shopple/services/chat/i_chat_repository.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:shopple/services/friends/friend_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart'
    as stream
    hide Unit;
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/config/env_config.dart';

class ChatRepository implements IChatRepository {
  ChatRepository(
    this._authService,
    this._streamChatClient, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final stream.StreamChatClient _streamChatClient;
  final FirebaseFirestore _firestore;

  // Stream Chat API configuration
  String get _apiSecret => EnvConfig.instance.streamChatApiSecret;

  @override
  Stream<ChatUserModel> get chatAuthStateChanges {
    return _streamChatClient.state.currentUserStream.map(
      (stream.OwnUser? user) =>
          user != null ? _streamUserToChatUser(user) : ChatUserModel.empty(),
    );
  }

  @override
  Stream<List<stream.Channel>> get channelsThatTheUserIsIncluded {
    try {
      final currentUser = _streamChatClient.state.currentUser;
      if (currentUser == null) {
        AppLogger.w('No current user found for channels stream');
        return Stream.value([]);
      }

      AppLogger.d(
        'Setting up real-time channels stream for user: ${currentUser.id}',
      );

      // Use the queryChannels stream directly for real-time updates with performance optimizations
      final channelsStream = _streamChatClient.queryChannels(
        filter: stream.Filter.in_('members', [currentUser.id]),
        channelStateSort: const [stream.SortOption.desc('last_message_at')],
        paginationParams: const stream.PaginationParams(
          limit: 30,
        ), // Reduced for better performance
      );

      return channelsStream
          .map((channels) {
            AppLogger.d(
              'Channels updated via real-time stream: ${channels.length} channels',
            );

            // Filter out uninitialized channels to prevent state errors
            final initializedChannels = channels.where((channel) {
              try {
                // Test if channel is properly initialized by accessing a property that requires initialization
                final _ = channel.memberCount;
                final _ = channel.state;
                return true;
              } catch (e) {
                AppLogger.w('Skipping uninitialized channel: ${channel.cid}');
                return false;
              }
            }).toList();

            AppLogger.d(
              'Returning ${initializedChannels.length} initialized channels',
            );
            return initializedChannels;
          })
          .handleError((error) {
            AppLogger.e('Error in real-time channels stream', error: error);
          });
    } catch (e) {
      AppLogger.e('Error setting up real-time channels stream', error: e);
      return Stream.value([]);
    }
  }

  @override
  Future<Either<ChatFailureEnum, ChatUnit>> connectTheCurrentUser() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return left(ChatFailureEnum.permissionDenied);
      }

      // Check if user is already connected
      if (_streamChatClient.state.currentUser?.id == currentUser.uid) {
        AppLogger.d('User already connected to chat: ${currentUser.uid}');
        return right(unit);
      }

      AppLogger.d('Setting user: ${currentUser.uid}');

      // Generate a token for the user
      final userToken = _generateToken(currentUser.uid);

      AppLogger.d('Opening web-socket connection for ${currentUser.uid}');

      // Get enhanced user profile data from Firestore for Stream Chat
      String displayName = currentUser.displayName ?? 'User';
      String? profileImageUrl = currentUser.photoURL;

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Build proper display name from Firestore data
          final firstName = userData['firstName'] as String?;
          final lastName = userData['lastName'] as String?;

          if (firstName != null && firstName.isNotEmpty) {
            if (lastName != null && lastName.isNotEmpty) {
              displayName = '$firstName $lastName';
            } else {
              displayName = firstName;
            }
          }

          // Use enhanced profile image data
          if (userData['customPhotoURL'] != null &&
              userData['customPhotoURL'].toString().isNotEmpty) {
            profileImageUrl = userData['customPhotoURL'];
          } else if (userData['photoURL'] != null &&
              userData['photoURL'].toString().isNotEmpty) {
            profileImageUrl = userData['photoURL'];
          }
        }
      } catch (e) {
        AppLogger.w(
          'Could not fetch enhanced user profile for Stream Chat: $e',
        );
      }

      await _streamChatClient.connectUser(
        stream.User(
          id: currentUser.uid,
          name: displayName,
          image: profileImageUrl,
          extraData: {
            'email': currentUser.email,
            'phone': currentUser.phoneNumber,
            'firebase_uid': currentUser.uid,
            'email_verified': currentUser.emailVerified,
          },
        ),
        userToken,
      );

      AppLogger.d('User connected to chat: ${currentUser.uid}');
      return right(unit);
    } catch (e) {
      AppLogger.e('Error connecting user to chat', error: e);
      return left(ChatFailureEnum.connectionFailure);
    }
  }

  @override
  Future<Either<ChatFailureEnum, ChatUnit>> disconnectUser() async {
    try {
      await _streamChatClient.disconnectUser();
      AppLogger.d('User disconnected from chat');
      return right(unit);
    } catch (e) {
      AppLogger.e('Error disconnecting user from chat', error: e);
      return left(ChatFailureEnum.serverError);
    }
  }

  @override
  Future<Either<ChatFailureEnum, ChatUnit>> createNewChannel({
    required List<String> listOfMemberIDs,
    required String channelName,
    required String channelImageUrl,
  }) async {
    try {
      if (listOfMemberIDs.isEmpty) {
        return left(ChatFailureEnum.channelCreateFailure);
      }

      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        return left(ChatFailureEnum.permissionDenied);
      }

      // ✅ CRITICAL: Verify all members are friends before creating group chat
      for (String memberId in listOfMemberIDs) {
        if (memberId != currentUserId) {
          final isFriend = await FriendService.isFriend(memberId);
          if (!isFriend) {
            AppLogger.w('Cannot create group chat with non-friend: $memberId');
            return left(ChatFailureEnum.permissionDenied);
          }
          // Ensure user exists in Stream Chat
          final userExists = await _ensureUserExists(memberId);
          if (!userExists) {
            AppLogger.w(
              'User does not exist and could not be created: $memberId',
            );
            return left(ChatFailureEnum.userNotFound);
          }
        }
      }

      final channelId = const stream.Uuid().v4();

      await _streamChatClient.createChannel(
        'messaging',
        channelId: channelId,
        channelData: {
          'members': listOfMemberIDs,
          'name': channelName,
          'image': channelImageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'created_by': currentUserId,
        },
      );

      AppLogger.d('Group channel created with verified friends: $channelId');
      return right(unit);
    } catch (e) {
      AppLogger.e('Error creating channel', error: e);
      return left(ChatFailureEnum.channelCreateFailure);
    }
  }

  @override
  Future<Either<ChatFailureEnum, stream.Channel>>
  createDirectMessageWithFriend({required String friendUserId}) async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        return left(ChatFailureEnum.permissionDenied);
      }

      // ✅ CRITICAL: Verify friendship exists before creating chat
      final isFriend = await FriendService.isFriend(friendUserId);
      if (!isFriend) {
        AppLogger.w('Attempted to create chat with non-friend: $friendUserId');
        return left(ChatFailureEnum.permissionDenied);
      }

      // Ensure user exists in Stream Chat
      final userExists = await _ensureUserExists(friendUserId);
      if (!userExists) {
        AppLogger.w(
          'User does not exist and could not be created: $friendUserId',
        );
        return left(ChatFailureEnum.userNotFound);
      }

      // Create a deterministic channel ID for direct messages
      final sortedIds = [currentUserId, friendUserId]..sort();
      final channelId = 'dm_${sortedIds.join('_')}';

      final channel = _streamChatClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'members': [currentUserId, friendUserId],
          'name': null, // No name for direct messages
          'type': 'direct',
          'created_by': currentUserId,
        },
      );

      await channel.watch();
      AppLogger.d('Direct message channel created with friend: $channelId');
      return right(channel);
    } catch (e) {
      AppLogger.e('Error creating direct message channel', error: e);
      return left(ChatFailureEnum.channelCreateFailure);
    }
  }

  @override
  Future<Either<ChatFailureEnum, ChatUnit>>
  sendPhotoAsMessageToTheSelectedUser({
    required String channelId,
    required int sizeOfTheTakenPhoto,
    required String pathOfTheTakenPhoto,
  }) async {
    if (channelId.isEmpty || pathOfTheTakenPhoto.isEmpty) {
      return left(ChatFailureEnum.imageUploadFailure);
    }

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return left(ChatFailureEnum.permissionDenied);
      }

      final messageId = const stream.Uuid().v4();

      // Upload the image first
      final response = await _streamChatClient.sendImage(
        stream.AttachmentFile(
          size: sizeOfTheTakenPhoto,
          path: pathOfTheTakenPhoto,
        ),
        channelId,
        'messaging',
      );

      // Create and send the message with the image
      final imageUrl = response.file;
      final image = stream.Attachment(type: 'image', imageUrl: imageUrl);

      final message = stream.Message(
        user: stream.User(id: currentUser.uid),
        id: messageId,
        createdAt: DateTime.now(),
        attachments: [image],
      );

      await _streamChatClient.sendMessage(message, channelId, 'messaging');
      AppLogger.d('Photo message sent to channel: $channelId');
      return right(unit);
    } catch (e) {
      AppLogger.e('Error sending photo message', error: e);
      return left(ChatFailureEnum.imageUploadFailure);
    }
  }

  @override
  Future<Either<ChatFailureEnum, stream.Channel>> getOrCreateDirectChannel({
    required String otherUserId,
  }) async {
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        return left(ChatFailureEnum.permissionDenied);
      }

      // ✅ CRITICAL: Verify friendship exists before creating/accessing chat
      final isFriend = await FriendService.isFriend(otherUserId);
      if (!isFriend) {
        AppLogger.w('Attempted to access chat with non-friend: $otherUserId');
        return left(ChatFailureEnum.permissionDenied);
      }

      // Create deterministic channel ID
      final sortedIds = [currentUserId, otherUserId]..sort();
      final channelId = 'dm_${sortedIds.join('_')}';

      // ✅ Ensure the other user exists in Stream Chat before creating channel
      final userExists = await _ensureUserExists(otherUserId);
      if (!userExists) {
        AppLogger.w(
          'User does not exist and could not be created: $otherUserId',
        );
        return left(ChatFailureEnum.userNotFound);
      }

      final channel = _streamChatClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'members': [currentUserId, otherUserId],
          'created_by_id': currentUserId,
          'is_direct_message': true,
        },
      );

      await channel.watch();
      AppLogger.d('Direct channel accessed with verified friend: $channelId');
      return right(channel);
    } catch (e) {
      AppLogger.e('Error getting/creating direct channel', error: e);
      return left(ChatFailureEnum.channelCreateFailure);
    }
  }

  /// Ensures a user exists in Stream Chat by fetching from Firestore if needed
  /// Returns true if user exists or was created, false otherwise
  Future<bool> _ensureUserExists(String userId) async {
    try {
      // 1. Check if user already exists in Stream
      final result = await _streamChatClient.queryUsers(
        filter: stream.Filter.equal('id', userId),
        // Removed paginationParams as it caused a lint error and default is fine
      );

      if (result.users.isNotEmpty) {
        return true; // User exists
      }

      AppLogger.d(
        'User $userId not found in Stream Chat, attempting to create...',
      );

      // 2. Fetch user details from Firestore

      // 3. Call Cloud Function to repair/create user securely
      // This avoids client-side permission issues
      try {
        await FirebaseFunctions.instanceFor(
          region: 'asia-south1',
        ).httpsCallable('ensureStreamUser').call({'userId': userId});

        AppLogger.d(
          'Successfully repaired/created user $userId via Cloud Function',
        );
        return true;
      } catch (functionError) {
        AppLogger.e(
          'Cloud Function ensureStreamUser failed',
          error: functionError,
        );
        return false;
      }
    } catch (e) {
      // Non-fatal: channel creation may still succeed
      AppLogger.w('Error ensuring user exists in Stream Chat: $e');
      return false;
    }
  }

  @override
  Future<Either<ChatFailureEnum, List<ChatUserModel>>> searchUsers({
    required String query,
  }) async {
    try {
      // ✅ SECURITY: Only search among user's friends, not all Stream Chat users
      final friendsStream = FriendService.getFriendsStream();
      final friends = await friendsStream.first;

      // Filter friends by query
      final filteredFriends = friends.where((friend) {
        final nameMatch = friend.displayName.toLowerCase().contains(
          query.toLowerCase(),
        );
        final emailMatch = friend.email.toLowerCase().contains(
          query.toLowerCase(),
        );
        return nameMatch || emailMatch;
      }).toList();

      final chatUsers = filteredFriends
          .map(
            (friend) => ChatUserModel(
              createdAt: DateTime.now().toIso8601String(),
              isUserBanned: false,
              userId: friend.userId,
              displayName: friend.displayName,
              photoUrl: friend.profileImageUrl,
            ),
          )
          .toList();

      AppLogger.d(
        'Search returned ${chatUsers.length} friends matching query: $query',
      );
      return right(chatUsers);
    } catch (e) {
      AppLogger.e('Error searching friends for chat', error: e);
      return left(ChatFailureEnum.serverError);
    }
  }

  @override
  Future<Either<ChatFailureEnum, ChatUnit>> markChannelAsRead({
    required String channelId,
  }) async {
    try {
      final channel = _streamChatClient.channel('messaging', id: channelId);
      await channel.markRead();
      return right(unit);
    } catch (e) {
      AppLogger.e('Error marking channel as read', error: e);
      return left(ChatFailureEnum.serverError);
    }
  }

  @override
  Future<Either<ChatFailureEnum, stream.Channel?>> getChannelById({
    required String channelId,
  }) async {
    try {
      final channel = _streamChatClient.channel('messaging', id: channelId);
      await channel.watch();
      return right(channel);
    } catch (e) {
      AppLogger.e('Error getting channel by ID', error: e);
      return left(ChatFailureEnum.serverError);
    }
  }

  /// Generates a Stream Chat token for the given user ID
  String _generateToken(String userId) {
    // In production, token generation should happen on the server
    // This is only for development purposes
    
    // If we are using the demo key, we can use a dev token
    if (EnvConfig.instance.streamChatApiKey == '8th42q528825') {
      return _streamChatClient.devToken(userId).rawValue;
    }

    // Header
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));

    // Payload with the user ID
    final payload = {'user_id': userId};
    final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

    // Create signature
    final message = '$encodedHeader.$encodedPayload';
    final hmac = Hmac(sha256, utf8.encode(_apiSecret));
    final digest = hmac.convert(utf8.encode(message));
    final signature = base64Url.encode(digest.bytes);

    // Return the JWT token
    return '$encodedHeader.$encodedPayload.$signature';
  }

  /// Converts a Stream User to ChatUserModel
  ChatUserModel _streamUserToChatUser(stream.User user) {
    return ChatUserModel(
      createdAt:
          user.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      isUserBanned: user.banned,
      userId: user.id,
      displayName: user.name,
      photoUrl: user.image,
    );
  }
}
