import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/search/recent_search_service.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/widgets/search/enhanced_product_card.dart' as list_card;
import 'package:shopple/screens/modern_product_details_screen.dart';

/// Local-only Discover screen (repurposed from old personalized recommendations)
class PersonalizedRecommendationsScreen extends StatefulWidget {
  final ValueChanged<String>?
  onQueryTap; // optional: navigate to Search with query
  const PersonalizedRecommendationsScreen({super.key, this.onQueryTap});

  @override
  State<PersonalizedRecommendationsScreen> createState() =>
      _PersonalizedRecommendationsScreenState();
}

class _PersonalizedRecommendationsScreenState
    extends State<PersonalizedRecommendationsScreen> {
  bool _loading = true;
  bool _refreshing = false;
  bool _clearing = false;
  bool _historyCleared = false;

  List<ProductWithPrices> _recentlyViewed = [];
  List<ProductWithPrices> _trending = [];
  List<Map<String, String>> _topCategories = [];

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      if (_loading) _historyCleared = false; // reset banner on first load
    });
    try {
      final viewed = await RecentlyViewedService.getWithPrices(limit: 12);
      final trending = await EnhancedProductService.searchProductsWithPrices(
        '',
      );
      final categories = CategoryService.getCategoriesForUI(
        includeAll: false,
      ).take(12).toList();
      if (!mounted) return;
      setState(() {
        _recentlyViewed = viewed;
        _trending = trending.take(12).toList();
        _topCategories = categories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load content')));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _clearing = true);
    try {
      await RecentSearchService.clearAll();
      await RecentlyViewedService.clear();
      if (!mounted) return;
      setState(() => _historyCleared = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Search history cleared')));
      await _loadLocal();
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _openDetails(ProductWithPrices pwp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModernProductDetailsScreen(
          product: pwp.product,
          allProductPrices: [pwp],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _refreshing ? null : _loadLocal,
          ),
          IconButton(
            tooltip: 'Clear history',
            icon: _clearing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep_rounded),
            onPressed: _clearing ? null : _clearHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocal,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_historyCleared) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('History cleared'),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    labelStyle: GoogleFonts.inter(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              // Recently viewed
              Row(
                children: [
                  const Icon(Icons.history_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Recently viewed',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_recentlyViewed.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearing
                          ? null
                          : () async {
                              setState(() => _clearing = true);
                              await RecentlyViewedService.clear();
                              await _loadLocal();
                              if (mounted) setState(() => _clearing = false);
                            },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_recentlyViewed.isEmpty)
                Text(
                  'No recent items yet',
                  style: GoogleFonts.inter(color: AppColors.primaryText70),
                )
              else
                ..._recentlyViewed.map(
                  (pwp) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: list_card.EnhancedProductCard(
                      productWithPrices: pwp,
                      selectedStores: const {},
                      onTap: () => _openDetails(pwp),
                      onAddToCart: () => _openDetails(pwp),
                      onSave: () => _openDetails(pwp),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Top categories
              Row(
                children: [
                  const Icon(Icons.category_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Top categories',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topCategories.take(10).map((c) {
                  final name = (c['displayName'] ?? c['name'] ?? '').toString();
                  return ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 16),
                    label: Text(name),
                    onPressed: () =>
                        widget.onQueryTap?.call(name.toLowerCase()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Trending
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Trending',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_trending.isEmpty)
                Text(
                  'No trending items yet',
                  style: GoogleFonts.inter(color: AppColors.primaryText70),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _trending
                        .take(12)
                        .map(
                          (pwp) => SizedBox(
                            width: 280,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: list_card.EnhancedProductCard(
                                productWithPrices: pwp,
                                selectedStores: const {},
                                onTap: () => _openDetails(pwp),
                                onAddToCart: () => _openDetails(pwp),
                                onSave: () => _openDetails(pwp),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
