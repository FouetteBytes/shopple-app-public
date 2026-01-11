import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/services/category_service.dart';

class CategoryQuickGrid extends StatelessWidget {
  final String selectedId;
  final void Function(String id) onSelect;
  // Optional override list; when empty, categories are sourced from CategoryService.
  final List<String> ids;
  // Limit how many categories to show when using CategoryService (default quick grid = 8)
  final int maxCount;

  const CategoryQuickGrid({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.ids = const [],
    this.maxCount = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Build the list of category IDs to show. Prefer explicit ids if provided, otherwise
    // pull from CategoryService (36 categories) and pick the first maxCount entries.
    final List<String> categoryIds = ids.isNotEmpty
        ? ids
        : CategoryService.getCategoriesForUI(
            includeAll: false,
          ).map((m) => m['id']!).take(maxCount).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryIds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85, // Slightly taller to accommodate text
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final id = categoryIds[index];
        final name = CategoryService.getDisplayName(id);
        final emoji = CategoryService.getCategoryIcon(id);
        final selected = selectedId == id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelect(id),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryAccentColor.withValues(alpha: 0.5)
                      : AppColors.primaryText.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
