import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/contact_models.dart';
import 'package:shopple/models/user_privacy_settings.dart';
import 'package:shopple/services/privacy/privacy_settings_service.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';

/// Optimized search result tile with:
/// - Centralized profile avatar service
/// - Privacy-aware contact display
/// - LiquidGlass styling
/// - Smooth animations
/// - Cached state management
class SearchResultTile extends StatelessWidget {
  final UserSearchResult user;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showPrivacyMasking;
  final double matchScore;

  const SearchResultTile({
    super.key,
    required this.user,
    this.trailing,
    this.onTap,
    this.showPrivacyMasking = true,
    this.matchScore = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: LiquidGlass(
        borderRadius: 14,
        padding: EdgeInsets.zero,
        gradientColors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _buildAvatar(),
                  SizedBox(width: 14),
                  Expanded(child: _buildUserInfo()),
                  if (trailing != null) ...[
                    SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return UnifiedProfileAvatar(
      userId: user.uid,
      radius: 24,
      enableCache: true,
      showBorder: true,
      borderColor: AppColors.primaryAccentColor.withValues(alpha: 0.3),
      borderWidth: 1.5,
    );
  }

  Widget _buildUserInfo() {
    return showPrivacyMasking
        ? _buildPrivacyAwareInfo()
        : _buildBasicInfo();
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (matchScore > 0.8)
              _buildMatchBadge(),
          ],
        ),
        SizedBox(height: 3),
        Text(
          _getContactDisplay(),
          style: GoogleFonts.lato(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPrivacyAwareInfo() {
    return FutureBuilder<UserPrivacySettings>(
      future: PrivacySettingsService.instance.getUserSettings(user.uid),
      builder: (context, snapshot) {
        final privacy = snapshot.data ?? UserPrivacySettings.defaultSettings;
        
        String displayName = user.name;
        String? contactDisplay = _getContactDisplayWithPrivacy(privacy);
        
        // Apply name privacy
        if (privacy.nameVisibility == ContactVisibility.partial) {
          displayName = ContactMasker.maskName(user.name);
        } else if (privacy.nameVisibility == ContactVisibility.hidden) {
          displayName = 'User';
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (matchScore > 0.8)
                  _buildMatchBadge(),
              ],
            ),
            SizedBox(height: 3),
            if (contactDisplay != null)
              Text(
                contactDisplay,
                style: GoogleFonts.lato(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'Contact hidden',
                style: GoogleFonts.lato(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );
      },
    );
  }

  String _getContactDisplay() {
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    }
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return user.phoneNumber!;
    }
    return '';
  }

  String? _getContactDisplayWithPrivacy(UserPrivacySettings privacy) {
    // Try email first
    if (user.email != null && user.email!.isNotEmpty) {
      switch (privacy.emailVisibility) {
        case ContactVisibility.full:
          return user.email;
        case ContactVisibility.partial:
          return ContactMasker.maskEmail(user.email!);
        case ContactVisibility.hidden:
          break; // Try phone
      }
    }
    
    // Try phone
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      switch (privacy.phoneVisibility) {
        case ContactVisibility.full:
          return user.phoneNumber;
        case ContactVisibility.partial:
          return ContactMasker.maskPhone(user.phoneNumber!);
        case ContactVisibility.hidden:
          return null;
      }
    }
    
    return null;
  }

  Widget _buildMatchBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Match',
        style: GoogleFonts.lato(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Recommendation/suggestion item with fuzzy match highlighting
class SearchSuggestionTile extends StatelessWidget {
  final UserSearchResult user;
  final String query;
  final VoidCallback? onTap;

  const SearchSuggestionTile({
    super.key,
    required this.user,
    required this.query,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              UnifiedProfileAvatar(
                userId: user.uid,
                radius: 18,
                enableCache: true,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHighlightedText(user.name, query),
                    if (user.email != null && user.email!.isNotEmpty)
                      Text(
                        user.email!,
                        style: GoogleFonts.lato(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.north_west,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final matchIndex = textLower.indexOf(queryLower);

    if (matchIndex == -1) {
      return Text(
        text,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (matchIndex > 0)
            TextSpan(
              text: text.substring(0, matchIndex),
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: GoogleFonts.lato(
              color: AppColors.primaryAccentColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(
              text: text.substring(matchIndex + query.length),
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading shimmer for search results
class SearchResultShimmer extends StatelessWidget {
  final int itemCount;

  const SearchResultShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: LiquidGlass(
        borderRadius: 14,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _shimmerCircle(48),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  _shimmerBox(width: 180, height: 12),
                ],
              ),
            ),
            _shimmerBox(width: 60, height: 30),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
