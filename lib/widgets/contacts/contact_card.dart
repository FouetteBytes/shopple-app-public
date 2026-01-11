import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../values/values.dart';
import '../../models/contact_models.dart';

class ContactCard extends StatelessWidget {
  final AppContact contact;
  final VoidCallback onTap;

  const ContactCard({super.key, required this.contact, required this.onTap});

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
            Expanded(child: _buildContactInfo()),
            _buildOnlineIndicator(),
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
      child:
          contact.profilePicture != null && contact.profilePicture!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: contact.profilePicture!,
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

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.name,
          style: GoogleFonts.lato(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        if (contact.phoneNumber != null)
          Text(
            _formatPhoneNumber(contact.phoneNumber!),
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (contact.email != null)
          Text(
            contact.email!,
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildOnlineIndicator() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: contact.hasAppAccount
                ? AppColors.primaryAccentColor.withValues(alpha: 0.1)
                : AppColors.primaryText.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                contact.hasAppAccount
                    ? FontAwesomeIcons.check
                    : FontAwesomeIcons.userPlus,
                size: 10,
                color: contact.hasAppAccount
                    ? AppColors.primaryAccentColor
                    : AppColors.primaryText70,
              ),
              SizedBox(width: 4),
              Text(
                contact.hasAppAccount ? "On Shopple" : "Invite",
                style: GoogleFonts.lato(
                  color: contact.hasAppAccount
                      ? AppColors.primaryAccentColor
                      : AppColors.primaryText70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (contact.lastSeen != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              _formatLastSeen(contact.lastSeen!),
              style: GoogleFonts.lato(
                color: AppColors.primaryText30,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials() {
    List<String> words = contact.name.split(' ');
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

  String _formatLastSeen(DateTime lastSeen) {
    Duration difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
