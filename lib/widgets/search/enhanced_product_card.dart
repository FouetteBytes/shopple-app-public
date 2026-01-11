import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/product_request/product_request_sheet.dart';

class EnhancedProductCard extends StatelessWidget {
  final ProductWithPrices productWithPrices;
  final Set<String> selectedStores;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final VoidCallback onSave;
  final VoidCallback? onAddToList;
  // When true, renders a more compact layout suitable for grid/tight widths
  final bool compact;

  const EnhancedProductCard({
    super.key,
    required this.productWithPrices,
    required this.selectedStores,
    required this.onTap,
    required this.onAddToCart,
    required this.onSave,
    this.onAddToList,
    this.compact = false,
  });

  void _showReportOptions(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LiquidGlass(
        borderRadius: 20,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Suggest Product Edit',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 20),
              _buildReportOption(
                context,
                icon: Icons.info_outline,
                title: 'Update Information',
                subtitle: 'Suggest information corrections',
                color: Colors.blue,
                requestType: 'Update Information',
                product: product,
              ),
              _buildReportOption(
                context,
                icon: Icons.price_change_outlined,
                title: 'Update Price',
                subtitle: 'Report price changes',
                color: Colors.green,
                requestType: 'Price Update',
                product: product,
              ),
              _buildReportOption(
                context,
                icon: Icons.flag_outlined,
                title: 'Report Error',
                subtitle: 'Something is wrong',
                color: Colors.orange,
                requestType: 'Report Error',
                product: product,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String requestType,
    required Product product,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlass(
        borderRadius: 12,
        enableBlur: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ProductRequestSheet(
                  initialRequestType: requestType,
                  preTaggedProduct: product,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primaryText.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primaryText.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shared pre-computations -------------------------------------------------
    final product = productWithPrices.product;
    final Map<String, CurrentPrice> allPrices = productWithPrices.prices;
    final Map<String, CurrentPrice> prices = selectedStores.isEmpty
        ? allPrices
        : Map<String, CurrentPrice>.fromEntries(
            allPrices.entries.where((e) => selectedStores.contains(e.key)),
          );

    CurrentPrice? bestPrice;
    CurrentPrice? worstPrice;
    String priceComparison = '';
    if (prices.isNotEmpty) {
      bestPrice = prices.values.reduce((a, b) => a.price < b.price ? a : b);
      worstPrice = prices.values.reduce((a, b) => a.price > b.price ? a : b);
      if (prices.length > 1 && worstPrice.price != bestPrice.price) {
        final difference = worstPrice.price - bestPrice.price;
        final percentSaving = (difference / worstPrice.price * 100).round();
        priceComparison =
            'Save Rs. ${difference.toStringAsFixed(2)} ($percentSaving%)';
      }
    }
    final bool hasSavings =
        prices.length > 1 &&
        bestPrice != null &&
        worstPrice != null &&
        worstPrice.price > bestPrice.price;
    int savingsPercent = 0;
    if (hasSavings) {
      final w = worstPrice.price;
      final b = bestPrice.price;
      savingsPercent = (((w - b) / w) * 100).round();
    }

    // Responsive layout chooser ----------------------------------------------
    return LayoutBuilder(
      builder: (context, constraints) {
        // Treat widths below this threshold as “grid / narrow” -> vertical card
        final bool vertical = constraints.maxWidth < 360 || compact;
        return _buildCardShell(
          context: context,
          vertical: vertical,
          hasSavings: hasSavings,
          savingsPercent: savingsPercent,
          product: product,
          bestPrice: bestPrice,
          worstPrice: worstPrice,
          priceComparison: priceComparison,
          prices: prices,
        );
      },
    );
  }

  // Card outer container (shared styles) with chosen inner layout
  Widget _buildCardShell({
    required BuildContext context,
    required bool vertical,
    required bool hasSavings,
    required int savingsPercent,
    required Product product,
    required CurrentPrice? bestPrice,
    required CurrentPrice? worstPrice,
    required String priceComparison,
    required Map<String, CurrentPrice> prices,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      // Consistent margin for all cards regardless of context
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Record as recently viewed before navigation
            RecentlyViewedService.add(productWithPrices.product.id);
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: LiquidGlass(
            borderRadius: 16,
            enableBlur:
                false, // keep perf tight in long lists; gradient borders are enough
            borderWidth: 1,
            borderColor: AppColors.primaryText.withValues(alpha: 0.08),
            gradientColors: const [
              Color(0x14FFFFFF), // ~8% white
              Color(0x08FFFFFF), // ~3% white
            ],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            child: Padding(
              // Consistent padding for all card layouts
              padding: const EdgeInsets.all(16),
              child: vertical
                  ? _verticalLayout(
                      product,
                      hasSavings,
                      savingsPercent,
                      bestPrice,
                      worstPrice,
                      priceComparison,
                      prices,
                    )
                  : _horizontalLayout(
                      product,
                      hasSavings,
                      savingsPercent,
                      bestPrice,
                      worstPrice,
                      priceComparison,
                      prices,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Horizontal (original) layout but with more defensive sizing
  Widget _horizontalLayout(
    Product product,
    bool hasSavings,
    int savingsPercent,
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
    String priceComparison,
    Map<String, CurrentPrice> prices,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imageSection(product, hasSavings, savingsPercent),
        const SizedBox(width: 16), // Consistent spacing
        Expanded(
          child: _detailsSection(
            product,
            bestPrice,
            worstPrice,
            priceComparison,
            prices,
          ),
        ),
        if (!compact)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onAddToList != null)
                _ActionSquareButton(
                  icon: Icons.playlist_add_rounded,
                  onTap: onAddToList!,
                  tooltip: 'Add to list',
                ),
              if (onAddToList != null) const SizedBox(height: 8),
              _ActionSquareButton(
                icon: Icons.bookmark_add_outlined,
                onTap: onSave,
                tooltip: 'Save',
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (ctx) => _SubtleActionButton(
                  icon: Icons.edit_note_outlined,
                  onTap: () => _showReportOptions(ctx, product),
                  tooltip: 'Suggest edit',
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Vertical layout for narrow widths (image on top, actions below)
  Widget _verticalLayout(
    Product product,
    bool hasSavings,
    int savingsPercent,
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
    String priceComparison,
    Map<String, CurrentPrice> prices,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlaid compact action buttons to minimize vertical height
            Stack(
              clipBehavior: Clip.none,
              children: [
                _imageSection(
                  product,
                  hasSavings,
                  savingsPercent,
                  square: true,
                ),
                // Vertical rail on the right edge so it won't steal vertical space below the image
                Positioned(
                  right: -6,
                  top: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniActionButton(
                        icon: Icons.add_shopping_cart_rounded,
                        onTap: onAddToCart,
                        tooltip: 'Add',
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      if (onAddToList != null) ...[
                        _MiniActionButton(
                          icon: Icons.playlist_add_rounded,
                          onTap: onAddToList!,
                          tooltip: 'List',
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                      ],
                      _MiniActionButton(
                        icon: Icons.bookmark_add_outlined,
                        onTap: onSave,
                        tooltip: 'Save',
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Use Expanded to take remaining space - no scrolling for grid cards
            Expanded(
              child: _detailsSection(
                product,
                bestPrice,
                worstPrice,
                priceComparison,
                prices,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _imageSection(
    Product product,
    bool hasSavings,
    int savingsPercent, {
    bool square = false,
  }) {
    // Force consistent image size regardless of compact mode for uniform card appearance
    final size = 90.0; // Always use 90px for consistency across all contexts
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = size;
        final bool isInactive = !product.isActive;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Hero(
              tag: 'product_${product.id}',
              child: SizedBox(
                width: side,
                height: side,
                child: Container(
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
                            fadeInDuration: const Duration(milliseconds: 220),
                            fadeOutDuration: const Duration(milliseconds: 120),
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryAccentColor.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.primaryText30,
                              size: 28,
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: AppColors.primaryText30,
                            size: 28,
                          ),
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
                  opacity: hasSavings && savingsPercent >= 5 ? 1.0 : 0.0,
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
            if (isInactive)
              Positioned(
                bottom: -6,
                left: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade700, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_off_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'UNAVAILABLE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _detailsSection(
    Product product,
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
    String priceComparison,
    Map<String, CurrentPrice> prices,
  ) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.brandName.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryAccentColor.withValues(alpha: 0.12),
                  AppColors.primaryAccentColor.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primaryAccentColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.12),
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
          SizedBox(height: compact ? 4 : 8),
        ],
        Text(
          product.name,
          style: GoogleFonts.poppins(
            color: AppColors.primaryText,
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w600,
            height: compact ? 1.2 : 1.25,
            letterSpacing: -0.2,
          ),
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: compact ? 4 : 8),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 4 : 6,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 3 : 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryAccentColor.withValues(alpha: 0.14),
                    AppColors.primaryAccentColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
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
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightMauveBackgroundColor.withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.lightMauveBackgroundColor.withValues(
                    alpha: 0.15,
                  ),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 11,
                    color: AppColors.lightMauveBackgroundColor,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 90 : 160),
                    child: Text(
                      CategoryService.getDisplayName(product.category),
                      style: GoogleFonts.poppins(
                        color: AppColors.lightMauveBackgroundColor,
                        fontSize: compact ? 9 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (product.variety.isNotEmpty && !compact) ...[
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
        SizedBox(height: compact ? 6 : 12),
        // Price section: no Flexible to avoid flex in unbounded height Column
        _modernPriceSection(
          bestPrice,
          worstPrice,
          priceComparison,
          prices,
          isCompact: compact,
        ),
      ],
    );

    if (compact) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: content,
      );
    }
    return content;
  }

  Widget _modernPriceSection(
    CurrentPrice? bestPrice,
    CurrentPrice? worstPrice,
    String priceComparison,
    Map<String, CurrentPrice> prices, {
    bool isCompact = false,
  }) {
    final product = productWithPrices.product;
    final bool inactive = !product.isActive;
    if (inactive) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withValues(alpha: 0.20),
                Colors.grey.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_rounded,
                size: 12,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'Currently unavailable',
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
    if (prices.isEmpty) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 4 : 6,
          ),
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
    // At this point bestPrice is non-null; hoist to a local non-nullable variable
    final CurrentPrice bp = bestPrice;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [if (currentChild != null) currentChild, ...previousChildren],
      ),
      key: ValueKey('price-${bp.id}-${prices.length}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: isCompact ? 3 : 6,
            ),
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
            child: LayoutBuilder(
              builder: (context, c) {
                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          color: Colors.green,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rs. ${bp.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 4 : 6,
                        vertical: isCompact ? 1.5 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 90 : 140,
                        ),
                        child: Text(
                          _storeName(bp.supermarketId),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontSize: isCompact ? 8 : 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!isCompact &&
              prices.length > 1 &&
              worstPrice != null &&
              bp.price != worstPrice.price) ...[
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
                    priceComparison,
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
          if (!isCompact && prices.length > 1) ...[
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
}

class _ActionSquareButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ActionSquareButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_ActionSquareButton> createState() => _ActionSquareButtonState();
}

class _SubtleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _SubtleActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryText.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: AppColors.primaryText.withValues(alpha: 0.5),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;

  const _MiniActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAccentColor,
            AppColors.primaryAccentColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, color: Colors.white, size: size * 0.57),
        ),
      ),
    );

    if (tooltip?.isNotEmpty ?? false) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _ActionSquareButtonState extends State<_ActionSquareButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _scale,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccentColor,
              AppColors.primaryAccentColor.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (isDown) {
              setState(() => _scale = isDown ? 0.94 : 1.0);
            },
            borderRadius: BorderRadius.circular(12),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );

    if (widget.tooltip?.isNotEmpty ?? false) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
