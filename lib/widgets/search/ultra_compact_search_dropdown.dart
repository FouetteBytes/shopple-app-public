import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';

/// 🔍 Ultra-compact search dropdown - minimal design, maximum usability
class UltraCompactSearchDropdown extends StatelessWidget {
  final List<String> recentSearches;
  final List<String> suggestions;
  final Function(String) onItemTap;
  final bool showRecent;

  const UltraCompactSearchDropdown({
    super.key,
    required this.recentSearches,
    required this.suggestions,
    required this.onItemTap,
    this.showRecent = true,
  });

  @override
  Widget build(BuildContext context) {
    // Show up to 6 suggestions then any provided recent subset
    final allItems = <_SearchItem>[];
    if (suggestions.isNotEmpty) {
      allItems.addAll(
        suggestions
            .take(6)
            .map((s) => _SearchItem(text: s, type: _SearchItemType.suggestion)),
      );
    }
    if (showRecent && recentSearches.isNotEmpty) {
      allItems.addAll(
        recentSearches.map(
          (r) => _SearchItem(text: r, type: _SearchItemType.recent),
        ),
      );
    }
    if (allItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(maxHeight: 320), // up to 10 items
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildUltraCompactItem(
                  item: item,
                  showDivider: index < allItems.length - 1,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUltraCompactItem({
    required _SearchItem item,
    required bool showDivider,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onItemTap(item.text),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 32, // Ultra-compact height
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  item.type == _SearchItemType.suggestion
                      ? Icons.search_rounded
                      : Icons.history_rounded,
                  size: 12,
                  color: item.type == _SearchItemType.suggestion
                      ? AppColors.primaryAccentColor.withValues(alpha: 0.7)
                      : AppColors.primaryText.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.inter(
                      color: AppColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (item.type == _SearchItemType.recent) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.north_west_rounded,
                    size: 9,
                    color: AppColors.primaryText.withValues(alpha: 0.25),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 30),
            color: AppColors.primaryText.withValues(alpha: 0.04),
          ),
      ],
    );
  }
}

enum _SearchItemType { suggestion, recent }

class _SearchItem {
  final String text;
  final _SearchItemType type;

  _SearchItem({required this.text, required this.type});
}

/// 🎯 Ultra-compact search overlay controller
class UltraCompactSearchOverlayController {
  OverlayEntry? _entry;
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void show({
    required BuildContext context,
    required LayerLink link,
    required Widget child,
    Offset offset = const Offset(0, 44), // Ultra-compact spacing
  }) {
    hide(); // Remove any existing overlay

    _entry = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            child: child,
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_entry!);
    _isVisible = true;
  }

  void hide() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
      _isVisible = false;
    }
  }

  void dispose() {
    hide();
  }
}
