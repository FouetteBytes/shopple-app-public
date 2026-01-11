import 'package:flutter/material.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/services/product/product_image_cache.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/widgets/shopping_lists/modern_list_item_card.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/item_assignment_widget.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/shopping_lists/collaborative_shopping_list_service.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

class ShoppingListItemWrapper extends StatefulWidget {
  final ShoppingListItem item;
  final ListDetailController controller;
  final bool allowDrag;
  final int? index;
  final VoidCallback onEdit;

  const ShoppingListItemWrapper({
    super.key,
    required this.item,
    required this.controller,
    this.allowDrag = false,
    this.index,
    required this.onEdit,
  });

  @override
  State<ShoppingListItemWrapper> createState() => _ShoppingListItemWrapperState();
}

class _ShoppingListItemWrapperState extends State<ShoppingListItemWrapper> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final controller = widget.controller;
    final list = controller.list;

    // Get cached image URL for instant display if available
    final cachedImageUrl = item.productId != null
        ? ProductImageCache.instance.peek(item.productId!)
        : null;

    final card = ModernListItemCard(
      item: item,
      overrideUnitPrice: (item.estimatedPrice <= 0 && item.productId != null)
          ? controller.currentUnitPrices[item.productId]
          : null,
      sizeLabel: item.productId != null
          ? controller.productSizeLabels[item.productId]
          : null,
      imageUrl: cachedImageUrl,
      onToggle: () {
        if (list.status != ListStatus.archived) {
          controller.toggleItem(item).then((ok) {
            if (!ok && mounted) {
              LiquidSnack.show(
                title: 'Info',
                message: 'Only the assignee or editors can complete this item',
                accentColor: AppColors.primaryAccentColor,
              );
            }
          });
        }
      },
      onEdit: widget.onEdit,
      onDelete: null, // handled by swipe
      onIncrement: () {
        final next = item.quantity + 1;
        ShoppingListService.updateItem(
          listId: list.id,
          itemId: item.id,
          quantity: next,
        ).then((_) {
          controller.pushLocalAggregates();
          ShoppingListCache.instance.reconcileHydrationFor([list.id]);
        });
      },
      onDecrement: () {
        if (item.quantity > 1) {
          final next = item.quantity - 1;
          ShoppingListService.updateItem(
            listId: list.id,
            itemId: item.id,
            quantity: next,
          ).then((_) {
            controller.pushLocalAggregates();
            ShoppingListCache.instance.reconcileHydrationFor([list.id]);
          });
        }
      },
      outOfStock: false,
      selectionMode: controller.itemsController.selectionMode,
      isSelected: controller.itemsController.selectedIds.contains(item.id),
      onSelectToggle: () {
        if (!controller.itemsController.selectionMode) {
          controller.itemsController.enterSelection(item.id);
        } else {
          controller.itemsController.toggleSelection(item.id);
        }
      },
      showDragHandle: widget.allowDrag,
      dragHandleBuilder: widget.allowDrag && widget.index != null
          ? (handle) => ReorderableDragStartListener(
              key: ValueKey('h_${item.id}'),
              index: widget.index!,
              child: handle,
            )
          : null,
    );

    // Below-card assignment strip for shared lists
    final assignmentStrip = !list.isShared
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
            child: Builder(
              builder: (context) {
                final assignment = list.itemAssignments[item.id];
                final collaborators = list.collaborators.values.toList();
                if (collaborators.isEmpty && assignment == null) {
                  return const SizedBox.shrink();
                }
                
                Widget withBadge(Widget child) {
                  if (assignment == null || assignment.assignedToUserId.isEmpty) {
                    return child;
                  }
                  final assignedTo = assignment.assignedToUserId;
                  return Stack(
                    children: [
                      child,
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4, left: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ClipOval(
                            child: UnifiedProfileAvatar(
                              userId: assignedTo,
                              radius: 10,
                              enableCache: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      withBadge(const SizedBox.shrink()),
                      ItemAssignmentWidget(
                        listId: list.id,
                        itemId: item.id,
                        assignment: assignment,
                        availableCollaborators: collaborators,
                        onAssignmentChanged: () {
                          // Stream updates handle refresh
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          list.isShared && details.data.isNotEmpty,
      onAcceptWithDetails: (details) async {
        final userId = details.data;
        
        final name = list.collaborators[userId]?.displayName;
        if (context.mounted) {
          LiquidSnack.show(
            title: 'Assigned',
            message:
                'Assigned to ${name != null && name.isNotEmpty ? name : userId.substring(0, 6)}',
            accentColor: AppColors.primaryAccentColor,
          );
        }
        await CollaborativeShoppingListService.assignItemToMember(
          listId: list.id,
          itemId: item.id,
          assignToUserId: userId,
        );
      },
      builder: (context, candidates, rejects) {
        final isHovering = candidates.isNotEmpty;
        return Dismissible(
          key: ValueKey('d_${item.id}'),
          direction: DismissDirection.horizontal,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? Colors.orange.withValues(alpha: .15)
                  : Colors.green.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            child: Icon(
              item.isCompleted ? Icons.refresh : Icons.check_circle,
              color: item.isCompleted
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              if (list.status != ListStatus.archived) {
                final ok = await controller.toggleItem(item);
                if (!ok && mounted) {
                  LiquidSnack.show(
                    title: 'Info',
                    message:
                        'Only the assignee or editors can complete this item',
                    accentColor: AppColors.primaryAccentColor,
                  );
                  return false;
                }
              }
              return false; 
            } else {
              controller.deleteItem(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Item deleted'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      controller.undoDelete();
                    },
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
              return false; 
            }
          },
          child: GestureDetector(
            onLongPress: widget.allowDrag
                ? null
                : () {
                    if (!controller.itemsController.selectionMode) {
                      controller.itemsController.enterSelection(item.id);
                    }
                  },
            onDoubleTap: null,
            onTap: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  decoration: isHovering
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryAccentColor.withValues(
                              alpha: 0.8,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccentColor.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Stack(
                    children: [
                      card,
                      Positioned.fill(
                        child: Builder(
                          builder: (context) {
                            // Use stream data for assignments
                            final effective = list;
                            final a = effective.itemAssignments[item.id];
                            final badgeUserId =
                                (a == null || a.assignedToUserId.isEmpty)
                                ? null
                                : a.assignedToUserId;
                            
                            if (badgeUserId == null) {
                              return const SizedBox.shrink();
                            }
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6, left: 6),
                                child: ClipOval(
                                  child: UnifiedProfileAvatar(
                                    userId: badgeUserId,
                                    radius: 10,
                                    enableCache: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                assignmentStrip,
              ],
            ),
          ),
        );
      },
    );
  }
}
