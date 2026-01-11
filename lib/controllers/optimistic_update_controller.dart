import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/shopping_lists/shopping_list_item_model.dart';
import '../services/shopping_lists/shopping_list_service.dart';

class OptimisticUpdateController extends ChangeNotifier {
  final Map<String, ShoppingListItem> _pendingAdds = {};
  final Map<String, Timer> _timers = {};
  final Map<String, int> _retryCounters = {};

  Future<void> addItemOptimistically({
    required String listId,
    required ShoppingListItem item,
    required void Function(ShoppingListItem) onLocalAdd,
    required void Function(String) onLocalRemove,
  }) async {
    final opId = '${listId}_${item.id}_add';
    try {
      onLocalAdd(item);
      _pendingAdds[opId] = item;
      _timers[opId] = Timer(const Duration(seconds: 10), () {
        _rollback(opId, () => onLocalRemove(item.id));
      });

      final result = await ShoppingListService.addCustomItemToList(
        listId: listId,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        notes: item.notes,
        category: item.category,
        estimatedPrice: item.estimatedPrice,
      );

      if (result != null) {
        _cleanup(opId);
      } else {
        _rollback(opId, () => onLocalRemove(item.id));
      }
    } catch (_) {
      _rollbackWithRetry(opId, listId, item, onLocalRemove, onLocalAdd);
    }
  }

  void _rollback(String opId, VoidCallback onRollback) {
    onRollback();
    _cleanup(opId);
    notifyListeners();
  }

  void _rollbackWithRetry(
    String opId,
    String listId,
    ShoppingListItem item,
    void Function(String) onLocalRemove,
    void Function(ShoppingListItem) onLocalAdd,
  ) {
    final retries = _retryCounters[opId] ?? 0;
    if (retries < 2) {
      _retryCounters[opId] = retries + 1;
      // naive retry: reattempt after delay
      _timers[opId]?.cancel();
      _timers[opId] = Timer(const Duration(seconds: 2), () {
        addItemOptimistically(
          listId: listId,
          item: item,
          onLocalAdd: onLocalAdd,
          onLocalRemove: onLocalRemove,
        );
      });
    } else {
      _rollback(opId, () => onLocalRemove(item.id));
    }
  }

  void _cleanup(String opId) {
    _pendingAdds.remove(opId);
    _timers[opId]?.cancel();
    _timers.remove(opId);
    _retryCounters.remove(opId);
  }
}
