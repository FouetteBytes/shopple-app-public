import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class RecentSearchesPanel extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;
  final VoidCallback? onClear;
  // Compact mode removes outer container/header for overlay dropdown
  final bool compact;
  // Limit number of items rendered
  final int? maxItems;
  const RecentSearchesPanel({
    super.key,
    required this.items,
    required this.onTap,
    this.onClear,
    this.compact = false,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = maxItems == null ? items : items.take(maxItems!).toList();

    if (compact) {
      // Minimal list without header/container
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(visible.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(
              height: 1,
              color: AppColors.primaryText.withValues(alpha: 0.06),
            );
          }
          final index = i ~/ 2;
          final q = visible[index];
          return ListTile(
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
              q,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.primaryText,
              ),
            ),
            onTap: () => onTap(q),
          );
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.primaryText70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recent searches',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText70,
                        ),
                      ),
                    ),
                    if (onClear != null)
                      TextButton(
                        onPressed: onClear,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryText70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Hide'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.primaryText.withValues(alpha: 0.06),
                ),
                itemBuilder: (context, index) {
                  final q = visible[index];
                  return ListTile(
                    leading: Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryAccentColor,
                      size: 18,
                    ),
                    title: Text(
                      q,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primaryText,
                      ),
                    ),
                    onTap: () => onTap(q),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
