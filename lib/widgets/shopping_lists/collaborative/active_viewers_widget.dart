import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';

/// Google Docs-style active viewer avatars showing who's currently viewing the list
class ActiveViewersWidget extends StatelessWidget {
  final String listId;
  final double avatarSize;
  final int maxVisible;
  final VoidCallback? onTap;

  const ActiveViewersWidget({
    super.key,
    required this.listId,
    this.avatarSize = 32.0,
    this.maxVisible = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActiveViewer>>(
      stream: CollaborativeShoppingListService.getActiveViewersStream(listId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final viewers = snapshot.data!;
        final displayedViewers = viewers.take(maxVisible).toList();
        final extraCount = viewers.length - maxVisible;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active viewers avatars
                ...displayedViewers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final viewer = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 4.0),
                    child: _ViewerAvatar(viewer: viewer, size: avatarSize),
                  );
                }),

                // Show extra count if more viewers
                if (extraCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: avatarSize * 0.8,
                    height: avatarSize * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '+$extraCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: avatarSize * 0.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 8),

                // "Viewing" text
                Text(
                  viewers.length == 1 ? 'Viewing' : '${viewers.length} viewing',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual viewer avatar with presence indicator
class _ViewerAvatar extends StatelessWidget {
  final ActiveViewer viewer;
  final double size;

  const _ViewerAvatar({required this.viewer, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: viewer.profilePicture != null
                ? DecorationImage(
                    image: NetworkImage(viewer.profilePicture!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: viewer.profilePicture == null
                ? _getAvatarColor(viewer.userId)
                : null,
          ),
          child: viewer.profilePicture == null
              ? Center(
                  child: Text(
                    _getInitials(viewer.displayName),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),

        // Active indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: _getActivityColor(viewer.currentActivity),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String userId) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
    ];

    final hash = userId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Color _getActivityColor(String activity) {
    switch (activity) {
      case 'editing':
        return Colors.orange;
      case 'adding_item':
        return Colors.blue;
      case 'viewing':
      default:
        return Colors.green;
    }
  }
}

/// Extended version with detailed viewer information
class ActiveViewersDetailSheet extends StatelessWidget {
  final String listId;

  const ActiveViewersDetailSheet({super.key, required this.listId});

  static void show(BuildContext context, String listId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActiveViewersDetailSheet(listId: listId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Active Viewers',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Viewers list
          StreamBuilder<List<ActiveViewer>>(
            stream: CollaborativeShoppingListService.getActiveViewersStream(
              listId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No active viewers',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final viewers = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewers.length,
                itemBuilder: (context, index) {
                  final viewer = viewers[index];
                  return ListTile(
                    leading: _ViewerAvatar(viewer: viewer, size: 40),
                    title: Text(
                      viewer.displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _getActivityText(viewer.currentActivity),
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getActivityColor(
                          viewer.currentActivity,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getActivityLabel(viewer.currentActivity),
                        style: GoogleFonts.inter(
                          color: _getActivityColor(viewer.currentActivity),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getActivityText(String activity) {
    switch (activity) {
      case 'editing':
        return 'Currently editing items';
      case 'adding_item':
        return 'Adding new items';
      case 'viewing':
      default:
        return 'Viewing list';
    }
  }

  String _getActivityLabel(String activity) {
    switch (activity) {
      case 'editing':
        return 'Editing';
      case 'adding_item':
        return 'Adding';
      case 'viewing':
      default:
        return 'Viewing';
    }
  }

  Color _getActivityColor(String activity) {
    switch (activity) {
      case 'editing':
        return Colors.orange;
      case 'adding_item':
        return Colors.blue;
      case 'viewing':
      default:
        return Colors.green;
    }
  }
}
