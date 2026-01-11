import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../product/product_image_cache.dart';
import '../../utils/app_logger.dart';

/// Preview data for a shopping list card.
class ListItemPreview {
  final String itemId;
  final String productId;
  final String name;
  final String? imageUrl;
  final bool isCompleted;
  final int order;

  const ListItemPreview({
    required this.itemId,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.isCompleted,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'productId': productId,
    'name': name,
    'imageUrl': imageUrl,
    'isCompleted': isCompleted,
    'order': order,
  };

  factory ListItemPreview.fromJson(Map<String, dynamic> json) => ListItemPreview(
    itemId: json['itemId'] ?? '',
    productId: json['productId'] ?? '',
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'],
    isCompleted: json['isCompleted'] ?? false,
    order: json['order'] ?? 0,
  );
  
  ListItemPreview copyWith({String? imageUrl, bool? isCompleted}) => ListItemPreview(
    itemId: itemId,
    productId: productId,
    name: name,
    imageUrl: imageUrl ?? this.imageUrl,
    isCompleted: isCompleted ?? this.isCompleted,
    order: order,
  );
}

/// Caches item previews (first N items with images) for shopping list cards.
/// Provides instant display without loading spinners.
/// Supports real-time updates via Firestore streams.
class ListItemPreviewCache {
  ListItemPreviewCache._();
  static final ListItemPreviewCache instance = ListItemPreviewCache._();

  static final _firestore = FirebaseFirestore.instance;
  
  // In-memory cache: listId -> list of previews.
  final Map<String, List<ListItemPreview>> _cache = {};
  
  // Active stream subscriptions for real-time updates.
  final Map<String, StreamSubscription<QuerySnapshot>> _subscriptions = {};
  
  // Notifiers for reactive UI updates.
  final Map<String, ValueNotifier<List<ListItemPreview>>> _notifiers = {};
  
  // Max items to preview per list.
  static const int maxPreviewItems = 6;
  
  // Persistence key.
  static const String _prefsKey = 'list_item_previews_v2';
  
  /// Get previews for a list synchronously (from cache).
  List<ListItemPreview> get(String listId) => _cache[listId] ?? const [];
  
  /// Get images only (filtered for non-null URLs).
  List<String> getImages(String listId) {
    return (_cache[listId] ?? const [])
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) => p.imageUrl!)
        .toList();
  }
  
  /// Get a reactive notifier for a list's previews.
  ValueNotifier<List<ListItemPreview>> notifierFor(String listId) {
    return _notifiers[listId] ??= ValueNotifier(_cache[listId] ?? const []);
  }
  
  /// Subscribe to real-time item updates for a list.
  void subscribeToList(String listId) {
    if (_subscriptions.containsKey(listId)) return;
    
    AppLogger.d('[PREVIEW_CACHE] Subscribing to real-time updates for $listId');
    
    _subscriptions[listId] = _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('items')
        .orderBy('order')
        .limit(maxPreviewItems * 2) // Fetch extra to filter for those with productId.
        .snapshots()
        .listen(
          (snap) => _processSnapshot(listId, snap),
          onError: (e) => AppLogger.w('[PREVIEW_CACHE] Stream error for $listId: $e'),
        );
  }
  
  /// Unsubscribe from a list's updates.
  void unsubscribeFromList(String listId) {
    _subscriptions[listId]?.cancel();
    _subscriptions.remove(listId);
  }
  
  /// Process a snapshot and update previews.
  Future<void> _processSnapshot(String listId, QuerySnapshot snap) async {
    try {
      final docs = snap.docs;
      final previews = <ListItemPreview>[];
      final productIds = <String>[];
      
      for (final doc in docs) {
        if (previews.length >= maxPreviewItems) break;
        
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String?;
        
        // Only include items with productId (they have images).
        if (productId == null || productId.isEmpty) continue;
        
        productIds.add(productId);
        previews.add(ListItemPreview(
          itemId: doc.id,
          productId: productId,
          name: data['name'] as String? ?? '',
          imageUrl: ProductImageCache.instance.peek(productId),
          isCompleted: data['isCompleted'] as bool? ?? false,
          order: data['order'] as int? ?? 0,
        ));
      }
      
      // Prefetch images for new products.
      final missingImages = productIds.where(
        (id) => ProductImageCache.instance.peek(id) == null
      ).toList();
      
      if (missingImages.isNotEmpty) {
        await ProductImageCache.instance.prefetch(missingImages);
        
        // Update previews with fetched URLs.
        final updatedPreviews = previews.map((p) {
          final url = ProductImageCache.instance.peek(p.productId);
          return url != null && url != p.imageUrl ? p.copyWith(imageUrl: url) : p;
        }).toList();
        
        _cache[listId] = updatedPreviews;
        _notifiers[listId]?.value = updatedPreviews;
      } else {
        _cache[listId] = previews;
        _notifiers[listId]?.value = previews;
      }
      
      _schedulePersist();
      AppLogger.d('[PREVIEW_CACHE] Updated ${previews.length} previews for $listId');
    } catch (e) {
      AppLogger.w('[PREVIEW_CACHE] Error processing snapshot for $listId: $e');
    }
  }
  
  /// Prefetch previews for multiple lists (one-time fetch, no subscription).
  Future<void> prefetchForLists(List<dynamic> lists) async {
    final listIds = lists.map((l) {
      if (l is String) return l;
      // Handle ShoppingList objects.
      try {
        return (l as dynamic).id as String;
      } catch (_) {
        return '';
      }
    }).where((id) => id.isNotEmpty && !_cache.containsKey(id)).toList();
    
    if (listIds.isEmpty) return;
    
    // Fetch in parallel.
    await Future.wait(listIds.map((id) => _fetchOnce(id)));
  }
  
  /// One-time fetch for a list (no subscription).
  Future<void> _fetchOnce(String listId) async {
    try {
      final itemsSnap = await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .orderBy('order')
          .limit(maxPreviewItems * 2)
          .get();
      
      if (itemsSnap.docs.isEmpty) {
        _cache[listId] = const [];
        _notifiers[listId]?.value = const [];
        return;
      }
      
      final previews = <ListItemPreview>[];
      final productIds = <String>[];
      
      for (final doc in itemsSnap.docs) {
        if (previews.length >= maxPreviewItems) break;
        
        final data = doc.data();
        final productId = data['productId'] as String?;
        if (productId == null || productId.isEmpty) continue;
        
        productIds.add(productId);
        previews.add(ListItemPreview(
          itemId: doc.id,
          productId: productId,
          name: data['name'] as String? ?? '',
          imageUrl: null,
          isCompleted: data['isCompleted'] as bool? ?? false,
          order: data['order'] as int? ?? 0,
        ));
      }
      
      if (productIds.isEmpty) {
        _cache[listId] = const [];
        _notifiers[listId]?.value = const [];
        return;
      }
      
      // Prefetch images
      await ProductImageCache.instance.prefetch(productIds);
      
      // Update with URLs
      final updatedPreviews = previews.map((p) {
        final url = ProductImageCache.instance.peek(p.productId);
        return p.copyWith(imageUrl: url);
      }).toList();
      
      _cache[listId] = updatedPreviews;
      _notifiers[listId]?.value = updatedPreviews;
      _schedulePersist();
      
      AppLogger.d('[PREVIEW_CACHE] Fetched ${updatedPreviews.length} previews for $listId');
    } catch (e) {
      AppLogger.w('[PREVIEW_CACHE] Failed to fetch for $listId: $e');
    }
  }
  
  /// Force refresh previews for a list.
  Future<void> refresh(String listId) async {
    await _fetchOnce(listId);
  }
  
  /// Invalidate cache for a list.
  void invalidate(String listId) {
    _cache.remove(listId);
    _notifiers[listId]?.value = const [];
  }
  
  /// Clear all cache and subscriptions.
  void clear() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _cache.clear();
    for (final n in _notifiers.values) {
      n.value = const [];
    }
  }
  
  // --- Persistence ---
  Timer? _persistDebounce;
  
  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 500), _persistNow);
  }
  
  Future<void> _persistNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final entry in _cache.entries) {
        data[entry.key] = entry.value.map((p) => p.toJson()).toList();
      }
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (_) {}
  }
  
  /// Hydrate from local storage for instant cold start.
  Future<void> hydrateFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final listId = entry.key;
        final items = (entry.value as List<dynamic>)
            .map((e) => ListItemPreview.fromJson(e as Map<String, dynamic>))
            .toList();
        _cache[listId] = items;
        _notifiers[listId]?.value = items;
      }
      
      AppLogger.d('[PREVIEW_CACHE] Hydrated ${_cache.length} lists from local');
    } catch (_) {}
  }
}
