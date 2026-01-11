import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/shopping_lists/shopping_list_item_model.dart';

class MentionableItemsList extends StatelessWidget {
  final List<ShoppingListItem> items;
  final Function(ShoppingListItem) onItemSelected;
  final String searchQuery;

  const MentionableItemsList({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? items
        : items
              .where(
                (item) =>
                    item.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          searchQuery.isEmpty
              ? 'No items in this list'
              : 'No items match "$searchQuery"',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2E36),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white54,
                size: 16,
              ),
            ),
            title: Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: item.notes.isNotEmpty
                ? Text(
                    item.notes,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: item.isCompleted
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 16,
                  )
                : null,
            onTap: () => onItemSelected(item),
          );
        },
      ),
    );
  }
}
