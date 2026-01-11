import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/shopping_lists/shopping_list_item_model.dart';
import '../../../models/shopping_lists/shopping_list_model.dart';
import '../../unified_profile_avatar.dart';
import '../../../services/shopping_lists/shopping_list_service.dart';
import '../../../services/shopping_lists/collaborative_shopping_list_service.dart';

class CollaborativeReorderableList extends StatefulWidget {
  final String listId;
  final List<ShoppingListItem> items;
  final void Function(ShoppingListItem) onItemTap;
  final void Function(ShoppingListItem, bool) onItemToggle;

  const CollaborativeReorderableList({
    super.key,
    required this.listId,
    required this.items,
    required this.onItemTap,
    required this.onItemToggle,
  });

  @override
  State<CollaborativeReorderableList> createState() =>
      _CollaborativeReorderableListState();
}

class _CollaborativeReorderableListState
    extends State<CollaborativeReorderableList> {
  late List<ShoppingListItem> _local;
  bool _reordering = false;
  Stream<ShoppingList?>? _listStream;
  ShoppingList? _list;

  @override
  void initState() {
    super.initState();
    _local = List.of(widget.items);
    _listStream = ShoppingListService.shoppingListStream(widget.listId);
  }

  @override
  void didUpdateWidget(covariant CollaborativeReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordering) {
      _local = List.of(widget.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShoppingList?>(
      stream: _listStream,
      builder: (context, snap) {
        _list = snap.data;
        return AnimatedReorderableListView(
          items: _local,
          // Identify when two items are the same for efficient animations
          isSameItem: (a, b) => a.id == b.id,
          itemBuilder: (context, index) {
            final item = _local[index];
            return _buildTile(item, index);
          },
          onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
        );
      },
    );
  }

  Widget _buildTile(ShoppingListItem item, int index) {
    final assignedTo = _list?.itemAssignments[item.id]?.assignedToUserId;
    return Container(
      key: ValueKey(item.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => widget.onItemTap(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => widget.onItemToggle(item, !item.isCompleted),
                  child: Icon(
                    item.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (item.notes.isNotEmpty)
                        Text(
                          item.notes,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (assignedTo != null && assignedTo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipOval(
                      child: UnifiedProfileAvatar(
                        userId: assignedTo,
                        radius: 14,
                        enableCache: true,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (item.estimatedPrice > 0)
                      Text(
                        'Rs. ${item.estimatedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _reordering = true;
      final item = _local.removeAt(oldIndex);
      _local.insert(newIndex, item);
    });
    _syncOrder();
  }

  Future<void> _syncOrder() async {
    final orderedIds = _local.map((e) => e.id).toList();
    // Broadcast reordering activity to collaborators
    try {
      await CollaborativeShoppingListService.updatePresence(
        listId: widget.listId,
        activity: 'reordering',
      );
    } catch (_) {}
    await ShoppingListService.updateItemOrders(widget.listId, orderedIds);
    // touch presence/activity like the guide suggests
    await FirebaseFirestore.instance
        .doc('shopping_lists/${widget.listId}')
        .update({
          'collaboration.lastActivity': {
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'userName':
                FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
            'action': 'items_reordered',
            'timestamp': FieldValue.serverTimestamp(),
            'details': {'itemCount': _local.length},
            'type': 'itemEdited',
          },
        });
    // Reset presence to viewing and clear local reordering flag
    try {
      await CollaborativeShoppingListService.updatePresence(
        listId: widget.listId,
        activity: 'viewing',
      );
    } catch (_) {}
    if (mounted) {
      setState(() => _reordering = false);
      // Show a subtle toast to confirm reorder completion
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Items reordered'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
