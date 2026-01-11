import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'enhanced_product_service.dart';
import '../core/backoff_scheduler.dart';

/// Tiny in-memory cache for product image URLs.
/// Avoids refetching documents while viewing a shopping list.
/// Keeps only a limited number to prevent unbounded growth.
class ProductImageCache {
  ProductImageCache._();
  static final ProductImageCache instance = ProductImageCache._();

  // Simple LRU using LinkedHashMap insertion order.
  final _cache = <String, String?>{};
  static const int _maxEntries = 120; // Generous for a single list view session.
  final Map<String, ValueNotifier<String?>> _notifiers = {};

  /// Get (and possibly fetch) the image URL for a product ID.
  Future<String?> getImageUrl(
    String productId, {
    bool forceRefresh = false,
  }) async {
    if (productId.isEmpty) return null;
    if (!forceRefresh && _cache.containsKey(productId)) {
      final val = _cache.remove(productId);
      _cache[productId] = val;
      return val;
    }
    try {
      final map = await EnhancedProductService.getProductsByIds([productId]);
      final product = map[productId];
      final url = product?.imageUrl.isNotEmpty == true
          ? product!.imageUrl
          : null;
      _insert(productId, url);
      if (url != null) {
        BackoffScheduler.instance.success('img:$productId');
      } else {
        // Schedule a future retry with backoff (silent).
        BackoffScheduler.instance.schedule(
          'img:$productId',
          () => getImageUrl(productId, forceRefresh: true),
        );
      }
      return url;
    } catch (e) {
      _insert(productId, null);
      BackoffScheduler.instance.schedule(
        'img:$productId',
        () => getImageUrl(productId, forceRefresh: true),
      );
      return null;
    }
  }

  void _insert(String k, String? v) {
    _cache[k] = v;
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    (_notifiers[k] ??= ValueNotifier<String?>(_cache[k])).value = v;
  }

  /// Return a cached URL synchronously if present (without triggering fetch).
  String? peek(String productId) {
    if (!_cache.containsKey(productId)) return null;
    final val = _cache.remove(productId); // Refresh LRU.
    _cache[productId] = val;
    return val;
  }

  Future<String?> retryIfNull(String productId) async {
    final existing = peek(productId);
    if (existing != null) return existing;
    return getImageUrl(productId, forceRefresh: true);
  }

  /// Obtain a ValueNotifier for a product's image URL that updates when fetched.
  ValueNotifier<String?> notifierFor(String productId) {
    if (_notifiers.containsKey(productId)) return _notifiers[productId]!;
    final n = ValueNotifier<String?>(_cache[productId]);
    _notifiers[productId] = n;
    return n;
  }

  /// Preload a batch of productIds (fire-and-forget recommended).
  Future<void> prefetch(List<String> productIds) async {
    final toFetch = productIds
        .where((id) => id.isNotEmpty && !_cache.containsKey(id))
        .toList();
    if (toFetch.isEmpty) return;
    try {
      final map = await EnhancedProductService.getProductsByIds(toFetch);
      for (final id in toFetch) {
        final p = map[id];
        _insert(id, p?.imageUrl.isNotEmpty == true ? p!.imageUrl : null);
      }
    } catch (_) {}
  }

  void clear() => _cache.clear();
}

/// Helper widget to render a circular product image using a cached URL future.
class ProductCircleImage extends StatelessWidget {
  final Future<String?> imageUrlFuture;
  final double size;
  const ProductCircleImage({
    super.key,
    required this.imageUrlFuture,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: imageUrlFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _placeholder();
        }
        final url = snap.data;
        if (url == null || url.isEmpty) {
          return _fallbackIcon();
        }
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: (size * 2).round(),
            memCacheHeight: (size * 2).round(),
            fadeInDuration: const Duration(milliseconds: 220),
            placeholder: (c, _) => _placeholder(),
            errorWidget: (c, _, __) => _fallbackIcon(),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFF444752), Color(0xFF2B2E36)]),
    ),
    alignment: Alignment.center,
    child: SizedBox(
      width: size * .4,
      height: size * .4,
      child: const CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _fallbackIcon() => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFFA06AFA), Color(0xFF6C3FBF)]),
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.shopping_bag_outlined,
      size: 20,
      color: Colors.white,
    ),
  );
}
