import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/shopping_lists/shopping_list_model.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../models/shopping_lists/list_note_model.dart';
import '../../models/budget/budget_period.dart';

import '../../services/shopping_lists/shopping_list_service.dart';
import '../../services/shopping_lists/shopping_list_cache.dart';
import '../../services/shopping_lists/list_notes_service.dart';
import '../../services/shopping_lists/collaborative_shopping_list_service.dart';
import '../../services/product/product_image_cache.dart';
import '../../services/product/product_details_cache.dart';
import '../../services/product/current_price_cache.dart';
import '../../services/user_service.dart';
import '../../services/user/user_profile_stream_service.dart';

import '../../utils/quick_add_parser.dart';
import '../../controllers/shopping_list_items_controller.dart';

class ListDetailController extends ChangeNotifier {
  ShoppingList list;
  final String listId;
  
  // Controllers
  late final ShoppingListItemsController itemsController;
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController priceController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  // State
  bool adding = false;
  bool showCategories = true;
  final Map<String, String> optimisticAssignments = {};
  final Map<String, double> currentUnitPrices = {};
  final Map<String, String> productSizeLabels = {};
  
  // Streams
  Stream<ShoppingList?>? _listStream;
  StreamSubscription<ShoppingList?>? _listStreamSub;
  late final Stream<List<ListNote>> notesCountStream;
  StreamSubscription<List<ListNote>>? _notesWarmSub;
  List<ListNote> prefetchedNotes = const [];

  ListDetailController({required this.list}) : listId = list.id {
    _init();
  }

  void _init() {
    itemsController = ShoppingListItemsController(listId);
    itemsController.addListener(notifyListeners);

    _listStream = ShoppingListService.shoppingListStream(listId);
    _listStreamSub = _listStream?.listen((updatedList) {
      if (updatedList != null) {
        list = updatedList;
        ShoppingListCache.instance.applyLocalAggregates(
          updatedList.id,
          totalItems: updatedList.totalItems,
          completedItems: updatedList.completedItems,
          estimatedTotal: updatedList.estimatedTotal,
          distinctProducts: updatedList.distinctProducts,
          distinctCompleted: updatedList.distinctCompleted,
        );
        notifyListeners();
      }
    });

    Get.put(ListNotesService());
    notesCountStream = ListNotesService.instance
        .getListNotesStream(listId)
        .distinct((prev, next) => prev.length == next.length)
        .asBroadcastStream();
        
    _notesWarmSub = ListNotesService.instance
        .getListNotesStream(listId)
        .listen((notes) {
          prefetchedNotes = notes;
          notifyListeners();
        });
  }

  void onReady() {
    _loadPrefs();
    _aggressivelyPrefetchImages();
    _primeSharedPrices();
    _maybeFetchProductDetailsForSizes();

    if (list.isShared) {
      _initializeCollaborativeFeatures();
      final ids = <String>{
        list.createdBy,
        ...list.memberIds,
        ...list.collaborators.keys,
      }..removeWhere((e) => e.isEmpty);
      if (ids.isNotEmpty) {
        UserService.prefetch(ids.toList());
        UserProfileStreamService.instance.prefetchUsers(ids);
      }
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    notesController.dispose();
    itemsController.removeListener(notifyListeners);
    itemsController.dispose();
    _notesWarmSub?.cancel();
    _listStreamSub?.cancel();
    if (list.isShared) {
      CollaborativeShoppingListService.removePresence(listId);
    }
    super.dispose();
  }

  // --- Actions ---

  Future<void> addItem() async {
    adding = true;
    notifyListeners();
    
    try {
      final raw = itemNameController.text.trim();
      final parsed = QuickAddParser.parse(raw);
      final name = parsed.name.isNotEmpty ? parsed.name : raw;
      final qty = parsed.quantity != 1 && quantityController.text.trim().isEmpty
          ? parsed.quantity
          : int.tryParse(quantityController.text.trim()) ?? parsed.quantity;
      final price = parsed.price != 0 && priceController.text.trim().isEmpty
          ? parsed.price
          : double.tryParse(priceController.text.trim()) ?? parsed.price;
      final notes = parsed.notes.isNotEmpty && notesController.text.trim().isEmpty
          ? parsed.notes
          : notesController.text.trim();

      await itemsController.addItemOptimistic(
        name: name,
        quantity: qty,
        price: price,
        notes: notes,
      );
      
      pushLocalAggregates();
      ShoppingListCache.instance.reconcileHydrationFor([listId]);
      
      itemNameController.clear();
      quantityController.text = '1';
      priceController.clear();
      notesController.clear();
    } catch (e) {
      rethrow;
    } finally {
      adding = false;
      notifyListeners();
    }
  }

  Future<bool> toggleItem(ShoppingListItem item) async {
    final assignment = list.itemAssignments[item.id];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final roleForRules = list.memberRoles[currentUid] ?? 'viewer';
    final canEdit = roleForRules == 'editor' || list.createdBy == currentUid;

    if (!item.isCompleted && assignment != null) {
      if (assignment.assignedToUserId == currentUid || canEdit) {
        final ok = await CollaborativeShoppingListService.completeAssignedItem(
          listId: listId,
          itemId: item.id,
        );
        return ok;
      } else {
        return false; // Permission denied
      }
    } else {
      await itemsController.toggleItemOptimistic(item);
      pushLocalAggregates();
      ShoppingListCache.instance.reconcileHydrationFor([listId]);
      return true;
    }
  }

  Future<void> deleteItem(ShoppingListItem item) async {
    await itemsController.deleteItemOptimistic(item);
    pushLocalAggregates();
    ShoppingListCache.instance.reconcileHydrationFor([listId]);
  }

  void undoDelete() {
    itemsController.undoDelete();
  }

  void pushLocalAggregates() {
    final items = itemsController.mergedItems;
    int total = items.length;
    int completed = items.where((e) => e.isCompleted).length;
    double est = 0;
    for (final it in items) {
      final unit = it.estimatedPrice > 0
          ? it.estimatedPrice
          : (it.productId != null ? currentUnitPrices[it.productId] ?? 0 : 0);
      est += unit * it.quantity;
    }
    ShoppingListCache.instance.applyLocalAggregates(
      listId,
      totalItems: total,
      completedItems: completed,
      estimatedTotal: est,
    );
  }

  // --- Helpers ---

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool('list:$listId:showCategories');
      if (v != null && v != showCategories) {
        showCategories = v;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleCategories() async {
    showCategories = !showCategories;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('list:$listId:showCategories', showCategories);
    } catch (_) {}
  }

  Future<void> _aggressivelyPrefetchImages() async {
    final ids = itemsController.mergedItems
        .map((e) => e.productId)
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    for (final id in ids) {
      if (ProductImageCache.instance.peek(id) == null) {
        ProductImageCache.instance.getImageUrl(id).catchError((_) => null);
      }
    }
    ProductImageCache.instance.prefetch(ids);
  }

  Future<void> _primeSharedPrices() async {
    final ids = itemsController.mergedItems
        .map((e) => e.productId)
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    final map = await CurrentPriceCache.instance.prime(ids);
    currentUnitPrices.addAll(map);
    notifyListeners();
  }

  Future<void> _maybeFetchProductDetailsForSizes() async {
    final missing = itemsController.mergedItems
        .where(
          (i) =>
              i.productId != null &&
              !productSizeLabels.containsKey(i.productId),
        )
        .map((i) => i.productId!)
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    ProductDetailsCache.instance.prefetch(missing);
    for (final id in missing) {
      ProductDetailsCache.instance.get(id).then((p) {
        if (p != null) {
          final label = _composeSizeLabel(p.sizeRaw, p.sizeUnit, p.size);
          productSizeLabels[id] = label;
          notifyListeners();
        }
      });
    }
  }

  String _composeSizeLabel(String raw, String unit, int size) {
    if (raw.isNotEmpty) return raw;
    if (size > 0 && unit.isNotEmpty) return '$size $unit';
    return '';
  }

  Future<void> _initializeCollaborativeFeatures() async {
    await CollaborativeShoppingListService.updatePresence(
      listId: listId,
      activity: 'viewing',
    );
  }

  // --- Budget Logic ---

  double spendForPeriod(BudgetPeriod period) {
    double total = 0;
    for (final item in itemsController.mergedItems) {
      if (!item.isCompleted) continue;
      final date = item.completedAt ?? item.updatedAt;
      if (!period.contains(date)) continue;
      total += estimateItemCost(item);
    }
    return total;
  }

  double estimateItemCost(ShoppingListItem item) {
    final quantity = item.quantity <= 0 ? 1 : item.quantity;
    final unitPrice = item.estimatedPrice > 0
        ? item.estimatedPrice
        : (item.productId != null
              ? currentUnitPrices[item.productId] ?? 0.0
              : 0.0);
    final safePrice = unitPrice < 0 ? 0.0 : unitPrice;
    return safePrice * quantity;
  }
}
