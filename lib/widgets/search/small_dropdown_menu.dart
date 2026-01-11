import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

class SmallDropdownMenu extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;
  final IconData leadingIcon;
  final double rowHeight;

  const SmallDropdownMenu({
    super.key,
    required this.items,
    required this.onTap,
    this.leadingIcon = Icons.search_rounded,
    this.rowHeight = 56, // Increased for better touch targets
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Determine header text based on icon type
    String headerText = 'Recent searches';
    if (leadingIcon == Icons.search_rounded) {
      headerText = 'Search suggestions';
    } else if (leadingIcon == Icons.trending_up_rounded) {
      headerText = 'Popular searches';
    } else if (leadingIcon == Icons.history_rounded) {
      headerText = 'Recent searches';
    }

    final hasItems = items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 12 to 8
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasItems) ...[
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                6,
                20,
                8,
              ), // Reduced vertical padding
              child: Text(
                headerText,
                style: GoogleFonts.poppins(
                  color: AppColors.primaryText70,
                  fontSize: 13, // Slightly smaller font
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Search items - only show the actual items without extra spacing
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _ModernDropdownRow(
                text: item,
                icon: leadingIcon,
                height: 42, // Further reduced height
                onTap: () => onTap(item),
                isLast: index == items.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ModernDropdownRow extends StatelessWidget {
  final String text;
  final IconData icon;
  final double height;
  final VoidCallback onTap;
  final bool isLast;

  const _ModernDropdownRow({
    required this.text,
    required this.icon,
    required this.height,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primaryAccentColor.withValues(alpha: 0.1),
        highlightColor: AppColors.primaryAccentColor.withValues(alpha: 0.05),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primaryAccentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: AppColors.primaryText.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
