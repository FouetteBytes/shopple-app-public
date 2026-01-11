import 'package:shopple/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';

class PersonalizedDefaultContent extends StatefulWidget {
  final Function(String) onQuerySelected;
  final TextEditingController searchController;

  const PersonalizedDefaultContent({
    super.key,
    required this.onQuerySelected,
    required this.searchController,
  });

  @override
  State<PersonalizedDefaultContent> createState() =>
      _PersonalizedDefaultContentState();
}

class _PersonalizedDefaultContentState extends State<PersonalizedDefaultContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<ProductWithPrices> _recentlyViewed = [];
  List<Map<String, String>> _topCategories = [];
  List<ProductWithPrices> _trending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadLocalDefaultContent();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadLocalDefaultContent() async {
    try {
      final viewed = await RecentlyViewedService.getWithPrices(limit: 8);
      final categories = CategoryService.getCategoriesForUI(
        includeAll: false,
      ).take(10).toList();
      // Trending: reuse local search results
      final trending = await EnhancedProductService.searchProductsWithPrices(
        '',
      );
      if (mounted) {
        setState(() {
          _recentlyViewed = viewed;
          _topCategories = categories;
          _trending = trending.take(10).toList();
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      AppLogger.e('Error loading local default content', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocalHeader(),
            const SizedBox(height: 16),
            if (_recentlyViewed.isNotEmpty) ...[
              _buildRecentlyViewedSection(),
              const SizedBox(height: 24),
            ],
            _buildTopCategoriesSection(),
            const SizedBox(height: 24),
            _buildTrendingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryAccentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading content...',
            style: GoogleFonts.inter(
              color: AppColors.primaryText70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: GoogleFonts.inter(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recently viewed, top categories, and trending picks',
          style: GoogleFonts.inter(
            color: AppColors.primaryText70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: AppColors.primaryAccentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Trending',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _trending.take(10).length,
            itemBuilder: (context, index) {
              final pwp = _trending[index];
              return _buildTrendingCard(pwp);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(ProductWithPrices pwp) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onQuerySelected(pwp.product.name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryText.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.background,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: pwp.product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_rounded,
                          color: AppColors.primaryText.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.primaryText.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Product Name
                Text(
                  pwp.product.name,
                  style: GoogleFonts.inter(
                    color: AppColors.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Price preview (if available)
                if (pwp.prices.isNotEmpty)
                  Text(
                    'from ${pwp.prices.values.map((e) => e.price).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryAccentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              color: AppColors.primaryAccentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Top Categories',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _topCategories.take(8).map((c) {
            final name = (c['displayName'] ?? c['name'] ?? '').toString();
            return ActionChip(
              avatar: const Icon(Icons.search_rounded, size: 16),
              label: Text(name),
              onPressed: () => widget.onQuerySelected(name.toLowerCase()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently viewed',
          style: GoogleFonts.inter(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentlyViewed.isEmpty)
          Text(
            'No recent items yet',
            style: GoogleFonts.inter(color: AppColors.primaryText70),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentlyViewed.length,
              itemBuilder: (context, index) {
                final pwp = _recentlyViewed[index];
                return _buildTrendingCard(pwp);
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
