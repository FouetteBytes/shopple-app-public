import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../values/values.dart';
import '../../models/contact_models.dart';

class SearchResultCard extends StatelessWidget {
  final UserSearchResult result;
  final bool isContact;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.isContact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            SizedBox(width: 12),
            Expanded(child: _buildUserInfo()),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
      ),
      child: result.profilePicture != null && result.profilePicture!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: result.profilePicture!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildDefaultAvatar(),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: GoogleFonts.lato(
            color: AppColors.primaryAccentColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                result.name,
                style: GoogleFonts.lato(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isContact)
              Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Contact",
                  style: GoogleFonts.lato(
                    color: AppColors.primaryAccentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        if (result.email != null)
          Text(
            result.email!,
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (result.phoneNumber != null)
          Text(
            _formatPhoneNumber(result.phoneNumber!),
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(
              FontAwesomeIcons.star,
              size: 10,
              color: AppColors.primaryAccentColor,
            ),
            SizedBox(width: 4),
            Text(
              "${(result.matchScore * 100).toInt()}% match",
              style: GoogleFonts.lato(
                color: AppColors.primaryText30,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isContact ? FontAwesomeIcons.message : FontAwesomeIcons.userPlus,
            size: 12,
            color: AppColors.primaryAccentColor,
          ),
          SizedBox(width: 6),
          Text(
            isContact ? "Message" : "Connect",
            style: GoogleFonts.lato(
              color: AppColors.primaryAccentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    List<String> words = result.name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatPhoneNumber(String phone) {
    // Basic phone formatting - can be enhanced
    if (phone.length == 10) {
      return '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }
}
