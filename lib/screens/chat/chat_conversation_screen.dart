import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/widgets/chat/quoted_message_preview.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ChatConversationScreen extends StatefulWidget {
  final Channel channel;

  const ChatConversationScreen({super.key, required this.channel});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late final StreamMessageInputController _messageInputController;
  @override
  void initState() {
    super.initState();
    _messageInputController = StreamMessageInputController();
    // Optimize channel initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markChannelAsRead();
    });
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    super.dispose();
  }

  User? _getOtherUser() {
    if (widget.channel.memberCount != 2) return null;
    try {
      final currentUserId = StreamChatCore.of(context).currentUser?.id;
      return widget.channel.state?.members
          .firstWhere((m) => m.userId != currentUserId)
          .user;
    } catch (_) {
      return null;
    }
  }

  void _markChannelAsRead() async {
    try {
      await widget.channel.markRead();
      ChatManagementController.instance.markChannelAsRead(widget.channel.id!);

      // Prefetch other participant's profile for DMs
      final otherUser = _getOtherUser();
      if (otherUser != null) {
        // ignore: discarded_futures
        UserProfileStreamService.instance.prefetchUsers({otherUser.id});
      }
    } catch (e) {
      AppLogger.e('Error marking channel as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamChannel(
      channel: widget.channel,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: ChatConversationBody(
          messageInputController: _messageInputController,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final otherUser = _getOtherUser();
    final isDirectMessage = otherUser != null;

    final displayName = isDirectMessage
        ? otherUser.name
        : widget.channel.name ?? 'Group Chat';

    final imageUrl = isDirectMessage ? otherUser.image : widget.channel.image;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: LiquidGlassButton.icon(
        icon: Icons.arrow_back_ios,
        iconColor: AppColors.primaryText,
        onTap: () => Get.back(),
        size: 40,
        iconSize: 20,
      ),
      title: Row(
        children: [
          _buildAvatar(imageUrl, isDirectMessage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDirectMessage)
                  StreamBuilder<UserPresenceStatus>(
                    stream: PresenceService.getUserPresenceStream(otherUser.id),
                    builder: (context, snapshot) {
                      final presence = snapshot.data;
                      if (presence?.isOnline == true) {
                        return Text(
                          'Online',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        LiquidGlassButton.icon(
          icon: Icons.videocam,
          iconColor: AppColors.primaryText,
          onTap: () {
            // TODO: Implement video call
          },
          size: 40,
          iconSize: 20,
        ),
        const SizedBox(width: 8),
        LiquidGlassButton.icon(
          icon: Icons.call,
          iconColor: AppColors.primaryText,
          onTap: () {
            // TODO: Implement voice call
          },
          size: 40,
          iconSize: 20,
        ),
        const SizedBox(width: 8),
        LiquidGlassButton.icon(
          icon: Icons.more_vert,
          iconColor: AppColors.primaryText,
          onTap: () => _showChannelOptions(),
          size: 40,
          iconSize: 20,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatar(String? imageUrl, bool isDirectMessage) {
    // For direct messages, use Firebase profile avatar
    if (isDirectMessage) {
      try {
        final currentUserId = StreamChatCore.of(context).currentUser?.id;
        final otherUser = widget.channel.state?.members
            .firstWhere((member) => member.userId != currentUserId)
            .user;

        if (otherUser != null) {
          return UnifiedProfileAvatar(
            userId: otherUser.id,
            radius: 18, // 36/2 = 18
            enableCache: true,
          );
        }
      } catch (e) {
        // Fall through to default avatar
      }
    }

    // Fallback for group chats or when other user not found
    const double avatarSize = 36;
    final Widget defaultAvatar = CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: AppColors.primaryBackgroundColor,
      child: Icon(
        isDirectMessage ? Icons.person : Icons.group,
        color: AppColors.primaryText,
        size: avatarSize / 2.5,
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return defaultAvatar;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: avatarSize / 2, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: avatarSize / 2,
        backgroundColor: AppColors.primaryBackgroundColor,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => defaultAvatar,
    );
  }

  void _showChannelOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  widget.channel.isMuted ? Icons.volume_up : Icons.volume_off,
                  color: AppColors.primaryText,
                ),
                title: Text(
                  widget.channel.isMuted ? 'Unmute' : 'Mute',
                  style: GoogleFonts.lato(color: AppColors.primaryText),
                ),
                onTap: () {
                  Get.back();
                  // TODO: Implement mute/unmute
                },
              ),
              if (widget.channel.memberCount == 2)
                ListTile(
                  leading: Icon(Icons.person, color: AppColors.primaryText),
                  title: Text(
                    'View Profile',
                    style: GoogleFonts.lato(color: AppColors.primaryText),
                  ),
                  onTap: () {
                    Get.back();
                    // TODO: Navigate to user profile
                  },
                ),
              if (widget.channel.memberCount! > 2)
                ListTile(
                  leading: Icon(Icons.group, color: AppColors.primaryText),
                  title: Text(
                    'Group Info',
                    style: GoogleFonts.lato(color: AppColors.primaryText),
                  ),
                  onTap: () {
                    Get.back();
                    // TODO: Navigate to group info
                  },
                ),
              ListTile(
                leading: Icon(Icons.block, color: AppColors.error),
                title: Text(
                  'Block',
                  style: GoogleFonts.lato(color: AppColors.error),
                ),
                onTap: () {
                  Get.back();
                  // TODO: Implement block user
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatConversationBody extends StatelessWidget {
  final StreamMessageInputController messageInputController;

  const ChatConversationBody({super.key, required this.messageInputController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamMessageListView(
            // Custom message builder with UnifiedProfileAvatar for Firebase profile integration
            messageBuilder: _buildMessageItem,
            emptyBuilder: (context) => Center(
              child: Text(
                'Send a message to start the conversation',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: AppColors.inactive,
                ),
              ),
            ),
            loadingBuilder: (context) => Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccentColor,
              ),
            ),
            // Optimized for real-time performance
            reverse: true,
            shrinkWrap: false,
          ),
        ),
        StreamMessageInput(
          autoCorrect: false,
          messageInputController: messageInputController,
          // Themed quoted message preview in the input composer
          quotedMessageBuilder: (context, quotedMessage) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: QuotedMessagePreview(
                message: quotedMessage,
                onClose: messageInputController.clearQuotedMessage,
                compact: true,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
            );
          },
          onQuotedMessageCleared: () {
            // Callback stub for future enhancements
          },
        ),
      ],
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    MessageDetails details,
    List<Message> messages,
    StreamMessageWidget defaultMessage,
  ) {
    final messageWidget = defaultMessage.copyWith(
      showUserAvatar: DisplayWidget.show,
      showTimestamp: true,
      // Show quoted replies inside message bubbles with custom styling
      showReplyMessage: true,
      quotedMessageBuilder: (context, quotedMessage) {
        return QuotedMessagePreview(
          message: quotedMessage,
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        );
      },
      // Custom avatar builder using UnifiedProfileAvatar
      userAvatarBuilder: (context, user) {
        return UnifiedProfileAvatar(
          userId: user.id,
          radius: 16, // Standard message avatar size
          enableCache: true,
        );
      },
      customActions: [
        StreamMessageAction(
          leading: const Icon(Icons.reply),
          title: const Text('Reply'),
          onTap: (message) {
            messageInputController.quotedMessage = message;
            Get.back();
          },
        ),
      ],
    );

    // Enable swipe-to-reply by wrapping each message widget in Swipeable
    return Swipeable(
      key: ValueKey('swipe-${details.message.id}'),
      onSwiped: (direction) {
        // Trigger inline quoted reply regardless of swipe direction
        messageInputController.quotedMessage = details.message;
      },
      direction: SwipeDirection.horizontal,
      child: messageWidget,
    );
  }
}
