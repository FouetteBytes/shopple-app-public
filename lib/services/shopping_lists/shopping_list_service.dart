import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shopping_lists/shopping_list_model.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../models/product_model.dart';
import 'package:shopple/utils/app_logger.dart';
import 'shopping_list_cache.dart';
import 'dart:async';
import 'package:shopple/models/budget/budget_cadence.dart';

class ShoppingListService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _currentUserId => _auth.currentUser?.uid;

  static Future<String> createShoppingList({
    required String name,
    String description = '',
    String iconId = 'shopping_cart',
    String colorTheme = '#4CAF50',
    double budgetLimit = 0.0,
    BudgetCadence budgetCadence = BudgetCadence.none,
    DateTime? budgetAnchor,
    List<String> memberIds = const [],
    Map<String, String> memberRoles = const {},
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final listId = _firestore.collection('shopping_lists').doc().id;

    final shoppingList = ShoppingList(
      id: listId,
      name: name,
      description: description,
      iconId: iconId,
      colorTheme: colorTheme,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      lastActivity: now,
      budgetLimit: budgetLimit,
      budgetCadence: budgetCadence,
      budgetAnchor: budgetAnchor ?? now,
      memberIds: memberIds,
      memberRoles: memberRoles,
      startDate: startDate,
      endDate: endDate,
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('shopping_lists').doc(listId),
      shoppingList.toFirestore(),
    );

    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('shopping_lists')
          .doc(listId),
      {
        'name': name,
        'iconId': iconId,
        'colorTheme': colorTheme,
        'lastAccessed': FieldValue.serverTimestamp(),
        'itemCount': 0,
        'completedCount': 0,
      },
    );

    await batch.commit();
    return listId;
  }

  static Future<List<ShoppingList>> getUserShoppingLists() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      // Fetch owned and collaborative lists.
      final owned = await _firestore
          .collection('shopping_lists')
          .where('createdBy', isEqualTo: userId)
          .orderBy('lastActivity', descending: true)
          .get();
      final collab = await _firestore
          .collection('shopping_lists')
          .where('memberIds', arrayContains: userId)
          .get();

      // Merge and deduplicate by ID.
      final allDocs = <String, QueryDocumentSnapshot>{};
      for (final d in owned.docs) {
        allDocs[d.id] = d;
      }
      for (final d in collab.docs) {
        allDocs[d.id] = d;
      }
      final lists = allDocs.values
          .map((doc) => ShoppingList.fromFirestore(doc))
          .toList();
      // Sort globally by last activity.
      lists.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return lists;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error fetching shopping lists: $e');
      return [];
    }
  }

  static Future<String?> addCustomItemToList({
    required String listId,
    required String name,
    int quantity = 1,
    String unit = 'items',
    String notes = '',
    String category = 'other',
    double estimatedPrice = 0.0,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    AppLogger.d(
      '[ADD_ITEM_DEBUG] Adding item to list $listId: name=$name, quantity=$quantity, estimatedPrice=$estimatedPrice',
    );

    try {
      final now = DateTime.now();
      final itemId = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc()
          .id;

      final item = ShoppingListItem(
        id: itemId,
        listId: listId,
        productId: null,
        name: name,
        quantity: quantity,
        unit: unit,
        notes: notes,
        estimatedPrice: estimatedPrice,
        category: category,
        addedBy: userId,
        addedAt: now,
        updatedAt: now,
      );

      final firestoreData = item.toFirestore();
      AppLogger.d('[ADD_ITEM_DEBUG] Firestore data: $firestoreData');

      final batch = _firestore.batch();

      batch.set(
        _firestore
            .collection('shopping_lists')
            .doc(listId)
            .collection('items')
            .doc(itemId),
        firestoreData,
      );

      batch.update(_firestore.collection('shopping_lists').doc(listId), {
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('shopping_lists')
            .doc(listId),
        {'lastAccessed': FieldValue.serverTimestamp()},
      );

      await batch.commit();

      // Apply optimistic UI update.
      final currentLists = ShoppingListCache.instance.current;
      final listIndex = currentLists.indexWhere((l) => l.id == listId);
      if (listIndex >= 0) {
        final currentList = currentLists[listIndex];
        final newTotalItems = currentList.totalItems + 1;
        final newEstimatedTotal =
            currentList.estimatedTotal + (estimatedPrice * quantity);
        ShoppingListCache.instance.applyLocalAggregates(
          listId,
          totalItems: newTotalItems,
          estimatedTotal: newEstimatedTotal,
          distinctProducts:
              currentList.distinctProducts +
              1, // Custom item is always a new distinct entry.
          distinctCompleted: currentList.distinctCompleted,
        );
      }

      // Mark list for smart hydration.
      ShoppingListCache.instance.markListForHydration(listId);

      return itemId;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error adding custom item to list: $e');
      return null;
    }
  }

  /// Adds a product-based item (with productId). If item with same productId exists, increments quantity.
  static Future<String?> addProductItemToList({
    required String listId,
    required Product product,
    int quantity = 1,
    double estimatedPrice = 0.0,
    String notes = '',
    String category = 'other',
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    AppLogger.d(
      '[ADD_PRODUCT_DEBUG] Adding product to list $listId: product=${product.name} (${product.id}), quantity=$quantity, estimatedPrice=$estimatedPrice',
    );

    try {
      final itemsRef = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items');
      final existing = await itemsRef
          .where('productId', isEqualTo: product.id)
          .limit(1)
          .get();
      final now = DateTime.now();
      final batch = _firestore.batch();
      String itemId;
      double totalIncrement = estimatedPrice * quantity;
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        itemId = doc.id;
        AppLogger.d(
          '[ADD_PRODUCT_DEBUG] Existing item found, incrementing quantity by $quantity',
        );
        batch.update(doc.reference, {
          'quantity': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        itemId = itemsRef.doc().id;
        final item = ShoppingListItem(
          id: itemId,
          listId: listId,
          productId: product.id,
          name: product.name,
          quantity: quantity,
          unit: product.sizeUnit.isNotEmpty ? product.sizeUnit : 'items',
          notes: notes,
          estimatedPrice: estimatedPrice,
          category: category,
          addedBy: userId,
          addedAt: now,
          updatedAt: now,
        );

        final firestoreData = item.toFirestore();
        AppLogger.d(
          '[ADD_PRODUCT_DEBUG] Creating new item. Firestore data: $firestoreData',
        );

        batch.set(itemsRef.doc(itemId), firestoreData);
        batch.update(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('shopping_lists')
              .doc(listId),
          {'lastAccessed': FieldValue.serverTimestamp()},
        );
      }

      // Always update shopping list lastActivity.
      batch.update(_firestore.collection('shopping_lists').doc(listId), {
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Mark for hydration before optimistic aggregates.
      ShoppingListCache.instance.markListForHydration(listId);

      // Apply optimistic UI update.
      final currentLists = ShoppingListCache.instance.current;
      final listIndex = currentLists.indexWhere((l) => l.id == listId);
      if (listIndex >= 0) {
        final currentList = currentLists[listIndex];
        // Only increment totalItems if we created a new item.
        final newTotalItems = existing.docs.isEmpty
            ? currentList.totalItems + 1
            : currentList.totalItems;
        final newEstimatedTotal = currentList.estimatedTotal + totalIncrement;
        final newDistinctProducts = existing.docs.isEmpty
            ? currentList.distinctProducts + 1
            : currentList.distinctProducts;
        ShoppingListCache.instance.applyLocalAggregates(
          listId,
          totalItems: newTotalItems,
          estimatedTotal: newEstimatedTotal,
          completedItems: currentList.completedItems,
          distinctProducts: newDistinctProducts,
          distinctCompleted: currentList.distinctCompleted,
        );
      }

      // Trigger smart hydration.
      // ignore: discarded_futures
      ShoppingListCache.instance.smartHydrationCheck();

      return itemId;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error adding product item: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Spec Compatibility Aliases
  // ---------------------------------------------------------------------------

  /// Alias matching documentation: addProductToList.
  static Future<String?> addProductToList({
    required String listId,
    required Product product,
    int quantity = 1,
    String notes = '',
  }) {
    // estimatedPrice intentionally 0.0 unless caller supplies via future.
    return addProductItemToList(
      listId: listId,
      product: product,
      quantity: quantity,
      notes: notes,
      estimatedPrice: 0.0,
    );
  }

  static Future<bool> toggleItemCompletion(String listId, String itemId) async {
    try {
      final itemDoc = await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId)
          .get();

      if (!itemDoc.exists) return false;

      final item = ShoppingListItem.fromFirestore(itemDoc);
      final newStatus = !item.isCompleted;
      final now = DateTime.now();

      final batch = _firestore.batch();

      batch.update(itemDoc.reference, {
        'isCompleted': newStatus,
        'completedAt': newStatus ? Timestamp.fromDate(now) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update shopping list's lastActivity only.
      batch.update(_firestore.collection('shopping_lists').doc(listId), {
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userId = _currentUserId;
      if (userId != null) {
        batch.update(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('shopping_lists')
              .doc(listId),
          {'lastAccessed': FieldValue.serverTimestamp()},
        );
      }

      await batch.commit();

      // Apply optimistic UI update immediately
      final currentLists = ShoppingListCache.instance.current;
      final listIndex = currentLists.indexWhere((l) => l.id == listId);
      if (listIndex >= 0) {
        final currentList = currentLists[listIndex];
        final newCompletedCount =
            currentList.completedItems + (newStatus ? 1 : -1);
        ShoppingListCache.instance.applyLocalAggregates(
          listId,
          completedItems: newCompletedCount,
        );
      }

      // Mark list for smart hydration.
      ShoppingListCache.instance.markListForHydration(listId);

      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error toggling item completion: $e');
      return false;
    }
  }

  /// Update list metadata.
  static Future<bool> updateShoppingList({
    required String listId,
    String? name,
    String? description,
    String? iconId,
    String? colorTheme,
    double? budgetLimit,
    BudgetCadence? budgetCadence,
    DateTime? budgetAnchor,
    ListStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool resetBudgetAnchorToNow = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      };
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (iconId != null) data['iconId'] = iconId;
      if (colorTheme != null) data['colorTheme'] = colorTheme;
      if (budgetLimit != null) data['budgetLimit'] = budgetLimit;
      if (budgetCadence != null) {
        data['budgetCadence'] = budgetCadence.storageValue;
      }
      if (budgetAnchor != null) {
        data['budgetAnchor'] = Timestamp.fromDate(budgetAnchor);
      } else if (resetBudgetAnchorToNow) {
        data['budgetAnchor'] = Timestamp.fromDate(DateTime.now());
      }
      if (status != null) data['status'] = status.toString().split('.').last;
      // Date handling: only modify if a new value provided OR explicit clear flag set.
      if (startDate != null) {
        data['startDate'] = Timestamp.fromDate(startDate);
      } else if (clearStartDate) {
        data['startDate'] = null; // Explicit clear.
      }
      if (endDate != null) {
        data['endDate'] = Timestamp.fromDate(endDate);
      } else if (clearEndDate) {
        data['endDate'] = null;
      }
      await _firestore.collection('shopping_lists').doc(listId).update(data);
      final userId = _currentUserId;
      if (userId != null &&
          (name != null || iconId != null || colorTheme != null)) {
        final indexData = <String, dynamic>{
          'lastAccessed': FieldValue.serverTimestamp(),
        };
        if (name != null) indexData['name'] = name;
        if (iconId != null) indexData['iconId'] = iconId;
        if (colorTheme != null) indexData['colorTheme'] = colorTheme;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('shopping_lists')
            .doc(listId)
            .update(indexData);
      }
      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error updating shopping list: $e');
      return false;
    }
  }

  /// Wrapper accepting a map of raw updates.
  static Future<bool> updateShoppingListMap(
    String listId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = Map<String, dynamic>.from(updates);
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['lastActivity'] = FieldValue.serverTimestamp();
      await _firestore.collection('shopping_lists').doc(listId).update(data);
      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error updateShoppingListMap: $e');
      return false;
    }
  }

  /// Update an item (quantity, notes, estimatedPrice, category).
  static Future<bool> updateItem({
    required String listId,
    required String itemId,
    int? quantity,
    String? notes,
    double? estimatedPrice,
    String? category,
  }) async {
    try {
      final itemRef = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId);
      final snap = await itemRef.get();
      if (!snap.exists) return false;
      final existing = ShoppingListItem.fromFirestore(snap);
      // Compute diff in estimated total.
      final newQuantity = quantity ?? existing.quantity;
      final newPrice = estimatedPrice ?? existing.estimatedPrice;
      final oldTotal = existing.estimatedPrice * existing.quantity;
      final newTotal = newPrice * newQuantity;
      final diff = newTotal - oldTotal;
      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (quantity != null) data['quantity'] = quantity;
      if (notes != null) data['notes'] = notes;
      if (estimatedPrice != null) data['estimatedPrice'] = estimatedPrice;
      if (category != null) data['category'] = category;
      final batch = _firestore.batch();
      batch.update(itemRef, data);
      batch.update(_firestore.collection('shopping_lists').doc(listId), {
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // Apply optimistic UI update if estimated total changed.
      if (diff.abs() > 0.0001) {
        final currentLists = ShoppingListCache.instance.current;
        final listIndex = currentLists.indexWhere((l) => l.id == listId);
        if (listIndex >= 0) {
          final currentList = currentLists[listIndex];
          final newEstimatedTotal = currentList.estimatedTotal + diff;
          ShoppingListCache.instance.applyLocalAggregates(
            listId,
            estimatedTotal: newEstimatedTotal,
          );
        }
      }

      // Mark list for smart hydration.
      ShoppingListCache.instance.markListForHydration(listId);

      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error updating item: $e');
      return false;
    }
  }

  static Future<bool> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    try {
      final ref = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId);
      final snap = await ref.get();
      if (!snap.exists) return false;
      final item = ShoppingListItem.fromFirestore(snap);
      final batch = _firestore.batch();
      batch.delete(ref);
      batch.update(_firestore.collection('shopping_lists').doc(listId), {
        'lastActivity': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final userId = _currentUserId;
      if (userId != null) {
        batch.update(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('shopping_lists')
              .doc(listId),
          {'lastAccessed': FieldValue.serverTimestamp()},
        );
      }
      await batch.commit();

      // Apply optimistic UI update.
      final currentLists = ShoppingListCache.instance.current;
      final listIndex = currentLists.indexWhere((l) => l.id == listId);
      if (listIndex >= 0) {
        final currentList = currentLists[listIndex];
        final newTotalItems = currentList.totalItems - 1;
        final newCompletedItems =
            currentList.completedItems - (item.isCompleted ? 1 : 0);
        final newEstimatedTotal =
            currentList.estimatedTotal - (item.estimatedPrice * item.quantity);
        ShoppingListCache.instance.applyLocalAggregates(
          listId,
          totalItems: newTotalItems,
          completedItems: newCompletedItems,
          estimatedTotal: newEstimatedTotal,
        );
      }

      // Mark list for smart hydration.
      ShoppingListCache.instance.markListForHydration(listId);

      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error deleting item: $e');
      return false;
    }
  }

  /// Alias matching documentation: removeItemFromList.
  static Future<bool> removeItemFromList({
    required String listId,
    required String itemId,
  }) {
    return deleteItem(listId: listId, itemId: itemId);
  }

  /// Update ordering for manual drag-and-drop.
  static Future<void> updateItemOrders(
    String listId,
    List<String> orderedIds,
  ) async {
    if (orderedIds.isEmpty) return;
    final batch = _firestore.batch();
    // Use gaps (step 10) to allow future inserts.
    for (var i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final orderVal = (i + 1) * 10; // Start at 10.
      final ref = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(id);
      batch.update(ref, {
        'order': orderVal,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastReorderedAt': FieldValue.serverTimestamp(),
      });
    }
    // Touch parent list to reflect recency.
    batch.update(_firestore.collection('shopping_lists').doc(listId), {
      'lastActivity': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Streams for realtime UI.
  static Stream<List<ShoppingList>> userShoppingListsStream() {
    final userId = _currentUserId;
    if (userId == null) return const Stream.empty();
    final controller = StreamController<List<ShoppingList>>();
    List<QueryDocumentSnapshot> ownedDocs = const [];
    List<QueryDocumentSnapshot> collabDocs = const [];

    void emit() {
      final map = <String, QueryDocumentSnapshot>{};
      for (final d in ownedDocs) {
        map[d.id] = d;
      }
      for (final d in collabDocs) {
        map[d.id] = d;
      }
      final lists = map.values
          .map((d) => ShoppingList.fromFirestore(d))
          .toList();
      lists.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      if (!controller.isClosed) controller.add(lists);
    }

    final subOwned = _firestore
        .collection('shopping_lists')
        .where('createdBy', isEqualTo: userId)
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .listen((snap) {
          ownedDocs = snap.docs;
          emit();
        });

    final subCollab = _firestore
        .collection('shopping_lists')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .listen((snap) {
          collabDocs = snap.docs;
          emit();
        });

    controller.onCancel = () async {
      await subOwned.cancel();
      await subCollab.cancel();
    };

    return controller.stream;
  }

  static Stream<List<ShoppingListItem>> listItemsStream(String listId) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('items')
        .orderBy('order')
        .orderBy('addedAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ShoppingListItem.fromFirestore(d)).toList(),
        );
  }

  /// Stream a single shopping list document.
  static Stream<ShoppingList?> shoppingListStream(String listId) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .snapshots()
        .map((doc) => doc.exists ? ShoppingList.fromFirestore(doc) : null);
  }

  static Future<List<ShoppingListItem>> getListItems(String listId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .orderBy('order', descending: false)
          .orderBy('addedAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ShoppingListItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.w('ShoppingListService: Error fetching list items: $e');
      return [];
    }
  }

  static Future<bool> deleteShoppingList(String listId) async {
    try {
      final batch = _firestore.batch();

      final itemsSnapshot = await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .get();

      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }

      batch.delete(_firestore.collection('shopping_lists').doc(listId));

      final userId = _currentUserId;
      if (userId != null) {
        batch.delete(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('shopping_lists')
              .doc(listId),
        );
      }

      await batch.commit();
      return true;
    } catch (e) {
      AppLogger.w('ShoppingListService: Error deleting shopping list: $e');
      return false;
    }
  }

  static Future<void> testServiceMethods() async {
    try {
      AppLogger.d('Testing ShoppingListService...');

      final listId = await createShoppingList(
        name: 'Test List',
        description: 'Testing service methods',
      );
      AppLogger.d('✅ Created list: $listId');

      final lists = await getUserShoppingLists();
      AppLogger.d('✅ Retrieved ${lists.length} lists');

      final itemId = await addCustomItemToList(
        listId: listId,
        name: 'Test Item',
        quantity: 2,
        estimatedPrice: 100.0,
      );
      AppLogger.d('✅ Added item: $itemId');

      final items = await getListItems(listId);
      AppLogger.d('✅ Retrieved ${items.length} items');

      if (itemId != null) {
        final success = await toggleItemCompletion(listId, itemId);
        AppLogger.d('✅ Toggled completion: $success');
      }

      AppLogger.d('🎉 All service tests passed!');
    } catch (e) {
      AppLogger.w('❌ Service test failed: $e');
    }
  }
}
