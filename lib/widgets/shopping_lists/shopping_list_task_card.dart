// Unified (non-legacy) ShoppingListTaskCard implementation
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/product/product_image_cache.dart';
// Controller not directly used; cheapest data passed in via props to avoid tight coupling.
import '../../values/values.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';

class ShoppingListTaskCard extends StatefulWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  // Cheapest pricing intelligence (optional)
  final double? cheapestUnitPrice; // price per unit from external intelligence
  final String? cheapestStore; // store identifier/name
  const ShoppingListTaskCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.cheapestUnitPrice,
    this.cheapestStore,
  });
  @override
  State<ShoppingListTaskCard> createState() => _ShoppingListTaskCardState();
}

class _ShoppingListTaskCardState extends State<ShoppingListTaskCard> {
  bool _active = true;
  Future<String?>? _imageFuture;
  String _shortStore(String store) {
    if (store.isEmpty) return 'store';
    // Simple abbreviation logic (take first word, max 8 chars)
    final parts = store.split(RegExp(r'[ _-]+'));
    var s = parts.first;
    if (s.length > 8) s = s.substring(0, 8);
    return s;
  }

  Widget _placeholderBox() {
    return Container(
      color: HexColor.fromHex('2B2E36'),
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryAccentColor.withValues(alpha: .6),
        ),
      ),
    );
  }

  Widget _fallbackBox() {
    return Container(
      color: HexColor.fromHex('3A3E48'),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white38),
    );
  }

  @override
  void initState() {
    super.initState();
    _active = !widget.item.isCompleted;
    _maybeInitImage();
  }

  @override
  void didUpdateWidget(covariant ShoppingListTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.productId != widget.item.productId) {
      _maybeInitImage(force: true);
    }
    if (oldWidget.item.isCompleted != widget.item.isCompleted) {
      _active = !widget.item.isCompleted;
    }
  }

  void _maybeInitImage({bool force = false}) {
    if (!widget.item.isFromProduct) return;
    if (_imageFuture != null && !force) return;
    final pid = widget.item.productId;
    if (pid != null && pid.isNotEmpty) {
      _imageFuture = ProductImageCache.instance.getImageUrl(pid);
    }
  }

  void _flipVisual() => setState(() => _active = !_active);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.selectionMode) {
          widget.onSelectToggle?.call();
        } else {
          widget.onEdit();
        }
      },
      onLongPress: () {
        if (widget.selectionMode) {
          widget.onSelectToggle?.call();
        } else {
          _flipVisual();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _active
              ? AppColors.primaryBackgroundColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _active
              ? null
              : Border.all(color: AppColors.primaryBackgroundColor, width: 3),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = constraints.maxWidth;
            final bool compact = maxW < 380; // first breakpoint
            final bool ultraCompact = maxW < 330; // stack trailing metrics
            final double imgSize = ultraCompact ? 48 : (compact ? 56 : 70);
            final double iconSpacing = compact ? 12 : 16;
            final TextStyle qtyStyle = GoogleFonts.lato(
              fontSize: ultraCompact ? 14 : (compact ? 18 : 20),
              fontWeight: FontWeight.bold,
              color: widget.item.isCompleted
                  ? AppColors.accentGreen.withValues(alpha: 0.7)
                  : HexColor.fromHex('EA9EEE'),
              decoration: widget.item.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: AppColors.accentGreen.withValues(alpha: 0.8),
            );
            Widget buildImageBox() {
              Widget imageContent;
              if (widget.item.isFromProduct) {
                imageContent = Container(
                  width: imgSize,
                  height: imgSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.item.isCompleted
                          ? AppColors.accentGreen.withValues(alpha: 0.3)
                          : AppColors.primaryText.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _imageFuture == null
                        ? _placeholderBox()
                        : FutureBuilder<String?>(
                            future: _imageFuture,
                            builder: (c, s) {
                              if (s.connectionState ==
                                  ConnectionState.waiting) {
                                return _placeholderBox();
                              }
                              final url = s.data;
                              if (url == null || url.isEmpty) {
                                return _fallbackBox();
                              }
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Underlay placeholder to keep layout stable
                                  Container(color: Colors.black12),
                                  // Fade-in image to minimize jank; ensure it's below overlays
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Image.network(
                                      url,
                                      key: ValueKey(url),
                                      fit: BoxFit.cover,
                                      width: imgSize,
                                      height: imgSize,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                  // Tick overlay always on top
                                  if (widget.item.isCompleted)
                                    IgnorePointer(
                                      ignoring: true,
                                      child: Container(
                                        color: AppColors.accentGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                );
              } else {
                imageContent = Container(
                  width: imgSize,
                  height: imgSize,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex('3A3E48'),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.item.isCompleted
                          ? AppColors.accentGreen.withValues(alpha: 0.3)
                          : AppColors.primaryText.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          color: Colors.white38,
                          size: compact ? 22 : 28,
                        ),
                      ),
                      if (widget.item.isCompleted)
                        IgnorePointer(
                          ignoring: true,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return SizedBox(width: imgSize + 5, child: imageContent);
            }

            Widget quantityBox() => Container(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 6 : 8,
                horizontal: compact ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: widget.item.isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.1)
                    : HexColor.fromHex('2B2E36'),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.item.isCompleted
                      ? AppColors.accentGreen.withValues(alpha: 0.3)
                      : HexColor.fromHex('3A3E48'),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: qtyStyle,
                    child: FittedBox(child: Text('${widget.item.quantity}')),
                  ),
                  SizedBox(height: compact ? 1 : 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.lato(
                      fontSize: ultraCompact ? 9 : 11,
                      fontWeight: FontWeight.w500,
                      color: widget.item.isCompleted
                          ? Colors.white38
                          : HexColor.fromHex('626677'),
                      decoration: widget.item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.accentGreen.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    child: Text(widget.item.unit.toUpperCase()),
                  ),
                ],
              ),
            );
            Widget priceBox() => Container(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 6 : 8,
                horizontal: compact ? 6 : 12,
              ),
              decoration: BoxDecoration(
                color: widget.item.isCompleted
                    ? AppColors.accentGreen.withValues(alpha: 0.1)
                    : HexColor.fromHex('2B2E36'),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.item.isCompleted
                      ? AppColors.accentGreen.withValues(alpha: 0.3)
                      : HexColor.fromHex('3A3E48'),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.totalPrice > 0) ...[
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.lato(
                        fontSize: ultraCompact ? 12 : (compact ? 14 : 16),
                        fontWeight: FontWeight.bold,
                        color: widget.item.isCompleted
                            ? AppColors.accentGreen.withValues(alpha: 0.7)
                            : HexColor.fromHex('EA9EEE'),
                        decoration: widget.item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.accentGreen.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      child: FittedBox(
                        child: Text(
                          'Rs ${widget.item.totalPrice.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.lato(
                        fontSize: ultraCompact ? 8 : (compact ? 9 : 9),
                        fontWeight: FontWeight.w500,
                        color: widget.item.isCompleted
                            ? Colors.white38
                            : HexColor.fromHex('626677'),
                        decoration: widget.item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.accentGreen.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        child: Text(
                          '${widget.item.estimatedPrice.toStringAsFixed(0)}/UNIT',
                        ),
                      ),
                    ),
                  ] else ...[
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.lato(
                        fontSize: ultraCompact ? 11 : (compact ? 12 : 14),
                        fontWeight: FontWeight.w500,
                        color: widget.item.isCompleted
                            ? Colors.white38
                            : HexColor.fromHex('626677'),
                        decoration: widget.item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.accentGreen.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: const Text('NO PRICE'),
                    ),
                  ],
                ],
              ),
            );

            Widget trailingMenu() => PopupMenuButton<String>(
              color: HexColor.fromHex('262A34'),
              icon: Icon(
                Icons.more_horiz,
                color: widget.item.isCompleted ? Colors.white38 : Colors.white,
              ),
              onSelected: (val) {
                switch (val) {
                  case 'edit':
                    widget.onEdit();
                    break;
                  case 'toggle':
                    widget.onToggle();
                    break;
                  case 'delete':
                    widget.onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Item')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    widget.item.isCompleted ? 'Mark Active' : 'Mark Completed',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );

            Widget detailsColumn() => Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: GoogleFonts.lato(
                      fontSize: ultraCompact ? 14 : (compact ? 15 : 16),
                      fontWeight: FontWeight.w600,
                      color: widget.item.isCompleted
                          ? AppColors.accentGreen.withValues(alpha: 0.7)
                          : AppColors.primaryText,
                      decoration: widget.item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2.0,
                      decorationColor: AppColors.accentGreen.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  if (widget.item.category.isNotEmpty ||
                      widget.item.notes.isNotEmpty) ...[
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.lato(
                        fontSize: ultraCompact ? 10 : 12,
                        color: widget.item.isCompleted
                            ? HexColor.fromHex('626677').withValues(alpha: 0.5)
                            : HexColor.fromHex('626677'),
                        decoration: widget.item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.accentGreen.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: Text(
                        widget.item.category.isNotEmpty
                            ? widget.item.category
                            : widget.item.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                  ],
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (widget.item.isFromProduct)
                        _enhancedChip(
                          'Product',
                          'FECE91',
                          Icons.inventory_2_outlined,
                        ),
                      if (widget.item.isFromProduct &&
                          widget.cheapestStore != null)
                        _enhancedChip(
                          _shortStore(widget.cheapestStore!),
                          'FECE91',
                          Icons.store_outlined,
                        ),
                      if (widget.item.isFromProduct &&
                          widget.cheapestUnitPrice != null)
                        _enhancedChip(
                          'Best: Rs ${widget.cheapestUnitPrice!.toStringAsFixed(0)}',
                          '94F0F1',
                          Icons.local_offer_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            );

            List<Widget> rowChildren = [];
            if (widget.selectionMode) {
              rowChildren.add(
                GestureDetector(
                  onTap: widget.onSelectToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    margin: EdgeInsets.only(right: iconSpacing - 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? AppColors.accentGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: AppColors.accentGreen,
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }
            rowChildren.add(
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: compact ? 26 : 28,
                  height: compact ? 26 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.item.isCompleted
                        ? AppColors.accentGreen
                        : Colors.black,
                    border: Border.all(color: AppColors.accentGreen, width: 2),
                  ),
                  child: widget.item.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            );
            rowChildren.add(SizedBox(width: iconSpacing));
            rowChildren.add(buildImageBox());
            rowChildren.add(SizedBox(width: iconSpacing));
            rowChildren.add(detailsColumn());

            Widget metricsSection;
            if (ultraCompact) {
              // Stack quantity & price vertically to save width
              metricsSection = Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [quantityBox(), SizedBox(height: 6), priceBox()],
                ),
              );
            } else {
              metricsSection = Flexible(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: quantityBox()),
                    SizedBox(width: compact ? 10 : 16),
                    Flexible(child: priceBox()),
                  ],
                ),
              );
            }
            rowChildren.add(SizedBox(width: compact ? 10 : 16));
            rowChildren.add(metricsSection);
            rowChildren.add(SizedBox(width: compact ? 8 : 12));
            rowChildren.add(trailingMenu());

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: rowChildren,
            );
          },
        ),
      ),
    );
  }

  Widget _enhancedChip(String text, String hex, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: HexColor.fromHex(hex).withValues(alpha: .15),
      border: Border.all(
        color: HexColor.fromHex(hex).withValues(alpha: .3),
        width: 0.5,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: HexColor.fromHex(hex)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: HexColor.fromHex(hex),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
