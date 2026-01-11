import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../values/values.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/product/product_image_cache.dart';

class ShoppingListItemWidget extends StatelessWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ShoppingListItemWidget({
    super.key,
    required this.item,
    required this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.isCompleted
        ? Colors.green
        : AppColors.primaryAccentColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.primaryText.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 2),
                  color: item.isCompleted ? color : Colors.transparent,
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Product thumbnail (if product-backed)
            if (item.productId != null) ...[
              FutureBuilder<String?>(
                future: ProductImageCache.instance.getImageUrl(item.productId!),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _thumbSkeleton();
                  }
                  final url = snap.data;
                  if (url == null || url.isEmpty) {
                    return _fallbackThumb();
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackThumb(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
            ],
            // Main text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: item.isCompleted
                                ? Colors.green.shade200
                                : Colors.white,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (item.totalPrice > 0)
                        Text(
                          'Rs ${(item.totalPrice).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip('${item.quantity} ${item.unit}'),
                      if (item.category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _chip(item.category),
                      ],
                      if (item.isFromProduct) ...[
                        const SizedBox(width: 6),
                        _chip('product'),
                      ],
                    ],
                  ),
                  if (item.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.redAccent,
                onPressed: onDelete,
                tooltip: 'Delete item',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

Widget _thumbSkeleton() => Container(
  width: 42,
  height: 42,
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(10),
  ),
  alignment: Alignment.center,
  child: const SizedBox(
    width: 14,
    height: 14,
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
);

Widget _fallbackThumb() => Container(
  width: 42,
  height: 42,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Color(0xFF444752), Color(0xFF2B2E36)],
    ),
    borderRadius: BorderRadius.circular(10),
  ),
  alignment: Alignment.center,
  child: const Icon(
    Icons.shopping_bag_outlined,
    color: Colors.white54,
    size: 20,
  ),
);
