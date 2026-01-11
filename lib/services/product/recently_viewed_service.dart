import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/product/current_price_cache.dart';
import 'package:shopple/config/feature_flags.dart';
import 'package:shopple/services/product/cloud_recently_viewed_service.dart';
import 'package:shopple/utils/app_logger.dart';

class RecentlyViewedService {
  static const String _key = 'recently_viewed_product_ids_v1';
  static const String _snapshotsKey = 'recently_viewed_snapshots_v1';
  static const int _maxItems = 30;
  // In-memory caches for ultra-fast access (<50ms)
  static List<String>? _idsCache;
  static Map<String, dynamic>? _snapshotsCache;
  static Timer? _cloudPushDebounce; // debounce timer for cloud id pushes
  static List<String>? _pendingIdsForPush; // last ids awaiting push

  static Future<void> add(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final List<String> ids = raw != null
          ? List<String>.from(jsonDecode(raw))
          : <String>[];
      ids.remove(productId);
      ids.insert(0, productId);
      final trimmed = ids.take(_maxItems).toList();
      // Fire-and-forget to minimize jank on hot path
      // ignore: unawaited_futures
      prefs.setString(_key, jsonEncode(trimmed));
      _idsCache = trimmed; // update memory cache immediately
      if (kDebugMode) {
        AppLogger.d(
          '[RecentlyViewed] add("$productId") -> ${trimmed.length} ids (top=${trimmed.isNotEmpty ? trimmed.first : 'none'})',
        );
      }
      if (FeatureFlags.enableCloudRecentlyViewed) {
        // Debounce cloud updates (rapid consecutive product opens)
        _pendingIdsForPush = trimmed;
        _cloudPushDebounce?.cancel();
        _cloudPushDebounce = Timer(const Duration(milliseconds: 650), () {
          final ids = _pendingIdsForPush;
          if (ids != null) {
            // ignore: unawaited_futures
            CloudRecentlyViewedService.pushIds(ids);
          }
        });
      }

      // Also ensure a lightweight snapshot exists (fire-and-forget)
      // ignore: unawaited_futures
      _ensureSnapshot(productId);
    } catch (_) {}
  }

  /// Add a snapshot immediately when we already have the product loaded (fast path)
  static Future<void> addSnapshot(
    Product product, {
    CurrentPrice? cheapest,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotsKey);
      final Map<String, dynamic> snapshots = raw != null
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : <String, dynamic>{};
      snapshots[product.id] = {
        'id': product.id,
        'name': product.name,
        'original_name': product.originalName,
        'brand_name': product.brandName,
        'category': product.category,
        'size': product.size,
        'sizeRaw': product.sizeRaw,
        'sizeUnit': product.sizeUnit,
        'variety': product.variety,
        'image_url': product.imageUrl,
        'is_active': product.isActive,
        if (cheapest != null)
          'cheapest': {
            'store': cheapest.supermarketId,
            'price': cheapest.price,
            'id': cheapest.id,
            'priceDate': cheapest.priceDate,
            'lastUpdated': cheapest.lastUpdated,
          },
      };
      // Update memory cache and write in background
      _snapshotsCache = snapshots;
      // ignore: unawaited_futures
      prefs.setString(_snapshotsKey, jsonEncode(snapshots));
      if (kDebugMode) {
        AppLogger.d(
          '[RecentlyViewed] addSnapshot(${product.id}) stored snapshot (total=${snapshots.length})',
        );
      }
    } catch (_) {}
  }

  /// Ensure a snapshot exists by fetching minimal data in the background
  static Future<void> _ensureSnapshot(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotsKey);
      final Map<String, dynamic> snapshots = raw != null
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : <String, dynamic>{};
      if (snapshots.containsKey(productId)) return;

      final map = await EnhancedProductService.getProductsByIds([productId]);
      final p = map[productId];
      if (p == null) return;
      // Use shared reactive cache instead of direct fetch
      await CurrentPriceCache.instance.prime([productId]);
      CurrentPrice? cheapest;
      final storePrices = CurrentPriceCache.instance.pricesFor(productId) ?? {};
      for (final cp in storePrices.values) {
        if (cheapest == null || cp.price < cheapest.price) cheapest = cp;
      }

      snapshots[productId] = {
        'id': p.id,
        'name': p.name,
        'original_name': p.originalName,
        'brand_name': p.brandName,
        'category': p.category,
        'size': p.size,
        'sizeRaw': p.sizeRaw,
        'sizeUnit': p.sizeUnit,
        'variety': p.variety,
        'image_url': p.imageUrl,
        'is_active': p.isActive,
        if (cheapest != null)
          'cheapest': {
            'store': cheapest.supermarketId,
            'price': cheapest.price,
            'id': cheapest.id,
            'priceDate': cheapest.priceDate,
            'lastUpdated': cheapest.lastUpdated,
          },
      };
      await prefs.setString(_snapshotsKey, jsonEncode(snapshots));
    } catch (_) {}
  }

  static Future<List<String>> getIds({int limit = 20}) async {
    try {
      if (_idsCache != null) {
        return _idsCache!.take(limit).toList();
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final List<String> ids = raw != null
          ? List<String>.from(jsonDecode(raw))
          : <String>[];
      _idsCache = ids;
      if (kDebugMode) {
        AppLogger.d(
          '[RecentlyViewed] getIds() loaded ${ids.length} from prefs',
        );
      }
      return ids.take(limit).toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<List<ProductWithPrices>> getWithPrices({int limit = 20}) async {
    // Fast path: build from local snapshots only (<50ms)
    final ids = await getIds(limit: limit);
    List<String> effectiveIds = ids;
    if (ids.isEmpty && FeatureFlags.enableCloudRecentlyViewed) {
      final cloudIds = await CloudRecentlyViewedService.fetchIds();
      if (cloudIds.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // ignore: unawaited_futures
        prefs.setString(_key, jsonEncode(cloudIds));
        _idsCache = cloudIds;
        effectiveIds = cloudIds.take(limit).toList();
      }
    }
    if (effectiveIds.isEmpty) return <ProductWithPrices>[];
    if (kDebugMode) {
      AppLogger.d(
        '[RecentlyViewed] getWithPrices() effectiveIds=${effectiveIds.length}',
      );
    }

    // Use memory cache if present for sub-50ms response
    Map<String, dynamic> snapshots;
    if (_snapshotsCache != null) {
      snapshots = _snapshotsCache!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotsKey);
      snapshots = raw != null
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : <String, dynamic>{};
      _snapshotsCache = snapshots;
    }

    final products = <ProductWithPrices>[];
    // Opportunistically fetch missing cloud snapshots in background (stealth)
    if (FeatureFlags.enableCloudRecentlyViewed) {
      final missing = effectiveIds
          .where((id) => !snapshots.containsKey(id))
          .toList();
      if (missing.isNotEmpty) {
        // ignore: unawaited_futures
        () async {
          try {
            final cloudSnaps = await CloudRecentlyViewedService.fetchSnapshots(
              missing,
            );
            if (cloudSnaps.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              snapshots.addAll(cloudSnaps);
              _snapshotsCache = snapshots;
              // Persist silently
              await prefs.setString(_snapshotsKey, jsonEncode(snapshots));
            }
          } catch (_) {}
        }();
      }
    }
    for (final id in effectiveIds) {
      final snap = snapshots[id];
      if (snap is Map<String, dynamic>) {
        final p = Product.fromMap(snap);
        if (!p.isActive) {
          // Show inactive product with empty prices (unavailable)
          products.add(ProductWithPrices(product: p, prices: const {}));
          continue;
        }
        final prices = <String, CurrentPrice>{};
        final cheapest = snap['cheapest'];
        if (cheapest is Map<String, dynamic>) {
          final store = cheapest['store']?.toString() ?? '';
          final price = (cheapest['price'] as num?)?.toDouble();
          if (store.isNotEmpty && price != null) {
            prices[store] = CurrentPrice(
              id: (cheapest['id']?.toString() ?? '${store}_${p.id}'),
              supermarketId: store,
              productId: p.id,
              price: price,
              priceDate: cheapest['priceDate']?.toString() ?? '',
              lastUpdated: cheapest['lastUpdated']?.toString() ?? '',
            );
          }
        }
        products.add(ProductWithPrices(product: p, prices: prices));
      }
    }

    // If we built anything from snapshots, return immediately (ultra-fast)
    if (products.isNotEmpty) {
      // Background refresh snapshots for next time (do not block)
      // ignore: unawaited_futures
      _refreshSnapshots(effectiveIds);
      return products;
    }

    // Fallback: fetch from Firestore (first-time users)
    final productsMap = await EnhancedProductService.getProductsByIds(
      effectiveIds,
    );
    await CurrentPriceCache.instance.prime(effectiveIds);
    for (final id in effectiveIds) {
      final p = productsMap[id];
      if (p == null) continue;
      if (!p.isActive) {
        products.add(ProductWithPrices(product: p, prices: const {}));
      } else {
        products.add(
          ProductWithPrices(
            product: p,
            prices: CurrentPriceCache.instance.pricesFor(id) ?? {},
          ),
        );
      }
    }
    // Update snapshots for future instant loads
    // ignore: unawaited_futures
    _saveSnapshotsFromData(products);
    return products;
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_snapshotsKey);
      _idsCache = null;
      _snapshotsCache = null;
      if (kDebugMode) {
        AppLogger.d('[RecentlyViewed] clear() local caches & prefs removed');
      }
      if (FeatureFlags.enableCloudRecentlyViewed) {
        // ignore: unawaited_futures
        CloudRecentlyViewedService.clearAll();
      }
    } catch (_) {}
  }

  static Future<void> _refreshSnapshots(List<String> ids) async {
    try {
      final productsMap = await EnhancedProductService.getProductsByIds(ids);
      await CurrentPriceCache.instance.prime(ids);
      final items = <ProductWithPrices>[];
      for (final id in ids) {
        final p = productsMap[id];
        if (p == null) continue;
        items.add(
          ProductWithPrices(
            product: p,
            prices: CurrentPriceCache.instance.pricesFor(id) ?? {},
          ),
        );
      }
      await _saveSnapshotsFromData(items);
    } catch (_) {}
  }

  static Future<void> _saveSnapshotsFromData(
    List<ProductWithPrices> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotsKey);
      final Map<String, dynamic> snapshots = raw != null
          ? Map<String, dynamic>.from(jsonDecode(raw))
          : <String, dynamic>{};
      for (final item in items) {
        final p = item.product;
        CurrentPrice? cheapest;
        for (final cp in item.prices.values) {
          if (cheapest == null || cp.price < cheapest.price) cheapest = cp;
        }
        snapshots[p.id] = {
          'id': p.id,
          'name': p.name,
          'original_name': p.originalName,
          'brand_name': p.brandName,
          'category': p.category,
          'size': p.size,
          'sizeRaw': p.sizeRaw,
          'sizeUnit': p.sizeUnit,
          'variety': p.variety,
          'image_url': p.imageUrl,
          'is_active': p.isActive,
          if (cheapest != null)
            'cheapest': {
              'store': cheapest.supermarketId,
              'price': cheapest.price,
              'id': cheapest.id,
              'priceDate': cheapest.priceDate,
              'lastUpdated': cheapest.lastUpdated,
            },
        };
        if (FeatureFlags.enableCloudRecentlyViewed) {
          // ignore: unawaited_futures
          CloudRecentlyViewedService.saveSnapshot(
            p.id,
            snapshots[p.id] as Map<String, dynamic>,
          );
        }
      }
      _snapshotsCache = snapshots;
      await prefs.setString(_snapshotsKey, jsonEncode(snapshots));
      if (kDebugMode) {
        AppLogger.d(
          '[RecentlyViewed] _saveSnapshotsFromData() persisted ${snapshots.length} snapshots',
        );
      }
    } catch (_) {}
  }

  /// Debug helper to print current stored ids & snapshot keys (call in debug builds only)
  static Future<void> debugDump() async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawIds = prefs.getString(_key);
      final rawSnaps = prefs.getString(_snapshotsKey);
      final ids = rawIds != null
          ? List<String>.from(jsonDecode(rawIds))
          : <String>[];
      final snaps = rawSnaps != null
          ? Map<String, dynamic>.from(jsonDecode(rawSnaps))
          : <String, dynamic>{};
      AppLogger.d('[RecentlyViewed][DUMP] ids(${ids.length}): $ids');
      AppLogger.d(
        '[RecentlyViewed][DUMP] snapshots keys(${snaps.length}): ${snaps.keys.take(10).toList()}',
      );
    } catch (e) {
      AppLogger.w('[RecentlyViewed][DUMP] error: $e');
    }
  }
}
