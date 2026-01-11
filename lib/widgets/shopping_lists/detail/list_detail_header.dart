import 'package:flutter/material.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/widgets/animated_diff_number.dart';
import 'package:shopple/widgets/buttons/primary_tab_buttons.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/activity_feed_widget.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/collaborators_manager_sheet.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/edit_history_sheet.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/list_sharing_dialog.dart';
import 'package:shopple/widgets/shopping_lists/header/modern_list_header.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/controllers/shopping_list_items_controller.dart';

class ListDetailHeader extends StatelessWidget {
  final ListDetailController controller;
  final VoidCallback onStoreMenuTap;
  final GlobalKey? storeButtonKey;

  const ListDetailHeader({
    super.key,
    required this.controller,
    required this.onStoreMenuTap,
    this.storeButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final list = controller.list;
    final items = controller.itemsController.mergedItems;
    
    double adjustedEstimated = 0;
    int completed = 0;
    
    for (final it in items) {
      final unit = it.estimatedPrice > 0
          ? it.estimatedPrice
          : (it.productId != null ? controller.currentUnitPrices[it.productId] ?? 0 : 0);
      adjustedEstimated += unit * it.quantity;
      if (it.isCompleted) completed++;
    }
    
    final totalItems = items.length;
    final double percent = totalItems == 0 ? 0.0 : completed / totalItems;
    final displayedEstimate = controller.currentUnitPrices.isEmpty
        ? list.estimatedTotal
        : adjustedEstimated;
    final budgetLimit = list.budgetLimit;
    final overBudget = budgetLimit > 0 && displayedEstimate > budgetLimit;
    final double budgetRemaining = budgetLimit > 0
        ? (budgetLimit - displayedEstimate).clamp(0, double.infinity).toDouble()
        : 0.0;

    double projectedOver = 0;
    if (budgetLimit > 0 && list.totalItems > 0) {
      final avgPerItem = list.totalItems > 0
          ? list.estimatedTotal / list.totalItems
          : 0;
      final remaining = (list.totalItems - list.completedItems).clamp(
        0,
        list.totalItems,
      );
      final projected =
          list.estimatedTotal + remaining * avgPerItem * 0.2; // 20% buffer
      if (projected > budgetLimit && !overBudget) {
        projectedOver = projected - budgetLimit;
      }
    }

    final extraBadges = <Widget>[];
    if (overBudget) {
      extraBadges.add(
        Chip(
          label: const Text(
            'Over budget',
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    if (projectedOver > 0) {
      extraBadges.add(
        Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Risk +',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
              const SizedBox(width: 4),
              AnimatedDiffNumber(
                value: projectedOver,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orangeAccent.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    
    final quickActions = <Widget>[
      PrimaryTabButton(
        buttonText: controller.showCategories ? 'Ungroup' : 'Group',
        itemIndex: 0,
        notifier: ValueNotifier(-1),
        callback: controller.toggleCategories,
      ),
      PopupMenuButton<ItemSortMode>(
        tooltip: 'Sort',
        onSelected: (m) {
          controller.itemsController.setSortMode(m);
        },
        itemBuilder: (c) => const [
          PopupMenuItem(
            value: ItemSortMode.manual,
            child: Text('Custom (manual)'),
          ),
          PopupMenuItem(value: ItemSortMode.name, child: Text('Name')),
          PopupMenuItem(value: ItemSortMode.priceAsc, child: Text('Price ↑')),
          PopupMenuItem(value: ItemSortMode.priceDesc, child: Text('Price ↓')),
          PopupMenuItem(
            value: ItemSortMode.recentlyAdded,
            child: Text('Recent'),
          ),
        ],
        child: PrimaryTabButton(
          buttonText: 'Sort: ${_prettySortLabel(controller.itemsController.sortMode)}',
          itemIndex: 2,
          notifier: ValueNotifier(-1),
          callback: () {},
        ),
      ),
      Container(
        key: storeButtonKey,
        child: PrimaryTabButton(
          buttonText: controller.itemsController.splitByStore
              ? 'Stores: Split'
              : "Store: ${controller.itemsController.filterStore ?? 'All'}",
          itemIndex: 1,
          notifier: ValueNotifier(-1),
          callback: onStoreMenuTap,
        ),
      ),
    ];

    return ModernListHeader(
      list: list,
      description: list.description.isEmpty ? null : list.description,
      completedItems: completed,
      totalItems: totalItems,
      percentComplete: percent,
      displayedEstimate: displayedEstimate,
      budgetLimit: budgetLimit,
      budgetRemaining: budgetRemaining,
      overBudget: overBudget,
      projectedOver: projectedOver,
      statusChip: _statusChip(list.status),
      extraBadges: extraBadges,
      quickActions: quickActions,
      activityFeed: CompactActivityFeed(listId: list.id),
      onShareTap: () => ListSharingDialog.showForExistingList(
        context,
        listId: list.id,
        onShared: () {},
      ),
      onActivityTap: () =>
          ActivityFeedBottomSheet.show(context, listId: list.id),
      onHistoryTap: () => EditHistorySheet.show(context, list.id),
      onManageMembersTap: () =>
          CollaboratorsManagerSheet.show(context, listId: list.id),
    );
  }

  String _prettySortLabel(ItemSortMode m) {
    switch (m) {
      case ItemSortMode.manual:
        return 'custom';
      case ItemSortMode.name:
        return 'name';
      case ItemSortMode.priceAsc:
        return 'price ↑';
      case ItemSortMode.priceDesc:
        return 'price ↓';
      case ItemSortMode.recentlyAdded:
        return 'recent';
    }
  }

  Widget _statusChip(ListStatus status) {
    Color color;
    String text;
    switch (status) {
      case ListStatus.active:
        color = Colors.blueAccent;
        text = 'Active';
        break;
      case ListStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case ListStatus.archived:
        color = Colors.grey;
        text = 'Archived';
        break;
    }
    return LiquidGlass(
      borderRadius: 18,
      enableBlur: true,
      blurSigmaX: 10,
      blurSigmaY: 16,
      gradientColors: [
        color.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.05),
      ],
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Chip(
          label: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );
  }
}
