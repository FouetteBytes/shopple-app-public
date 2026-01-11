import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';

/// Simple time ago formatter
String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'just now';
  }
}

/// Real-time activity feed showing collaborative updates
class ActivityFeedWidget extends StatelessWidget {
  final String listId;
  final int maxItems;
  final bool showHeader;
  final bool expandable;

  const ActivityFeedWidget({
    super.key,
    required this.listId,
    this.maxItems = 10,
    this.showHeader = true,
    this.expandable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (expandable)
                    IconButton(
                      onPressed: () => _showFullActivityFeed(context),
                      icon: Icon(
                        Icons.open_in_full,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          ],

          StreamBuilder<List<ActivityInfo>>(
            stream: CollaborativeShoppingListService.getActivityFeedStream(
              listId,
              limit: maxItems,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No recent activity',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final activities = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: activities.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.05),
                  height: 1,
                  indent: 56,
                ),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _ActivityItem(activity: activity);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFullActivityFeed(BuildContext context) {
    ActivityFeedBottomSheet.show(context, listId: listId);
  }
}

/// Individual activity item widget
class _ActivityItem extends StatelessWidget {
  final ActivityInfo activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getActivityColor(activity.type),
                width: 1,
              ),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity description
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    children: _buildActivityText(),
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(activity.timestamp),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildActivityText() {
    switch (activity.type) {
      case ActivityType.itemAdded:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' added '),
          TextSpan(
            text: activity.details['itemName'] ?? 'an item',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];

      case ActivityType.itemEdited:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' edited '),
          TextSpan(
            text: activity.details['itemName'] ?? 'an item',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];

      case ActivityType.itemCompleted:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' completed '),
          TextSpan(
            text: activity.details['itemName'] ?? 'an item',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];

      case ActivityType.itemAssigned:
        final assigneeName = activity.details['assigneeName'] ?? 'someone';
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' assigned '),
          TextSpan(
            text: activity.details['itemName'] ?? 'an item',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const TextSpan(text: ' to '),
          TextSpan(
            text: assigneeName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ];

      case ActivityType.itemReassigned:
        final newAssigneeName =
            activity.details['newAssigneeName'] ?? 'someone';
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' reassigned '),
          TextSpan(
            text: activity.details['itemName'] ?? 'an item',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const TextSpan(text: ' to '),
          TextSpan(
            text: newAssigneeName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ];

      case ActivityType.memberAdded:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' added '),
          TextSpan(
            text: activity.details['memberName'] ?? 'a member',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' to the list'),
        ];

      case ActivityType.memberRemoved:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' removed '),
          TextSpan(
            text: activity.details['memberName'] ?? 'a member',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' from the list'),
        ];

      case ActivityType.roleChanged:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' changed '),
          TextSpan(
            text: activity.details['memberName'] ?? 'a member',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: '\'s role to '),
          TextSpan(
            text: activity.details['newRole'] ?? 'member',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ];

      case ActivityType.listShared:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' shared this list'),
        ];

      case ActivityType.listEdited:
        return [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' updated the list details'),
        ];
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.itemAdded:
        return Colors.green;
      case ActivityType.itemEdited:
        return Colors.blue;
      case ActivityType.itemCompleted:
        return Colors.purple;
      case ActivityType.itemAssigned:
      case ActivityType.itemReassigned:
        return Colors.orange;
      case ActivityType.memberAdded:
        return Colors.cyan;
      case ActivityType.memberRemoved:
        return Colors.red;
      case ActivityType.roleChanged:
        return Colors.amber;
      case ActivityType.listShared:
        return Colors.pink;
      case ActivityType.listEdited:
        return Colors.indigo;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.itemAdded:
        return Icons.add_circle;
      case ActivityType.itemEdited:
        return Icons.edit;
      case ActivityType.itemCompleted:
        return Icons.check_circle;
      case ActivityType.itemAssigned:
      case ActivityType.itemReassigned:
        return Icons.assignment_ind;
      case ActivityType.memberAdded:
        return Icons.person_add;
      case ActivityType.memberRemoved:
        return Icons.person_remove;
      case ActivityType.roleChanged:
        return Icons.admin_panel_settings;
      case ActivityType.listShared:
        return Icons.share;
      case ActivityType.listEdited:
        return Icons.edit_note;
    }
  }
}

/// Full-screen activity feed bottom sheet
class ActivityFeedBottomSheet extends StatelessWidget {
  final String listId;

  const ActivityFeedBottomSheet({super.key, required this.listId});

  static void show(BuildContext context, {required String listId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFeedBottomSheet(listId: listId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Activity Feed',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
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

              // Activity list
              Expanded(
                child: StreamBuilder<List<ActivityInfo>>(
                  stream:
                      CollaborativeShoppingListService.getActivityFeedStream(
                        listId,
                        limit: 100,
                      ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activity yet',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Activity will appear here as you and your\ncollaborators work on this list',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final activities = snapshot.data!;
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.05),
                        height: 1,
                        indent: 68,
                      ),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _ActivityItem(activity: activity);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact activity feed widget for use in list headers
class CompactActivityFeed extends StatelessWidget {
  final String listId;
  final VoidCallback? onTap;

  const CompactActivityFeed({super.key, required this.listId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ?? () => ActivityFeedBottomSheet.show(context, listId: listId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              color: Colors.white.withValues(alpha: 0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            StreamBuilder<List<ActivityInfo>>(
              stream: CollaborativeShoppingListService.getActivityFeedStream(
                listId,
                limit: 1,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text(
                    'No activity',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }

                final lastActivity = snapshot.data!.first;
                return Text(
                  _formatTimeAgo(lastActivity.timestamp),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
