import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';
import '../../../services/friends/friend_service.dart';
import '../../../models/friends/friend.dart';
import '../../common/liquid_glass.dart';
import '../../unified_profile_avatar.dart';
import '../../../services/user/user_profile_stream_service.dart';
import '../../../services/user_service.dart';

/// Enhanced sharing dialog with permission settings and collaboration features
class ListSharingDialog extends StatefulWidget {
  final String? listId; // null for new list, provided for existing list
  final List<dynamic>? preSelectedFriends; // For create flow
  final Function(List<Friend>, Map<String, String>)?
  onFriendsSelected; // For create flow
  final VoidCallback? onShared; // For existing list

  const ListSharingDialog({
    super.key,
    this.listId,
    this.preSelectedFriends,
    this.onFriendsSelected,
    this.onShared,
  });

  static void showForNewList(
    BuildContext context, {
    List<dynamic>? preSelectedFriends,
    required Function(List<Friend>, Map<String, String>) onFriendsSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListSharingDialog(
        preSelectedFriends: preSelectedFriends,
        onFriendsSelected: onFriendsSelected,
      ),
    );
  }

  static void showForExistingList(
    BuildContext context, {
    required String listId,
    VoidCallback? onShared,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ListSharingDialog(listId: listId, onShared: onShared),
    );
  }

  @override
  State<ListSharingDialog> createState() => _ListSharingDialogState();
}

class _ListSharingDialogState extends State<ListSharingDialog> {
  List<Friend> _availableFriends = [];
  final Map<String, bool> _selectedFriends = {};
  final Map<String, String> _friendRoles = {}; // userId -> role
  bool _loading = true;
  bool _sharing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      // Align with existing FriendService API (stream-based)
      final friends = await FriendService.getFriendsStream().first;
      // Prefetch profile streams and cache to avoid avatar/name flicker
      final ids = friends.map((f) => f.userId).toList();
      Future.microtask(() => UserService.prefetch(ids));
      Future.microtask(
        () => UserProfileStreamService.instance.prefetchUsers(ids),
      );

      setState(() {
        _availableFriends = friends;

        // Initialize selection and roles based on pre-selected friends
        if (widget.preSelectedFriends != null) {
          for (final friend in widget.preSelectedFriends!) {
            final String userId = (friend as Friend).userId;
            _selectedFriends[userId] = true;
            _friendRoles[userId] = 'member'; // Default role
          }
        }

        // Set default roles for all friends
        for (final friend in friends) {
          _friendRoles[friend.userId] ??= 'member';
        }

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load friends: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic height calculation based on actual content
    final size = MediaQuery.of(context).size;
    final friendCount = _availableFriends.length;
    // Calculate grid dimensions based on screen width
    final estColumns = size.width < 380 ? 3 : (size.width < 480 ? 4 : 5);
    final estRows = friendCount > 0 ? (friendCount / estColumns).ceil() : 1;

    // Component heights: header+info ~ 140, search ~ 56, bulk row ~ 40, grid rows ~ 104 each, buttons ~ 70, padding ~ 40
    final fixedHeight = 140.0 + 56.0 + 40.0 + 70.0 + 40.0;
    final gridHeight = estRows * 104.0;
    final totalEstimated = fixedHeight + gridHeight;

    // Dynamic sizing based on content with reasonable bounds
    final minSize = 0.5; // Increased minimum for better comfort
    final maxSize = 0.92; // Maximum to keep some screen visible
    final dynamicSize = (totalEstimated / size.height).clamp(minSize, maxSize);

    // Use larger initial size for better UX
    final initialSize = friendCount <= 2
        ? 0.6
        : // More generous for few friends
          friendCount <= 6
        ? 0.7
        : // Good size for medium
          dynamicSize.clamp(0.65, maxSize); // Ensure minimum 65% for many

    return LiquidGlass(
      borderRadius: 20,
      enableBlur: true,
      padding: const EdgeInsets.only(bottom: 8),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        snap: true,
        snapSizes: [
          minSize,
          (minSize + maxSize) / 2,
          maxSize,
        ], // Dynamic snap points based on calculated bounds
        builder: (context, controller) {
          const double footerBarHeight = 64;
          final bottomInset = MediaQuery.of(context).padding.bottom;
          // Account for pinned footer
          final bottomPadding = footerBarHeight + bottomInset + 12;
          return Stack(
            children: [
              CustomScrollView(
                controller: controller,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            widget.listId == null
                                ? 'Add Collaborators'
                                : 'Share List',
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
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select friends and set their permission levels for real-time collaboration',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v.trim()),
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          hintText: 'Search by name…',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_availableFriends.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends to share with',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add friends to start collaborating!',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Bulk actions row (Select all / Deselect all)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_filteredFriends().length} friends',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _toggleSelectAll,
                              icon: Icon(
                                _areAllFilteredSelected()
                                    ? Icons.clear_all
                                    : Icons.select_all,
                                color: Colors.white70,
                                size: 18,
                              ),
                              label: Text(
                                _areAllFilteredSelected()
                                    ? 'Deselect all'
                                    : 'Select all',
                                style: GoogleFonts.inter(color: Colors.white70),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Grid of friends (Telegram-style chips)
                    SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final crossAxisCount = width ~/ 92.0 < 3
                            ? 3
                            : width ~/ 92.0;
                        final filtered = _filteredFriends();
                        return SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            bottomPadding,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final friend = filtered[index];
                              final isSelected =
                                  _selectedFriends[friend.userId] ?? false;
                              final role =
                                  _friendRoles[friend.userId] ?? 'member';
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _selectedFriends[friend.userId] =
                                        !isSelected;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.blueAccent
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: UnifiedProfileAvatar(
                                              userId: friend.userId,
                                              radius: 32,
                                              enableCache: true,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            right: -4,
                                            bottom: -4,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.black,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 80,
                                      child: _LiveName(
                                        userId: friend.userId,
                                        fallback: friend.displayName,
                                        firstNameOnly: true,
                                        center: true,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 96,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Text(
                                                  _roleLabel(role),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () => _showRolePicker(
                                                friend.userId,
                                                currentRole: role,
                                              ),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.06),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.settings,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }, childCount: filtered.length),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              // Footer action bar pinned to bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    height: footerBarHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[600]!),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sharing ? null : _handleShare,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _sharing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(widget.listId == null ? 'Add' : 'Share'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Member';
    }
  }

  void _showRolePicker(String userId, {required String currentRole}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return LiquidGlass(
          borderRadius: 16,
          enableBlur: true,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Choose permission',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _roleTile(
                    'admin',
                    'Admin - Full access',
                    currentRole,
                    userId,
                  ),
                  _roleTile(
                    'member',
                    'Member - Can edit items',
                    currentRole,
                    userId,
                  ),
                  _roleTile(
                    'viewer',
                    'Viewer - Read only',
                    currentRole,
                    userId,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _roleTile(
    String value,
    String label,
    String currentRole,
    String userId,
  ) {
    final selected = value == currentRole;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(label, style: GoogleFonts.inter(color: Colors.white)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.radio_button_unchecked, color: Colors.white38),
      onTap: () {
        setState(() => _friendRoles[userId] = value);
        Navigator.pop(context);
      },
    );
  }

  // Bulk selection helpers (moved into State to allow setState)
  bool _areAllFilteredSelected() {
    final filtered = _filteredFriends();
    if (filtered.isEmpty) return false;
    for (final f in filtered) {
      if (!(_selectedFriends[f.userId] ?? false)) return false;
    }
    return true;
  }

  void _toggleSelectAll() {
    final filtered = _filteredFriends();
    final makeSelected = !_areAllFilteredSelected();
    setState(() {
      for (final f in filtered) {
        _selectedFriends[f.userId] = makeSelected;
      }
    });
  }

  Future<void> _handleShare() async {
    setState(() => _sharing = true);

    try {
      final selectedFriends = _availableFriends
          .where((friend) => _selectedFriends[friend.userId] == true)
          .toList();

      final selectedRoles = <String, String>{};
      for (final friend in selectedFriends) {
        selectedRoles[friend.userId] = _friendRoles[friend.userId] ?? 'member';
      }

      if (widget.listId == null) {
        // For create flow - return selected friends and roles
        widget.onFriendsSelected?.call(selectedFriends, selectedRoles);
      } else {
        // For existing list - share using collaborative service
        await CollaborativeShoppingListService.shareList(
          listId: widget.listId!,
          userIds: selectedFriends.map((f) => f.userId).toList(),
          role:
              'member', // Base role; individual role diffs can be handled separately if needed
        );
        widget.onShared?.call();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedFriends.length == 1
                  ? 'Shared with ${selectedFriends.first.displayName}'
                  : 'Shared with ${selectedFriends.length} friends',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// Live-updating display name using UserProfileStreamService with robust fallbacks
class _LiveName extends StatelessWidget {
  final String userId;
  final String fallback;
  final bool firstNameOnly;
  final bool center;
  const _LiveName({
    required this.userId,
    required this.fallback,
    this.firstNameOnly = false,
    this.center = false,
  });

  String _compose(Map<String, dynamic>? data) {
    if (data == null) return fallback;
    final display = (data['displayName'] as String?)?.trim();
    if (display != null && display.isNotEmpty) {
      if (firstNameOnly) return display.split(' ').first;
      return display;
    }
    final first = (data['firstName'] as String?)?.trim();
    final last = (data['lastName'] as String?)?.trim();
    if (first != null && first.isNotEmpty) {
      return firstNameOnly
          ? first
          : ((last != null && last.isNotEmpty) ? '$first $last' : first);
    }
    final name =
        (data['name'] as String?)?.trim() ??
        (data['fullName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      if (firstNameOnly) return name.split(' ').first;
      return name;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final initial = UserProfileStreamService.instance.getCached(userId);
    return StreamBuilder<Map<String, dynamic>?>(
      stream: UserProfileStreamService.instance.watchUser(userId),
      initialData: initial,
      builder: (context, snap) {
        final data = snap.data ?? initial;
        return Text(
          _compose(data),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}

extension _Filtering on _ListSharingDialogState {
  List<Friend> _filteredFriends() {
    if (_query.isEmpty) return _availableFriends;
    final q = _query.toLowerCase();
    return _availableFriends.where((f) {
      final data = UserProfileStreamService.instance.getCached(f.userId);
      final name = _composeName(data, fallback: f.displayName).toLowerCase();
      return name.contains(q) || (f.email.toLowerCase().contains(q));
    }).toList();
  }

  String _composeName(Map<String, dynamic>? data, {required String fallback}) {
    if (data != null) {
      final display = (data['displayName'] as String?)?.trim();
      if (display != null && display.isNotEmpty) return display;
      final first = (data['firstName'] as String?)?.trim();
      final last = (data['lastName'] as String?)?.trim();
      if (first != null && first.isNotEmpty) {
        return (last != null && last.isNotEmpty) ? '$first $last' : first;
      }
      final name =
          (data['name'] as String?)?.trim() ??
          (data['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return fallback;
  }
}
