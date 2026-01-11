import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/category_service.dart';

// Modernized product card with size & category chips, smooth animations, and a "Best deal" badge.
class EnhancedProductCard extends StatefulWidget {
  final ProductWithPrices productWithPrices;
  final VoidCallback? onTap;

  const EnhancedProductCard({
    super.key,
    required this.productWithPrices,
    this.onTap,
  });

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  void _onDown(TapDownDetails _) => _pressController.forward();
  void _onUp(TapUpDetails _) => _pressController.reverse();
  void _onCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final product = widget.productWithPrices.product;
    final Map<String, CurrentPrice> priceMap = widget.productWithPrices.prices;
    final List<CurrentPrice> prices = priceMap.values.toList();
    CurrentPrice? bestPrice;
    CurrentPrice? worstPrice;
    if (prices.isNotEmpty) {
      bestPrice = prices.reduce((a, b) => a.price < b.price ? a : b);
      worstPrice = prices.reduce((a, b) => a.price > b.price ? a : b);
    }
    final int savingsPercent = _computeSavingsPercent(bestPrice, worstPrice);
    final bool hasSavings = savingsPercent >= 1;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: _onDown,
        onTapUp: _onUp,
        onTapCancel: _onCancel,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryText.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Best deal badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: 'product_${product.id}_card',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primaryText.withValues(alpha: 0.06),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  fadeOutDuration: const Duration(
                                    milliseconds: 120,
                                  ),
                                  placeholder: (context, url) => Container(
                                    color: AppColors.background,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primaryAccentColor
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.primaryText30,
                                    size: 26,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  color: AppColors.primaryText30,
                                  size: 26,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      right: -10,
                      child: AnimatedScale(
                        scale: hasSavings && savingsPercent >= 5 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: hasSavings && savingsPercent >= 5
                              ? 1.0
                              : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_offer_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Best deal • $savingsPercent%'.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brandName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryAccentColor.withValues(
                                  alpha: 0.12,
                                ),
                                AppColors.primaryAccentColor.withValues(
                                  alpha: 0.06,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryAccentColor.withValues(
                                alpha: 0.2,
                              ),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryAccentColor.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            product.brandName.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryAccentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Text(
                        EnhancedProductService.getProductDisplayName(product),
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Size + category chips with subtle scale-in
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.94, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          alignment: Alignment.centerLeft,
                          child: child,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryAccentColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    AppColors.primaryAccentColor.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryAccentColor
                                      .withValues(alpha: 0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    size: 11,
                                    color: AppColors.primaryAccentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.sizeRaw,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primaryAccentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightMauveBackgroundColor
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.lightMauveBackgroundColor
                                        .withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 11,
                                      color:
                                          AppColors.lightMauveBackgroundColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 160,
                                        ),
                                        child: Text(
                                          CategoryService.getDisplayName(
                                            product.category,
                                          ),
                                          style: GoogleFonts.poppins(
                                            color: AppColors
                                                .lightMauveBackgroundColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (product.variety.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.variety,
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryText70,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),
                      _priceSectionAnimated(bestPrice, worstPrice, prices),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _computeSavingsPercent(
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
  ) {
    if (bestPrice == null || worstPrice == null) return 0;
    if (worstPrice.price <= bestPrice.price) return 0;
    final pct = ((worstPrice.price - bestPrice.price) / worstPrice.price) * 100;
    return pct.round();
  }

  Widget _priceSectionAnimated(
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
    List<CurrentPrice> prices,
  ) {
    // Loading / no prices yet
    if (prices.isEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Container(
          key: const ValueKey('loading'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.12),
                Colors.orange.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 12,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Fetching prices...',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (bestPrice == null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Container(
          key: const ValueKey('no-price'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Price unavailable',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final CurrentPrice bp = bestPrice; // non-null
    final double? worst = worstPrice?.price;
    final bool showSavings = (worst != null && worst != bp.price);
    final double saveAmount = worstPrice != null
        ? (worstPrice.price - bp.price)
        : 0.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [if (currentChild != null) currentChild, ...previousChildren],
      ),
      child: Column(
        key: ValueKey('price-${bp.id}-${prices.length}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.12),
                  Colors.green.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.green,
                  size: 12,
                ),
                Text(
                  'Rs. ${bp.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      _storeName(bp.supermarketId),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (prices.length > 1 && showSavings) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 11,
                  color: AppColors.primaryText70,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Save Rs. ${saveAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryText70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (prices.length > 1) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 10,
                  color: AppColors.primaryAccentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Available at ${prices.length} stores',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryAccentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _storeName(String id) {
    switch (id) {
      case 'keells':
        return 'Keells Super';
      case 'cargills':
        return 'Cargills Food City';
      case 'arpico':
        return 'Arpico Supercenter';
      default:
        return id;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }
}
