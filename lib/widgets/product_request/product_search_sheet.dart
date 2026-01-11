import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/services/search/unified_product_search_service.dart';
import 'package:shopple/services/search/autocomplete_service.dart';

/// Product search sheet for tagging products in correction requests
class ProductSearchSheet extends StatefulWidget {
  const ProductSearchSheet({super.key});

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  final _searchController = TextEditingController();
  List<ProductWithPrices> _searchResults = [];
  List<ProductWithPrices> _recentProducts = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentProducts() async {
    // Load recent products using the unified search service
    // This will show products from recent searches
    setState(() {
      _recentProducts = [];
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Show autocomplete suggestions immediately by searching products
    if (query.length >= 2) {
      _showAutocompleteSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _showAutocompleteSuggestions(String query) async {
    try {
      // Use UnifiedProductSearchService to get real product suggestions
      final results = await UnifiedProductSearchService.search(query, limit: 5);

      if (mounted) {
        setState(() {
          _suggestions = results
              .map((p) => p.product.name)
              .where((name) => name.toLowerCase().contains(query.toLowerCase()))
              .take(5)
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      // Fallback to category suggestions if product search fails
      if (mounted) {
        setState(() {
          _suggestions = AutocompleteService.getSuggestions(query);
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = false; // Hide suggestions when showing results
    });

    try {
      // Use the existing unified search service
      final results = await UnifiedProductSearchService.search(
        query,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = _searchController.text.isEmpty
        ? _recentProducts
        : _searchResults;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: LiquidGlass(
        borderRadius: 0,
        enableBlur: true,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const SizedBox(height: 10),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryGreen.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Product',
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Find the product to tag',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LiquidGlass(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.lato(fontSize: 15, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or brand...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              color: Colors.white38,
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Autocomplete Suggestions
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlass(
                    borderRadius: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _suggestions.take(5).map((suggestion) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _searchController.text = suggestion;
                              _performSearch(suggestion);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      suggestion,
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.north_west,
                                    size: 14,
                                    color: AppColors.primaryText.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              if (_showSuggestions && _suggestions.isNotEmpty)
                const SizedBox(height: 16),

              // Results Label
              if (!_showSuggestions && displayProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        _searchController.text.isEmpty
                            ? 'Recent Products'
                            : 'Search Results',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${displayProducts.length})',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_showSuggestions) const SizedBox(height: 8),

              // Results List
              if (!_showSuggestions)
                Flexible(
                  child: _isSearching
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : displayProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _searchController.text.isEmpty
                                      ? Icons.inventory_2_outlined
                                      : Icons.search_off,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Start typing to search'
                                      : 'No products found',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shrinkWrap: true,
                          itemCount: displayProducts.length,
                          itemBuilder: (context, index) {
                            final productWithPrices = displayProducts[index];
                            return _ProductSearchResultCard(
                              productWithPrices: productWithPrices,
                              onTap: () => Navigator.pop(
                                context,
                                productWithPrices.product,
                              ),
                            );
                          },
                        ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product search result card
class _ProductSearchResultCard extends StatelessWidget {
  final ProductWithPrices productWithPrices;
  final VoidCallback onTap;

  const _ProductSearchResultCard({
    required this.productWithPrices,
    required this.onTap,
  });

  String _getRelativeTime(String timestampStr) {
    try {
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestampStr; // Return original string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = productWithPrices.product;
    final prices = productWithPrices.prices;

    // Calculate best price and store info
    MapEntry<String, CurrentPrice>? bestPriceEntry;
    if (prices.isNotEmpty) {
      bestPriceEntry = prices.entries.reduce(
        (a, b) => a.value.price < b.value.price ? a : b,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: LiquidGlass(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.white12,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white12,
                    child: const Icon(Icons.image_not_supported, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.brandName.isNotEmpty) ...[
                          Text(
                            product.brandName,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                        Text(
                          '${product.size} ${product.sizeUnit}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    if (bestPriceEntry != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Rs. ${bestPriceEntry.value.price.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bestPriceEntry.key,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRelativeTime(bestPriceEntry.value.lastUpdated),
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                          if (prices.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '+${prices.length - 1} ${prices.length - 1 == 1 ? 'store' : 'stores'}',
                                style: GoogleFonts.lato(
                                  fontSize: 9,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
