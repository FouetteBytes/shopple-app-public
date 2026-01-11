import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:shopple/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import '../../services/product/current_price_cache.dart';
import 'package:shopple/utils/app_logger.dart';
import 'cards/shopping_list_card_images.dart';
import 'cards/shopping_list_card_members.dart';

/// Modern multi-select sheet to add a product to several shopping lists at once.
class MultiAddToListsSheet extends StatefulWidget {
  final Product product;
  final Map<String, CurrentPrice>?
  prices; // optional map supermarketId->price for determining best price
  final double assumedPrice; // fallback price per unit if prices map absent
  final int initialQuantity;
  // When true, the sheet renders without Expanded/Fixed height so a parent SingleChildScrollView can size it (fit content).
  final bool scrollFriendly;
  const MultiAddToListsSheet({
    super.key,
    required this.product,
    this.prices,
    this.assumedPrice = 0,
    this.initialQuantity = 1,
    this.scrollFriendly = false,
  });
  @override
  State<MultiAddToListsSheet> createState() => _MultiAddToListsSheetState();
}

class _MultiAddToListsSheetState extends State<MultiAddToListsSheet> {
  final Set<String> _selected = {}; // list ids
  bool _submitting = false;
  int _quantity = 1;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  // Per-list customized quantities (defaults inserted on select)
  final Map<String, int> _quantities = {}; // listId -> qty
  // Cached actual totals per list (calculated from items) - with timestamps to prevent over-calculation
  final Map<String, double> _realTimeTotals = {};
  final Map<String, int> _realTimeItemCounts = {};
  final Map<String, int> _realTimeCompletedCounts = {};
  final Map<String, DateTime> _lastCalculated = {}; // listId -> timestamp
  // Price overrides per product (like main cards)
  final Map<String, double> _unitOverrides = {};
  bool _fetchingPrices = false;
  // Cached existing quantity already in list (presence indicator)
  final Map<String, int> _existingQty = {}; // listId -> existing quantity
  Timer? _presenceDebounce;
  final Set<String> _presenceQueued = {}; // listIds to check
  // Freeze lists snapshot while submitting so user doesn't see each list update one-by-one
  List<ShoppingList> _latestLists = [];
  List<ShoppingList>? _frozenListsDuringSubmit;
  // Debounce + in-flight tracking for real-time total calculations to avoid repeated work per build frame
  final Map<String, Timer> _calcDebounceTimers = {}; // listId -> debounce timer
  final Set<String> _calculatingLists =
      {}; // listIds currently being fetched/calculated
  // Cached text styles (GoogleFonts are expensive repeatedly)
  static final TextStyle _listNameStyleBase = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static final TextStyle _countStyleBase = GoogleFonts.lato(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle _percentStyleBase = GoogleFonts.lato(fontSize: 11);
  static final TextStyle _priceIncStyleBase = GoogleFonts.lato(
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _remStyleBase = GoogleFonts.lato(
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle _budgetStyleBase = GoogleFonts.lato(
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle _inListBadgeStyleBase = GoogleFonts.lato(
    fontSize: 9,
    fontWeight: FontWeight.w700,
  );
  // Decoration caches
  final Map<int, BoxDecoration> _tileDecoCache = {}; // key=color.value^selected
  final Map<int, BoxDecoration> _iconDecoCache = {}; // key=color.value

  BoxDecoration _tileDeco(ShoppingList l, bool selected) {
    final key = (l.themeColor.toARGB32() << 1) ^ (selected ? 1 : 0);
    final cached = _tileDecoCache[key];
    if (cached != null) return cached;
    final deco = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: selected
            ? [
                l.themeColor.withValues(alpha: 0.08),
                l.themeColor.withValues(alpha: 0.12),
              ]
            : const [Color(0xFF1A1C22), Color(0xFF16181E)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected
            ? l.themeColor.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.06),
        width: selected ? 1.5 : 0.5,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: l.themeColor.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
    _tileDecoCache[key] = deco;
    return deco;
  }

  BoxDecoration _iconDeco(ShoppingList l) {
    final key = l.themeColor.toARGB32();
    final cached = _iconDecoCache[key];
    if (cached != null) return cached;
    final deco = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          l.themeColor.withValues(alpha: .8),
          l.themeColor.withValues(alpha: .6),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: l.themeColor.withValues(alpha: .25),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
    _iconDecoCache[key] = deco;
    return deco;
  }

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });

    // Force refresh of shopping list data to ensure we get the latest budget information
    _refreshShoppingListData();
  }

  @override
  void dispose() {
    for (final t in _calcDebounceTimers.values) {
      t.cancel();
    }
    _presenceDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Force refresh the shopping list data to ensure budget calculations are up-to-date
  Future<void> _refreshShoppingListData() async {
    try {
      // Small delay to ensure any recent updates have propagated
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.w('Error refreshing shopping list data: $e');
    }
  }

  // Schedule a debounced calculation for a list (coalesces multiple build-triggered requests)
  void _scheduleRealTimeTotalsCalculation(String listId) {
    // If we already have a cached value and it's fresh (<2s) skip scheduling.
    final lastCalc = _lastCalculated[listId];
    if (lastCalc != null &&
        DateTime.now().difference(lastCalc).inMilliseconds < 2000) {
      return;
    }
    if (_calculatingLists.contains(listId)) {
      // Already in flight; let it finish.
      return;
    }
    // Debounce: if a timer already exists let it run; otherwise schedule a short delay to batch rapid build passes.
    if (_calcDebounceTimers[listId]?.isActive ?? false) return;
    _calcDebounceTimers[listId] = Timer(const Duration(milliseconds: 120), () {
      _calculateRealTimeTotals(listId);
    });
  }

  // Calculate real-time totals from shopping list items (with intelligent caching and duplication guards)
  Future<void> _calculateRealTimeTotals(String listId) async {
    final lastCalc = _lastCalculated[listId];
    if (lastCalc != null &&
        DateTime.now().difference(lastCalc).inMilliseconds < 2000) {
      return; // still fresh
    }
    if (_calculatingLists.contains(listId)) return; // already running
    _calculatingLists.add(listId);
    try {
      final items = await ShoppingListService.getListItems(listId);
      await _maybeFetchPricesForItems(items);

      double total = 0.0;
      int completedCount = 0;

      // Limit verbose logging to debug mode and only small lists to avoid UI jank
      final shouldLog =
          kDebugMode && items.length <= 8; // cap logging to modest lists
      if (shouldLog) {
        AppLogger.d(
          'MultiAddToLists: Calculating ${items.length} items for list $listId',
        );
      }
      for (final item in items) {
        final estimatedPrice = item.estimatedPrice;
        final overridePrice = item.productId != null
            ? _unitOverrides[item.productId]
            : null;
        final unit = estimatedPrice > 0
            ? estimatedPrice
            : (overridePrice ?? estimatedPrice);
        final itemTotal = unit * item.quantity;
        total += itemTotal;
        if (item.isCompleted) completedCount++;
        if (shouldLog) {
          AppLogger.d(
            '  • ${item.productId} qty=${item.quantity} unit=$unit total=$itemTotal',
          );
        }
      }
      _realTimeTotals[listId] = total;
      _realTimeItemCounts[listId] = items.length;
      _realTimeCompletedCounts[listId] = completedCount;
      _lastCalculated[listId] = DateTime.now();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      AppLogger.w('Error calculating real-time totals for $listId: $e');
      _realTimeTotals[listId] = 0.0;
      _realTimeItemCounts[listId] = 0;
      _realTimeCompletedCounts[listId] = 0;
    } finally {
      _calculatingLists.remove(listId);
    }
  }

  // Fetch prices for items that need them (same logic as main cards)
  Future<void> _maybeFetchPricesForItems(List<ShoppingListItem> items) async {
    if (_fetchingPrices) return;
    final ids = items
        .map((e) => e.productId)
        .whereType<String>()
        .where((id) => !_unitOverrides.containsKey(id))
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    _fetchingPrices = true;
    try {
      await CurrentPriceCache.instance.prime(ids);
      for (final id in ids) {
        final cheapest = CurrentPriceCache.instance.cheapestFor(id);
        if (cheapest != null) {
          _unitOverrides[id] = cheapest;
        }
      }
    } catch (e) {
      AppLogger.w('Error fetching prices: $e');
    } finally {
      _fetchingPrices = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If scrollFriendly is true, don't force a height; let parent (LiquidGlass sheet) constrain and scroll.
    final content = SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to Shopping Lists',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Header product card (LiquidGlass)
                LiquidGlass(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 18,
                  enableBlur: true,
                  blurSigmaX: 10,
                  blurSigmaY: 16,
                  gradientColors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _productThumb(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.2,
                              ),
                            ),
                            if (widget.product.brandName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  widget.product.brandName,
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_unitPrice > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryAccentColor
                                              .withValues(alpha: .85),
                                          AppColors.primaryAccentColor
                                              .withValues(alpha: .55),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Rs ${_unitPrice.toStringAsFixed(2)} / unit',
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (_unitPrice > 0) const SizedBox(width: 8),
                                if (_unitPrice > 0)
                                  Text(
                                    '+Rs ${(_unitPrice * _quantity).toStringAsFixed(0)}',
                                    style: GoogleFonts.lato(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _quantityStepper(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _searchField(),
                const SizedBox(height: 8),
                // List area
                // If scrollFriendly: render a shrinkWrap list so parent can scroll the entire sheet.
                // Else: keep previous Expanded list for full-height sheets.
                widget.scrollFriendly
                    ? StreamBuilder<List<ShoppingList>>(
                        stream: ShoppingListService.userShoppingListsStream(),
                        builder: (context, snap) {
                          if (snap.hasData && !_submitting) {
                            _latestLists = snap.data!;
                            // Pre-warm totals
                            final prewarm = _latestLists
                                .take(12)
                                .map((l) => l.id)
                                .toList();
                            for (final id in prewarm) {
                              if (!_realTimeTotals.containsKey(id)) {
                                _scheduleRealTimeTotalsCalculation(id);
                              }
                            }
                          }
                          var lists =
                              _submitting && _frozenListsDuringSubmit != null
                              ? _frozenListsDuringSubmit!
                              : _latestLists;
                          if (lists.isEmpty && !snap.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          lists = lists
                              .where((l) => l.status != ListStatus.completed)
                              .toList();
                          if (_search.isNotEmpty) {
                            lists = lists
                                .where(
                                  (l) => l.name.toLowerCase().contains(_search),
                                )
                                .toList();
                          }
                          if (lists.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No active lists yet. Create one first.',
                                  style: GoogleFonts.lato(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: lists.length,
                            itemBuilder: (context, i) {
                              final l = lists[i];
                              final selected = _selected.contains(l.id);
                              final rowQty = selected
                                  ? (_quantities[l.id] ?? _quantity)
                                  : _quantity;
                              final priceInc = _unitPrice * rowQty;
                              final actualEstimatedTotal =
                                  _realTimeTotals[l.id] ?? l.estimatedTotal;
                              final actualTotalItems =
                                  _realTimeItemCounts[l.id] ?? l.totalItems;
                              final actualCompletedItems =
                                  _realTimeCompletedCounts[l.id] ??
                                  l.completedItems;
                              final futureTotal =
                                  actualEstimatedTotal +
                                  (selected ? priceInc : 0);
                              final overBudget =
                                  l.budgetLimit > 0 &&
                                  futureTotal > l.budgetLimit;
                              final pct = actualTotalItems == 0
                                  ? 0.0
                                  : actualCompletedItems / actualTotalItems;
                              if (!_realTimeTotals.containsKey(l.id)) {
                                _scheduleRealTimeTotalsCalculation(l.id);
                              }
                              if (!_existingQty.containsKey(l.id)) {
                                _queuePresenceFetch(l.id);
                              }
                              final existing = _existingQty[l.id];
                              final isInList = existing != null && existing > 0;
                              final willAddItemCount =
                                  (existing == null || existing == 0) &&
                                      selected
                                  ? 1
                                  : 0;
                              final newTotalItems =
                                  actualTotalItems + willAddItemCount;
                              final predictedPct = newTotalItems == 0
                                  ? 0.0
                                  : actualCompletedItems / newTotalItems;
                              final budgetRemaining = l.budgetLimit > 0
                                  ? (l.budgetLimit - actualEstimatedTotal)
                                  : 0.0;
                              final futureRemaining = l.budgetLimit > 0
                                  ? (l.budgetLimit - futureTotal)
                                  : 0.0;
                              final currentUsedPct = l.budgetLimit > 0
                                  ? (actualEstimatedTotal / l.budgetLimit)
                                        .clamp(0.0, 2.0)
                                  : 0.0;
                              final futureUsedPct = l.budgetLimit > 0
                                  ? (futureTotal / l.budgetLimit).clamp(
                                      0.0,
                                      2.0,
                                    )
                                  : 0.0;
                              return _listTile(
                                l,
                                selected: selected,
                                priceInc: priceInc,
                                actualEstimatedTotal: actualEstimatedTotal,
                                actualTotalItems: actualTotalItems,
                                actualCompletedItems: actualCompletedItems,
                                futureTotal: futureTotal,
                                overBudget: overBudget,
                                pct: pct,
                                existing: existing,
                                isInList: isInList,
                                willAddItemCount: willAddItemCount,
                                newTotalItems: newTotalItems,
                                predictedPct: predictedPct,
                                budgetRemaining: budgetRemaining,
                                futureRemaining: futureRemaining,
                                currentUsedPct: currentUsedPct,
                                futureUsedPct: futureUsedPct,
                              );
                            },
                          );
                        },
                      )
                    : Expanded(
                        child: StreamBuilder<List<ShoppingList>>(
                          stream: ShoppingListService.userShoppingListsStream(),
                          builder: (context, snap) {
                            if (snap.hasData && !_submitting) {
                              _latestLists = snap.data!;
                              // Pre-warm totals for the first page of lists to avoid lazy calculation jank
                              final prewarm = _latestLists
                                  .take(12)
                                  .map((l) => l.id)
                                  .toList();
                              for (final id in prewarm) {
                                if (!_realTimeTotals.containsKey(id)) {
                                  _scheduleRealTimeTotalsCalculation(id);
                                }
                              }
                            }
                            var lists =
                                _submitting && _frozenListsDuringSubmit != null
                                ? _frozenListsDuringSubmit!
                                : _latestLists;
                            if (lists.isEmpty && !snap.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            lists = lists
                                .where((l) => l.status != ListStatus.completed)
                                .toList();
                            if (_search.isNotEmpty) {
                              lists = lists
                                  .where(
                                    (l) =>
                                        l.name.toLowerCase().contains(_search),
                                  )
                                  .toList();
                            }
                            if (lists.isEmpty) {
                              return Center(
                                child: Text(
                                  'No active lists yet. Create one first.',
                                  style: GoogleFonts.lato(
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: lists.length,
                              itemBuilder: (context, i) {
                                final l = lists[i];
                                final selected = _selected.contains(l.id);
                                final rowQty = selected
                                    ? (_quantities[l.id] ?? _quantity)
                                    : _quantity;
                                final priceInc = _unitPrice * rowQty;
                                final actualEstimatedTotal =
                                    _realTimeTotals[l.id] ?? l.estimatedTotal;
                                final actualTotalItems =
                                    _realTimeItemCounts[l.id] ?? l.totalItems;
                                final actualCompletedItems =
                                    _realTimeCompletedCounts[l.id] ??
                                    l.completedItems;
                                final futureTotal =
                                    actualEstimatedTotal +
                                    (selected ? priceInc : 0);
                                final overBudget =
                                    l.budgetLimit > 0 &&
                                    futureTotal > l.budgetLimit;
                                final pct = actualTotalItems == 0
                                    ? 0.0
                                    : actualCompletedItems / actualTotalItems;
                                if (!_realTimeTotals.containsKey(l.id)) {
                                  _scheduleRealTimeTotalsCalculation(l.id);
                                }
                                if (!_existingQty.containsKey(l.id)) {
                                  _queuePresenceFetch(l.id);
                                }
                                final existing = _existingQty[l.id];
                                final isInList =
                                    existing != null && existing > 0;
                                final willAddItemCount =
                                    (existing == null || existing == 0) &&
                                        selected
                                    ? 1
                                    : 0;
                                final newTotalItems =
                                    actualTotalItems + willAddItemCount;
                                final predictedPct = newTotalItems == 0
                                    ? 0.0
                                    : actualCompletedItems / newTotalItems;
                                final budgetRemaining = l.budgetLimit > 0
                                    ? (l.budgetLimit - actualEstimatedTotal)
                                    : 0.0;
                                final futureRemaining = l.budgetLimit > 0
                                    ? (l.budgetLimit - futureTotal)
                                    : 0.0;
                                final currentUsedPct = l.budgetLimit > 0
                                    ? (actualEstimatedTotal / l.budgetLimit)
                                          .clamp(0.0, 2.0)
                                    : 0.0;
                                final futureUsedPct = l.budgetLimit > 0
                                    ? (futureTotal / l.budgetLimit).clamp(
                                        0.0,
                                        2.0,
                                      )
                                    : 0.0;
                                return _listTile(
                                  l,
                                  selected: selected,
                                  priceInc: priceInc,
                                  actualEstimatedTotal: actualEstimatedTotal,
                                  actualTotalItems: actualTotalItems,
                                  actualCompletedItems: actualCompletedItems,
                                  futureTotal: futureTotal,
                                  overBudget: overBudget,
                                  pct: pct,
                                  existing: existing,
                                  isInList: isInList,
                                  willAddItemCount: willAddItemCount,
                                  newTotalItems: newTotalItems,
                                  predictedPct: predictedPct,
                                  budgetRemaining: budgetRemaining,
                                  futureRemaining: futureRemaining,
                                  currentUsedPct: currentUsedPct,
                                  futureUsedPct: futureUsedPct,
                                );
                              },
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty || _submitting
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Add $_quantity × to ${_selected.length} list${_selected.length == 1 ? '' : 's'}',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Decide container: either return content directly (for scroll-friendly) or wrap in FractionallySizedBox for legacy full-height usage
    if (widget.scrollFriendly) return content;
    return FractionallySizedBox(heightFactor: 0.88, child: content);
  }

  double get _unitPrice {
    if (widget.prices != null && widget.prices!.isNotEmpty) {
      try {
        return widget.prices!.values
            .map((e) => e.price)
            .reduce((a, b) => a < b ? a : b);
      } catch (_) {
        return widget.assumedPrice;
      }
    }
    return widget.assumedPrice;
  }

  void _queuePresenceFetch(String listId) {
    _presenceQueued.add(listId);
    _presenceDebounce?.cancel();
    _presenceDebounce = Timer(
      const Duration(milliseconds: 250),
      _flushPresenceQueue,
    );
  }

  Future<void> _flushPresenceQueue() async {
    if (!mounted || _presenceQueued.isEmpty) return;
    final ids = List<String>.from(_presenceQueued);
    _presenceQueued.clear();
    for (final id in ids) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('shopping_lists')
            .doc(id)
            .collection('items')
            .where('productId', isEqualTo: widget.product.id)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final q = (snap.docs.first.data()['quantity'] ?? 1) as int;
          _existingQty[id] = q;
        } else {
          _existingQty[id] = 0;
        }
      } catch (_) {
        /* ignore */
      }
    }
    if (mounted) setState(() {});
  }

  IconData _getListIcon(String iconId) {
    switch (iconId) {
      case 'groceries':
        return Icons.local_grocery_store;
      case 'electronics':
        return Icons.devices_other;
      case 'home':
        return Icons.home_outlined;
      case 'gift':
        return Icons.card_giftcard;
      case 'travel':
        return Icons.flight_takeoff;
      case 'work':
        return Icons.work_outline;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.list_alt;
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _frozenListsDuringSubmit = List<ShoppingList>.from(_latestLists);
    });
    final selections = _selected.toList();
    // Perform Firestore writes concurrently to shorten perceived delay
    await Future.wait(
      selections.map(
        (id) => ShoppingListService.addProductItemToList(
          listId: id,
          product: widget.product,
          quantity: _quantities[id] ?? _quantity,
          estimatedPrice: _unitPrice,
        ),
      ),
    );
    // Optimistic UI: bump estimatedTotal locally for smoother feedback; final totals
    // will be reconciled via hydration callable right after.
    try {
      final cache = ShoppingListCache.instance;
      for (final id in selections) {
        final qty = _quantities[id] ?? _quantity;
        final inc = _unitPrice * qty;
        final lists = cache.current;
        final idx = lists.indexWhere((l) => l.id == id);
        if (idx >= 0) {
          final cur = lists[idx];
          final newE = cur.estimatedTotal + inc;
          cache.applyLocalAggregates(id, estimatedTotal: newE);
        }
      }
      // Best-effort server reconciliation (does not block UI)
      // ignore: discarded_futures
      cache.reconcileHydrationFor(selections);
    } catch (_) {
      /* non-fatal */
    }
    if (!mounted) return;
    Navigator.pop(context, selections.length);
    // Use root ScaffoldMessenger after pop via microtask
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added to ${selections.length} list${selections.length == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    });
  }

  Widget _quantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove, size: 18, color: Colors.white70),
          ),
          Text(
            '$_quantity',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add, size: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      style: GoogleFonts.lato(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
        hintText: 'Search lists...',
        hintStyle: GoogleFonts.lato(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryAccentColor),
        ),
      ),
    );
  }

  // Small product thumbnail
  Widget _productThumb() {
    final img = widget.product.imageUrl;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1.2),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: .02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: img.isNotEmpty
          ? Image.network(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackThumb(),
            )
          : _fallbackThumb(),
    );
  }

  Widget _fallbackThumb() {
    final letter = widget.product.name.isNotEmpty
        ? widget.product.name[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.lato(
          color: Colors.white54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Extracted to keep list tile code reused between modes
  Widget _listTile(
    ShoppingList l, {
    required bool selected,
    required double priceInc,
    required double actualEstimatedTotal,
    required int actualTotalItems,
    required int actualCompletedItems,
    required double futureTotal,
    required bool overBudget,
    required double pct,
    required int? existing,
    required bool isInList,
    required int willAddItemCount,
    required int newTotalItems,
    required double predictedPct,
    required double budgetRemaining,
    required double futureRemaining,
    required double currentUsedPct,
    required double futureUsedPct,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: _tileDeco(l, selected),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Toggle selection
            setState(() {
              if (selected) {
                _selected.remove(l.id);
                _quantities.remove(l.id);
              } else {
                _selected.add(l.id);
                _quantities[l.id] = _quantity;
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: _iconDeco(l),
                      child: Icon(
                        _getListIcon(l.iconId),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.name,
                                  style: _listNameStyleBase.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isInList)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: l.themeColor.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: l.themeColor.withValues(alpha: .4),
                                      width: .8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 10,
                                        color: l.themeColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'in ×$existing',
                                        style: _inListBadgeStyleBase.copyWith(
                                          color: l.themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '$actualCompletedItems/$actualTotalItems',
                                style: _countStyleBase.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                              if (selected && willAddItemCount > 0) ...[
                                Text(
                                  ' → $actualCompletedItems/$newTotalItems',
                                  style: _countStyleBase.copyWith(
                                    color: l.themeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              Text(
                                ' • ${(pct * 100).round()}%',
                                style: _percentStyleBase.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                              if (selected && willAddItemCount > 0)
                                Text(
                                  ' → ${(predictedPct * 100).round()}%',
                                  style: _percentStyleBase.copyWith(
                                    color: l.themeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Modern visual elements: Members & Product Images
                          Row(
                            children: [
                              buildMemberAvatars(
                                l,
                                maxVisible: 3,
                                compact: true,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: buildStackedItemImages(
                                  l.id,
                                  maxVisible: 4,
                                  size: 24,
                                  overlap: 8,
                                  accentColor: l.themeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: selected ? l.themeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: selected ? l.themeColor : Colors.white30,
                              width: 1,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (selected && _unitPrice > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+Rs ${priceInc.toStringAsFixed(0)}',
                            style: _priceIncStyleBase.copyWith(
                              color: overBudget
                                  ? Colors.redAccent
                                  : l.themeColor,
                            ),
                          ),
                        ],
                        if (l.budgetLimit > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: overBudget
                                  ? Colors.redAccent.withValues(alpha: .15)
                                  : l.themeColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: overBudget
                                    ? Colors.redAccent
                                    : l.themeColor.withValues(alpha: .5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              () {
                                final cur = budgetRemaining.toStringAsFixed(0);
                                if (selected) {
                                  final fut = futureRemaining.toStringAsFixed(
                                    0,
                                  );
                                  return 'Rem $cur → $fut';
                                }
                                return 'Rem $cur';
                              }(),
                              style: _remStyleBase.copyWith(
                                color: overBudget
                                    ? Colors.redAccent
                                    : l.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (l.budgetLimit > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final currentPct = currentUsedPct.clamp(0.0, 1.0);
                        final futurePct = futureUsedPct.clamp(0.0, 1.1);
                        final curW = maxWidth * currentPct;
                        final futW = maxWidth * futurePct;
                        return Stack(
                          children: [
                            if (currentPct > 0)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: curW,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: overBudget
                                        ? Colors.redAccent.withValues(alpha: .8)
                                        : l.themeColor.withValues(alpha: .7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            if (selected && priceInc > 0 && futW > curW)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: futW,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: overBudget
                                        ? Colors.redAccent
                                        : l.themeColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Budget ${(currentUsedPct * 100).round()}%',
                        style: _budgetStyleBase.copyWith(
                          color: overBudget ? Colors.redAccent : Colors.white54,
                        ),
                      ),
                      if (selected && priceInc > 0)
                        Text(
                          ' → ${(futureUsedPct * 100).round()}%',
                          style: _budgetStyleBase.copyWith(
                            color: overBudget ? Colors.redAccent : l.themeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
