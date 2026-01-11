import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/models/user_privacy_settings.dart';
import 'package:shopple/services/privacy/privacy_settings_service.dart';
import 'package:shopple/services/user/other_user_details_service.dart';
import 'package:shopple/values/values.dart';

/// Centralized widget for displaying user contact information
/// with privacy settings applied automatically.
/// 
/// This widget:
/// - Loads user details from OtherUserDetailsService
/// - Fetches privacy settings from PrivacySettingsService
/// - Applies masking/hiding based on privacy preferences
/// - Shows only one contact (primary) based on sign-in method
/// - Is fully responsive and reusable across the app
class PrivacyAwareContactDisplay extends StatelessWidget {
  final String userId;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final bool showSecondary;
  final CrossAxisAlignment alignment;
  final Widget? placeholder;

  const PrivacyAwareContactDisplay({
    super.key,
    required this.userId,
    this.primaryStyle,
    this.secondaryStyle,
    this.showSecondary = false,
    this.alignment = CrossAxisAlignment.start,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OtherUserDetails?>(
      stream: OtherUserDetailsService.instance.watchUserDetails(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return placeholder ?? _buildPlaceholder();
        }

        final userDetails = userSnapshot.data!;

        return StreamBuilder<UserPrivacySettings>(
          stream: PrivacySettingsService.instance.watchUserSettings(userId),
          builder: (context, privacySnapshot) {
            final privacy = privacySnapshot.data ?? UserPrivacySettings.defaultSettings;

            return _buildContactInfo(userDetails, privacy);
          },
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: AppColors.inactive.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(OtherUserDetails details, UserPrivacySettings privacy) {
    final signInMethod = details.signInMethod ?? 'email';
    
    // Determine what to show based on sign-in method
    String? primaryContact;
    String? secondaryContact;
    
    if (signInMethod == 'phone') {
      // Phone users: show phone first, then email
      primaryContact = details.getPhone(privacy: privacy);
      secondaryContact = showSecondary ? details.getEmail(privacy: privacy) : null;
    } else {
      // Email/Google users: show email first, then phone
      primaryContact = details.getEmail(privacy: privacy);
      secondaryContact = showSecondary ? details.getPhone(privacy: privacy) : null;
    }

    // If primary is hidden, try secondary
    if (primaryContact == null && secondaryContact != null) {
      primaryContact = secondaryContact;
      secondaryContact = null;
    }

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (primaryContact != null)
          Text(
            primaryContact,
            style: primaryStyle ?? GoogleFonts.lato(
              fontSize: 12,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            'Contact hidden',
            style: (primaryStyle ?? GoogleFonts.lato(
              fontSize: 12,
              color: Colors.white70,
            )).copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.inactive,
            ),
          ),
        if (secondaryContact != null && showSecondary) ...[
          SizedBox(height: 2),
          Text(
            secondaryContact,
            style: secondaryStyle ?? GoogleFonts.lato(
              fontSize: 11,
              color: Colors.white54,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Compact version for tight spaces (e.g., list tiles)
class CompactPrivacyContactDisplay extends StatelessWidget {
  final String userId;
  final TextStyle? style;

  const CompactPrivacyContactDisplay({
    super.key,
    required this.userId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return PrivacyAwareContactDisplay(
      userId: userId,
      primaryStyle: style ?? GoogleFonts.lato(
        fontSize: 12,
        color: Colors.white70,
      ),
      showSecondary: false,
    );
  }
}

/// Badge showing privacy status for the current user
class PrivacyStatusBadge extends StatelessWidget {
  final bool isCompact;

  const PrivacyStatusBadge({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserPrivacySettings>(
      stream: PrivacySettingsService.instance.watchCurrentUserSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? UserPrivacySettings.defaultSettings;

        if (settings.isFullyPrivate) {
          return _buildBadge(
            icon: Icons.visibility_off,
            label: isCompact ? 'Private' : 'Fully Private',
            color: AppColors.primaryGreen,
          );
        } else if (!settings.isSearchable) {
          return _buildBadge(
            icon: Icons.shield_outlined,
            label: isCompact ? 'Limited' : 'Limited Search',
            color: Colors.orange,
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
