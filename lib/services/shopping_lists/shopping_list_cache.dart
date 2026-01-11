import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/shopping_lists/shopping_list_model.dart';
import 'shopping_list_service.dart';
import '../user_service.dart';
import '../user/user_info_disk_cache.dart';
import 'list_hydration_service.dart';
import 'list_item_preview_cache.dart';
import '../../utils/app_logger.dart';

/// Lightweight in-memory cache + notifier for the user's shopping lists.
///  - Provides immediate synchronous snapshot for UI.
///  - Subscribes lazily once and keeps stream subscription alive.
///  - Applies silent diff updates.
class ShoppingListCache {
  ShoppingListCache._();
  static ShoppingListCache? _instanceOverride;
  @visibleForTesting
  static set instance(ShoppingListCache? value) => _instanceOverride = value;
  static ShoppingListCache get instance => _instanceOverride ?? _instance;
  static final ShoppingListCache _instance = ShoppingListCache._();

  final ValueNotifier<List<ShoppingList>> _lists = ValueNotifier(const []);
  StreamSubscription<List<ShoppingList>>? _sub;
  StreamSubscription<User?>? _authSub;
  bool _initialized = false;
  bool _hydrated = false;
  Timer? _persistDebounce;

  // Track optimistic aggregates to preserve them against server overwrite.
  final Map<String, Map<String, dynamic>> _optimisticAggregates = {};

  // Rate limiting for hydration calls.
  static DateTime? _lastHydrationCall;
  static const Duration _hydrationCooldown = Duration(seconds: 3);

  // Deferred hydration queue.
  final Set<String> _listsNeedingHydration = {};

  static const _prefsKeyBase = 'shopping_list_cache_v1';
  String _prefsKeyForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return '$uid:$_prefsKeyBase';
  }

  ValueListenable<List<ShoppingList>> get listenable => _lists;
  List<ShoppingList> get current => _lists.value;

  /// Optimistically insert a newly created list locally.
  void optimisticInsert(ShoppingList list) {
    final cur = List<ShoppingList>.from(_lists.value);
    // Avoid duplicates if snapshot already arrived.
    if (cur.any((l) => l.id == list.id)) return;
    cur.insert(0, list);
    _lists.value = cur;
  }

  Future<void> ensureSubscribed() async {
    if (_initialized) return;
    _initialized = true;
    // Hydrate from local storage first.
    await _hydrateFromLocal();
    // If auth not yet ready, wait for first non-null user then subscribe.
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      _authSub?.cancel();
      _authSub = auth.authStateChanges().listen((user) {
        if (user != null) {
          _authSub?.cancel();
          _authSub = null;
          _subscribeToUserLists();
        }
      });
    } else {
      _subscribeToUserLists();
    }
  }

  void _subscribeToUserLists() {
    _sub?.cancel();
    _sub = ShoppingListService.userShoppingListsStream().listen((remote) {
      final prev = _lists.value;
      // Build a map of previous values for quick lookup.
      final prevMap = {for (final l in prev) l.id: l};
      
      // Check for any meaningful change: id order, timestamps, OR aggregate values.
      bool changed = false;
      if (prev.length != remote.length) {
        changed = true;
      } else {
        for (int i = 0; i < remote.length; i++) {
          final r = remote[i];
          final p = prev[i];
          if (r.id != p.id ||
              r.updatedAt != p.updatedAt ||
              r.lastActivity != p.lastActivity ||
              // Check aggregate fields for hydration updates.
              r.totalItems != p.totalItems ||
              r.completedItems != p.completedItems ||
              r.distinctProducts != p.distinctProducts ||
              r.distinctCompleted != p.distinctCompleted ||
              (r.estimatedTotal - p.estimatedTotal).abs() > 0.001) {
            changed = true;
            break;
          }
        }
      }
      if (changed) {
        // Apply optimistic aggregates and previous cache values.
        final mergedLists = _mergeOptimisticAggregates(remote, prevMap);
        _lists.value = mergedLists;
        _schedulePersist();
        _prefetchMemberUsers(mergedLists);
        
        // Prefetch item previews.
        // ignore: discarded_futures
        ListItemPreviewCache.instance.prefetchForLists(
          mergedLists.map((l) => l.id).toList(),
        );

        AppLogger.d(
          '[HYDRATION_DEBUG] Stream updated with aggregate changes, lists count: ${mergedLists.length}',
        );
        // Smart hydration check.
        // ignore: discarded_futures
        smartHydrationCheck();
      }
    });
  }

  /// Merge optimistic aggregates with server data.
  /// Uses previous cache values to prevent showing 0 when server hasn't hydrated yet.
  List<ShoppingList> _mergeOptimisticAggregates(
    List<ShoppingList> serverLists,
    Map<String, ShoppingList> prevMap,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = <ShoppingList>[];

    for (final serverList in serverLists) {
      final optimistic = _optimisticAggregates[serverList.id];
      final previous = prevMap[serverList.id];

      // Determine best values to use (priority: optimistic > server-if-valid > previous).
      int bestTotal = serverList.totalItems;
      int bestCompleted = serverList.completedItems;
      double bestEstimated = serverList.estimatedTotal;
      int bestDistinctProducts = serverList.distinctProducts;
      int bestDistinctCompleted = serverList.distinctCompleted;
      bool usedOptimistic = false;

      // Use optimistic values if they're recent (within 10 seconds).
      if (optimistic != null) {
        final timestamp = optimistic['timestamp'] as int;
        final age = now - timestamp;
        
        if (age < 10000) {
          // Within 10 seconds - use optimistic values.
          bestTotal = optimistic['totalItems'] as int;
          bestCompleted = optimistic['completedItems'] as int;
          bestEstimated = optimistic['estimatedTotal'] as double;
          bestDistinctProducts = optimistic['distinctProducts'] as int? ?? bestDistinctProducts;
          bestDistinctCompleted = optimistic['distinctCompleted'] as int? ?? bestDistinctCompleted;
          usedOptimistic = true;
          
          // Check if server has caught up.
          final serverMatchesOptimistic = serverList.totalItems == bestTotal &&
              (serverList.estimatedTotal - bestEstimated).abs() < 0.01;
          
          if (serverMatchesOptimistic) {
            // Server caught up - clear optimistic.
            _optimisticAggregates.remove(serverList.id);
            usedOptimistic = false;
            bestTotal = serverList.totalItems;
            bestCompleted = serverList.completedItems;
            bestEstimated = serverList.estimatedTotal;
            bestDistinctProducts = serverList.distinctProducts;
            bestDistinctCompleted = serverList.distinctCompleted;
          }
        } else {
          // Optimistic values are stale - remove them.
          _optimisticAggregates.remove(serverList.id);
        }
      }
      
      // Prevent 0-flash: retain previous values when server hasn't hydrated yet.
      if (!usedOptimistic && serverList.totalItems == 0 && previous != null && previous.totalItems > 0) {
        AppLogger.d(
          '[HYDRATION_DEBUG] Preventing 0-flash for ${serverList.id}: keeping previous values '
          '(prev=${previous.totalItems}/${previous.estimatedTotal}, server=0)',
        );
        bestTotal = previous.totalItems;
        bestCompleted = previous.completedItems;
        bestEstimated = previous.estimatedTotal;
        bestDistinctProducts = previous.distinctProducts;
        bestDistinctCompleted = previous.distinctCompleted;
        
        // Mark list for hydration.
        _listsNeedingHydration.add(serverList.id);
      }

      result.add(
        ShoppingList(
          id: serverList.id,
          name: serverList.name,
          description: serverList.description,
          iconId: serverList.iconId,
          colorTheme: serverList.colorTheme,
          createdBy: serverList.createdBy,
          createdAt: serverList.createdAt,
          updatedAt: serverList.updatedAt,
          status: serverList.status,
          budgetLimit: serverList.budgetLimit,
          budgetCadence: serverList.budgetCadence,
          budgetAnchor: serverList.budgetAnchor,
          totalItems: bestTotal,
          completedItems: bestCompleted,
          estimatedTotal: bestEstimated,
          distinctProducts: bestDistinctProducts,
          distinctCompleted: bestDistinctCompleted,
          lastActivity: serverList.lastActivity,
          memberIds: serverList.memberIds,
          memberRoles: serverList.memberRoles,
          startDate: serverList.startDate,
          endDate: serverList.endDate,
        ),
      );
    }

    // Clean up optimistic aggregates for deleted lists.
    final existingIds = serverLists.map((l) => l.id).toSet();
    _optimisticAggregates.removeWhere(
      (key, value) => !existingIds.contains(key),
    );

    return result;
  }

  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    _initialized = false;
  }

  /// Call this when FirebaseAuth user changes.
  Future<void> onAuthChanged(User? user) async {
    // Cancel existing stream and clear snapshot.
    _sub?.cancel();
    clearInMemory();
    // Force re-hydration.
    _hydrated = false;
    if (user != null) {
      await _hydrateFromLocal();
      _subscribeToUserLists();
    }
  }

  // --- Persistence ---
  Future<void> _hydrateFromLocal() async {
    if (_hydrated) return; // Avoid double hydration.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyForCurrentUser());
      if (raw != null) {
        String jsonStr = raw;
        if (raw.startsWith('gz:')) {
          final b64 = raw.substring(3);
          final bytes = base64Decode(b64);
          final decompressed = GZipCodec().decode(bytes as List<int>);
          jsonStr = utf8.decode(decompressed);
        }
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        final lists = decoded
            .map((e) => ShoppingList.fromJson(e as Map<String, dynamic>))
            .toList();
        if (lists.isNotEmpty) {
          _lists.value = lists; // Provide snapshot immediately.
          // Prefetch member user info.
          _prefetchMemberUsers(lists);
          // Hydrate item previews.
          // ignore: discarded_futures
          ListItemPreviewCache.instance.hydrateFromLocal();
        }
      }
    } catch (e) {
      // Non-blocking error handling.
    } finally {
      _hydrated = true;
    }
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), _persistNow);
  }

  Future<void> _persistNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jsonEncode(_lists.value.map((e) => e.toJson()).toList());
      // Compress if large.
      if (jsonList.length > 24 * 1024) {
        final comp = GZipCodec(level: 6).encode(utf8.encode(jsonList));
        final b64 = base64Encode(Uint8List.fromList(comp));
        await prefs.setString(_prefsKeyForCurrentUser(), 'gz:$b64');
      } else {
        await prefs.setString(_prefsKeyForCurrentUser(), jsonList);
      }
    } catch (e) {
      // Ignore.
    }
  }

  /// Clear in-memory snapshot immediately.
  /// Used on auth changes to avoid showing previous user's lists.
  void clearInMemory() {
    _lists.value = const [];
  }

  void _prefetchMemberUsers(List<ShoppingList> lists) {
    final ids = <String>{};
    for (final l in lists) {
      if (l.createdBy.isNotEmpty) ids.add(l.createdBy);
      ids.addAll(l.memberIds.where((m) => m.isNotEmpty));
    }
    if (ids.isNotEmpty) {
      // Fire and forget.
      // ignore: discarded_futures
      () async {
        await UserService.prefetch(ids.toList());
        // Persist subset to disk cache (max 120 users).
        final all = UserService.allCached().take(120).toList();
        await UserInfoDiskCache.instance.persistSnapshot(all);
      }();
    }
  }

  Future<void> _reconcileHydration(List<ShoppingList> lists) async {
    // Rate limiting: prevent excessive hydration calls.
    final now = DateTime.now();
    if (_lastHydrationCall != null &&
        now.difference(_lastHydrationCall!) < _hydrationCooldown) {
      AppLogger.d(
        '[HYDRATION_DEBUG] Rate limited: skipping auto-hydration call (last call was ${now.difference(_lastHydrationCall!).inMilliseconds}ms ago)',
      );
      return;
    }
    _lastHydrationCall = now;

    try {
      // Limit batch size to keep callable payload small.
      final ids = lists.take(50).map((e) => e.id).toList();
      if (ids.isEmpty) return;
      final map = await ListHydrationService.fetchBatch(ids);
      if (map.isEmpty) return;
      bool any = false;
      final updated = <ShoppingList>[];
      for (final l in _lists.value) {
        final h = map[l.id];
        if (h == null) {
          updated.add(l);
          continue;
        }
        final t = h.containsKey('totalItems')
            ? ((h['totalItems'] as num?)?.toInt() ?? l.totalItems)
            : l.totalItems;
        final c = h.containsKey('completedItems')
            ? ((h['completedItems'] as num?)?.toInt() ?? l.completedItems)
            : l.completedItems;
        final e = h.containsKey('estimatedTotal')
            ? ((h['estimatedTotal'] as num?)?.toDouble() ?? l.estimatedTotal)
            : l.estimatedTotal;
        if (t != l.totalItems ||
            c != l.completedItems ||
            (e - l.estimatedTotal).abs() > 0.0001) {
          any = true;
          // Clear optimistic aggregates when server provides authoritative hydration data.
          _optimisticAggregates.remove(l.id);
          updated.add(
            ShoppingList(
              id: l.id,
              name: l.name,
              description: l.description,
              iconId: l.iconId,
              colorTheme: l.colorTheme,
              createdBy: l.createdBy,
              createdAt: l.createdAt,
              updatedAt: l.updatedAt,
              status: l.status,
              budgetLimit: l.budgetLimit,
              budgetCadence: l.budgetCadence,
              budgetAnchor: l.budgetAnchor,
              totalItems: t,
              completedItems: c,
              estimatedTotal: e,
              lastActivity: l.lastActivity,
              memberIds: l.memberIds,
              memberRoles: l.memberRoles,
              startDate: l.startDate,
              endDate: l.endDate,
            ),
          );
        } else {
          updated.add(l);
        }
      }
      if (any) {
        _lists.value = updated;
        _schedulePersist();
      }
    } catch (_) {
      // Silent; best-effort reconciliation only.
    }
  }

  /// Mark a list as needing hydration after item changes.
  void markListForHydration(String listId) {
    _listsNeedingHydration.add(listId);
    AppLogger.d('[HYDRATION_DEBUG] Marked list $listId for hydration');
  }

  /// User-triggered refresh - always update hydration.
  Future<void> forceRefreshHydration() async {
    AppLogger.d(
      '[HYDRATION_DEBUG] User-triggered refresh, forcing hydration update',
    );

    final lists = _lists.value;
    if (lists.isNotEmpty) {
      // Clear rate limiting for user-triggered refresh.
      _lastHydrationCall = null;
      await _reconcileHydration(lists);
    }
  }

  /// Smart hydration that only calls Cloud Function when needed.
  Future<void> smartHydrationCheck() async {
    final now = DateTime.now();

    // Check if we have lists that explicitly need hydration.
    if (_listsNeedingHydration.isEmpty) {
      AppLogger.d('[HYDRATION_DEBUG] No lists marked for hydration, skipping');
      return;
    }

    // Rate limiting check.
    if (_lastHydrationCall != null &&
        now.difference(_lastHydrationCall!) < _hydrationCooldown) {
      AppLogger.d(
        '[HYDRATION_DEBUG] Rate limited: skipping hydration (last call was ${now.difference(_lastHydrationCall!).inMilliseconds}ms ago)',
      );
      return;
    }

    // Get lists that need hydration.
    final listsToHydrate = _lists.value
        .where((list) => _listsNeedingHydration.contains(list.id))
        .toList();

    if (listsToHydrate.isNotEmpty) {
      AppLogger.d(
        '[HYDRATION_DEBUG] Running smart hydration for ${listsToHydrate.length} lists: ${listsToHydrate.map((l) => l.id).join(', ')}',
      );
      _lastHydrationCall = now;

      try {
        final ids = listsToHydrate.map((e) => e.id).toList();
        final map = await ListHydrationService.fetchBatch(ids);
        await _applyHydrationResults(map);

        // Clear the hydration flags for successfully updated lists.
        for (final list in listsToHydrate) {
          _listsNeedingHydration.remove(list.id);
        }
      } catch (e) {
        AppLogger.d('[HYDRATION_DEBUG] Smart hydration failed: $e');
      }
    }
  }

  /// Apply hydration results without triggering more calls.
  Future<void> _applyHydrationResults(
    Map<String, Map<String, dynamic>> map,
  ) async {
    if (map.isEmpty) return;

    bool any = false;
    final updated = <ShoppingList>[];
    for (final l in _lists.value) {
      final h = map[l.id];
      if (h == null) {
        updated.add(l);
        continue;
      }

      final t = h.containsKey('totalItems')
          ? ((h['totalItems'] as num?)?.toInt() ?? l.totalItems)
          : l.totalItems;
      final c = h.containsKey('completedItems')
          ? ((h['completedItems'] as num?)?.toInt() ?? l.completedItems)
          : l.completedItems;
      final e = h.containsKey('estimatedTotal')
          ? ((h['estimatedTotal'] as num?)?.toDouble() ?? l.estimatedTotal)
          : l.estimatedTotal;
      final dp = h.containsKey('distinctProducts')
          ? ((h['distinctProducts'] as num?)?.toInt() ?? l.distinctProducts)
          : l.distinctProducts;
      final dc = h.containsKey('distinctCompleted')
          ? ((h['distinctCompleted'] as num?)?.toInt() ?? l.distinctCompleted)
          : l.distinctCompleted;

      if (t != l.totalItems ||
          c != l.completedItems ||
          (e - l.estimatedTotal).abs() > 0.0001 ||
          dp != l.distinctProducts ||
          dc != l.distinctCompleted) {
        any = true;
        AppLogger.d(
          '[HYDRATION_DEBUG] Updating list ${l.id}: old(t:${l.totalItems}, c:${l.completedItems}, e:${l.estimatedTotal}, dp:${l.distinctProducts}, dc:${l.distinctCompleted}) -> new(t:$t, c:$c, e:$e, dp:$dp, dc:$dc)',
        );

        // Clear optimistic aggregates when server provides authoritative data.
        _optimisticAggregates.remove(l.id);

        updated.add(
          ShoppingList(
            id: l.id,
            name: l.name,
            description: l.description,
            iconId: l.iconId,
            colorTheme: l.colorTheme,
            createdBy: l.createdBy,
            createdAt: l.createdAt,
            updatedAt: l.updatedAt,
            status: l.status,
            budgetLimit: l.budgetLimit,
            budgetCadence: l.budgetCadence,
            budgetAnchor: l.budgetAnchor,
            totalItems: t,
            completedItems: c,
            estimatedTotal: e,
            distinctProducts: dp,
            distinctCompleted: dc,
            lastActivity: l.lastActivity,
            memberIds: l.memberIds,
            memberRoles: l.memberRoles,
            startDate: l.startDate,
            endDate: l.endDate,
          ),
        );
      } else {
        updated.add(l);
      }
    }

    if (any) {
      _lists.value = updated;
      _schedulePersist();
    }
  }

  /// Locally apply aggregate values for a single list (optimistic/UI-first).
  /// Use this right after item edits to keep cards in sync.
  ///
  /// Set [skipNotify] to true when calling from dispose() to avoid setState errors.
  void applyLocalAggregates(
    String listId, {
    int? totalItems,
    int? completedItems,
    double? estimatedTotal,
    int? distinctProducts,
    int? distinctCompleted,
    bool skipNotify = false,
  }) {
    final current = _lists.value;
    int index = current.indexWhere((l) => l.id == listId);
    if (index < 0) return;
    final l = current[index];
    final t = totalItems ?? l.totalItems;
    final c = completedItems ?? l.completedItems;
    final e = estimatedTotal ?? l.estimatedTotal;
    final dp = distinctProducts ?? l.distinctProducts;
    final dc = distinctCompleted ?? l.distinctCompleted;
    
    // Always update optimistic aggregates to ensure fresh timestamp.
    _optimisticAggregates[listId] = {
      'totalItems': t,
      'completedItems': c,
      'estimatedTotal': e,
      'distinctProducts': dp,
      'distinctCompleted': dc,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (t == l.totalItems &&
        c == l.completedItems &&
        dp == l.distinctProducts &&
        dc == l.distinctCompleted &&
        (e - l.estimatedTotal).abs() < 0.0001) {
      return;
    }

    final updated = List<ShoppingList>.from(current);
    updated[index] = ShoppingList(
      id: l.id,
      name: l.name,
      description: l.description,
      iconId: l.iconId,
      colorTheme: l.colorTheme,
      createdBy: l.createdBy,
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
      status: l.status,
      budgetLimit: l.budgetLimit,
      budgetCadence: l.budgetCadence,
      budgetAnchor: l.budgetAnchor,
      totalItems: t,
      completedItems: c,
      estimatedTotal: e,
      distinctProducts: dp,
      distinctCompleted: dc,
      lastActivity: l.lastActivity,
      memberIds: l.memberIds,
      memberRoles: l.memberRoles,
      startDate: l.startDate,
      endDate: l.endDate,
    );
    
    // Skip notifying during dispose to avoid setState errors
    if (skipNotify) {
      return;
    }
    
    _lists.value = updated;
    _schedulePersist();
  }

  /// Reconcile hydration for specific list IDs when item changes occur.
  Future<void> reconcileHydrationFor(List<String> listIds) async {
    if (listIds.isEmpty) return;

    // Mark these lists as needing hydration.
    for (final id in listIds) {
      _listsNeedingHydration.add(id);
    }

    AppLogger.d(
      '[HYDRATION_DEBUG] Marked ${listIds.length} lists for hydration: ${listIds.join(', ')}',
    );

    // Trigger smart hydration check.
    await smartHydrationCheck();
  }
}
