import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';
import '../../../services/user/user_profile_stream_service.dart';
import 'item_assignment_history_sheet.dart';
import '../../unified_profile_avatar.dart';
import '../../../services/user_service.dart';
import '../../../services/shopping_lists/shopping_list_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/liquid_glass.dart';
import 'collaborators_manager_sheet.dart';

/// Widget for displaying and managing item assignments
class ItemAssignmentWidget extends StatelessWidget {
  final String listId;
  final String itemId;
  final ItemAssignment? assignment;
  final List<CollaboratorInfo> availableCollaborators;
  final VoidCallback? onAssignmentChanged;

  const ItemAssignmentWidget({
    super.key,
    required this.listId,
    required this.itemId,
    this.assignment,
    required this.availableCollaborators,
    this.onAssignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final content = assignment == null
        ? _UnassignedItemWidget(
            listId: listId,
            itemId: itemId,
            availableCollaborators: availableCollaborators,
            onAssignmentChanged: onAssignmentChanged,
          )
        : _AssignedItemWidget(
            listId: listId,
            itemId: itemId,
            assignment: assignment!,
            availableCollaborators: availableCollaborators,
            onAssignmentChanged: onAssignmentChanged,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => ItemAssignmentHistorySheet.show(
            context,
            listId: listId,
            itemId: itemId,
          ),
          icon: const Icon(Icons.history, size: 16, color: Colors.white70),
          label: Text(
            'History',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

/// Widget for unassigned items with assign button
class _UnassignedItemWidget extends StatelessWidget {
  final String listId;
  final String itemId;
  final List<CollaboratorInfo> availableCollaborators;
  final VoidCallback? onAssignmentChanged;

  const _UnassignedItemWidget({
    required this.listId,
    required this.itemId,
    required this.availableCollaborators,
    this.onAssignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (availableCollaborators.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showAssignmentDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              'Assign',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentDialog(BuildContext context) {
    ItemAssignmentSheet.show(
      context,
      listId: listId,
      itemId: itemId,
      availableCollaborators: availableCollaborators,
      onAssigned: onAssignmentChanged,
    );
  }
}

/// Widget for assigned items with assignee avatar
class _AssignedItemWidget extends StatelessWidget {
  final String listId;
  final String itemId;
  final ItemAssignment assignment;
  final List<CollaboratorInfo> availableCollaborators;
  final VoidCallback? onAssignmentChanged;

  const _AssignedItemWidget({
    required this.listId,
    required this.itemId,
    required this.assignment,
    required this.availableCollaborators,
    this.onAssignmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final assignedUserId = assignment.assignedToUserId;
    // Best-effort collaborator lookup for avatar border/status, but name will be resolved via live stream
    final collaboratorFallback = availableCollaborators.firstWhere(
      (c) => c.userId == assignedUserId,
      orElse: () => CollaboratorInfo(
        userId: assignedUserId,
        role: 'member',
        joinedAt: DateTime.now(),
        invitedBy: '',
        permissions: CollaboratorPermissions.member(),
        displayName: 'Unknown',
      ),
    );

    return GestureDetector(
      onTap: () => _showAssignmentDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(assignment.status).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getStatusColor(assignment.status)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AssigneeAvatar(collaborator: collaboratorFallback, size: 20),
            const SizedBox(width: 6),
            // Resolve name live from profile stream with resilient fallbacks
            StreamBuilder<Map<String, dynamic>?>(
              stream: UserProfileStreamService.instance.watchUser(
                assignedUserId,
              ),
              initialData: UserProfileStreamService.instance.getCached(
                assignedUserId,
              ),
              builder: (context, snap) {
                String name = '';
                final data =
                    snap.data ??
                    UserProfileStreamService.instance.getCached(assignedUserId);
                if (data != null &&
                    (data['displayName'] is String) &&
                    (data['displayName'] as String).isNotEmpty) {
                  name = data['displayName'];
                } else {
                  final cached = UserService.maybeGet(assignedUserId);
                  if (cached != null &&
                      cached.displayName.isNotEmpty &&
                      cached.displayName != 'Unknown') {
                    name = cached.displayName;
                  } else if (collaboratorFallback.displayName.isNotEmpty &&
                      collaboratorFallback.displayName != 'Unknown' &&
                      collaboratorFallback.displayName != 'Unknown User') {
                    name = collaboratorFallback.displayName;
                  } else {
                    name = assignedUserId.length > 8
                        ? '${assignedUserId.substring(0, 8)}...'
                        : assignedUserId;
                  }
                }
                // Show first name only like before
                final first = name.split(' ').first;
                return Text(
                  first,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            if (assignment.status != AssignmentStatus.assigned) ...[
              const SizedBox(width: 4),
              Icon(
                _getStatusIcon(assignment.status),
                size: 14,
                color: _getStatusColor(assignment.status),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAssignmentDialog(BuildContext context) {
    ItemAssignmentSheet.show(
      context,
      listId: listId,
      itemId: itemId,
      availableCollaborators: availableCollaborators,
      currentAssignment: assignment,
      onAssigned: onAssignmentChanged,
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.blue;
      case AssignmentStatus.inProgress:
        return Colors.orange;
      case AssignmentStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Icons.schedule;
      case AssignmentStatus.inProgress:
        return Icons.play_circle_filled;
      case AssignmentStatus.completed:
        return Icons.check_circle;
    }
  }
}

/// Small avatar for assigned collaborators
class _AssigneeAvatar extends StatelessWidget {
  final CollaboratorInfo collaborator;
  final double size;

  const _AssigneeAvatar({required this.collaborator, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: UnifiedProfileAvatar(
          userId: collaborator.userId,
          radius: size / 2,
          enableCache: true,
          showBorder: true,
          borderColor: Colors.white,
          borderWidth: 1,
        ),
      ),
    );
  }

  // No-op: UnifiedProfileAvatar handles initials and colors internally.
}

/// Dialog for selecting item assignment
class ItemAssignmentSheet extends StatefulWidget {
  final String listId;
  final String itemId;
  final List<CollaboratorInfo> availableCollaborators;
  final ItemAssignment? currentAssignment;
  final VoidCallback? onAssigned;

  const ItemAssignmentSheet({
    super.key,
    required this.listId,
    required this.itemId,
    required this.availableCollaborators,
    this.currentAssignment,
    this.onAssigned,
  });

  static void show(
    BuildContext context, {
    required String listId,
    required String itemId,
    required List<CollaboratorInfo> availableCollaborators,
    ItemAssignment? currentAssignment,
    VoidCallback? onAssigned,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemAssignmentSheet(
        listId: listId,
        itemId: itemId,
        availableCollaborators: availableCollaborators,
        currentAssignment: currentAssignment,
        onAssigned: onAssigned,
      ),
    );
  }

  @override
  State<ItemAssignmentSheet> createState() => _ItemAssignmentSheetState();
}

class _ItemAssignmentSheetState extends State<ItemAssignmentSheet> {
  final _notesController = TextEditingController();
  bool _isAssigning = false;
  bool _prefetched = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentAssignment?.notes != null) {
      _notesController.text = widget.currentAssignment!.notes!;
    }
    _prefetchUsers();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 20,
      enableBlur: true,
      padding: const EdgeInsets.only(bottom: 10),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.56,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return CustomScrollView(
            controller: controller,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        widget.currentAssignment == null
                            ? 'Assign Item'
                            : 'Update Assignment',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<ShoppingList?>(
                        stream: ShoppingListService.shoppingListStream(
                          widget.listId,
                        ),
                        builder: (context, snap) {
                          final list = snap.data;
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final canManage =
                              list != null &&
                              uid != null &&
                              (uid == list.createdBy ||
                                  (list
                                          .collaborators[uid]
                                          ?.permissions
                                          .canManageMembers ??
                                      false));
                          if (!canManage) return const SizedBox.shrink();
                          return TextButton.icon(
                            onPressed: () => CollaboratorsManagerSheet.show(
                              context,
                              listId: widget.listId,
                            ),
                            icon: const Icon(
                              Icons.lock_open,
                              size: 18,
                              color: Colors.white70,
                            ),
                            label: Text(
                              'Permissions',
                              style: GoogleFonts.inter(color: Colors.white70),
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
              ),

              if (widget.availableCollaborators.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.availableCollaborators.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final c = widget.availableCollaborators[index];
                        final isAssigned =
                            widget.currentAssignment?.assignedToUserId ==
                            c.userId;
                        return GestureDetector(
                          onTap: () => _assignToCollaborator(c),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  ClipOval(
                                    child: UnifiedProfileAvatar(
                                      userId: c.userId,
                                      radius: 22,
                                      enableCache: true,
                                    ),
                                  ),
                                  if (isAssigned)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  _resolveDisplayName(
                                    c.userId,
                                    fallback: c.displayName,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (widget.availableCollaborators.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

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
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (widget.currentAssignment != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: UnifiedProfileAvatar(
                            userId: widget.currentAssignment!.assignedToUserId,
                            radius: 18,
                            enableCache: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _resolveDisplayName(
                                  widget.currentAssignment!.assignedToUserId,
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Status: ${widget.currentAssignment!.status.toString().split('.').last}',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.currentAssignment != null)
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assign to',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent; // available width
                  final filtered = widget.availableCollaborators.where((c) {
                    if (_query.isEmpty) return true;
                    final name = _resolveDisplayName(
                      c.userId,
                      fallback: c.displayName,
                    ).toLowerCase();
                    return name.contains(_query.toLowerCase());
                  }).toList();
                  final crossAxisCount = width ~/ 92.0 < 3 ? 3 : width ~/ 92.0;
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final c = filtered[index];
                        final isAssigned =
                            widget.currentAssignment?.assignedToUserId ==
                            c.userId;
                        final name = _resolveDisplayName(
                          c.userId,
                          fallback: c.displayName,
                        );
                        return InkWell(
                          onTap: () => _assignToCollaborator(c),
                          borderRadius: BorderRadius.circular(12),
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
                                        color: isAssigned
                                            ? Colors.greenAccent
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: UnifiedProfileAvatar(
                                        userId: c.userId,
                                        radius: 32,
                                        enableCache: true,
                                      ),
                                    ),
                                  ),
                                  if (isAssigned)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
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
                                width: 76,
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.role,
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: filtered.length),
                    ),
                  );
                },
              ),

              if (widget.currentAssignment != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes (optional)',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add a note about this assignment...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

              if (widget.currentAssignment != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isAssigning ? null : _removeAssignment,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('Remove assignment'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAssigning ? null : _updateNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isAssigning
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Update notes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _prefetchUsers() async {
    if (_prefetched) return;
    _prefetched = true;
    try {
      final ids = widget.availableCollaborators.map((e) => e.userId).toList();
      // Use both services for comprehensive prefetching
      await UserService.prefetch(ids);
      await UserProfileStreamService.instance.prefetchUsers(ids);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String _resolveDisplayName(String userId, {String? fallback}) {
    // Prefer live profile data
    final data = UserProfileStreamService.instance.getCached(userId);
    final fromData = _extractNameFromUserData(data);
    if (fromData != null && fromData.isNotEmpty) return fromData;

    // Then use any collaborator-provided fallback (from list doc)
    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback.toLowerCase() != 'unknown' &&
        fallback.toLowerCase() != 'unknown user') {
      return fallback;
    }

    // Finally, try legacy UserService cache, but only if not the synthetic default
    final cached = UserService.maybeGet(userId);
    if (cached != null &&
        cached.displayName.isNotEmpty &&
        cached.displayName != 'Unknown') {
      return cached.displayName;
    }

    // Last resort: shorten UID
    return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
  }

  String? _extractNameFromUserData(Map<String, dynamic>? data) {
    if (data == null) return null;
    // 1) displayName
    final display = (data['displayName'] as String?)?.trim();
    if (display != null && display.isNotEmpty) return display;
    // 2) firstName + lastName
    final first = (data['firstName'] as String?)?.trim();
    final last = (data['lastName'] as String?)?.trim();
    if (first != null && first.isNotEmpty) {
      if (last != null && last.isNotEmpty) return '$first $last';
      return first;
    }
    // 3) name / fullName variants
    final name =
        (data['name'] as String?)?.trim() ??
        (data['fullName'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  Future<void> _assignToCollaborator(CollaboratorInfo collaborator) async {
    if (_isAssigning) return;

    setState(() => _isAssigning = true);

    try {
      await CollaborativeShoppingListService.assignItemToMember(
        listId: widget.listId,
        itemId: widget.itemId,
        assignToUserId: collaborator.userId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _removeAssignment() async {
    if (_isAssigning) return;

    setState(() => _isAssigning = true);

    try {
      await CollaborativeShoppingListService.unassignItem(
        listId: widget.listId,
        itemId: widget.itemId,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  Future<void> _updateNotes() async {
    if (_isAssigning || widget.currentAssignment == null) return;

    setState(() => _isAssigning = true);

    try {
      await CollaborativeShoppingListService.updateAssignmentNotes(
        listId: widget.listId,
        itemId: widget.itemId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update notes: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }
}
