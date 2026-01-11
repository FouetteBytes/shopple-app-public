import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/shopping_lists/shopping_list_service.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';
// Uses only public API from collaborative service
import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../common/liquid_glass.dart';
import '../../unified_profile_avatar.dart';
import 'list_sharing_dialog.dart';
import 'mini_chat_sheet.dart';
import '../../../services/user_service.dart';
import '../../../services/user/user_profile_stream_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollaboratorsManagerSheet extends StatelessWidget {
  final String listId;
  const CollaboratorsManagerSheet({super.key, required this.listId});

  static void show(BuildContext context, {required String listId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CollaboratorsManagerSheet(listId: listId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 20,
      enableBlur: true,
      padding: const EdgeInsets.only(bottom: 10),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Collaborators',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Show Add only if current user can invite/manage members
                        StreamBuilder<ShoppingList?>(
                          stream: ShoppingListService.shoppingListStream(
                            listId,
                          ),
                          builder: (context, snap) {
                            final l = snap.data;
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final canInvite =
                                l != null &&
                                uid != null &&
                                (uid == l.createdBy ||
                                    (l
                                            .collaborators[uid]
                                            ?.permissions
                                            .canInvite ??
                                        false) ||
                                    (l
                                            .collaborators[uid]
                                            ?.permissions
                                            .canManageMembers ??
                                        false));
                            if (!canInvite) return const SizedBox.shrink();
                            return TextButton.icon(
                              onPressed: () {
                                ListSharingDialog.showForExistingList(
                                  context,
                                  listId: listId,
                                  onShared: () {},
                                );
                              },
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.blue,
                              ),
                              label: const Text(
                                'Add',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<ShoppingList?>(
                      stream: ShoppingListService.shoppingListStream(listId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final list = snapshot.data!;
                        final entries = list.collaborators.entries.toList();

                        // Prefetch names/avatars to reduce Unknown fallbacks
                        final userIds = entries
                            .map((e) => e.value.userId)
                            .toList();
                        UserService.prefetch(userIds);
                        UserProfileStreamService.instance.prefetchUsers(
                          userIds,
                        );

                        // Sort with owner first and use resolved names
                        entries.sort((a, b) {
                          if (a.value.userId == list.createdBy) return -1;
                          if (b.value.userId == list.createdBy) return 1;
                          final an = _resolvedName(a.value);
                          final bn = _resolvedName(b.value);
                          return an.compareTo(bn);
                        });

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: _LegendRow(),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: controller,
                                itemCount: entries.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final collaborator = entries[index].value;
                                  return _CollaboratorTile(
                                    list: list,
                                    collaborator: collaborator,
                                    maxWidth: constraints.maxWidth,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _resolvedName(CollaboratorInfo c) {
    if (c.displayName.isNotEmpty && c.displayName.toLowerCase() != 'unknown') {
      return c.displayName;
    }
    final cached = UserService.maybeGet(c.userId);
    return cached?.displayName ?? c.userId;
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 10, color: Colors.green),
        const SizedBox(width: 6),
        Text(
          'Online',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.circle, size: 10, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Offline',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _CollaboratorTile extends StatelessWidget {
  final ShoppingList list;
  final CollaboratorInfo collaborator;
  final double maxWidth;
  const _CollaboratorTile({
    required this.list,
    required this.collaborator,
    required this.maxWidth,
  });

  bool get _isOwner => collaborator.userId == list.createdBy;

  String _resolvedName(CollaboratorInfo c) {
    if (c.displayName.isNotEmpty && c.displayName.toLowerCase() != 'unknown') {
      return c.displayName;
    }

    // Check UserProfileStreamService cache first for real-time data
    final streamData = UserProfileStreamService.instance.getCached(c.userId);
    if (streamData?['displayName']?.isNotEmpty == true) {
      return streamData!['displayName'];
    }

    // Fallback to UserService cache
    final cached = UserService.maybeGet(c.userId);
    final displayName = cached?.displayName;
    if (displayName?.isNotEmpty == true) return displayName!;

    // Fallback to user ID prefix instead of "Unknown"
    return c.userId.length > 8 ? '${c.userId.substring(0, 8)}...' : c.userId;
  }

  @override
  Widget build(BuildContext context) {
    final isEditor =
        (list.memberRoles[collaborator.userId] ?? 'viewer') == 'editor';
    final isCompact = maxWidth < 400; // Adjust layout for narrow screens

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCompact ? 4 : 8,
      ),
      leading: Stack(
        children: [
          ClipOval(
            child: UnifiedProfileAvatar(
              userId: collaborator.userId,
              radius: 22,
              enableCache: true,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: collaborator.isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        _resolvedName(collaborator),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _roleChip(collaborator.role),
                const SizedBox(height: 2),
                if (isEditor) _permChip('Editor') else _permChip('Viewer'),
              ],
            )
          : Row(
              children: [
                _roleChip(collaborator.role),
                const SizedBox(width: 8),
                if (isEditor) _permChip('Editor') else _permChip('Viewer'),
              ],
            ),
      trailing: isCompact
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) {
                switch (value) {
                  case 'message':
                    MiniChatSheet.show(context, userId: collaborator.userId);
                    break;
                  case 'remove':
                    _confirmRemove(
                      context,
                      list.id,
                      collaborator.userId,
                      collaborator.displayName,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.white70),
                      SizedBox(width: 8),
                      Text('Message', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                if (!_isOwner)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_alt_1,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Remove',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Message',
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      MiniChatSheet.show(context, userId: collaborator.userId),
                ),
                // Only owners or users with manageMembers permission can change roles or remove
                if (!_isOwner && _canManageMembers(list))
                  _RoleDropdown(
                    listId: list.id,
                    userId: collaborator.userId,
                    initialRole: collaborator.role,
                  ),
                if (!_isOwner && _canManageMembers(list))
                  IconButton(
                    tooltip: 'Remove collaborator',
                    icon: const Icon(
                      Icons.person_remove_alt_1,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmRemove(
                      context,
                      list.id,
                      collaborator.userId,
                      collaborator.displayName,
                    ),
                  ),
              ],
            ),
    );
  }

  bool _canManageMembers(ShoppingList l) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (uid == l.createdBy) return true; // owner always can
    final self = l.collaborators[uid];
    return self?.permissions.canManageMembers ?? false;
  }

  Widget _roleChip(String role) {
    Color c;
    switch (role) {
      case 'owner':
        c = Colors.amber;
        break;
      case 'admin':
        c = Colors.purple;
        break;
      case 'member':
        c = Colors.blue;
        break;
      default:
        c = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        role,
        style: GoogleFonts.inter(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _permChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    String listId,
    String userId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Remove collaborator',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Remove $name from this list? They will lose access.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await CollaborativeShoppingListService.removeCollaborator(
      listId: listId,
      userId: userId,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove collaborator')),
      );
    }
  }
}

class _RoleDropdown extends StatefulWidget {
  final String listId;
  final String userId;
  final String initialRole;
  const _RoleDropdown({
    required this.listId,
    required this.userId,
    required this.initialRole,
  });

  @override
  State<_RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<_RoleDropdown> {
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _role,
      dropdownColor: Colors.grey[900],
      style: GoogleFonts.inter(color: Colors.white),
      underline: const SizedBox.shrink(),
      onChanged: _saving
          ? null
          : (v) async {
              if (v == null) return;
              setState(() => _saving = true);
              try {
                await _updateRole(widget.listId, widget.userId, v);
                setState(() => _role = v);
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
      items: const [
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'member', child: Text('Member')),
        DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
      ],
    );
  }

  Future<void> _updateRole(String listId, String userId, String role) async {
    final rulesRole = _memberRoleForRules(role);
    await FirebaseFirestore.instance.doc('shopping_lists/$listId').update({
      'collaboration.members.$userId.role': role,
      'collaboration.members.$userId.permissions': _permissionsForRole(role),
      'memberRoles.$userId': rulesRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _memberRoleForRules(String role) {
    switch (role.toLowerCase()) {
      case 'viewer':
        return 'viewer';
      case 'admin':
      case 'member':
        return 'editor';
      default:
        return 'viewer';
    }
  }

  Map<String, bool> _permissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return {
          'canEdit': true,
          'canInvite': true,
          'canDelete': true,
          'canManageMembers': true,
          'canViewActivity': true,
          'canAssignItems': true,
          'canManageRoles': true,
          'canViewEditHistory': true,
        };
      case 'admin':
        return {
          'canEdit': true,
          'canInvite': true,
          'canDelete': false,
          'canManageMembers': true,
          'canViewActivity': true,
          'canAssignItems': true,
          'canManageRoles': false,
          'canViewEditHistory': true,
        };
      case 'member':
        return {
          'canEdit': true,
          'canInvite': false,
          'canDelete': false,
          'canManageMembers': false,
          'canViewActivity': true,
          'canAssignItems': false,
          'canManageRoles': false,
          'canViewEditHistory': false,
        };
      case 'viewer':
      default:
        return {
          'canEdit': false,
          'canInvite': false,
          'canDelete': false,
          'canManageMembers': false,
          'canViewActivity': true,
          'canAssignItems': false,
          'canManageRoles': false,
          'canViewEditHistory': false,
        };
    }
  }
}
