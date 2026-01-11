import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';

class ChatUserTile extends StatelessWidget {
  final ChatUserModel user;
  final VoidCallback? onTap;
  final bool showOnlineStatus;
  final Widget? trailing;

  const ChatUserTile({
    super.key,
    required this.user,
    this.onTap,
    this.showOnlineStatus = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          UnifiedProfileAvatar(
            userId: user.userId,
            radius: 24,
            enableCache: true,
          ),
          if (showOnlineStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: StreamBuilder<UserPresenceStatus>(
                stream: PresenceService.getUserPresenceStream(user.userId),
                builder: (context, snapshot) {
                  final isOnline = snapshot.data?.isOnline ?? false;
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.primaryGreen
                          : AppColors.inactive,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      title: Text(
        user.displayName ?? 'Unknown User',
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
      subtitle: showOnlineStatus
          ? StreamBuilder<UserPresenceStatus>(
              stream: PresenceService.getUserPresenceStream(user.userId),
              builder: (context, snapshot) {
                final isOnline = snapshot.data?.isOnline ?? false;
                return Text(
                  isOnline ? 'Online' : 'Last seen recently',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: isOnline
                        ? AppColors.primaryGreen
                        : AppColors.inactive,
                  ),
                );
              },
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
