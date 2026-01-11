import 'package:flutter/material.dart';
import 'package:shopple/controllers/search/product_search_controller.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/search/ultra_compact_search_dropdown.dart';

class SearchSuggestionsView extends StatelessWidget {
  final ProductSearchController controller;

  const SearchSuggestionsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: controller.showRecentSearches ? null : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: controller.showRecentSearches ? 1.0 : 0.0,
        child: controller.showRecentSearches
            ? Container(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    UltraCompactSearchDropdown(
                      recentSearches: controller.recentSearches,
                      suggestions: controller.suggestions,
                      showRecent: controller.searchController.text.trim().isEmpty ||
                          controller.matchingRecent.isNotEmpty,
                      onItemTap: (query) {
                        controller.searchController.text = query;
                        controller.showRecentSearches = false;
                        FocusScope.of(context).unfocus();
                        controller.performIntelligentSearch(query);
                      },
                    ),
                    if (controller.searchController.text.trim().isEmpty &&
                        controller.allRecentSearches.length > 4)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.toggleShowAllRecent,
                          child: Text(
                            controller.showAllRecent
                                ? 'Show less'
                                : 'Show all history (${controller.allRecentSearches.length})',
                          ),
                        ),
                      ),
                    if (controller.allRecentSearches.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: controller.clearHistory,
                          icon: const Icon(
                            Icons.clear_all_rounded,
                            size: 16,
                          ),
                          label: const Text('Clear history'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryText70,
                            padding: const EdgeInsets.only(top: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
