import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/utils/app_logger.dart';
import '../../models/product_model.dart';
import '../../services/product/price_history_service.dart';

class ProductHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get enhanced product overview similar to backend API
  static Future<List<ProductWithPrices>> getProductsOverview({
    int limit = 100,
  }) async {
    try {
      // Get all products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('is_active', isEqualTo: true)
          .limit(limit)
          .get();

      final products = productsSnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      // Get current prices for each product
      final productsWithPrices = <ProductWithPrices>[];

      for (final product in products) {
        final pricesSnapshot = await _firestore
            .collection('current_prices')
            .where('productId', isEqualTo: product.id)
            .get();

        final prices = <String, CurrentPrice>{};
        for (final doc in pricesSnapshot.docs) {
          final price = CurrentPrice.fromFirestore(doc);
          prices[price.supermarketId] = price;
        }

        if (prices.isNotEmpty) {
          productsWithPrices.add(
            ProductWithPrices(product: product, prices: prices),
          );
        }
      }

      return productsWithPrices;
    } catch (e) {
      AppLogger.e('Error getting products overview', error: e);
      return [];
    }
  }

  /// Get complete price history for a product (similar to backend API)
  static Future<ProductHistoryResponse?> getProductPriceHistory(
    String productId,
  ) async {
    try {
      // Get product details
      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        return null;
      }

      final product = Product.fromFirestore(productDoc);

      // Get current prices
      final currentPricesSnapshot = await _firestore
          .collection('current_prices')
          .where('productId', isEqualTo: productId)
          .get();

      final currentPrices = currentPricesSnapshot.docs
          .map((doc) => CurrentPrice.fromFirestore(doc))
          .toList();

      // Sort by price (lowest first)
      currentPrices.sort((a, b) => a.price.compareTo(b.price));

      // Get price history for all stores
      final priceHistory = await PriceHistoryService.getPriceTrendsAllStores(
        productId,
        monthsBack: 6,
      );

      // Calculate price analysis
      final allHistoryData = <MonthlyPriceHistory>[];
      for (final storeHistory in priceHistory.values) {
        allHistoryData.addAll(storeHistory);
      }

      final priceAnalysis = PriceHistoryService.calculatePriceStatistics(
        allHistoryData,
      );

      return ProductHistoryResponse(
        product: product,
        currentPrices: currentPrices,
        priceHistory: priceHistory,
        priceAnalysis: priceAnalysis,
      );
    } catch (e) {
      AppLogger.e('Error getting product price history', error: e);
      return null;
    }
  }

  /// Search products similar to backend functionality
  static Future<List<ProductWithPrices>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    try {
      final searchLower = query.toLowerCase();

      // Search by name, brand, or category
      final querySnapshot = await _firestore
          .collection('products')
          .where('is_active', isEqualTo: true)
          .get();

      final matchingProducts = querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) {
            return product.name.toLowerCase().contains(searchLower) ||
                product.brandName.toLowerCase().contains(searchLower) ||
                product.category.toLowerCase().contains(searchLower);
          })
          .take(50)
          .toList();

      // Get prices for matching products
      final productsWithPrices = <ProductWithPrices>[];

      for (final product in matchingProducts) {
        final pricesSnapshot = await _firestore
            .collection('current_prices')
            .where('productId', isEqualTo: product.id)
            .get();

        final prices = <String, CurrentPrice>{};
        for (final doc in pricesSnapshot.docs) {
          final price = CurrentPrice.fromFirestore(doc);
          prices[price.supermarketId] = price;
        }

        if (prices.isNotEmpty) {
          productsWithPrices.add(
            ProductWithPrices(product: product, prices: prices),
          );
        }
      }

      return productsWithPrices;
    } catch (e) {
      AppLogger.e('Error searching products', error: e);
      return [];
    }
  }
}

/// Response model matching backend structure
class ProductHistoryResponse {
  final Product product;
  final List<CurrentPrice> currentPrices;
  final Map<String, List<MonthlyPriceHistory>> priceHistory;
  final Map<String, dynamic> priceAnalysis;

  ProductHistoryResponse({
    required this.product,
    required this.currentPrices,
    required this.priceHistory,
    required this.priceAnalysis,
  });

  /// Check if the product has price history data
  bool get hasPriceHistory => priceHistory.isNotEmpty;

  /// Get the number of stores with data
  int get storeCount => priceHistory.keys.length;

  /// Get best current price
  CurrentPrice? get bestPrice {
    if (currentPrices.isEmpty) return null;
    return currentPrices.first; // Already sorted by price
  }

  /// Get worst current price
  CurrentPrice? get worstPrice {
    if (currentPrices.isEmpty) return null;
    return currentPrices.last; // Already sorted by price
  }

  /// Get price range
  double get priceRange {
    if (currentPrices.length < 2) return 0.0;
    return worstPrice!.price - bestPrice!.price;
  }

  /// Get savings percentage
  double get savingsPercentage {
    if (currentPrices.length < 2) return 0.0;
    final best = bestPrice!.price;
    final worst = worstPrice!.price;
    return ((worst - best) / worst) * 100;
  }
}
