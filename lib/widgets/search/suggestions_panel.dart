import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class SuggestionsPanel extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTapSuggestion;
  // Compact mode removes outer container and extra spacing for overlay dropdown use
  final bool compact;
  // Limit items rendered (defaults to all provided)
  final int? maxItems;
  // Optional clear actions
  final VoidCallback? onClearRecentSearches;
  final VoidCallback? onClearRecentlyViewed;

  const SuggestionsPanel({
    super.key,
    required this.suggestions,
    required this.onTapSuggestion,
    this.compact = false,
    this.maxItems,
    this.onClearRecentSearches,
    this.onClearRecentlyViewed,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final items = maxItems == null
        ? suggestions
        : suggestions.take(maxItems!).toList();

    // Compact list only: no container, minimal spacing
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClearRecentSearches != null || onClearRecentlyViewed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (onClearRecentSearches != null)
                    TextButton.icon(
                      onPressed: onClearRecentSearches,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        foregroundColor: AppColors.primaryAccentColor,
                      ),
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text(
                        'Clear searches',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  const Spacer(),
                  if (onClearRecentlyViewed != null)
                    TextButton.icon(
                      onPressed: onClearRecentlyViewed,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        foregroundColor: AppColors.primaryAccentColor,
                      ),
                      icon: const Icon(
                        Icons.history_toggle_off_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Clear viewed',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ...List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Divider(
                height: 1,
                color: AppColors.primaryText.withValues(alpha: 0.06),
              );
            }
            final index = i ~/ 2;
            final s = items[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 6),
                  child: child,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                dense: true,
                minLeadingWidth: 20,
                horizontalTitleGap: 8,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
                leading: Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryAccentColor,
                  size: 18,
                ),
                title: Text(
                  s,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primaryText,
                  ),
                ),
                onTap: () => onTapSuggestion(s),
              ),
            );
          }),
        ],
      );
    }

    // Default (non-compact) with container
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryText.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClearRecentSearches != null ||
                  onClearRecentlyViewed != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 6,
                    bottom: 2,
                  ),
                  child: Row(
                    children: [
                      if (onClearRecentSearches != null)
                        TextButton.icon(
                          onPressed: onClearRecentSearches,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            foregroundColor: AppColors.primaryAccentColor,
                          ),
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text(
                            'Clear recent',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      const Spacer(),
                      if (onClearRecentlyViewed != null)
                        TextButton.icon(
                          onPressed: onClearRecentlyViewed,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            foregroundColor: AppColors.primaryAccentColor,
                          ),
                          icon: const Icon(
                            Icons.history_toggle_off_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Clear viewed',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.primaryText.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final s = items[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 8),
                          child: child,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.search,
                          color: AppColors.primaryAccentColor,
                          size: 18,
                        ),
                        title: Text(
                          s,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.primaryText,
                          ),
                        ),
                        onTap: () => onTapSuggestion(s),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
