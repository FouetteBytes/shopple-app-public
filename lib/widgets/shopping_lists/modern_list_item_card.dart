import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../values/values.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/product/product_image_cache.dart';

/// Modern card style inspired by marketplace mock (image left, details, price & qty action right)
class ModernListItemCard extends StatelessWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete; // optional; when using swipe-to-delete can omit
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool outOfStock;

  /// Optional unit price override (e.g. live fetched current price) if item's estimatedPrice is zero
  final double? overrideUnitPrice;

  /// Optional product size label (e.g. "1 L", "500 g") to show next to quantity
  final String? sizeLabel;
  final String? imageUrl; // preloaded image url for instant paint
  // Multi-select support
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  // When provided, the card will render a drag handle which parent can wrap with ReorderableDragStartListener.
  final bool showDragHandle;
  final Widget Function(Widget handle)?
  dragHandleBuilder; // parent may wrap with ReorderableDragStartListener
  const ModernListItemCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
    required this.onIncrement,
    required this.onDecrement,
    this.outOfStock = false,
    this.overrideUnitPrice,
    this.sizeLabel,
    this.imageUrl,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.showDragHandle = false,
    this.dragHandleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUnit = item.estimatedPrice > 0
        ? item.estimatedPrice
        : (overrideUnitPrice ?? 0);
    final total = effectiveUnit * item.quantity;
    final priceStr = total > 0 ? 'Rs ${total.toStringAsFixed(0)}' : '—';
    final unitPriceStr = effectiveUnit > 0
        ? 'Rs ${effectiveUnit.toStringAsFixed(0)}'
        : '';
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8), // Increased margin
          padding: const EdgeInsets.all(14), // Increased padding
          decoration: BoxDecoration(
            color: const Color(0xFF1E2026), // Slightly lighter dark
            borderRadius: BorderRadius.circular(20), // More rounded
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              _thumbnail(),
              const SizedBox(width: 16), // More spacing
              Expanded(child: _details(priceStr, unitPriceStr)),
              const SizedBox(width: 12),
              _qtyPriceBlock(priceStr, unitPriceStr),
              // Only show inline drag handle when no external drag wrapper is provided.
              if (showDragHandle && dragHandleBuilder == null) ...[
                const SizedBox(width: 8),
                _dragHandle(),
              ],
            ],
          ),
        ),
        // Selection overlay, delete button, or drag handle
        if (selectionMode)
          Positioned(
            top: 6,
            right: 8,
            child: GestureDetector(
              onTap: onSelectToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccentColor
                      : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryAccentColor
                        : Colors.white24,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          )
        else if (onDelete != null && !showDragHandle)
          Positioned(
            top: 2,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.redAccent,
                ),
              ),
            ),
          )
        else if (showDragHandle && dragHandleBuilder != null)
          Positioned(
            top: 4,
            right: 6,
            child:
                dragHandleBuilder?.call(
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: .3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ) ??
                const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _dragHandle() {
    // Green three-dot grip for better affordance
    final dot = Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
    final base = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: .25)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(height: 3),
          dot,
          const SizedBox(height: 3),
          dot,
        ],
      ),
    );
    if (dragHandleBuilder != null) {
      return dragHandleBuilder!(base);
    }
    return base;
  }

  Widget _thumbnail() {
    if (item.productId == null) {
      return _staticThumbFallback();
    }
    // If parent passed a preloaded image URL, paint immediately.
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: 64, // Larger thumbnail
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 128, // 2x for retina
            memCacheHeight: 128,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => _staticThumbFallback(),
            errorWidget: (_, __, ___) => _staticThumbFallback(),
          ),
        ),
      );
    }
    // Start fetch silently if not already present.
    if (ProductImageCache.instance.peek(item.productId!) == null) {
      // ignore: discarded_futures
      ProductImageCache.instance.getImageUrl(item.productId!);
    }
    final notifier = ProductImageCache.instance.notifierFor(item.productId!);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ValueListenableBuilder<String?>(
          valueListenable: notifier,
          builder: (context, url, _) {
            if (url == null || url.isEmpty) {
              return _loadingFadeContainer();
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 128,
              memCacheHeight: 128,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => _loadingFadeContainer(),
              errorWidget: (_, __, ___) => _staticThumbFallback(),
            );
          },
        ),
      ),
    );
  }

  Widget _loadingFadeContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(color: HexColor.fromHex('30323A')),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24),
    );
  }

  Widget _staticThumbFallback() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: HexColor.fromHex('30323A'),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white38),
    );
  }

  Widget _details(String priceStr, String unitPriceStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.name,
          maxLines: 2, // Allow 2 lines for better readability
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(
            fontSize: 16, // Slightly larger
            fontWeight: FontWeight.w700, // Bolder
            color: item.isCompleted ? Colors.white54 : Colors.white,
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (unitPriceStr.isNotEmpty)
              Text(
                unitPriceStr,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.isCompleted
                      ? AppColors.accentGreen.withValues(alpha: .7)
                      : AppColors.primaryAccentColor,
                ),
              ),
            if (unitPriceStr.isNotEmpty) const SizedBox(width: 6),
            Builder(
              builder: (_) {
                final sz = sizeLabel?.trim();
                if (sz != null && sz.isNotEmpty) {
                  return Text(
                    sz,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: item.isCompleted ? Colors.white38 : Colors.white70,
                    ),
                  );
                }
                return Text(
                  '${item.quantity} ${item.unit}'.trim(),
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: item.isCompleted ? Colors.white38 : Colors.white70,
                  ),
                );
              },
            ),
          ],
        ),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: item.isCompleted ? Colors.white24 : Colors.white38,
              decoration: item.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }

  Widget _qtyPriceBlock(String priceStr, String unitPriceStr) {
    if (outOfStock) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: HexColor.fromHex('393C46'),
            ),
            child: Text(
              'OUT OF STOCK',
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _notifyButton(),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          priceStr,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: item.isCompleted ? Colors.white54 : Colors.white,
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        _qtyStepper(),
      ],
    );
  }

  Widget _qtyStepper() {
    return Container(
      height: 36, // Slightly taller
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2A2C34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(Icons.remove, onDecrement, enabled: item.quantity > 1),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          _iconBtn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _notifyButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primaryAccentColor),
        foregroundColor: AppColors.primaryAccentColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
      ),
      onPressed: () {},
      child: Text(
        'NOTIFY',
        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Icon(
          icon, 
          size: 16, 
          color: enabled ? Colors.white : Colors.white24
        ),
      ),
    );
  }
}
