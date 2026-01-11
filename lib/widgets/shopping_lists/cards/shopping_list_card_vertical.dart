import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/shopping_lists/list_item_preview_cache.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';

import 'shopping_list_card_helpers.dart';
import 'shopping_list_card_images.dart';
import 'shopping_list_card_members.dart';

class ShoppingListCardVertical extends StatefulWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final bool compact; // grid variant
  const ShoppingListCardVertical({
    super.key,
    required this.list,
    this.onTap,
    this.onDelete,
    this.onArchive,
    this.compact = false,
  });

  @override
  State<ShoppingListCardVertical> createState() =>
      _ShoppingListCardVerticalState();
}

class _ShoppingListCardVerticalState extends State<ShoppingListCardVertical> {
  // Fast hydration: do not subscribe to items here; use aggregated fields
  // from the ShoppingList model for instant paint.

  @override
  void initState() {
    super.initState();
    // Subscribe to real-time item updates for instant image refresh
    ListItemPreviewCache.instance.subscribeToList(widget.list.id);
  }

  @override
  void didUpdateWidget(covariant ShoppingListCardVertical oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list.id != widget.list.id) {
      ListItemPreviewCache.instance.unsubscribeFromList(oldWidget.list.id);
      ListItemPreviewCache.instance.subscribeToList(widget.list.id);
    }
  }

  @override
  void dispose() {
    ListItemPreviewCache.instance.unsubscribeFromList(widget.list.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    // Instant render from aggregated fields; no per-card streams.
    return _buildContent(context, list);
  }

  Widget _buildContent(BuildContext context, ShoppingList list) {
    final hex = list.colorTheme.replaceAll('#', '');
    final totalItems = list.totalItems;
    final completedItems = list.completedItems;
    final estimatedTotal = list.estimatedTotal;
    final percent = totalItems == 0 ? 0.0 : completedItems / totalItems;

    return InkWell(
      onTap: widget.onTap,
      onLongPress: () => _showListOptions(context),
      child: Container(
        padding: EdgeInsets.all(widget.compact ? 18 : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F2128), Color(0xFF191B21)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: HexColor.fromHex(hex).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: HexColor.fromHex(hex).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip with item images preview
            Container(
              width: double.infinity,
              height: widget.compact ? 74 : 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HexColor.fromHex(hex).withValues(alpha: .16),
                    HexColor.fromHex(hex).withValues(alpha: .07),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Item images preview - shown bottom left
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: buildStackedItemImages(
                      list.id,
                      maxVisible: widget.compact ? 3 : 4,
                      size: widget.compact ? 32 : 38,
                      overlap: widget.compact ? 8 : 10,
                      accentColor: HexColor.fromHex(hex),
                    ),
                  ),
                  // Icon in center-right area
                  Positioned(
                    right: widget.compact ? 12 : 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: widget.compact ? 44 : 50,
                        height: widget.compact ? 44 : 50,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              HexColor.fromHex(hex),
                              HexColor.fromHex(hex).withValues(alpha: .75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: HexColor.fromHex(hex).withValues(alpha: .32),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          getIconFromId(list.iconId),
                          color: Colors.white,
                          size: widget.compact ? 22 : 26,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(list: list, hex: hex),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(widget.compact ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: widget.compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                      ),
                    ),
                    if (!widget.compact && list.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        list.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          color: HexColor.fromHex('9CA3AF'),
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                    SizedBox(height: widget.compact ? 6 : 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: percent.clamp(0, 1)),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (c, v, _) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 2.5,
                              backgroundColor: HexColor.fromHex('2C2F38'),
                              valueColor: AlwaysStoppedAnimation(
                                HexColor.fromHex(hex),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Item count text
                              Text(
                                '$totalItems items',
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontSize: widget.compact ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (list.budgetLimit > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: buildBudgetChip(
                                      estimate: estimatedTotal,
                                      budget: list.budgetLimit,
                                      accent: HexColor.fromHex(hex),
                                      compact: widget.compact,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.compact ? 4 : 6),
                    Row(
                      children: [
                        if (list.memberIds.isNotEmpty ||
                            list.createdBy.isNotEmpty) ...[
                          Expanded(
                            child: buildMemberAvatars(
                              list,
                              maxVisible: widget.compact ? 3 : 4,
                              compact: widget.compact,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (list.status != ListStatus.archived)
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CompleteToggleButton(
                              list: list,
                              compact: widget.compact,
                            ),
                          ),
                        Text(
                          timeAgo(list.lastActivity),
                          style: GoogleFonts.lato(
                            color: HexColor.fromHex('3C3E49'),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListOptions(BuildContext context) {
    final list = widget.list;
    showAppBottomSheet(
      LiquidGlass(
        enableBlur: true,
        blurSigmaX: 10,
        blurSigmaY: 16,
        borderRadius: 18,
        padding: const EdgeInsets.all(20),
        gradientColors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.03),
        ],
        borderColor: Colors.white.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              list.name,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (list.status != ListStatus.archived)
              ListTile(
                leading: const Icon(
                  Icons.archive_outlined,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Archive List',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onArchive?.call();
                },
              ),
            if (list.status == ListStatus.archived)
              ListTile(
                leading: const Icon(
                  Icons.unarchive_outlined,
                  color: Colors.green,
                ),
                title: const Text(
                  'Unarchive List',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onArchive?.call();
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete List',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete?.call();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: false,
      maxHeightFactor: 0.5,
    );
  }
}
