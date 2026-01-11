import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';
import '../../../services/user_service.dart';
import '../../../services/user/user_profile_stream_service.dart';
import '../../common/liquid_glass.dart';
import '../../unified_profile_avatar.dart';
import 'collaborators_manager_sheet.dart';
import 'mini_chat_sheet.dart';

/// A horizontal strip of collaborators shown inline on the list header.
/// - Avatars are `Draggable<String>` with data = userId for drag-to-assign onto items.
/// - Long-press an avatar for quick actions: message, permissions, remove.
/// - Tapping the trailing "+" opens the collaborators manager/add flow.
class MemberDragStrip extends StatefulWidget {
  final ShoppingList list;
  final double avatarRadius;
  final bool showBackground;
  const MemberDragStrip({
    super.key,
    required this.list,
    this.avatarRadius = 16,
    this.showBackground = true,
  });

  @override
  State<MemberDragStrip> createState() => _MemberDragStripState();
}

class _MemberDragStripState extends State<MemberDragStrip> {
  final Map<String, Widget> _cachedAvatars = {};

  @override
  void initState() {
    super.initState();
    // Prefetch user names once to avoid repeated lookups
    _prefetchUserData();
  }

  @override
  void didUpdateWidget(MemberDragStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear cache if collaborators changed
    if (oldWidget.list.collaborators != widget.list.collaborators) {
      _cachedAvatars.clear();
      _prefetchUserData();
    }
  }

  void _prefetchUserData() {
    final userIds = widget.list.collaborators.keys.toList();
    if (userIds.isNotEmpty) {
      // Use both UserService and UserProfileStreamService for comprehensive prefetching
      UserService.prefetch(userIds);
      UserProfileStreamService.instance.prefetchUsers(userIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.list.isShared) return const SizedBox.shrink();
    final entries = widget.list.collaborators.values.toList()
      ..sort((a, b) {
        if (a.userId == widget.list.createdBy) return -1;
        if (b.userId == widget.list.createdBy) return 1;
        final an = _resolvedName(a);
        final bn = _resolvedName(b);
        return an.compareTo(bn);
      });

    final content = Row(
      children: [
        for (final c in entries) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildCachedDraggableAvatar(c),
          ),
        ],
        // Quick manage button
        InkWell(
          onTap: () =>
              CollaboratorsManagerSheet.show(context, listId: widget.list.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.showBackground) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return LiquidGlass(
      borderRadius: 16,
      enableBlur: true,
      blurSigmaX: 8,
      blurSigmaY: 14,
      gradientColors: [
        Colors.white.withValues(alpha: 0.06),
        Colors.white.withValues(alpha: 0.02),
      ],
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: content,
      ),
    );
  }

  Widget _buildCachedDraggableAvatar(CollaboratorInfo collaborator) {
    // Use a unique key for caching based on collaborator ID and basic properties
    final cacheKey =
        '${collaborator.userId}_${collaborator.isActive}_${widget.avatarRadius}';

    return _cachedAvatars.putIfAbsent(cacheKey, () {
      return _DraggableAvatar(
        list: widget.list,
        collaborator: collaborator,
        radius: widget.avatarRadius,
      );
    });
  }

  String _resolvedName(CollaboratorInfo c) {
    if (c.displayName.isNotEmpty && c.displayName.toLowerCase() != 'unknown') {
      return c.displayName;
    }

    // Try UserProfileStreamService cache first for real-time data
    final streamData = UserProfileStreamService.instance.getCached(c.userId);
    if (streamData?['displayName']?.isNotEmpty == true) {
      return streamData!['displayName'];
    }

    // Fallback to UserService cache
    final cached = UserService.maybeGet(c.userId);
    final displayName = cached?.displayName;
    if (displayName?.isNotEmpty == true) return displayName!;

    // Final fallback to user ID prefix
    return c.userId.length > 8 ? '${c.userId.substring(0, 8)}...' : c.userId;
  }
}

class _DraggableAvatar extends StatefulWidget {
  final ShoppingList list;
  final CollaboratorInfo collaborator;
  final double radius;
  const _DraggableAvatar({
    required this.list,
    required this.collaborator,
    required this.radius,
  });

  @override
  State<_DraggableAvatar> createState() => _DraggableAvatarState();
}

class _DraggableAvatarState extends State<_DraggableAvatar> {
  bool _isDragging = false;
  Map<String, dynamic>? _userProfile;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;

  bool get _isOwner => widget.collaborator.userId == widget.list.createdBy;

  @override
  void initState() {
    super.initState();
    // Get initial cached profile data without triggering rebuilds
    _userProfile = UserProfileStreamService.instance.getCached(
      widget.collaborator.userId,
    );

    // Listen to real-time user profile updates with debouncing
    _profileSubscription = UserProfileStreamService.instance
        .watchUser(widget.collaborator.userId)
        .distinct() // Only emit when data actually changes
        .listen((profile) {
          if (mounted && _userProfile != profile) {
            setState(() {
              _userProfile = profile;
            });
          }
        });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get display name from real-time profile data
    final displayName = _getDisplayName();

    // Cache the avatar widget to prevent rebuilds when drag state changes
    final avatarWidget = _buildCachedAvatar();

    final avatar = Stack(
      children: [
        avatarWidget,
        // Online/offline indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.collaborator.isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
          ),
        ),
        // Owner crown indicator
        if (_isOwner)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, size: 8, color: Colors.white),
            ),
          ),
      ],
    );

    return Tooltip(
      message: displayName,
      child: GestureDetector(
        onLongPress: () => _showQuickActions(context),
        child: Draggable<String>(
          data: widget.collaborator.userId,
          feedback: _buildDragFeedback(avatarWidget, displayName),
          childWhenDragging: Opacity(opacity: 0.3, child: avatar),
          onDragStarted: () {
            setState(() => _isDragging = true);
          },
          onDragEnd: (_) {
            setState(() => _isDragging = false);
          },
          child: AnimatedScale(
            scale: _isDragging ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: avatar,
          ),
        ),
      ),
    );
  }

  Widget _buildCachedAvatar() {
    // Build avatar once and cache it
    return UnifiedProfileAvatar(
      userId: widget.collaborator.userId,
      radius: widget.radius,
      enableCache: true,
    );
  }

  Widget _buildDragFeedback(Widget avatarWidget, String displayName) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: avatarWidget,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    // Priority: real-time profile data > collaborator display name > user ID fallback
    if (_userProfile?['displayName']?.isNotEmpty == true) {
      return _userProfile!['displayName'];
    }
    if (widget.collaborator.displayName.isNotEmpty &&
        widget.collaborator.displayName.toLowerCase() != 'unknown') {
      return widget.collaborator.displayName;
    }
    return widget.collaborator.userId.length > 8
        ? '${widget.collaborator.userId.substring(0, 8)}...'
        : widget.collaborator.userId;
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LiquidGlass(
        borderRadius: 16,
        enableBlur: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            runSpacing: 8,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Message',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  MiniChatSheet.show(
                    context,
                    userId: widget.collaborator.userId,
                  );
                },
              ),
              if (!_isOwner)
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Permissions',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    CollaboratorsManagerSheet.show(
                      context,
                      listId: widget.list.id,
                    );
                  },
                ),
              if (!_isOwner)
                ListTile(
                  leading: const Icon(
                    Icons.person_remove_alt_1,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await CollaborativeShoppingListService.removeCollaborator(
                      listId: widget.list.id,
                      userId: widget.collaborator.userId,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
