import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_lists/shopping_list_item_model.dart';
import '../services/shopping_lists/shopping_list_service.dart';
import '../services/product/product_image_cache.dart';
import '../services/product/current_price_cache.dart';
import '../utils/app_logger.dart';

enum ItemSortMode { manual, name, priceAsc, priceDesc, recentlyAdded }

class ShoppingListItemsController extends ChangeNotifier {
  final String listId;
  late final StreamSubscription<List<ShoppingListItem>> _sub;
  List<ShoppingListItem> _serverItems = [];
  final Map<String, ShoppingListItem> _optimisticAdds = {};
  final Map<String, ShoppingListItem> _optimisticUpdates = {};
  final Set<String> _optimisticCompleted = {};
  final Set<String> _optimisticUncompleted = {};
  // Track the intended completion state while a toggle is in-flight so UI doesn't revert
  final Map<String, bool> _pendingCompletionTargets =
      {}; // itemId -> desired isCompleted
  final Map<String, ShoppingListItem> _optimisticDeletes = {};
  final Set<String> _toggleInFlight =
      {}; // prevent rapid double-toggles per item
  bool selectionMode = false;
  final Set<String> selectedIds = {};
  ShoppingListItem? _lastDeleted;

  // Pricing cache (cheapest per productId)
  final Map<String, double> _cheapestPrice = {}; // productId -> price
  final Map<String, String> _cheapestStore = {}; // productId -> storeId
  final Map<String, String?> _productImages =
      {}; // productId -> image url (null if none)
  bool _infillRunning = false; // guard for price infill writes

  // Filtering / sorting state
  ItemSortMode sortMode = ItemSortMode.manual;
  String? filterCategory; // null == all
  String? filterStore; // storeId
  bool splitByStore =
      false; // when true, ignore filterStore and split list into store sections

  ShoppingListItemsController(this.listId) {
    _sub = ShoppingListService.listItemsStream(listId).listen(_onServerItems);
    _loadPrefs();
    // Eagerly fetch initial items to avoid first-frame delay before stream emits
    _preloadInitial();
  }

  bool _hasStreamEvent = false;

  Future<void> _preloadInitial() async {
    try {
      final initial = await ShoppingListService.getListItems(listId);
      if (initial.isEmpty) return;
      if (_hasStreamEvent) return; // stream already delivered; skip
      _serverItems = initial;
      // Prime images and prices so UI feels instant
      final productIds = initial
          .where((e) => e.productId != null)
          .map((e) => e.productId!)
          .toList();
      if (productIds.isNotEmpty) {
        // ignore: discarded_futures
        ProductImageCache.instance.prefetch(productIds).then((_) async {
          bool changed = false;
          for (final id in productIds) {
            final url = ProductImageCache.instance.peek(id);
            if (url != null && _productImages[id] != url) {
              _productImages[id] = url;
              changed = true;
              _predownloadImage(url);
            }
          }
          if (changed) notifyListeners();
        });
        // ignore: discarded_futures
        CurrentPriceCache.instance.prime(productIds).then((map) {
          bool changed = false;
          map.forEach((pid, price) {
            if (_cheapestPrice[pid] != price) {
              _cheapestPrice[pid] = price;
              changed = true;
            }
          });
          if (changed) notifyListeners();
          // After we learned prices, try to infill missing estimatedPrice to persist totals
          // ignore: discarded_futures
          _maybeInfillEstimatedPrices();
        });
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('list:$listId:sortMode');
      if (modeStr != null) {
        final m = ItemSortMode.values.firstWhere(
          (e) => e.toString().split('.').last == modeStr,
          orElse: () => ItemSortMode.manual,
        );
        if (m != sortMode) {
          sortMode = m;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _onServerItems(List<ShoppingListItem> items) {
    _hasStreamEvent = true;
    AppLogger.d('Received ${items.length} items from server');
    _serverItems = items;
    // Reconcile optimistic state with server; clear flags when synced
    if (_pendingCompletionTargets.isNotEmpty) {
      AppLogger.d(
        'Reconciling ${_pendingCompletionTargets.length} pending targets',
      );
      final completedTargets = <String>[];
      for (final itm in items) {
        final target = _pendingCompletionTargets[itm.id];
        if (target != null) {
          final inFlight = _toggleInFlight.contains(itm.id);
          AppLogger.d(
            'Item ${itm.id}: server=${itm.isCompleted}, target=$target, inFlight=$inFlight',
          );
          if (itm.isCompleted == target && !inFlight) {
            completedTargets.add(itm.id);
            AppLogger.d(
              'Will clear optimistic state for ${itm.id} (target achieved)',
            );
          }
        }
      }
      // Clear completed targets
      for (final id in completedTargets) {
        _pendingCompletionTargets.remove(id);
        _optimisticCompleted.remove(id);
        _optimisticUncompleted.remove(id);
        AppLogger.d('Cleared optimistic state for $id');
      }
    }
    // Fire-and-forget prefetch of product images with aggressive caching
    // ignore: discarded_futures
    final productIds = items
        .where((e) => e.productId != null)
        .map((e) => e.productId!)
        .toList();
    // Fire-and-forget prefetch and immediate download for instant paint
    // ignore: discarded_futures
    ProductImageCache.instance.prefetch(productIds).then((_) {
      bool changed = false;
      for (final id in productIds) {
        final url = ProductImageCache.instance.peek(id);
        if (url != null && _productImages[id] != url) {
          _productImages[id] = url;
          changed = true;
          // Aggressively download to system cache for instant paint
          _predownloadImage(url);
        }
      }
      if (changed) {
        notifyListeners();
      }
      // Schedule a retry for any still-null after short delay (in case of late writes)
      final missing = productIds
          .where((id) => _productImages[id] == null)
          .toList();
      if (missing.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          bool updated = false;
          for (final id in missing) {
            final refreshed = await ProductImageCache.instance.retryIfNull(id);
            if (refreshed != null) {
              _productImages[id] = refreshed;
              updated = true;
              // Aggressively download for instant future access
              _predownloadImage(refreshed);
            }
          }
          if (updated) notifyListeners();
        });
      }
    });
    // Fire-and-forget price fetch
    _fetchCheapestPrices();
    notifyListeners();
  }

  Future<void> _fetchCheapestPrices() async {
    final productIds = _serverItems
        .where((e) => e.productId != null)
        .map((e) => e.productId!)
        .toSet()
        .toList();
    if (productIds.isEmpty) return;
    try {
      final map = await CurrentPriceCache.instance.prime(productIds);
      bool changed = false;
      for (final pid in productIds) {
        final cheapest = map[pid];
        if (cheapest != null && _cheapestPrice[pid] != cheapest) {
          _cheapestPrice[pid] = cheapest;
          changed = true;
          // Update cheapest store id based on loaded prices
          _updateCheapestStoreFor(pid);
        }
      }
      if (changed) notifyListeners();
      // Now that we have prices, infill any items with missing estimatedPrice
      // ignore: discarded_futures
      _maybeInfillEstimatedPrices();
    } catch (_) {}
  }

  /// Persist cheapest known prices into item.estimatedPrice when it's zero.
  /// This keeps list aggregates current so cards can show Rs totals.
  Future<void> _maybeInfillEstimatedPrices() async {
    if (_infillRunning) return;
    // Build candidates list from latest server items
    final candidates = <ShoppingListItem>[];
    for (final it in _serverItems) {
      final pid = it.productId;
      if (pid == null) continue;
      if ((it.estimatedPrice).abs() > 0.0001) continue; // already has price
      final price = _cheapestPrice[pid];
      if (price != null && price > 0) {
        candidates.add(it);
      }
    }
    if (candidates.isEmpty) return;
    _infillRunning = true;
    try {
      // Limit batch size to reduce write burst; leftovers will be handled in future cycles
      for (final it in candidates.take(12)) {
        final pid = it.productId!;
        final price = _cheapestPrice[pid];
        if (price == null || price <= 0) continue;
        await ShoppingListService.updateItem(
          listId: listId,
          itemId: it.id,
          estimatedPrice: price,
        );
      }
    } catch (_) {
      // ignore errors, will retry on next refresh
    } finally {
      _infillRunning = false;
    }
  }

  List<ShoppingListItem> get mergedItems {
    var base = _serverItems
        .where((i) => !_optimisticDeletes.containsKey(i.id))
        .map((i) {
          var item = i;
          if (_optimisticUpdates.containsKey(i.id)) {
            item = _optimisticUpdates[i.id]!;
          }
          if (_optimisticCompleted.contains(i.id)) {
            item = item.copyWith(isCompleted: true);
          }
          if (_optimisticUncompleted.contains(i.id)) {
            item = item.copyWith(isCompleted: false);
          }
          return item;
        })
        .toList();
    base.addAll(_optimisticAdds.values);
    // Filter
    if (filterCategory != null) {
      base = base.where((i) => i.category == filterCategory).toList();
    }
    if (filterStore != null) {
      base = base
          .where(
            (i) =>
                i.productId == null ||
                _cheapestStore[i.productId] == filterStore,
          )
          .toList();
    }
    // Sort
    switch (sortMode) {
      case ItemSortMode.manual:
        base.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          final o = a.order.compareTo(b.order);
          if (o != 0) return o;
          return a.name.compareTo(b.name);
        });
        break;
      case ItemSortMode.name:
        base.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ItemSortMode.priceAsc:
        base.sort((a, b) {
          final ap = _cheapestPrice[a.productId] ?? a.estimatedPrice;
          final bp = _cheapestPrice[b.productId] ?? b.estimatedPrice;
          return ap.compareTo(bp);
        });
        break;
      case ItemSortMode.priceDesc:
        base.sort((a, b) {
          final ap = _cheapestPrice[a.productId] ?? a.estimatedPrice;
          final bp = _cheapestPrice[b.productId] ?? b.estimatedPrice;
          return bp.compareTo(ap);
        });
        break;
      case ItemSortMode.recentlyAdded:
        base.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
    }
    return base;
  }

  Map<String, List<ShoppingListItem>> groupedByCategory(
    List<ShoppingListItem> items,
  ) {
    final map = <String, List<ShoppingListItem>>{};
    for (final i in items) {
      final key = i.category.isEmpty ? 'other' : i.category;
      map.putIfAbsent(key, () => []).add(i);
    }
    return map;
  }

  // Public accessors for cheapest data
  double? cheapestPriceFor(String? productId) =>
      productId == null ? null : _cheapestPrice[productId];
  String? cheapestStoreFor(String? productId) =>
      productId == null ? null : _cheapestStore[productId];
  String? imageFor(String? productId) =>
      productId == null ? null : _productImages[productId];

  List<String> get availableStores => _cheapestStore.values.toSet().toList();
  // Group items by their cheapest known store id (lowercased keys)
  Map<String, List<ShoppingListItem>> groupedByCheapestStore(
    List<ShoppingListItem> items,
  ) {
    final map = <String, List<ShoppingListItem>>{};
    for (final i in items) {
      final pid = i.productId;
      final store =
          (pid == null ? 'unknown' : (_cheapestStore[pid] ?? 'unknown'))
              .toLowerCase();
      map.putIfAbsent(store, () => []).add(i);
    }
    return map;
  }

  void setSortMode(ItemSortMode mode) async {
    sortMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'list:$listId:sortMode',
        mode.toString().split('.').last,
      );
    } catch (_) {}
  }

  void setFilterCategory(String? cat) {
    filterCategory = cat;
    notifyListeners();
  }

  void setFilterStore(String? store) {
    filterStore = store;
    notifyListeners();
  }

  void setSplitByStore(bool value) {
    splitByStore = value;
    if (value) filterStore = null;
    notifyListeners();
  }

  void _updateCheapestStoreFor(String productId) {
    final prices = CurrentPriceCache.instance.pricesFor(productId);
    if (prices == null || prices.isEmpty) return;
    String? minStore;
    double minPrice = double.infinity;
    prices.forEach((storeId, cp) {
      if (cp.price < minPrice) {
        minPrice = cp.price;
        minStore = storeId;
      }
    });
    if (minStore != null && _cheapestStore[productId] != minStore) {
      _cheapestStore[productId] = minStore!;
    }
  }

  Future<void> addItemOptimistic({
    required String name,
    required int quantity,
    required double price,
    required String notes,
  }) async {
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final temp = ShoppingListItem(
      id: tempId,
      listId: listId,
      name: name,
      quantity: quantity,
      estimatedPrice: price,
      notes: notes,
      addedBy: 'me',
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isCompleted: false,
      category: 'other',
      order: mergedItems.length + 1,
    );
    _optimisticAdds[tempId] = temp;
    notifyListeners();
    try {
      await ShoppingListService.addCustomItemToList(
        listId: listId,
        name: name,
        quantity: quantity,
        estimatedPrice: price,
        notes: notes,
      );
      _optimisticAdds.remove(tempId);
    } catch (e) {
      _optimisticAdds.remove(tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleItemOptimistic(ShoppingListItem item) async {
    AppLogger.d(
      'Toggle request for item ${item.id}, current isCompleted: ${item.isCompleted}',
    );

    if (_toggleInFlight.contains(item.id)) {
      AppLogger.d('Toggle ignored - already in flight for item ${item.id}');
      return; // ignore rapid re-tap while pending
    }

    // Determine the new intended state (toggle current effective state)
    final effectiveCompleted =
        item.isCompleted || _optimisticCompleted.contains(item.id);
    final newStatus = !effectiveCompleted;
    AppLogger.d(
      'Setting pending target for ${item.id}: $newStatus (was effectively: $effectiveCompleted)',
    );

    _pendingCompletionTargets[item.id] = newStatus;

    // Apply optimistic overlay immediately
    if (newStatus) {
      _optimisticUncompleted.remove(item.id);
      _optimisticCompleted.add(item.id);
      AppLogger.d('Applied optimistic completion for ${item.id}');
    } else {
      _optimisticCompleted.remove(item.id);
      _optimisticUncompleted.add(item.id);
      AppLogger.d('Applied optimistic uncompletion for ${item.id}');
    }

    notifyListeners();
    AppLogger.d('Notified listeners after optimistic update for ${item.id}');

    try {
      _toggleInFlight.add(item.id);
      AppLogger.d('Starting server toggle for ${item.id}');
      await ShoppingListService.toggleItemCompletion(listId, item.id);
      AppLogger.d('Server toggle completed for ${item.id}');
      // Don't clear optimistic flags yet; wait for stream reconciliation in _onServerItems
    } catch (e) {
      AppLogger.w('Toggle failed for ${item.id}: $e');
      // On failure, revert optimistic changes immediately
      _pendingCompletionTargets.remove(item.id);
      _optimisticCompleted.remove(item.id);
      _optimisticUncompleted.remove(item.id);
      notifyListeners();
    } finally {
      _toggleInFlight.remove(item.id);
      AppLogger.d('Removed ${item.id} from toggle in-flight');
    }
  }

  Future<void> deleteItemOptimistic(ShoppingListItem item) async {
    if (_optimisticDeletes.containsKey(item.id)) return;
    _optimisticDeletes[item.id] = item;
    _lastDeleted = item;
    notifyListeners();
    try {
      await ShoppingListService.deleteItem(listId: listId, itemId: item.id);
      _optimisticDeletes.remove(item.id);
    } catch (_) {
      _optimisticDeletes.remove(item.id);
      notifyListeners();
    }
  }

  bool get canUndoDelete => _lastDeleted != null;
  Future<void> undoDelete() async {
    final item = _lastDeleted;
    if (item == null) return;
    _lastDeleted = null;
    _optimisticAdds[item.id] = item;
    notifyListeners();
    try {
      await ShoppingListService.addCustomItemToList(
        listId: listId,
        name: item.name,
        quantity: item.quantity,
        estimatedPrice: item.estimatedPrice,
        notes: item.notes,
      );
      _optimisticAdds.remove(item.id);
    } catch (_) {
      _optimisticAdds.remove(item.id);
      notifyListeners();
    }
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    notifyListeners();
  }

  void enterSelection(String id) {
    selectionMode = true;
    selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    selectionMode = false;
    selectedIds.clear();
    notifyListeners();
  }

  Future<void> bulkCompleteSelected() async {
    final futures = <Future>[];
    for (final id in selectedIds) {
      final item = mergedItems.firstWhere(
        (e) => e.id == id,
        orElse: () => _optimisticAdds[id]!,
      );
      futures.add(toggleItemOptimistic(item));
    }
    await Future.wait(futures);
    clearSelection();
  }

  Future<void> bulkDeleteSelected() async {
    final futures = <Future>[];
    for (final id in selectedIds) {
      final item = mergedItems.firstWhere(
        (e) => e.id == id,
        orElse: () => _optimisticAdds[id]!,
      );
      futures.add(deleteItemOptimistic(item));
    }
    await Future.wait(futures);
    clearSelection();
  }

  // --- Reordering (manual drag & drop) ---
  bool _reorderPending = false;
  List<ShoppingListItem> _pendingManualOrder = [];
  bool get reorderInProgress => _reorderPending;

  /// Apply a local optimistic reorder (only valid in manual sort mode).
  void reorder(int oldIndex, int newIndex) {
    if (sortMode != ItemSortMode.manual) return; // ignore
    final list = mergedItems; // fresh snapshot
    if (newIndex > list.length) newIndex = list.length;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _pendingManualOrder = list;
    _reorderPending = true;
    // Assign temp order locally so UI reflects new arrangement immediately
    for (var i = 0; i < list.length; i++) {
      final it = list[i];
      _optimisticUpdates[it.id] = it.copyWith(order: (i + 1) * 10);
    }
    notifyListeners();
  }

  /// Persist pending reorder to backend; debounced externally by caller (e.g., after drag ends).
  Future<void> commitReorder() async {
    if (!_reorderPending || _pendingManualOrder.isEmpty) return;
    final orderedIds = _pendingManualOrder.map((e) => e.id).toList();
    _reorderPending = false;
    try {
      await ShoppingListService.updateItemOrders(listId, orderedIds);
    } catch (_) {
      // On failure, clear optimistic updates so server order re-streams.
      _optimisticUpdates.removeWhere((key, value) => true);
      notifyListeners();
    } finally {
      _pendingManualOrder = [];
    }
  }

  /// Discard any pending local reorder and clear optimistic overrides.
  void cancelReorder() {
    if (!_reorderPending) return;
    _reorderPending = false;
    _pendingManualOrder = [];
    _optimisticUpdates.removeWhere((key, value) => true);
    notifyListeners();
  }

  /// Aggressively pre-download images to system cache for instant paint
  void _predownloadImage(String url) {
    if (url.isEmpty) return;
    // Fire-and-forget: download to system cache without displaying
    try {
      CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    } catch (_) {
      // Ignore download errors
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
