import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';
import 'package:shopple/services/shopping_lists/list_item_preview_cache.dart';
import 'package:shopple/widgets/common/date_range_picker.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';

import 'shopping_list_card_helpers.dart';
import 'shopping_list_card_images.dart';
import 'shopping_list_card_members.dart';

class ShoppingListCardHorizontal extends StatefulWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  const ShoppingListCardHorizontal({
    super.key,
    required this.list,
    this.onTap,
    this.onDelete,
    this.onArchive,
  });
  @override
  State<ShoppingListCardHorizontal> createState() =>
      _ShoppingListCardHorizontalState();
}

class _ShoppingListCardHorizontalState
    extends State<ShoppingListCardHorizontal> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _pendingStart;
  DateTime? _pendingEnd;
  Timer? _debounceTimer;
  bool _saving = false;
  // Fast hydration: avoid item stream here; use aggregated fields from list

  @override
  void initState() {
    super.initState();
    // hydrate from model so persisted dates show immediately
    _startDate = widget.list.startDate;
    _endDate = widget.list.endDate;
    // Subscribe to real-time item updates for instant image refresh
    ListItemPreviewCache.instance.subscribeToList(widget.list.id);
  }

  @override
  void didUpdateWidget(covariant ShoppingListCardHorizontal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list.id != widget.list.id) {
      // Reset per-list cached state to avoid showing previous list's data when a new list
      // occupies the recycled element (ListView re-use).
      _debounceTimer?.cancel();
      _pendingStart = null;
      _pendingEnd = null;
      _saving = false;
      // Update item preview subscription
      ListItemPreviewCache.instance.unsubscribeFromList(oldWidget.list.id);
      ListItemPreviewCache.instance.subscribeToList(widget.list.id);
      _startDate = widget.list.startDate;
      _endDate = widget.list.endDate;
      if (mounted) setState(() {}); // ensure rebuild with fresh values
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    ListItemPreviewCache.instance.unsubscribeFromList(widget.list.id);
    super.dispose();
  }

  String _getDatePeriod() {
    // Prefer any in-flight edits, else persisted widget.list values, else cached locals
    final startEffective = _pendingStart ?? _startDate ?? widget.list.startDate;
    final endEffective = _pendingEnd ?? _endDate ?? widget.list.endDate;
    if (startEffective == null) return 'Set dates';
    final startStr = _formatShortDate(startEffective);
    if (endEffective == null) return startStr;
    return '$startStr - ${_formatShortDate(endEffective)}';
  }

  String _formatShortDate(DateTime d) => '${d.day} ${_getMonthAbbr(d.month)}';

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return _buildHorizontalContent(context, list);
  }

  Widget _buildHorizontalContent(BuildContext context, ShoppingList list) {
    final hex = list.colorTheme.replaceAll('#', '');
    // Use TextScaler instead of deprecated textScaleFactor; derive an approximate
    // scale factor from a representative base size and clamp to preserve UX.
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = (textScaler.scale(16.0) / 16.0).clamp(0.85, 1.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: () => _showListOptions(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HexColor.fromHex("1F2128"),
                  HexColor.fromHex("191B21"),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final isNarrow = cardWidth < 380;
                // Increased header height to prevent overlap between tag and images
                final headerHeight = isNarrow ? 90.0 : 100.0;
                final totalItems = list.totalItems;
                final completedItems = list.completedItems;
                final progress = totalItems == 0
                    ? 0.0
                    : completedItems / totalItems;
                final estimate = list.estimatedTotal;

                return Stack(
                  children: [
                    // Faded background icon
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Icon(
                          getIconFromId(list.iconId),
                          size: 140,
                          color: HexColor.fromHex(hex).withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full-width colored header strip with hero icon
                        Container(
                          height: headerHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                HexColor.fromHex(hex).withValues(alpha: .85),
                                HexColor.fromHex(hex),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HexColor.fromHex(hex).withValues(alpha: .45),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // subtle pattern / radial glow overlay
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.1,
                                      colors: [
                                        Colors.white.withValues(alpha: .12),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Item images preview - left side
                              Positioned(
                                left: 12,
                                bottom: 12, // Slightly higher
                                child: buildStackedItemImages(
                                  list.id,
                                  maxVisible: isNarrow ? 3 : 4,
                                  size: isNarrow ? 36 : 44, // Larger images
                                  overlap: 14,
                                  accentColor: Colors.white,
                                ),
                              ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: isNarrow ? 12 : 16),
                              child: Container(
                                width: isNarrow ? 40 : 46,
                                height: isNarrow ? 40 : 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .25),
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  getIconFromId(list.iconId),
                                  size: isNarrow ? 20 : 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 8,
                            child: StatusBadge(list: list, hex: hex),
                          ),
                          Positioned(
                            top: 4,
                            right: 6,
                            child: InkWell(
                              onTap: () => _openUnifiedDatePicker(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .25),
                                    width: .8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 130,
                                      ),
                                      child: Text(
                                        _getDatePeriod(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.lato(
                                          color: Colors.white,
                                          fontSize: 11 * textScale,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _maybeSavingSpinner(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 10 : 12,
                        6,
                        isNarrow ? 10 : 12,
                        8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Single row: progress circle + name/description/budget inline
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: isNarrow ? 42 : 46,
                                height: isNarrow ? 42 : 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HexColor.fromHex('2C2F38'),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress.clamp(0, 1),
                                      strokeWidth: 4,
                                      backgroundColor: Colors.black26,
                                      valueColor: AlwaysStoppedAnimation(
                                        HexColor.fromHex(hex),
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      list.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize:
                                            (isNarrow ? 15 : 17) * textScale,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (list.description.isNotEmpty)
                                      Text(
                                        list.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.lato(
                                          color: HexColor.fromHex('9CA3AF'),
                                          fontSize:
                                              (isNarrow ? 11 : 12) * textScale,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          // Smooth transition when item counts change
                                          child: Text(
                                            '$completedItems of $totalItems items',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.lato(
                                              color: Colors.white,
                                              fontSize: 10.5 * textScale,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (list.budgetLimit > 0)
                                          buildBudgetChip(
                                            estimate: estimate,
                                            budget: list.budgetLimit,
                                            accent: HexColor.fromHex(hex),
                                            compact: isNarrow,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (list.memberIds.isNotEmpty ||
                              list.createdBy.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: buildMemberAvatars(
                                    list,
                                    maxVisible: isNarrow ? 3 : 5,
                                  ),
                                ),
                                if (list.status != ListStatus.archived)
                                  CompleteToggleButton(
                                    list: list,
                                    compact: false,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  ),
);
}

  void _openUnifiedDatePicker() {
    final themeColor = HexColor.fromHex(
      widget.list.colorTheme.replaceAll('#', ''),
    );
    showModernDateRangePickerSheet(
      context,
      themeColor: themeColor,
      initialStart: _startDate,
      initialEnd: _endDate,
    ).then((res) {
      if (res == null) return;
      setState(() {
        _startDate = res.start;
        _endDate = res.end;
        _pendingStart = res.start;
        _pendingEnd = res.end;
      });
      _scheduleDebouncedPersist();
    });
  }

  void _scheduleDebouncedPersist() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _saving = true);
      await ShoppingListService.updateShoppingList(
        listId: widget.list.id,
        startDate: _pendingStart,
        endDate: _pendingEnd,
      );
      if (mounted) setState(() => _saving = false);
    });
  }

  void _showListOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LiquidGlass(
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
              widget.list.name,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.list.status != ListStatus.archived)
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
            if (widget.list.status == ListStatus.archived)
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
    );
  }

  // Add spinner indicator in date badge when saving
  Widget _maybeSavingSpinner() {
    if (!_saving) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white70),
        ),
      ),
    );
  }
}
