import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/controllers/shopping_list_items_controller.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/shopping_lists/collaborative/collaborative_reorderable_list.dart';
import 'package:shopple/widgets/shopping_lists/detail/shopping_list_item_wrapper.dart';

class ShoppingItemsList extends StatelessWidget {
  final ListDetailController controller;
  final Function(ShoppingListItem) onEditItem;

  const ShoppingItemsList({
    super.key,
    required this.controller,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = controller.itemsController.mergedItems;
    final list = controller.list;
    
    if (items.isEmpty) return const Center(child: Text('No items yet'));

    // 1. Store View (Always grouped, no drag)
    if (controller.itemsController.splitByStore) {
      final byStore = controller.itemsController.groupedByCheapestStore(items);
      final storeOrder = <String>['keells', 'cargills'];
      final entries = byStore.entries.toList()
        ..sort((a, b) {
          int ia = storeOrder.indexOf(a.key.toLowerCase());
          if (ia == -1) ia = 999;
          int ib = storeOrder.indexOf(b.key.toLowerCase());
          if (ib == -1) ib = 999;
          if (ia != ib) return ia.compareTo(ib);
          return a.key.compareTo(b.key);
        });

      return CustomScrollView(
        slivers: [
          for (final entry in entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 14),
                child: Row(
                  children: [
                    Text(
                      _prettyStore(entry.key).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        letterSpacing: 1.1,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.value.where((e) => !e.isCompleted).length}/${entry.value.length}',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = entry.value[index];
                  return ShoppingListItemWrapper(
                    item: item,
                    controller: controller,
                    onEdit: () => onEditItem(item),
                  );
                },
                childCount: entry.value.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      );
    }

    // 2. Manual Sort Mode (Flat list, drag enabled)
    // Only if NOT showing categories
    if (controller.itemsController.sortMode == ItemSortMode.manual && !controller.showCategories) {
      if (list.isShared) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 140,
            left: 14,
            right: 14,
            top: 8,
          ),
          child: CollaborativeReorderableList(
            listId: list.id,
            items: items,
            onItemTap: (item) {
              if (controller.itemsController.selectionMode) {
                controller.itemsController.toggleSelection(item.id);
              } else {
                onEditItem(item);
              }
            },
            onItemToggle: (item, next) {
              if (list.status != ListStatus.archived) controller.toggleItem(item);
            },
          ),
        );
      }
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 140, left: 14, right: 14, top: 8),
        itemCount: items.length,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) async {
          controller.itemsController.reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          final child = ShoppingListItemWrapper(
            item: item,
            controller: controller,
            allowDrag: true,
            index: index,
            onEdit: () => onEditItem(item),
          );
          return KeyedSubtree(key: ValueKey(item.id), child: child);
        },
      );
    }

    // 3. Category/Grouped View (Default)
    final grouped = controller.showCategories
        ? controller.itemsController.groupedByCategory(items)
        : {'all': items};
    final sections = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return CustomScrollView(
      slivers: [
        for (final section in sections) ...[
          if (controller.showCategories && section.key != 'all')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                child: Text(
                  section.key.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryAccentColor.withValues(alpha: .8),
                  ),
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = section.value[index];
                return ShoppingListItemWrapper(
                  item: item,
                  controller: controller,
                  onEdit: () => onEditItem(item),
                );
              },
              childCount: section.value.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  String _prettyStore(String key) {
    switch (key.toLowerCase()) {
      case 'keells':
        return 'Keells';
      case 'cargills':
        return 'Cargills';
      case 'unknown':
        return 'Other Stores';
      default:
        return key;
    }
  }
}
