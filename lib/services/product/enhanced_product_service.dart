import 'package:shopple/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/search/search_engine_service.dart';

class EnhancedProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<Product>> _cache = {};
  static const Duration cacheTimeout = Duration(minutes: 15);

  // Get all products using EXACT Firebase field names.
  static Future<List<Product>> getAllProducts({
    bool forceRefresh = false,
  }) async {
    // Use existing shared_preferences package for caching.
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'products_cache_timestamp';

    if (!forceRefresh && _cache.containsKey('all_products')) {
      final lastUpdate = prefs.getInt(cacheKey);
      if (lastUpdate != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
        if (cacheAge < cacheTimeout.inMilliseconds) {
          return _cache['all_products']!;
        }
      }
    }

    try {
      // Use exact Firebase field names (with underscores).
      final querySnapshot = await _firestore
          .collection('products')
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          originalName: data['original_name'] ?? '',
          brandName: data['brand_name'] ?? '',
          category: data['category'] ?? '',
          size: (data['size'] ?? 0).toInt(), // Fix: Convert to int.
          sizeRaw: data['sizeRaw'] ?? '',
          sizeUnit: data['sizeUnit'] ?? '',
          variety: data['variety'] ?? '',
          imageUrl:
              data['image_url'] ?? data['imageUrl'] ?? data['imageURL'] ?? '',
          isActive: data['is_active'] ?? false,
          createdAt: data['created_at'] ?? Timestamp.now(),
          updatedAt: data['updated_at'] ?? Timestamp.now(),
        );
      }).toList();

      // Cache using existing SharedPreferences.
      _cache['all_products'] = products;
      await prefs.setInt(cacheKey, DateTime.now().millisecondsSinceEpoch);

      return products;
    } catch (e) {
      AppLogger.e('Error fetching products', error: e);
      return _cache['all_products'] ?? [];
    }
  }

  // Enhanced category-based queries.
  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    final cacheKey = 'category_$categoryId';

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryId)
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          originalName: data['original_name'] ?? '',
          brandName: data['brand_name'] ?? '',
          category: data['category'] ?? '',
          size: (data['size'] ?? 0).toInt(), // Fix: Convert to int.
          sizeRaw: data['sizeRaw'] ?? '',
          sizeUnit: data['sizeUnit'] ?? '',
          variety: data['variety'] ?? '',
          imageUrl:
              data['image_url'] ?? data['imageUrl'] ?? data['imageURL'] ?? '',
          isActive: data['is_active'] ?? false,
          createdAt: data['created_at'] ?? Timestamp.now(),
          updatedAt: data['updated_at'] ?? Timestamp.now(),
        );
      }).toList();

      _cache[cacheKey] = products;
      return products;
    } on FirebaseException catch (e) {
      // Common in dev: missing composite index for (category, is_active) with orderBy name.
      if (e.code == 'failed-precondition' ||
          e.message?.toLowerCase().contains('index') == true) {
        AppLogger.w(
          '[EnhancedProductService] Missing Firestore index for category browse. Falling back to local filter. Create a composite index: products(category ASC, is_active ASC, name ASC).',
        );
      } else {
        AppLogger.e(
          'Error fetching products by category: ${e.code} ${e.message}',
        );
      }
      // Fallback: load all active products and filter client-side (cached).
      try {
        final all = await getAllProducts();
        final filtered = all
            .where((p) => p.isActive && p.category == categoryId)
            .toList();
        _cache[cacheKey] = filtered;
        return filtered;
      } catch (inner) {
        AppLogger.e('Fallback filtering failed', error: inner);
        return _cache[cacheKey] ?? [];
      }
    } catch (e) {
      AppLogger.e('Error fetching products by category', error: e);
      // Final fallback to cache if available.
      return _cache[cacheKey] ?? [];
    }
  }

  // Get current prices using CORRECT database structure.
  static Future<Map<String, CurrentPrice>> getCurrentPricesForProduct(
    String productId,
  ) async {
    try {
      // Query using correct document structure: current_prices collection.
      // Document IDs are: {supermarketId}_{productId}.
      final querySnapshot = await _firestore
          .collection('current_prices')
          .where('productId', isEqualTo: productId)
          .get();

      final prices = <String, CurrentPrice>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final currentPrice = CurrentPrice(
          id: doc.id, // Document ID: "cargills_productId".
          supermarketId: data['supermarketId'] ?? '',
          productId: data['productId'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          priceDate: data['priceDate'] ?? '',
          lastUpdated: data['lastUpdated'] ?? '',
        );
        prices[currentPrice.supermarketId] = currentPrice;
      }

      return prices;
    } catch (e) {
      AppLogger.e('Error fetching prices', error: e);
      return {};
    }
  }

  /// Batch fetch current prices for multiple products using Firestore 'in' queries (chunked by 10).
  /// Returns a map: productId -> (storeId -> CurrentPrice).
  static Future<Map<String, Map<String, CurrentPrice>>>
  getCurrentPricesForProducts(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    // Helper to chunk to Firestore 'in' limit.
    List<List<String>> chunk(List<String> ids, int size) {
      final out = <List<String>>[];
      for (int i = 0; i < ids.length; i += size) {
        out.add(ids.sublist(i, i + size > ids.length ? ids.length : i + size));
      }
      return out;
    }

    final result = <String, Map<String, CurrentPrice>>{};
    try {
      final chunks = chunk(productIds, 10);
      for (final ids in chunks) {
        final snap = await _firestore
            .collection('current_prices')
            .where('productId', whereIn: ids)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final pid = data['productId'] ?? '';
          if (pid.isEmpty) continue;
          final storeId = data['supermarketId'] ?? '';
          final cp = CurrentPrice(
            id: doc.id,
            supermarketId: storeId,
            productId: pid,
            price: (data['price'] ?? 0).toDouble(),
            priceDate: data['priceDate'] ?? '',
            lastUpdated: data['lastUpdated'] ?? '',
          );
          (result[pid] ??= <String, CurrentPrice>{})[storeId] = cp;
        }
      }
    } catch (e) {
      AppLogger.e('Error batch fetching prices', error: e);
    }
    return result;
  }

  // Fetch a single product by its ID.
  static Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return Product(
        id: doc.id,
        name: data['name'] ?? '',
        originalName: data['original_name'] ?? '',
        brandName: data['brand_name'] ?? '',
        category: data['category'] ?? '',
        size: (data['size'] ?? 0).toInt(),
        sizeRaw: data['sizeRaw'] ?? '',
        sizeUnit: data['sizeUnit'] ?? '',
        variety: data['variety'] ?? '',
        imageUrl:
            data['image_url'] ?? data['imageUrl'] ?? data['imageURL'] ?? '',
        isActive: data['is_active'] ?? false,
        createdAt: data['created_at'] ?? Timestamp.now(),
        updatedAt: data['updated_at'] ?? Timestamp.now(),
      );
    } catch (e) {
      AppLogger.e('Error fetching product by id', error: e);
      return null;
    }
  }

  // Fetch multiple products by IDs using chunked 'in' queries (limit 10 per query).
  static Future<Map<String, Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    List<List<String>> chunk(List<String> list, int size) {
      final out = <List<String>>[];
      for (int i = 0; i < list.length; i += size) {
        out.add(
          list.sublist(i, i + size > list.length ? list.length : i + size),
        );
      }
      return out;
    }

    final results = <String, Product>{};
    try {
      for (final part in chunk(ids, 10)) {
        final snap = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: part)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          results[doc.id] = Product(
            id: doc.id,
            name: data['name'] ?? '',
            originalName: data['original_name'] ?? '',
            brandName: data['brand_name'] ?? '',
            category: data['category'] ?? '',
            size: (data['size'] ?? 0).toInt(),
            sizeRaw: data['sizeRaw'] ?? '',
            sizeUnit: data['sizeUnit'] ?? '',
            variety: data['variety'] ?? '',
            imageUrl:
                data['image_url'] ?? data['imageUrl'] ?? data['imageURL'] ?? '',
            isActive: data['is_active'] ?? false,
            createdAt: data['created_at'] ?? Timestamp.now(),
            updatedAt: data['updated_at'] ?? Timestamp.now(),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Error fetching products by IDs', error: e);
    }
    return results;
  }

  // Get categories using exact Firebase field names.
  static Future<List<Category>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('sort_order')
          .get();

      final categories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          displayName: data['display_name'] ?? '',
          description: data['description'] ?? '',
          isFood: data['is_food'] ?? false,
          sortOrder: data['sort_order'] ?? 0,
          createdAt: data['created_at'] ?? Timestamp.now(),
          updatedAt: data['updated_at'] ?? Timestamp.now(),
        );
      }).toList();

      return categories;
    } catch (e) {
      AppLogger.e('Error fetching categories', error: e);
      return [];
    }
  }

  // Search products with fuzzy matching and current prices.
  static Future<List<ProductWithPrices>> searchProductsWithPrices(
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    AppLogger.d('[SEARCH] Starting search for: "$query"');

    // Ensure products are loaded with timeout protection.
    List<Product> products;
    try {
      products = await getAllProducts().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.w(
            '[SEARCH] Product loading timed out, using cached products',
          );
          return _cache['all_products'] ?? [];
        },
      );
      AppLogger.d('[SEARCH] Loaded ${products.length} products for search');
    } catch (e) {
      AppLogger.e('[SEARCH] Error loading products: $e');
      products = _cache['all_products'] ?? [];
      AppLogger.d('[SEARCH] Using cached products: ${products.length}');
    }

    if (products.isEmpty) {
      AppLogger.w('[SEARCH] No products available for search');
      return [];
    }

    final searchResults = await AdvancedSearchEngine.performFuzzySearch(
      products: products,
      query: query,
      threshold: 0.3, // Lower threshold for broader results.
    );

    AppLogger.d(
      '[SEARCH] Fuzzy search returned ${searchResults.length} results for "$query"',
    );

    final top = searchResults.take(20).toList();
    final ids = top.map((p) => p.id).toList();

    // Log top search results for debugging.
    if (top.isNotEmpty) {
      final topNames = top
          .take(5)
          .map((p) => '${p.name} (${p.brandName})')
          .join(', ');
      AppLogger.d('[SEARCH] Top results: $topNames');
    }

    final batched = await getCurrentPricesForProducts(ids);

    return top
        .map((p) => ProductWithPrices(product: p, prices: batched[p.id] ?? {}))
        .toList();
  }

  // Clear cache when needed (uses existing SharedPreferences).
  static Future<void> clearCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products_cache_timestamp');
  }

  // Handle unbranded products (IDs start with "_").
  static bool isUnbrandedProduct(Product product) {
    return product.brandName.isEmpty || product.id.startsWith('_');
  }

  // Get display name with proper brand handling.
  static String getProductDisplayName(Product product) {
    if (isUnbrandedProduct(product)) {
      return product.name; // Just product name for unbranded.
    } else {
      return '${product.brandName} ${product.name}'; // Brand + product name.
    }
  }
}
