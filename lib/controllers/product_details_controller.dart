import 'dart:async';
import 'package:get/get.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/price_history_service.dart';
import 'package:shopple/services/analytics/enhanced_search_analytics_service.dart';
import 'package:shopple/services/analytics/comprehensive_analytics_service.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/utils/app_logger.dart';

class ProductDetailsController extends GetxController {
  final Product product;
  final List<ProductWithPrices> allProductPrices;

  ProductDetailsController({
    required this.product,
    required this.allProductPrices,
  });

  // Progressive loading states
  final RxBool isBasicDataLoaded = false.obs;
  final RxBool isPriceDataLoaded = false.obs;
  final RxBool isPriceHistoryLoaded = false.obs;
  final RxBool isStatisticsLoaded = false.obs;

  final RxMap<String, List<MonthlyPriceHistory>> priceHistory =
      <String, List<MonthlyPriceHistory>>{}.obs;
  final RxMap<String, dynamic> priceStatistics = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Load basic data immediately
    _loadBasicData();
    // Load price history in background
    _loadPriceHistory();
    // 🎯 CRITICAL: Track product view for personalization
    _trackProductView();
  }

  void _loadBasicData() {
    // Basic product info and prices are available immediately from widget data
    isBasicDataLoaded.value = true;
    isPriceDataLoaded.value = true; // Price data comes from widget
  }

  Future<void> _loadPriceHistory() async {
    try {
      final history = await PriceHistoryService.getPriceTrendsAllStores(
        product.id,
        monthsBack: 6,
      );

      priceHistory.value = history;
      isPriceHistoryLoaded.value = true;

      // Calculate statistics after price history is loaded
      final allHistory = <MonthlyPriceHistory>[];
      for (final storeHistory in history.values) {
        allHistory.addAll(storeHistory);
      }

      final statistics = PriceHistoryService.calculatePriceStatistics(
        allHistory,
      );

      priceStatistics.value = statistics;
      isStatisticsLoaded.value = true;
    } catch (e) {
      AppLogger.e('Error loading price history', error: e);
      // Mark as loaded even if failed to stop loading indicators
      isPriceHistoryLoaded.value = true;
      isStatisticsLoaded.value = true;
    }
  }

  /// 🎯 CRITICAL PERSONALIZATION: Track product view for user analytics
  Future<void> _trackProductView() async {
    try {
      final startTime = DateTime.now();

      AppLogger.d(
        '[PRODUCT_VIEW] Start: id=${product.id}, name=${product.name}, brand=${product.brandName.isNotEmpty ? product.brandName : "UNBRANDED"}, category=${product.category}, variety=${product.variety}, size=${product.size} ${product.sizeUnit}, start=$startTime',
      );

      // Track with enhanced analytics service
      await EnhancedSearchAnalyticsService.trackProductView(
        productId: product.id,
        productName: product.name,
        timeSpent: 1000, // Initial 1 second view
        category: product.category,
        brand: product.brandName,
      );

      // Also update local Recently Viewed list for fast, offline defaults
      unawaited(RecentlyViewedService.add(product.id));

      AppLogger.d('[PRODUCT_VIEW] Enhanced analytics tracking completed');

      // Track with comprehensive analytics service for advanced insights
      final priceRange = _getPriceRange();
      final additionalData = {
        'product_name': product.name,
        'brand_name': product.brandName,
        'variety': product.variety,
        'size': product.size,
        'size_unit': product.sizeUnit,
        'price_range': priceRange,
        'store_count': allProductPrices.length,
        'view_timestamp': startTime.toIso8601String(),
      };

      AppLogger.d(
        '[PRODUCT_VIEW] Sending analytics: range=$priceRange stores=${allProductPrices.length} extra=$additionalData',
      );

      await ComprehensiveAnalyticsService.trackProductView(
        productId: product.id,
        timeSpent: 1000, // Initial 1 second view
        category: product.category,
        brand: product.brandName,
        additionalData: additionalData,
      );

      AppLogger.d('[PRODUCT_VIEW] Comprehensive analytics tracking completed');
    } catch (e, st) {
      AppLogger.e(
        '[PRODUCT_VIEW] Error tracking product view',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Helper to get price range for analytics
  Map<String, dynamic> _getPriceRange() {
    if (allProductPrices.isEmpty) return {};

    final prices = allProductPrices
        .expand((p) => p.prices.values)
        .map((currentPrice) => currentPrice.price)
        .toList();

    if (prices.isEmpty) return {};

    prices.sort();
    return {
      'min_price': prices.first,
      'max_price': prices.last,
      'avg_price': prices.reduce((a, b) => a + b) / prices.length,
      'price_count': prices.length,
    };
  }
}
