import 'package:flutter/material.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';

class OnlineUserProfile extends StatelessWidget {
  final String userId;
  final double radius;
  final bool showPresence;

  const OnlineUserProfile({
    super.key,
    required this.userId,
    this.radius = 24,
    this.showPresence = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UnifiedProfileAvatar(userId: userId, radius: radius, enableCache: true),
        if (showPresence)
          Positioned(
            top: -2,
            right: -2,
            child: StreamBuilder<UserPresenceStatus>(
              stream: PresenceService.getUserPresenceStream(userId),
              builder: (context, snapshot) {
                final isOnline = snapshot.data?.isOnline ?? false;
                return Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? HexColor.fromHex("94D57B")
                            : AppColors.inactive,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
