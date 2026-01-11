import 'package:flutter/material.dart';

import '../../../models/shopping_lists/shopping_list_model.dart';
import '../collaborative/member_drag_strip.dart';
import '../../../values/values.dart';

/// Compact horizontal collaborator row with quick action icons.
/// Avatars scroll horizontally if many members exist.
class CollaboratorActionRow extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onActivityTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onManageMembersTap;
  final double avatarRadius;

  const CollaboratorActionRow({
    super.key,
    required this.list,
    required this.onActivityTap,
    required this.onHistoryTap,
    required this.onManageMembersTap,
    this.avatarRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Scrollable avatar strip (takes available space, scrolls if needed)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: MemberDragStrip(
              list: list,
              avatarRadius: avatarRadius,
              showBackground: false,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Compact action buttons in a row
        _CompactIconButton(
          icon: Icons.timeline_rounded,
          tooltip: 'Activity',
          onTap: onActivityTap,
        ),
        const SizedBox(width: 6),
        _CompactIconButton(
          icon: Icons.history_toggle_off_rounded,
          tooltip: 'History',
          onTap: onHistoryTap,
        ),
        const SizedBox(width: 6),
        _CompactIconButton(
          icon: Icons.manage_accounts_rounded,
          tooltip: 'Manage',
          onTap: onManageMembersTap,
        ),
      ],
    );
  }
}

/// Ultra-compact icon button for header actions
class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: HexColor.fromHex('2A2D35'),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: AppColors.primaryAccentColor, size: 18),
        ),
      ),
    );
  }
}
