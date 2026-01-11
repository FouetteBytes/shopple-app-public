import 'dart:ui';
import '../../models/friends/friend_request.dart';
import '../../models/friends/friend_group.dart';
import '../../models/friends/friend.dart';

abstract class IFriendService {
  String get currentUserId;

  Future<bool> sendFriendRequest({
    required String targetUserId,
    required String targetUserName,
    required String targetUserEmail,
    String? message,
  });

  Future<bool> acceptFriendRequest(String requestId);

  Future<bool> declineFriendRequest(String requestId);

  Future<String> createFriendGroup({
    required String name,
    String? description,
    required String iconName,
    required Color color,
    List<String>? initialMemberIds,
  });

  Future<void> createDefaultFriendGroups();

  Future<bool> addFriendsToGroup({
    required String groupId,
    required List<String> friendIds,
  });

  Future<bool> removeFriendsFromGroup({
    required String groupId,
    required List<String> friendIds,
  });

  Stream<List<FriendRequest>> getReceivedFriendRequestsStream();

  Stream<List<FriendRequest>> getSentFriendRequestsStream();

  Stream<List<Friend>> getFriendsStream();

  Stream<List<FriendGroup>> getFriendGroupsStream();

  Stream<int> getPendingRequestsCountStream();

  Future<bool> removeFriend(String friendId);

  String getCurrentUserId();

  Future<bool> isFriend(String userId);

  Future<bool> hasSentFriendRequest(String targetUserId);

  Future<bool> hasReceivedFriendRequest(String fromUserId);

  Future<bool> acceptFriendRequestByUserId(String fromUserId);
}
