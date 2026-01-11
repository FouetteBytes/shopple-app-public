import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enhanced_product_service.dart';
import '../../models/product_model.dart';
import '../core/backoff_scheduler.dart';

/// Singleton reactive cache for current product prices.
/// Maintains cheapest price per product and store map.
/// Listens to Firestore changes so all devices see updates quickly.
class CurrentPriceCache {
  CurrentPriceCache._();
  static final CurrentPriceCache instance = CurrentPriceCache._();

  final _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, CurrentPrice>> _prices =
      {}; // productId -> storeId -> price
  final Map<String, double> _cheapest = {}; // productId -> cheapest price
  final StreamController<Set<String>> _changedProductsCtrl =
      StreamController.broadcast();
  Stream<Set<String>> get changedProducts => _changedProductsCtrl.stream;
  StreamSubscription<QuerySnapshot>? _liveSub;

  /// Prime cache for given product ids (batch fetch); returns map of cheapest prices.
  Future<Map<String, double>> prime(List<String> productIds) async {
    final missing = productIds.where((id) => !_prices.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      try {
        final batched =
            await EnhancedProductService.getCurrentPricesForProducts(missing);
        _merge(batched, markChanged: true);
        for (final id in missing) {
          BackoffScheduler.instance.success('price:$id');
        }
        _ensureListener();
      } catch (e) {
        for (final id in missing) {
          BackoffScheduler.instance.schedule('price:$id', () => prime([id]));
        }
      }
    }
    return {
      for (final id in productIds)
        if (_cheapest[id] != null) id: _cheapest[id]!,
    };
  }

  double? cheapestFor(String productId) => _cheapest[productId];
  Map<String, CurrentPrice>? pricesFor(String productId) => _prices[productId];
  // Backwards compat for consumer widget expected API.
  double? getCheapestPriceForProduct(String productId) => _cheapest[productId];

  void _merge(
    Map<String, Map<String, CurrentPrice>> incoming, {
    bool markChanged = false,
  }) {
    final changed = <String>{};
    incoming.forEach((pid, storeMap) {
      final existing = _prices[pid] ??= {};
      bool localChanged = false;
      storeMap.forEach((store, cp) {
        final prev = existing[store];
        if (prev == null || prev.price != cp.price) {
          existing[store] = cp;
          localChanged = true;
        }
      });
      if (localChanged) {
        final cheapest = existing.values.isEmpty
            ? null
            : existing.values
                  .map((e) => e.price)
                  .reduce((a, b) => a < b ? a : b);
        if (cheapest != null && _cheapest[pid] != cheapest) {
          _cheapest[pid] = cheapest;
          changed.add(pid);
        }
      }
    });
    if (markChanged && changed.isNotEmpty) {
      _changedProductsCtrl.add(changed);
    }
  }

  void _ensureListener() {
    if (_liveSub != null) return;
    // Listen to all price docs (could scope further for scale)
    _liveSub = _firestore.collection('current_prices').snapshots().listen((
      snap,
    ) {
      final map = <String, Map<String, CurrentPrice>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final pid = data['productId'] ?? '';
        if (pid.isEmpty) continue;
        final cp = CurrentPrice(
          id: doc.id,
          supermarketId: data['supermarketId'] ?? '',
          productId: pid,
          price: (data['price'] ?? 0).toDouble(),
          priceDate: data['priceDate'] ?? '',
          lastUpdated: data['lastUpdated'] ?? '',
        );
        (map[pid] ??= {})[cp.supermarketId] = cp;
      }
      if (map.isNotEmpty) {
        _merge(map, markChanged: true);
      }
    });
  }

  void dispose() {
    _liveSub?.cancel();
    _changedProductsCtrl.close();
  }
}
