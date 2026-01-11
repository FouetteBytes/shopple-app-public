import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/search/product_search_controller.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/search/category_quick_grid.dart';
import 'package:shopple/widgets/search/quick_filters_row.dart';

class AnimatedCategoriesHeader extends StatelessWidget {
  final ProductSearchController controller;
  final double shrinkOffset;
  final Animation<double> collapseAnimation;

  const AnimatedCategoriesHeader({
    super.key,
    required this.controller,
    required this.shrinkOffset,
    required this.collapseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    double t = controller.forceCollapsed ? 1.0 : 0.0;
    final ids = CategoryService.getCategoriesForUI(
      includeAll: false,
    ).map((m) => m['id']!).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double range = (constraints.maxHeight - 72);
        final double safeRange = range <= 0 ? 1 : range;
        final double tBase = (shrinkOffset / safeRange).clamp(0.0, 1.0);
        t = controller.forceCollapsed ? 1.0 : tBase;
        
        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRect(
            child: Stack(
              alignment: Alignment.topLeft,
              children: <Widget>[
                // Expanded grid + inline quick filters
                Builder(
                  builder: (context) {
                    final animT = collapseAnimation.value;
                    final combined = t > animT ? t : animT;
                    final combinedClamped = combined.clamp(0.0, 1.0);
                    final eased = Curves.easeInOut.transform(combinedClamped);
                    final inv = 1 - eased;
                    
                    return Opacity(
                      opacity: inv,
                      child: Transform.translate(
                        offset: Offset(0, eased * -12),
                        child: Transform.scale(
                          scale: 1 - (eased * 0.04),
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CategoryQuickGrid(
                                  selectedId: controller.selectedProductType,
                                  onSelect: (id) async {
                                    controller.selectedProductType = id;
                                    controller.searchController.clear();
                                    controller.suggestions.clear();
                                    await controller.loadCategoryProducts(id);
                                  },
                                  maxCount: 12,
                                ),
                                const SizedBox(height: 8),
                                _buildQuickFiltersRow(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Collapsed horizontal bar
                Align(
                  alignment: Alignment.topLeft,
                  child: Opacity(
                    opacity: Curves.easeInOut.transform(
                      (t > collapseAnimation.value ? t : collapseAnimation.value)
                          .clamp(0.0, 1.0),
                    ),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (controller.activeUnitFilter != null)
                              _collapsedActiveFilterChip(
                                'Unit: ${controller.activeUnitFilter!}',
                                () => controller.setUnitFilter(null),
                              ),
                            if (controller.activeBrandFilter != null)
                              _collapsedActiveFilterChip(
                                controller.activeBrandFilter!,
                                () => controller.setBrandFilter(null),
                              ),
                            if (controller.hasActiveQuickFilter)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: InkWell(
                                  onTap: controller.clearQuickFilters,
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: AppColors.primaryText.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ...ids.asMap().entries.map((entry) {
                              final id = entry.value;
                              final name = CategoryService.getDisplayName(id);
                              final emoji = CategoryService.getCategoryIcon(id);
                              final selected = controller.selectedProductType == id;
                              final delay = (entry.key * 30).clamp(0, 180);
                              
                              return AnimatedOpacity(
                                opacity: 1,
                                duration: Duration(milliseconds: 300 + delay),
                                curve: Curves.easeOut,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      controller.selectedProductType = id;
                                      controller.searchController.clear();
                                      controller.suggestions.clear();
                                      await controller.loadCategoryProducts(id);
                                    },
                                    style: ButtonStyle(
                                      elevation: WidgetStateProperty.all<double>(0),
                                      padding: WidgetStateProperty.all<EdgeInsets>(
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                        if (selected) return AppColors.primaryGreen;
                                        if (states.contains(WidgetState.pressed)) {
                                          return AppColors.primaryGreen.withValues(alpha: .85);
                                        }
                                        return AppColors.surface;
                                      }),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                          side: BorderSide(
                                            color: selected ? AppColors.primaryGreen : AppColors.surface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$emoji  $name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickFiltersRow() {
    final source = controller.baseResults.isNotEmpty ? controller.baseResults : controller.searchResults;
    return QuickFiltersRow(
      source: source,
      hasActiveFilter: controller.hasActiveQuickFilter,
      activeUnit: controller.activeUnitFilter,
      activeBrand: controller.activeBrandFilter,
      onClear: controller.clearQuickFilters,
      onFilterUnit: controller.setUnitFilter,
      onFilterBrand: controller.setBrandFilter,
    );
  }

  Widget _collapsedActiveFilterChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.primaryGreen),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
