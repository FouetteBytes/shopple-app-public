import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/search/product_search_controller.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/screens/modern_product_details_screen.dart';
import 'package:shopple/services/saved_lists_service.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/search/enhanced_product_card.dart';
import 'package:shopple/widgets/skeleton_loader.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/shopping_lists/multi_add_to_lists_sheet.dart';
import 'package:shopple/utils/app_logger.dart';

class SearchResultsView extends StatelessWidget {
  final ProductSearchController controller;

  const SearchResultsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return SliverList.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      );
    }

    if (controller.searchController.text.isNotEmpty && controller.searchResults.isEmpty) {
      return SliverToBoxAdapter(child: _buildNoResultsWidget(context));
    }

    if (controller.searchResults.isEmpty && controller.showPersonalizedDefaults) {
      return _buildRecentlyViewedSection(context);
    }

    if (controller.searchResults.isEmpty &&
        controller.searchController.text.isEmpty &&
        !controller.showPersonalizedDefaults) {
      return SliverToBoxAdapter(child: _buildNoResultsWidget(context));
    }

    return _buildResultsList(context);
  }

  Widget _buildRecentlyViewedSection(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: AppColors.primaryAccentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recently viewed',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        // TODO: Move clear logic to controller
                        // await RecentlyViewedService.clear();
                        // await controller.loadRecentlyViewed();
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryText70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (controller.loadingRecent)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ProductCardSkeleton(),
            ),
          )
        else if (controller.recentlyViewed.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'You haven\'t viewed any products yet.',
                style: GoogleFonts.poppins(color: AppColors.primaryText70),
              ),
            ),
          )
        else
          _buildProductGridOrList(context, controller.recentlyViewed),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (controller.isFallbackSuggestions && controller.searchController.text.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_alt_rounded,
                    size: 18,
                    color: AppColors.primaryAccentColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Suggestions for "${controller.searchController.text}"',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildProductGridOrList(context, controller.searchResults),
      ],
    );
  }

  Widget _buildProductGridOrList(BuildContext context, List<ProductWithPrices> list) {
    if (controller.gridMode) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final productWithPrices = list[index];
            return _buildAnimatedProductCard(context, index, productWithPrices, true);
          }, childCount: list.length),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final productWithPrices = list[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnimatedProductCard(context, index, productWithPrices, false),
            );
          },
        ),
      );
    }
  }

  Widget _buildAnimatedProductCard(
    BuildContext context,
    int index,
    ProductWithPrices productWithPrices,
    bool compact,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 200 + (index * 18).clamp(0, 180),
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: EnhancedProductCard(
        productWithPrices: productWithPrices,
        selectedStores: controller.selectedStores,
        compact: compact,
        onTap: () => _showProductDetails(context, productWithPrices),
        onAddToCart: () => _addToCart(context, productWithPrices),
        onSave: () async {
          try {
            await SavedListsService.addToQuickList(
              productWithPrices.product,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to list')),
            );
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign in required to save items'), backgroundColor: Colors.red),
            );
          }
        },
        onAddToList: () => _showAddToListDialog(context, productWithPrices),
      ),
    );
  }

  void _showProductDetails(BuildContext context, ProductWithPrices productWithPrices) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernProductDetailsScreen(
          product: productWithPrices.product,
          allProductPrices: [productWithPrices],
        ),
      ),
    ).then((_) {
      controller.loadRecentlyViewed();
    });
  }

  void _addToCart(BuildContext context, ProductWithPrices productWithPrices) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Added "${productWithPrices.product.name}" to cart',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    AppLogger.d('Added to cart: ${productWithPrices.product.name}');
  }

  void _showAddToListDialog(BuildContext context, ProductWithPrices productWithPrices) {
    final bestPrice = productWithPrices.getBestPrice()?.price ?? 0.0;
    showAppBottomSheet(
      MultiAddToListsSheet(
        product: productWithPrices.product,
        prices: productWithPrices.prices,
        assumedPrice: bestPrice,
        initialQuantity: 1,
        scrollFriendly: true,
      ),
      isScrollControlled: true,
      maxHeightFactor: 0.88,
    );
  }

  Widget _buildNoResultsWidget(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.08,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.25,
                height: MediaQuery.of(context).size.width * 0.25,
                constraints: const BoxConstraints(
                  minWidth: 100,
                  maxWidth: 120,
                  minHeight: 100,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAccentColor.withValues(alpha: 0.1),
                      AppColors.lightMauveBackgroundColor.withValues(
                        alpha: 0.1,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width * 0.125,
                  ),
                  border: Border.all(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: MediaQuery.of(context).size.width * 0.12,
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.7),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.025),

              Text(
                'No Results Found',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryText,
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              Text(
                'No products found for "${controller.searchController.text}"',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryText70,
                  fontSize: MediaQuery.of(context).size.width * 0.038,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightMauveBackgroundColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lightMauveBackgroundColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: MediaQuery.of(context).size.width * 0.04,
                          color: AppColors.lightMauveBackgroundColor,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015,
                        ),
                        Flexible(
                          child: Text(
                            'Try these suggestions:',
                            style: GoogleFonts.poppins(
                              color: AppColors.lightMauveBackgroundColor,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      '• Check your spelling\n• Use different keywords\n• Try brand names like "Anchor" or "Keells"',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryText70,
                        fontSize: MediaQuery.of(context).size.width * 0.032,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
