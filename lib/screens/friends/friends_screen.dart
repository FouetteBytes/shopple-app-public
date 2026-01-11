import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/friends/friend_request.dart';
import '../../models/friends/friend.dart';
import '../../models/friends/friend_group.dart';
import '../../services/friends/friend_service.dart';
import '../../widgets/friends/friend_request_tile.dart';
import '../../widgets/friends/friend_tile.dart';
import '../../values/values.dart';
import 'add_friends_screen.dart';
import 'friend_groups_screen.dart';
import '../../screens/contacts/contacts_screen.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/segmented_button_picker.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background style.
          DarkRadialBackground(
            color: AppColors.background,
            position: "topLeft",
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: "Friends",
                    actions: [
                      PageHeaderAction.iconButton(
                        icon: Icons.contacts,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactsScreen(),
                            ),
                          );
                        },
                        tooltip: 'Sync Contacts',
                      ),
                      PageHeaderAction.iconButton(
                        icon: Icons.person_add,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddFriendsScreen(),
                            ),
                          );
                        },
                        tooltip: 'Search Users',
                      ),
                      PageHeaderAction.iconButton(
                        icon: Icons.group,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendGroupsScreen(),
                            ),
                          );
                        },
                        tooltip: 'Friend Groups',
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  SegmentedButtonPicker(
                    controller: _tabController,
                    tabs: [
                      SegmentedTabFactory.simple(
                        text: 'Friends',
                        icon: Icons.people,
                      ),
                      SegmentedTabFactory.withBadge(
                        text: 'Requests',
                        icon: Icons.inbox,
                        countStream:
                            FriendService.getPendingRequestsCountStream(),
                      ),
                      SegmentedTabFactory.simple(
                        text: 'Groups',
                        icon: Icons.folder,
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFriendsTab(),
                        _buildRequestsTab(),
                        _buildGroupsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryAccentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading friends',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                SizedBox(height: 8),
                LiquidGlassButton.text(
                  onTap: () => setState(() {}),
                  text: 'Retry',
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data ?? [];

        // Prefetch profiles for avatar cache.
        if (friends.isNotEmpty) {
          // ignore: discarded_futures
          UserProfileStreamService.instance.prefetchUsers(
            friends.map((f) => f.userId),
          );
        }

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add friends to start building your network!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.grey[400]),
                ),
                SizedBox(height: 16),
                LiquidGlassButton.primary(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendsScreen(),
                      ),
                    );
                  },
                  icon: Icons.person_add,
                  text: 'Add Friends',
                  gradientColors: [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)],
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FriendTile(
                friend: friend,
                showOnlineStatus: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleFriendAction(value, friend),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.person_remove, color: Colors.red),
                        title: Text('Remove Friend'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: FriendService.getReceivedFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryAccentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests',
              style: GoogleFonts.lato(color: Colors.white),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friend requests',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Friend requests will appear here when you receive them.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return FriendRequestTile(
              request: requests[index],
              onRequestHandled: () {
                // Refresh handled automatically by stream
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return StreamBuilder<List<FriendGroup>>(
      stream: FriendService.getFriendGroupsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryAccentColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading groups',
              style: GoogleFonts.lato(color: Colors.white),
            ),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friend groups',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create groups to organize your friends by family, work, school, etc.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.grey[400]),
                ),
                SizedBox(height: 16),
                LiquidGlassButton.primary(
                  onTap: _createDefaultGroups,
                  icon: Icons.add,
                  text: 'Create Default Groups',
                  gradientColors: [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)],
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: group.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getIconData(group.iconName),
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  group.name,
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                subtitle: Text(
                  '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
                  style: GoogleFonts.lato(color: Colors.grey[400]),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                ),
                onTap: () {
                  // TODO: Navigate to group detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group detail screen coming soon!')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _handleFriendAction(String action, Friend friend) async {
    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Remove Friend',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to remove ${friend.displayName} from your friends list?',
            style: GoogleFonts.lato(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await FriendService.removeFriend(friend.userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${friend.displayName} removed from friends'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error removing friend: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  void _createDefaultGroups() async {
    try {
      await FriendService.createDefaultFriendGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default friend groups created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'family_restroom':
        return Icons.family_restroom;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.group;
    }
  }
}
