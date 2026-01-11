import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/services/shopping_lists/list_item_preview_cache.dart';

/// Modern stacked item images for shopping list cards.
/// Shows product images in a scrollable horizontal list with square frames.
/// Images are pre-cached for instant display without loading states.
/// Updates in real-time when items change.
Widget buildStackedItemImages(
  String listId, {
  int maxVisible = 5,
  double size = 44,
  double overlap = 14,
  Color? accentColor,
}) {
  return ValueListenableBuilder<List<ListItemPreview>>(
    valueListenable: ListItemPreviewCache.instance.notifierFor(listId),
    builder: (context, previews, _) {
      // Filter previews with valid images
      final withImages = previews
          .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
          .take(maxVisible + 1) // Get one extra to show overflow indicator
          .toList();
      
      if (withImages.isEmpty) {
        return const SizedBox.shrink();
      }
      
      final showImages = withImages.take(maxVisible).toList();
      final hasMore = withImages.length > maxVisible;
      
      // Calculate total width based on overlap
      final totalWidth = showImages.length == 1 
          ? size 
          : size + (showImages.length - 1) * (size - overlap) + (hasMore ? (size - overlap) : 0);
      
      return Container(
        height: size + 4, // Add padding for shadows
        width: totalWidth + 4,
        alignment: Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < showImages.length; i++)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: i * (size - overlap),
                top: 2,
                child: ItemImageTile(
                  key: ValueKey(showImages[i].itemId),
                  imageUrl: showImages[i].imageUrl!,
                  size: size,
                  isCompleted: showImages[i].isCompleted,
                  accentColor: accentColor,
                ),
              ),
            // +N overflow indicator
            if (hasMore)
              Positioned(
                left: showImages.length * (size - overlap),
                top: 2,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1E1E1E),
                    border: Border.all(
                      color: (accentColor ?? Colors.white).withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${previews.length - maxVisible}',
                    style: GoogleFonts.lato(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Scrollable horizontal item images for shopping list cards (larger variant).
/// Shows product images that user can swipe through.
Widget buildScrollableItemImages(
  String listId, {
  double size = 48,
  double spacing = 8,
  Color? accentColor,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12),
}) {
  return ValueListenableBuilder<List<ListItemPreview>>(
    valueListenable: ListItemPreviewCache.instance.notifierFor(listId),
    builder: (context, previews, _) {
      final withImages = previews
          .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
          .toList();
      
      if (withImages.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return SizedBox(
        height: size,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding,
          physics: const BouncingScrollPhysics(),
          itemCount: withImages.length,
          separatorBuilder: (_, __) => SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final preview = withImages[index];
            return ItemImageTile(
              key: ValueKey(preview.itemId),
              imageUrl: preview.imageUrl!,
              size: size,
              isCompleted: preview.isCompleted,
              accentColor: accentColor,
            );
          },
        ),
      );
    },
  );
}

/// Single item image tile with square frame.
/// Uses smooth transitions when image updates without flickering.
class ItemImageTile extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isCompleted;
  final Color? accentColor;
  
  const ItemImageTile({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.isCompleted,
    this.accentColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final borderColor = isCompleted 
        ? Colors.green.withValues(alpha: 0.6)
        : (accentColor ?? Colors.white).withValues(alpha: 0.15);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // More rounded
        border: Border.all(color: borderColor, width: 1),
        color: const Color(0xFF252525),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Use RepaintBoundary to isolate image repaints
          RepaintBoundary(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              // Use memory cache for instant display
              memCacheWidth: (size * 2.5).round(), // Higher res for retina
              memCacheHeight: (size * 2.5).round(),
              // No fade - image swaps instantly since it's pre-cached
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              // Placeholder shows only briefly on first load
              placeholder: (_, __) => _buildPlaceholder(),
              errorWidget: (_, __, ___) => _buildPlaceholder(),
            ),
          ),
          // Completed overlay with smooth animation
          AnimatedOpacity(
            opacity: isCompleted ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.green.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: size * 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholder() => Container(
    color: Colors.grey[850],
    child: Icon(
      Icons.shopping_bag_outlined,
      size: size * 0.5,
      color: Colors.grey[700],
    ),
  );
}
