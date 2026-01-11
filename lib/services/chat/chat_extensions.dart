import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Extensions for converting between Stream Chat objects and our app models
extension ChatUserExtensions on User {
  /// Convert Stream Chat User to our ChatUserModel
  ChatUserModel toDomain() {
    return ChatUserModel(
      createdAt:
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      isUserBanned: banned,
      userId: id,
      displayName: name,
      photoUrl: image,
    );
  }
}

extension OwnUserExtensions on OwnUser {
  /// Convert Stream Chat OwnUser to our ChatUserModel
  ChatUserModel toDomain() {
    return ChatUserModel(
      createdAt:
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      isUserBanned: banned,
      userId: id,
      displayName: name,
      photoUrl: image,
    );
  }
}

extension ChannelExtensions on Channel {
  /// Get display name for the channel
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // For direct messages, use the other user's name
    if (memberCount == 2) {
      final members = state?.members ?? [];
      if (members.length >= 2) {
        // Get the first member's name as fallback
        return members.first.user?.name ?? 'Direct Message';
      }
    }

    return 'Group Chat';
  }

  /// Get display name for the channel with current user context
  String getDisplayName(String? currentUserId) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // For direct messages, use the other user's name
    if (memberCount == 2 && currentUserId != null) {
      final members = state?.members ?? [];
      if (members.length >= 2) {
        try {
          final otherMember = members.firstWhere(
            (member) => member.userId != currentUserId,
          );
          return otherMember.user?.name ?? 'Direct Message';
        } catch (e) {
          // Fallback to first member if we can't find the other user
          return members.first.user?.name ?? 'Direct Message';
        }
      }
    }

    return displayName; // Use the original getter as fallback
  }

  /// Get avatar URL for the channel
  String? get avatarUrl {
    if (image != null && image!.isNotEmpty) {
      return image;
    }

    // For direct messages, use the other user's avatar
    if (memberCount == 2) {
      final members = state?.members ?? [];
      if (members.length >= 2) {
        return members.first.user?.image;
      }
    }

    return null;
  }

  /// Get avatar URL for the channel with current user context
  String? getAvatarUrl(String? currentUserId) {
    if (image != null && image!.isNotEmpty) {
      return image;
    }

    // For direct messages, use the other user's avatar
    if (memberCount == 2 && currentUserId != null) {
      final members = state?.members ?? [];
      if (members.length >= 2) {
        try {
          final otherMember = members.firstWhere(
            (member) => member.userId != currentUserId,
          );
          return otherMember.user?.image;
        } catch (e) {
          // Fallback to first member if we can't find the other user
          return members.first.user?.image;
        }
      }
    }

    return null;
  }

  /// Check if this is a direct message channel
  bool get isDirectMessage => memberCount == 2;

  /// Get the other user in a direct message channel (requires context)
  User? getOtherUser(String currentUserId) {
    if (!isDirectMessage) return null;

    final members = state?.members ?? [];
    try {
      return members
          .firstWhere((member) => member.userId != currentUserId)
          .user;
    } catch (e) {
      return members.isNotEmpty ? members.first.user : null;
    }
  }

  /// Get unread message count
  int get unreadCount => state?.unreadCount ?? 0;
}
