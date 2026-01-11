import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shopple/services/chat/chat_extensions.dart';
import 'package:intl/intl.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';

class ChatChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback? onTap;

  const ChatChannelTile({super.key, required this.channel, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Safely get StreamChat client, fallback if not available
    String? currentUserId;
    try {
      final streamChat = StreamChat.of(context);
      currentUserId = streamChat.client.state.currentUser?.id;
    } catch (e) {
      // StreamChat context not available yet, use fallback
      currentUserId = null;
    }

    // Prefetch the other user's profile for DMs to avoid jank when opening
    try {
      if (channel.isDirectMessage) {
        final otherUser = channel.getOtherUser(currentUserId ?? '');
        if (otherUser != null) {
          // ignore: discarded_futures
          UserProfileStreamService.instance.prefetchUsers({otherUser.id});
        }
      }
    } catch (_) {}

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _MemoizedAvatarStack(
        channel: channel,
        currentUserId: currentUserId,
      ),
      title: _MemoizedTitleRow(channel: channel, currentUserId: currentUserId),
      subtitle: _MemoizedSubtitle(channel: channel),
      onTap: onTap,
    );
  }
}

// Memoized components for better performance
class _MemoizedAvatarStack extends StatelessWidget {
  final Channel channel;
  final String? currentUserId;

  const _MemoizedAvatarStack({
    required this.channel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = channel.getAvatarUrl(currentUserId);

    // Safely get unread count
    int unreadCount;
    try {
      unreadCount = channel.unreadCount;
    } catch (e) {
      unreadCount = 0; // Fallback if channel not initialized
    }

    return Stack(
      children: [
        _buildAvatar(context, avatarUrl),
        if (unreadCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: GoogleFonts.lato(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl) {
    if (channel.isDirectMessage) {
      // For direct messages, get the other user and load their Firebase profile picture
      final otherUser = channel.getOtherUser(currentUserId ?? '');

      if (otherUser != null) {
        // Use UnifiedProfileAvatar with presence indicator for DM chats
        return Stack(
          children: [
            UnifiedProfileAvatar(
              userId: otherUser.id,
              radius: 24,
              enableCache: true,
            ),
            // Presence indicator for DM chats
            Positioned(
              right: 0,
              bottom: 0,
              child: StreamBuilder<UserPresenceStatus>(
                stream: PresenceService.getUserPresenceStream(otherUser.id),
                builder: (context, snapshot) {
                  final isOnline = snapshot.data?.isOnline ?? false;
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    }

    // Fallback for group chats or when other user not found
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryBackgroundColor,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? CachedNetworkImageProvider(avatarUrl) // Built-in efficient caching
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Icon(
              channel.isDirectMessage ? Icons.person : Icons.group,
              color: AppColors.primaryText,
              size: 24,
            )
          : null,
    );
  }
}

class _MemoizedTitleRow extends StatelessWidget {
  final Channel channel;
  final String? currentUserId;

  const _MemoizedTitleRow({required this.channel, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Safely get display name and unread count
    String displayName;
    int unreadCount;

    try {
      displayName = channel.getDisplayName(currentUserId);
      unreadCount = channel.unreadCount;
    } catch (e) {
      displayName = 'Chat'; // Fallback
      unreadCount = 0;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            displayName,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.primaryText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (channel.lastMessageAt != null)
          _MemoizedTimeStamp(timestamp: channel.lastMessageAt!),
      ],
    );
  }
}

class _MemoizedTimeStamp extends StatelessWidget {
  final DateTime timestamp;

  const _MemoizedTimeStamp({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(timestamp),
      style: GoogleFonts.lato(fontSize: 12, color: AppColors.inactive),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEE').format(dateTime); // Mon, Tue, etc.
      } else {
        return DateFormat('MM/dd').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class _MemoizedSubtitle extends StatelessWidget {
  final Channel channel;

  const _MemoizedSubtitle({required this.channel});

  @override
  Widget build(BuildContext context) {
    // Safely check for last message
    Message? lastMessage;
    bool isMuted = false;
    int unreadCount = 0;

    try {
      lastMessage = channel.state?.lastMessage;
      isMuted = channel.isMuted;
      unreadCount = channel.unreadCount;
    } catch (e) {
      // Channel not properly initialized, return empty widget
      return const SizedBox.shrink();
    }

    if (lastMessage?.text == null) {
      return const SizedBox.shrink(); // Return empty widget instead of null
    }

    return Row(
      children: [
        if (isMuted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.volume_off, size: 14, color: AppColors.inactive),
          ),
        Expanded(
          child: Text(
            _getLastMessagePreview(lastMessage!),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: unreadCount > 0
                  ? AppColors.primaryText70
                  : AppColors.inactive,
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getLastMessagePreview(Message message) {
    if (message.attachments.isNotEmpty) {
      final attachment = message.attachments.first;
      switch (attachment.type) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'file':
          return '📎 File';
        default:
          return '📎 Attachment';
      }
    }

    if (message.text != null && message.text!.isNotEmpty) {
      return message.text!;
    }

    return 'Message';
  }
}
