import 'dart:collection';
import '../../models/product_model.dart';
import 'enhanced_product_service.dart';

/// Lightweight in-memory cache for Product documents with background stealth refresh.
/// Returns cached product instantly (if present) while triggering a silent refresh
/// in the background when the entry is stale. Avoids UI jank while keeping data fresh.
class ProductDetailsCache {
  ProductDetailsCache._();
  static final ProductDetailsCache instance = ProductDetailsCache._();

  // Explicit LinkedHashMap to guarantee predictable insertion order for LRU eviction
  final LinkedHashMap<String, _Entry> _cache = LinkedHashMap();
  static const _maxEntries = 250; // generous; LRU eviction
  static const _staleAfter = Duration(minutes: 10);

  Future<Product?> get(String productId) async {
    if (productId.isEmpty) return null;
    final now = DateTime.now();
    final existing = _cache[productId];
    if (existing != null) {
      // Move to end (LRU)
      _cache.remove(productId);
      _cache[productId] = existing;
      // Trigger stealth refresh if stale but return old immediately
      if (now.difference(existing.fetchedAt) > _staleAfter) {
        _stealthRefresh(productId);
      }
      return existing.product;
    }
    // Not cached: fetch, insert, return.
    final product = await EnhancedProductService.getProductById(productId);
    _insert(productId, product);
    return product;
  }

  Future<void> prefetch(List<String> productIds) async {
    final toFetch = productIds
        .where((id) => id.isNotEmpty && !_cache.containsKey(id))
        .toList();
    if (toFetch.isEmpty) return;
    try {
      final map = await EnhancedProductService.getProductsByIds(toFetch);
      map.forEach((id, prod) => _insert(id, prod));
    } catch (_) {}
  }

  void clear() {
    _cache.clear();
  }

  void _insert(String id, Product? product) {
    _cache[id] = _Entry(product, DateTime.now());
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  void _stealthRefresh(String id) {
    // Fire-and-forget; ignore errors.
    EnhancedProductService.getProductById(id).then((p) {
      if (p != null) {
        _insert(id, p);
      }
    });
  }
}

class _Entry {
  final Product? product;
  final DateTime fetchedAt;
  _Entry(this.product, this.fetchedAt);
}
