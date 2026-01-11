import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/widgets/search/enhanced_product_card.dart';
import 'package:shopple/services/analytics/enhanced_search_analytics_service.dart';

class StoresOverview extends StatelessWidget {
  final List<ProductWithPrices> baseOrResults;
  final Set<String> selectedStores;
  final void Function(String storeId) onToggleStore;
  final void Function(ProductWithPrices p) onTapProduct;
  final void Function(ProductWithPrices p) onAddToCart;
  final Future<void> Function() onRefresh;

  const StoresOverview({
    super.key,
    required this.baseOrResults,
    required this.selectedStores,
    required this.onToggleStore,
    required this.onTapProduct,
    required this.onAddToCart,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _getStoreStats(baseOrResults);
    String? bestStore;
    int? bestSaving;
    stats.forEach((id, s) {
      if (s.savingPercent != null) {
        if (bestSaving == null || s.savingPercent! > bestSaving!) {
          bestSaving = s.savingPercent!;
          bestStore = id;
        }
      }
    });

    String storeName(String id) {
      switch (id) {
        case 'cargills':
          return 'Cargills Food City';
        case 'keells':
          return 'Keells';
        case 'arpico':
          return 'Arpico';
        default:
          return id;
      }
    }

    Widget storeCard(String id, String name) {
      final s = stats[id] ?? const _StoreStats.empty();
      final selected = selectedStores.contains(id);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggleStore(id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primaryAccentColor.withValues(alpha: 0.5)
                    : AppColors.primaryText.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.store_mall_directory_rounded,
                  color: selected
                      ? AppColors.primaryAccentColor
                      : AppColors.primaryText70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.count == 0
                            ? 'Browse to see deals here'
                            : '${s.count} matching items · Best from Rs. ${s.bestPrice?.toStringAsFixed(2) ?? '--'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primaryText70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.savingPercent != null && s.savingPercent! >= 5)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_down,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '-${s.savingPercent}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryAccentColor,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          if (bestStore != null && (bestSaving ?? 0) >= 5) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings_rounded, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Best potential savings around $bestSaving% at ${storeName(bestStore!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),
          Text(
            'Stores',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          storeCard('cargills', 'Cargills Food City'),
          const SizedBox(height: 12),
          storeCard('keells', 'Keells'),
          const SizedBox(height: 12),
          storeCard('arpico', 'Arpico'),
          const SizedBox(height: 20),

          Text(
            'For you at your stores',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.primaryText70,
            ),
          ),
          const SizedBox(height: 8),
          ...baseOrResults
              .take(12)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EnhancedProductCard(
                    productWithPrices: p,
                    selectedStores: selectedStores,
                    onTap: () {
                      EnhancedSearchAnalyticsService.trackProductInteraction(
                        productId: p.product.id,
                        productName: p.product.name,
                        interactionType: 'tap',
                        interactionData: {
                          'brand': p.product.brandName,
                          'category': p.product.category,
                        },
                      );
                      onTapProduct(p);
                    },
                    onAddToCart: () => onAddToCart(p),
                    onSave: () {},
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Map<String, _StoreStats> _getStoreStats(List<ProductWithPrices> list) {
    final stats = <String, _StoreStats>{
      'cargills': const _StoreStats.empty(),
      'keells': const _StoreStats.empty(),
      'arpico': const _StoreStats.empty(),
    };
    double? minForStore(String store, ProductWithPrices p) {
      final cp = p.prices[store];
      return cp?.price;
    }

    for (final p in list) {
      for (final store in stats.keys) {
        final price = minForStore(store, p);
        if (price != null) {
          final current = stats[store]!;
          final best = current.bestPrice == null
              ? price
              : (price < current.bestPrice! ? price : current.bestPrice!);
          final worst = current.worstPrice == null
              ? price
              : (price > current.worstPrice! ? price : current.worstPrice!);
          stats[store] = _StoreStats(
            count: current.count + 1,
            bestPrice: best,
            worstPrice: worst,
          );
        }
      }
    }
    stats.updateAll((key, s) {
      final hasBoth =
          s.bestPrice != null && s.worstPrice != null && s.worstPrice! > 0;
      final percent = hasBoth
          ? (((s.worstPrice! - s.bestPrice!) / s.worstPrice!) * 100).round()
          : null;
      return _StoreStats(
        count: s.count,
        bestPrice: s.bestPrice,
        worstPrice: s.worstPrice,
        savingPercent: percent,
      );
    });
    return stats;
  }
}

class _StoreStats {
  final int count;
  final double? bestPrice;
  final double? worstPrice;
  final int? savingPercent;
  const _StoreStats({
    required this.count,
    this.bestPrice,
    this.worstPrice,
    this.savingPercent,
  });
  const _StoreStats.empty()
    : count = 0,
      bestPrice = null,
      worstPrice = null,
      savingPercent = null;
}
