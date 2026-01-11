import 'dart:async';
import 'package:get/get.dart';
import 'package:shopple/services/chat/i_chat_repository.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/friends/friend_service.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';

/// Controller for managing chat operations like creating channels, searching users, etc.
class ChatManagementController extends GetxController {
  static ChatManagementController get instance => Get.find();

  final IChatRepository _chatRepository;
  StreamSubscription<List<Channel>>? _channelsSubscription;
  final Map<String, StreamSubscription> _perChannelSubscriptions = {};
  StreamSubscription? _clientEventSubscription;

  ChatManagementController(this._chatRepository);

  // Reactive observables
  final RxList<Channel> _channels = <Channel>[].obs;
  final RxList<ChatUserModel> _searchResults = <ChatUserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSearching = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxInt _totalUnreadCount = 0.obs;

  // Getters
  List<Channel> get channels => _channels;
  List<ChatUserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading.value;
  bool get isSearching => _isSearching.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;

  /// Get total unread message count across all channels (reactive)
  int get totalUnreadCount => _totalUnreadCount.value;

  @override
  void onInit() {
    super.onInit();
    _loadChannels();
    _listenToChatSessionChanges();
    _setupRealTimeUnreadCountListener();
  }

  /// Setup real-time client event listener for unread counts
  /// According to Stream Chat docs, listen to notification events for real-time updates
  void _setupRealTimeUnreadCountListener() {
    try {
      final client = Get.find<StreamChatClient>();

      _clientEventSubscription = client.on().listen((event) {
        // Listen to the specific events that include total_unread_count
        if (event.totalUnreadCount != null) {
          _totalUnreadCount.value = event.totalUnreadCount!;
          AppLogger.d(
            'Real-time unread count updated: ${event.totalUnreadCount}',
          );
        }

        // Also refresh channels on relevant notification events
        final eventType = event.type;
        if (eventType == 'notification.message_new' ||
            eventType == 'notification.mark_read' ||
            eventType == 'notification.mark_unread' ||
            eventType == 'notification.channel_updated') {
          AppLogger.d('Received client notification event: $eventType');
          _channels.refresh(); // Trigger UI update
        }
      });
      AppLogger.d('Real-time client event listener setup complete');
    } catch (e) {
      AppLogger.w('Could not setup client event listener yet: $e');
      // Fallback: retry setup after a short delay
      Timer(const Duration(seconds: 2), _setupRealTimeUnreadCountListener);
    }
  }

  /// Listen to chat session changes to reload channels when connection status changes
  void _listenToChatSessionChanges() {
    // Periodic fallback check (real-time events handle most updates)
    Timer.periodic(const Duration(seconds: 10), (timer) {
      try {
        final chatSession = Get.find<ChatSessionController>();
        if (chatSession.isConnected &&
            !chatSession.isLoading &&
            _channels.isEmpty) {
          // User is connected but channels not loaded yet, reload them
          AppLogger.d('Chat session connected and stable, reloading channels');
          _loadChannels();
          // Also setup real-time listener if not already done
          if (_clientEventSubscription == null) {
            _setupRealTimeUnreadCountListener();
          }
        }
      } catch (e) {
        // ChatSessionController may not be initialized
      }
    });
  }

  @override
  void onClose() {
    _channelsSubscription?.cancel();
    _clientEventSubscription?.cancel();
    // Cancel per-channel event subscriptions
    for (final sub in _perChannelSubscriptions.values) {
      sub.cancel();
    }
    _perChannelSubscriptions.clear();
    super.onClose();
  }

  /// Load user's chat channels
  Future<void> _loadChannels() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Cancel any existing subscription
      await _channelsSubscription?.cancel();

      // Create new subscription
      _channelsSubscription = _chatRepository.channelsThatTheUserIsIncluded
          .listen(
            (channels) {
              _channels.value = channels;
              _updateUnreadCount(); // Update unread count when channels change
              _rebindChannelEventListeners(channels);
              _isLoading.value = false;
              AppLogger.d('Channels loaded: ${channels.length} channels');
            },
            onError: (error) {
              AppLogger.e('Error loading channels', error: error);
              _errorMessage.value = 'Failed to load channels';
              _isLoading.value = false;
            },
          );
    } catch (e) {
      AppLogger.e('Error setting up channel stream', error: e);
      _errorMessage.value = 'Failed to load channels';
      _isLoading.value = false;
    }
  }

  void _rebindChannelEventListeners(List<Channel> channels) {
    // Remove subscriptions for channels no longer in the list
    final currentCids = channels.map((c) => c.cid).toSet();
    final existingCids = _perChannelSubscriptions.keys.toList();
    for (final cid in existingCids) {
      if (!currentCids.contains(cid)) {
        _perChannelSubscriptions[cid]?.cancel();
        _perChannelSubscriptions.remove(cid);
      }
    }

    // Add listeners for new channels
    for (final channel in channels) {
      final cid = channel.cid!;
      if (_perChannelSubscriptions.containsKey(cid)) continue;
      _perChannelSubscriptions[cid] = channel.on().listen((event) {
        // Refresh UI on events that may change unread counts or last message
        final type = event.type;
        AppLogger.d('Received channel event: $type for channel: $cid');

        if (type == 'message.read' ||
            type == 'notification.mark_read' ||
            type == 'message.new' ||
            type == 'notification.message_new' ||
            type == 'notification.message_read' ||
            type == 'message.updated' ||
            type == 'notification.channel_updated' ||
            type == 'channel.updated') {
          AppLogger.d('Updating UI for event: $type');
          _channels.refresh();
          _updateUnreadCount(); // Update unread count when relevant events occur
        }
      });
    }
  }

  /// Refresh channels list
  Future<void> refreshChannels() async {
    AppLogger.d('Refreshing channels list');
    await _loadChannels();
  }

  /// Update total unread count from all channels
  void _updateUnreadCount() {
    final total = _channels.fold<int>(0, (sum, channel) {
      try {
        // Safely access unread count, skip if channel not initialized
        final unreadCount = channel.state?.unreadCount ?? 0;
        return sum + unreadCount;
      } catch (e) {
        // Channel not initialized yet, skip it
        AppLogger.w(
          'Skipping uninitialized channel in unread count: ${channel.cid}',
        );
        return sum;
      }
    });
    _totalUnreadCount.value = total;
    AppLogger.d('Total unread count updated: $total');
  }

  /// Search for users to chat with
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;
    _errorMessage.value = '';

    final result = await _chatRepository.searchUsers(query: query.trim());

    result.fold(
      (failure) {
        AppLogger.e('Failed to search users', error: failure);
        _errorMessage.value = 'Failed to search users';
        _searchResults.clear();
      },
      (users) {
        _searchResults.value = users;
      },
    );

    _isSearching.value = false;
  }

  /// Create a direct message channel with a friend
  Future<Channel?> createDirectMessageWithFriend(String friendUserId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    final result = await _chatRepository.createDirectMessageWithFriend(
      friendUserId: friendUserId,
    );

    _isLoading.value = false;

    return result.fold(
      (failure) {
        AppLogger.e('Failed to create direct message', error: failure);
        _errorMessage.value = 'Failed to create chat';
        return null;
      },
      (channel) {
        AppLogger.d('Direct message channel created');
        // Refresh channels to show the new conversation
        refreshChannels();
        return channel;
      },
    );
  }

  /// Get or create a direct channel with a user
  Future<Channel?> getOrCreateDirectChannel(String otherUserId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    final result = await _chatRepository.getOrCreateDirectChannel(
      otherUserId: otherUserId,
    );

    _isLoading.value = false;

    return result.fold(
      (failure) {
        AppLogger.e('Failed to get/create direct channel', error: failure);
        _errorMessage.value = 'Failed to open chat';
        return null;
      },
      (channel) {
        // Refresh channels to ensure the conversation appears in the list
        refreshChannels();
        return channel;
      },
    );
  }

  /// Create a new group chat
  Future<bool> createGroupChat({
    required List<String> memberIds,
    required String groupName,
    String? groupImageUrl,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    final result = await _chatRepository.createNewChannel(
      listOfMemberIDs: memberIds,
      channelName: groupName,
      channelImageUrl: groupImageUrl ?? '',
    );

    _isLoading.value = false;

    return result.fold(
      (failure) {
        AppLogger.e('Failed to create group chat', error: failure);
        _errorMessage.value = 'Failed to create group chat';
        return false;
      },
      (_) {
        AppLogger.d('Group chat created successfully');
        refreshChannels(); // Refresh the channels list
        return true;
      },
    );
  }

  /// Mark a channel as read
  Future<void> markChannelAsRead(String channelId) async {
    final result = await _chatRepository.markChannelAsRead(
      channelId: channelId,
    );

    result.fold(
      (failure) =>
          AppLogger.e('Failed to mark channel as read', error: failure),
      (_) => AppLogger.d('Channel marked as read'),
    );
  }

  /// Send a photo message
  Future<bool> sendPhotoMessage({
    required String channelId,
    required String imagePath,
    required int imageSize,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    final result = await _chatRepository.sendPhotoAsMessageToTheSelectedUser(
      channelId: channelId,
      sizeOfTheTakenPhoto: imageSize,
      pathOfTheTakenPhoto: imagePath,
    );

    _isLoading.value = false;

    return result.fold(
      (failure) {
        AppLogger.e('Failed to send photo message', error: failure);
        _errorMessage.value = 'Failed to send photo';
        return false;
      },
      (_) {
        AppLogger.d('Photo message sent successfully');
        return true;
      },
    );
  }

  /// Search friends for chat
  Future<List<ChatUserModel>> searchFriendsForChat(String query) async {
    try {
      // Get user's friends from FriendService stream
      final friendsStream = FriendService.getFriendsStream();
      final friends = await friendsStream.first;

      if (query.trim().isEmpty) {
        // Convert friends to ChatUserModel
        return friends
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
      }

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

      return filteredFriends
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
    } catch (e) {
      AppLogger.e('Error searching friends for chat', error: e);
      return [];
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults.clear();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Reset controller state
  void reset() {
    _channels.clear();
    _searchResults.clear();
    _isLoading.value = false;
    _isSearching.value = false;
    _errorMessage.value = '';
  }
}
