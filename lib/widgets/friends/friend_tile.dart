import 'package:flutter/material.dart';
import '../../models/friends/friend.dart';
import '../../services/presence/presence_service.dart';
import '../../models/user_presence_status.dart';
import '../../widgets/unified_profile_avatar.dart';
import '../../services/user/other_user_details_service.dart';
import '../../services/privacy/privacy_settings_service.dart';
import '../../models/user_privacy_settings.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOnlineStatus;

  const FriendTile({
    super.key,
    required this.friend,
    this.onTap,
    this.trailing,
    this.showOnlineStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to get real-time user details from Firestore
    return StreamBuilder<OtherUserDetails?>(
      stream: OtherUserDetailsService.instance.watchUserDetails(friend.userId),
      builder: (context, userSnapshot) {
        // Use fresh data from Firestore, or fall back to friend model data
        final userDetails = userSnapshot.data;
        final displayName = userDetails?.displayName ?? friend.displayName;

        // Also watch privacy settings for this user
        return StreamBuilder<UserPrivacySettings>(
          stream: PrivacySettingsService.instance.watchUserSettings(friend.userId),
          builder: (context, privacySnapshot) {
            final privacy = privacySnapshot.data ?? UserPrivacySettings.defaultSettings;

            return StreamBuilder<UserPresenceStatus>(
              stream: showOnlineStatus
                  ? PresenceService.getUserPresenceStream(friend.userId)
                  : null,
              builder: (context, presenceSnapshot) {
                final presence = presenceSnapshot.data;

                // Get privacy-applied contact info
                String? primaryContact;
                
                if (userDetails != null) {
                  // Use privacy-aware methods
                  primaryContact = userDetails.getPrimaryContactWithPrivacy(privacy: privacy);
                } else {
                  // Fallback to friend model data with masking
                  final signInMethod = friend.signInMethod ?? 'email';
                  if (signInMethod == 'phone') {
                    primaryContact = ContactMasker.applyVisibility(
                      friend.phoneNumber,
                      privacy.phoneVisibility,
                      ContactType.phone,
                    ) ?? ContactMasker.applyVisibility(
                      friend.email,
                      privacy.emailVisibility,
                      ContactType.email,
                    );
                  } else {
                    primaryContact = ContactMasker.applyVisibility(
                      friend.email,
                      privacy.emailVisibility,
                      ContactType.email,
                    ) ?? ContactMasker.applyVisibility(
                      friend.phoneNumber,
                      privacy.phoneVisibility,
                      ContactType.phone,
                    );
                  }
                }

                return ListTile(
                  leading: Stack(
                    children: [
                      UnifiedProfileAvatar(
                        userId: friend.userId,
                        radius: 25,
                        enableCache: true,
                      ),
                      if (showOnlineStatus && presence != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: presence.isOnline ? Colors.green : Colors.grey,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (primaryContact != null)
                        Text(
                          primaryContact,
                          style: GoogleFonts.lato(fontSize: 12, color: Colors.white70),
                        )
                      else
                        Text(
                          'Contact hidden',
                          style: GoogleFonts.lato(
                            fontSize: 12, 
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (showOnlineStatus && presence != null) ...[
                        SizedBox(height: 2),
                        Text(
                          presence.displayText,
                          style: TextStyle(
                            fontSize: 12,
                            color: presence.isOnline ? Colors.green : Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: trailing,
                  onTap: onTap,
                );
              },
            );
          },
        );
      },
    );
  }
}
