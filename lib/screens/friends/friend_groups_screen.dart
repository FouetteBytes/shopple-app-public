import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/friends/friend_group.dart';
import '../../services/friends/friend_service.dart';
import '../../values/values.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class FriendGroupsScreen extends StatefulWidget {
  const FriendGroupsScreen({super.key});

  @override
  State<FriendGroupsScreen> createState() => _FriendGroupsScreenState();
}

class _FriendGroupsScreenState extends State<FriendGroupsScreen> {
  bool _isCreatingGroup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Friend Groups',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primaryAccentColor),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: StreamBuilder<List<FriendGroup>>(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading groups',
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

            final groups = snapshot.data ?? [];

            if (groups.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupTile(group);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Friend Groups',
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
          SizedBox(height: 24),
          LiquidGlassButton.primary(
            onTap: _createDefaultGroups,
            icon: Icons.auto_awesome,
            text: 'Create Default Groups',
            gradientColors: [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          SizedBox(height: 12),
          LiquidGlassButton.text(
            onTap: _showCreateGroupDialog,
            text: 'Create Custom Group',
            accentColor: AppColors.primaryAccentColor,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(FriendGroup group) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: group.color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            _getIconData(group.iconName),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          group.name,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description?.isNotEmpty == true) ...[
              SizedBox(height: 4),
              Text(
                group.description!,
                style: GoogleFonts.lato(color: Colors.grey[300], fontSize: 14),
              ),
            ],
            SizedBox(height: 4),
            Text(
              '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
              style: GoogleFonts.lato(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleGroupAction(value, group),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppColors.primaryAccentColor),
                title: Text('Edit Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'manage_members',
              child: ListTile(
                leading: Icon(Icons.people, color: Colors.blue),
                title: Text('Manage Members'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showGroupDetail(group),
      ),
    );
  }

  void _showGroupDetail(FriendGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)),
    );
  }

  void _handleGroupAction(String action, FriendGroup group) async {
    switch (action) {
      case 'edit':
        _showEditGroupDialog(group);
        break;
      case 'manage_members':
        _showManageMembersDialog(group);
        break;
      case 'delete':
        _confirmDeleteGroup(group);
        break;
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = AppColors.primaryAccentColor;
    String selectedIcon = 'group';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Create Friend Group',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.lato(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: GoogleFonts.lato(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primaryAccentColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: GoogleFonts.lato(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: GoogleFonts.lato(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primaryAccentColor,
                      ),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Text(
                  'Choose Color',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.pink,
                            Colors.teal,
                            Colors.red,
                            Colors.indigo,
                          ]
                          .map(
                            (color) => GestureDetector(
                              onTap: () =>
                                  setState(() => selectedColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: selectedColor == color
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                SizedBox(height: 16),
                Text(
                  'Choose Icon',
                  style: GoogleFonts.lato(color: Colors.white),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            {'icon': Icons.group, 'name': 'group'},
                            {
                              'icon': Icons.family_restroom,
                              'name': 'family_restroom',
                            },
                            {'icon': Icons.work, 'name': 'work'},
                            {'icon': Icons.school, 'name': 'school'},
                            {'icon': Icons.favorite, 'name': 'favorite'},
                            {
                              'icon': Icons.sports_soccer,
                              'name': 'sports_soccer',
                            },
                            {'icon': Icons.music_note, 'name': 'music_note'},
                            {'icon': Icons.local_cafe, 'name': 'local_cafe'},
                          ]
                          .map(
                            (iconData) => GestureDetector(
                              onTap: () => setState(
                                () => selectedIcon = iconData['name'] as String,
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selectedIcon == iconData['name']
                                      ? AppColors.primaryAccentColor
                                      : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  iconData['icon'] as IconData,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            LiquidGlassButton.text(
              onTap: () => Navigator.of(context).pop(),
              text: 'Cancel',
            ),
            LiquidGlassGradientButton(
              onTap: _isCreatingGroup
                  ? null
                  : () => _createGroup(
                      context,
                      nameController.text.trim(),
                      descriptionController.text.trim(),
                      selectedColor,
                      selectedIcon,
                    ),
              gradientColors: [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)],
              customChild: _isCreatingGroup
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGroupDialog(FriendGroup group) {
    // TODO: Implement edit group dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit group feature coming soon!')));
  }

  void _showManageMembersDialog(FriendGroup group) {
    // TODO: Implement manage members dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manage members feature coming soon!')),
    );
  }

  void _confirmDeleteGroup(FriendGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Group',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
          style: GoogleFonts.lato(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement delete group in FriendService
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete group feature coming soon!'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createGroup(
    BuildContext dialogContext,
    String name,
    String description,
    Color color,
    String iconName,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Group name is required')));
      return;
    }

    setState(() => _isCreatingGroup = true);

    try {
      await FriendService.createFriendGroup(
        name: name,
        description: description.isEmpty ? null : description,
        color: color,
        iconName: iconName,
      );

      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$name" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingGroup = false);
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
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'music_note':
        return Icons.music_note;
      case 'local_cafe':
        return Icons.local_cafe;
      default:
        return Icons.group;
    }
  }
}

// Simple group detail screen placeholder
class GroupDetailScreen extends StatelessWidget {
  final FriendGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          group.name,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                _getIconData(group.iconName),
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              group.name,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (group.description?.isNotEmpty == true) ...[
              SizedBox(height: 8),
              Text(
                group.description!,
                style: GoogleFonts.lato(color: Colors.grey[400]),
              ),
            ],
            SizedBox(height: 16),
            Text(
              '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
              style: GoogleFonts.lato(color: Colors.grey[400]),
            ),
            SizedBox(height: 32),
            Text(
              'Group member management\ncoming soon!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      ),
    );
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
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'music_note':
        return Icons.music_note;
      case 'local_cafe':
        return Icons.local_cafe;
      default:
        return Icons.group;
    }
  }
}
