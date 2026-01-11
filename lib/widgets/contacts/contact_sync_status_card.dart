import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../values/values.dart';

class ContactSyncStatusCard extends StatelessWidget {
  final String status;
  final int totalContacts;
  final int totalMatches;
  final String lastSyncTime;
  final VoidCallback onRefresh;

  const ContactSyncStatusCard({
    super.key,
    required this.status,
    required this.totalContacts,
    required this.totalMatches,
    required this.lastSyncTime,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
                  SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FontAwesomeIcons.arrowsRotate,
                    size: 14,
                    color: AppColors.primaryAccentColor,
                  ),
                ),
              ),
            ],
          ),
          if (totalContacts > 0 || totalMatches > 0) ...[
            AppSpaces.verticalSpace10,
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: FontAwesomeIcons.addressBook,
                    label: "Contacts",
                    value: totalContacts.toString(),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: FontAwesomeIcons.userCheck,
                    label: "On Shopple",
                    value: totalMatches.toString(),
                  ),
                ),
              ],
            ),
          ],
          if (lastSyncTime.isNotEmpty) ...[
            AppSpaces.verticalSpace10,
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  size: 12,
                  color: AppColors.primaryText30,
                ),
                SizedBox(width: 6),
                Text(
                  "Last sync: ${_formatSyncTime(lastSyncTime)}",
                  style: GoogleFonts.lato(
                    color: AppColors.primaryText30,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryAccentColor),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lato(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              color: AppColors.primaryText70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      default:
        return AppColors.primaryText70;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'completed':
        return FontAwesomeIcons.circleCheck;
      case 'failed':
        return FontAwesomeIcons.circleXmark;
      case 'in_progress':
        return FontAwesomeIcons.spinner;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'completed':
        return 'Contacts Synced';
      case 'failed':
        return 'Sync Failed';
      case 'in_progress':
        return 'Syncing...';
      default:
        return 'Not Synced';
    }
  }

  String _formatSyncTime(String syncTime) {
    try {
      DateTime dateTime = DateTime.parse(syncTime);
      Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
