import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/controllers/shopping_lists/list_detail_controller.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/shopping_lists/shopping_list_item_model.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';
import 'package:shopple/widgets/common/liquid_text_field.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/pricing/current_price_consumer.dart';
import 'package:shopple/services/product/current_price_cache.dart';
import 'package:shopple/controllers/shopping_list_items_controller.dart';
import 'package:shopple/models/budget/budget_cadence.dart';
import 'package:shopple/models/budget/budget_period.dart';
import 'package:shopple/services/budget/budget_analytics_service.dart';

// Components.
import 'package:shopple/widgets/shopping_lists/detail/list_detail_header.dart';
import 'package:shopple/widgets/shopping_lists/detail/add_item_form.dart';
import 'package:shopple/widgets/shopping_lists/detail/shopping_items_list.dart';
import 'package:shopple/widgets/shopping_lists/detail/list_notes_bar.dart';
import 'ai_list_assistant_sheet.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;
  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late final ListDetailController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _storeBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = ListDetailController(list: widget.shoppingList);
    // Initialize after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.onReady();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Apply aggregates before deactivation.
    _controller.pushLocalAggregates();
    super.deactivate();
  }

  void _openAISheet() {
    showAppBottomSheet(
      const AIListAssistantSheet(),
      title: 'AI Assistant',
      isScrollControlled: true,
      maxHeightFactor: 0.82,
      
    );
  }

  void _showStoreMenu() async {
    final ctx = _storeBtnKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final stores = [..._controller.itemsController.availableStores]..sort();
    final selected = await showMenu<String?>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String?>(value: null, child: Text('All Stores')),
        const PopupMenuDivider(),
        const PopupMenuItem<String?>(
          value: '__SPLIT__',
          child: Text('Show Both (split by store)'),
        ),
        ...stores.map(
          (s) => PopupMenuItem<String?>(value: s, child: _PrettyStoreText(s)),
        ),
      ],
    );
    if (!mounted) return;
    if (selected == null) return;
    
    if (selected == '__SPLIT__') {
      _controller.itemsController.setSplitByStore(true);
    } else {
      _controller.itemsController.setSplitByStore(false);
      _controller.itemsController.setFilterStore(selected);
    }
  }

  void _showEditItemDialog(ShoppingListItem item) {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(
      text: item.estimatedPrice > 0
          ? item.estimatedPrice.toStringAsFixed(0)
          : '',
    );
    final notesController = TextEditingController(text: item.notes);
    final categoryController = TextEditingController(text: item.category);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LiquidTextField(
                controller: nameController,
                hintText: 'Name',
              ),
              const SizedBox(height: 12),
              LiquidTextField(
                controller: qtyController,
                hintText: 'Quantity',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              LiquidTextField(
                controller: priceController,
                hintText: 'Price',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              LiquidTextField(
                controller: categoryController,
                hintText: 'Category',
              ),
              const SizedBox(height: 12),
              LiquidTextField(
                controller: notesController,
                hintText: 'Notes',
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context),
            text: 'Cancel',
            isDestructive: true,
          ),
          LiquidGlassButton.primary(
            onTap: () async {
              final qty = int.tryParse(qtyController.text.trim());
              final price = double.tryParse(priceController.text.trim());
              final nav = Navigator.of(context);
              await ShoppingListService.updateItem(
                listId: _controller.listId,
                itemId: item.id,
                quantity: qty,
                notes: notesController.text.trim(),
                estimatedPrice: price,
                category: categoryController.text.trim(),
              );
              _controller.pushLocalAggregates();
              ShoppingListCache.instance.reconcileHydrationFor([_controller.listId]);
              nav.pop();
            },
            text: 'Save',
          ),
        ],
      ),
    );
  }

  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text(
          'Are you sure you want to delete this shopping list and all its items?',
        ),
        actions: [
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context),
            text: 'Cancel',
          ),
          LiquidGlassButton.primary(
            gradientColors: [Colors.redAccent, Colors.red.shade700],
            onTap: () async {
              final nav = Navigator.of(context);
              await ShoppingListService.deleteShoppingList(_controller.listId);
              nav.pop();
              nav.pop();
            },
            text: 'Delete',
          ),
        ],
      ),
    );
  }

  void _showEditListDialog() {
    final list = _controller.list;
    final nameController = TextEditingController(text: list.name);
    final descController = TextEditingController(text: list.description);
    final budgetController = TextEditingController(
      text: list.budgetLimit > 0 ? list.budgetLimit.toStringAsFixed(0) : '',
    );
    final initialCadence = list.budgetLimit > 0
        ? (list.budgetCadence == BudgetCadence.none
              ? BudgetCadence.oneTime
              : list.budgetCadence)
        : BudgetCadence.none;
    final currentPeriod = BudgetAnalyticsService.currentPeriodForList(
      list,
      DateTime.now(),
    );
    final currentPeriodSpend = _controller.spendForPeriod(currentPeriod);
    
    showDialog(
      context: context,
      builder: (context) {
        BudgetCadence cadence = initialCadence;
        DateTime anchor = list.budgetAnchor;
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final period = cadence == BudgetCadence.none
                ? null
                : _periodForCadence(anchor, cadence);
            final periodSpend = period != null ? _controller.spendForPeriod(period) : 0;
            final periodLabel = period != null
                ? period.formattedLabel()
                : 'No active budget';
            final remainingPreview =
                (double.tryParse(budgetController.text.trim()) ?? 0) -
                periodSpend;

            return AlertDialog(
              title: const Text('Edit List'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LiquidTextField(
                      controller: nameController,
                      hintText: 'Name',
                    ),
                    const SizedBox(height: 12),
                    LiquidTextField(
                      controller: descController,
                      hintText: 'Description',
                    ),
                    const SizedBox(height: 12),
                    LiquidTextField(
                      controller: budgetController,
                      hintText: 'Budget (optional)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BudgetCadence>(
                      initialValue: cadence,
                      decoration: const InputDecoration(
                        labelText: 'Budget cadence',
                      ),
                      items: BudgetCadence.values
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          cadence = value;
                          if (cadence != BudgetCadence.none) {
                            anchor = _recommendedAnchorForCadence(cadence);
                          }
                        });
                      },
                    ),
                    if (cadence != BudgetCadence.none) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Period: $periodLabel')),
                          LiquidGlassButton.text(
                            onTap: () {
                              setDialogState(() {
                                anchor = _recommendedAnchorForCadence(cadence);
                              });
                            },
                            text: 'Align to now',
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ],
                      ),
                      Text(
                        'Spend this period: Rs ${periodSpend.toStringAsFixed(0)}',
                      ),
                      Text(
                        'Remaining after save: Rs ${remainingPreview.toStringAsFixed(0)}',
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        'Current period spend: Rs ${currentPeriodSpend.toStringAsFixed(0)}',
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                LiquidGlassButton.text(
                  onTap: () => Navigator.pop(context),
                  text: 'Cancel',
                ),
                LiquidGlassButton.primary(
                  onTap: () async {
                    final parsedBudget = double.tryParse(
                      budgetController.text.trim(),
                    );
                    final double budgetValue = parsedBudget ?? 0;
                    final hasBudget = budgetValue > 0;
                    final effectiveCadence = hasBudget
                        ? (cadence == BudgetCadence.none
                              ? BudgetCadence.oneTime
                              : cadence)
                        : BudgetCadence.none;
                    final BudgetPeriod? nextPeriod = hasBudget
                        ? _periodForCadence(anchor, effectiveCadence)
                        : null;
                    final double nextPeriodSpend = nextPeriod != null
                        ? _controller.spendForPeriod(nextPeriod)
                        : 0;
                    if (hasBudget &&
                        nextPeriod != null &&
                        budgetValue < nextPeriodSpend) {
                      setDialogState(() {
                        error =
                            'Current spend ${nextPeriodSpend.toStringAsFixed(0)} exceeds the new budget.';
                      });
                      return;
                    }
                    final nav = Navigator.of(context);
                    await ShoppingListService.updateShoppingList(
                      listId: list.id,
                      name: nameController.text.trim().isEmpty
                          ? null
                          : nameController.text.trim(),
                      description: descController.text.trim(),
                      budgetLimit: budgetValue,
                      budgetCadence: effectiveCadence,
                      budgetAnchor: nextPeriod?.start,
                    );
                    nav.pop();
                  },
                  text: 'Save',
                ),
              ],
            );
          },
        );
      },
    );
  }

  BudgetPeriod _periodForCadence(DateTime anchor, BudgetCadence cadence) {
    final normalized = DateTime(anchor.year, anchor.month, anchor.day);
    switch (cadence) {
      case BudgetCadence.none:
        return BudgetPeriod(
          start: normalized,
          end: null,
          cadence: BudgetCadence.none,
        );
      case BudgetCadence.oneTime:
        return BudgetPeriod(
          start: normalized,
          end: null,
          cadence: BudgetCadence.oneTime,
        );
      case BudgetCadence.weekly:
        final start = _startOfWeekDate(normalized);
        return BudgetPeriod(
          start: start,
          end: start.add(const Duration(days: 7)),
          cadence: BudgetCadence.weekly,
        );
      case BudgetCadence.monthly:
        final start = DateTime(normalized.year, normalized.month);
        final end = DateTime(start.year, start.month + 1);
        return BudgetPeriod(
          start: start,
          end: end,
          cadence: BudgetCadence.monthly,
        );
    }
  }

  DateTime _recommendedAnchorForCadence(BudgetCadence cadence) {
    final now = DateTime.now();
    switch (cadence) {
      case BudgetCadence.none:
      case BudgetCadence.oneTime:
        return DateTime(now.year, now.month, now.day);
      case BudgetCadence.weekly:
        return _startOfWeekDate(now);
      case BudgetCadence.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _startOfWeekDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CurrentPriceConsumer(
          productIds: _controller.itemsController.mergedItems
              .map((e) => e.productId)
              .whereType<String>()
              .toList(),
          builder: (context, _) {
            // sync from cache
            final cache = CurrentPriceCache.instance;
            for (final id
                in _controller.itemsController.mergedItems
                    .map((e) => e.productId)
                    .whereType<String>()) {
              final cheapest = cache.cheapestFor(id);
              if (cheapest != null) _controller.currentUnitPrices[id] = cheapest;
            }
            
            return Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _openAISheet,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Assist'),
                backgroundColor: HexColor.fromHex(_controller.list.colorTheme),
              ),
              body: Stack(
                children: [
                  // background gradient / legacy style
                  DarkRadialBackground(
                    color: HexColor.fromHex("#181a1f"),
                    position: 'topLeft',
                  ),
                  // Scroll body
                  Positioned.fill(
                    top: 120,
                    child: Column(
                      children: [
                        ListDetailHeader(
                          controller: _controller,
                          onStoreMenuTap: _showStoreMenu,
                          storeButtonKey: _storeBtnKey,
                        ),
                        AddItemForm(
                          controller: _controller,
                          formKey: _formKey,
                        ),
                        Expanded(
                          child: ShoppingItemsList(
                            controller: _controller,
                            onEditItem: _showEditItemDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection action bar.
                  if (_controller.itemsController.selectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 70,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: LiquidGlass(
                            borderRadius: 18,
                            enableBlur: true,
                            blurSigmaX: 14,
                            blurSigmaY: 22,
                            gradientColors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                            borderColor: Colors.white.withValues(alpha: 0.10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${_controller.itemsController.selectedIds.length} selected',
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      _controller.itemsController.bulkCompleteSelected();
                                    },
                                    child: const Text('Complete'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: () {
                                      _controller.itemsController.bulkDeleteSelected();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Deleted ${_controller.itemsController.selectedIds.length} items',
                                          ),
                                          action: SnackBarAction(
                                            label: 'UNDO',
                                            onPressed: () {
                                              _controller.undoDelete();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () =>
                                        _controller.itemsController.clearSelection(),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // All items completed prompt.
                  if (_controller.itemsController.mergedItems.isNotEmpty &&
                      _controller.itemsController.mergedItems.every((i) => i.isCompleted) &&
                      _controller.list.status != ListStatus.completed)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 140,
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: LiquidGlassButton.primary(
                            onTap: () {
                              ShoppingListService.updateShoppingList(
                                listId: _controller.listId,
                                status: ListStatus.completed,
                              );
                            },
                            icon: Icons.check_circle_outline,
                            text: 'Mark list completed',
                            gradientColors: [AppColors.accentGreen, AppColors.accentGreen.withValues(alpha: 0.8)],
                            borderRadius: 30,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // Blurred header with actions.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: LiquidGlass(
                        borderRadius: 0,
                        enableBlur: true,
                        blurSigmaX: 10,
                        blurSigmaY: 20,
                        gradientColors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                        borderColor: Colors.white.withValues(alpha: 0.06),
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.only(
                            top: 40,
                            left: 16,
                            right: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              // Quick completion toggle.
                              IconButton(
                                tooltip: _controller.list.status == ListStatus.completed
                                    ? 'Mark Active'
                                    : 'Mark Completed',
                                icon: Icon(
                                  _controller.list.status == ListStatus.completed
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle,
                                  color: AppColors.accentGreen,
                                ),
                                onPressed: () {
                                  ShoppingListService.updateShoppingList(
                                    listId: _controller.listId,
                                    status: _controller.list.status == ListStatus.completed
                                        ? ListStatus.active
                                        : ListStatus.completed,
                                  );
                                },
                              ),
                              Expanded(
                                child: Text(
                                  _controller.list.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: HexColor.fromHex("262A34"),
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                ),
                                onSelected: (val) {
                                  switch (val) {
                                    case 'edit':
                                      _showEditListDialog();
                                      break;
                                    case 'complete':
                                      ShoppingListService.updateShoppingList(
                                        listId: _controller.listId,
                                        status: ListStatus.completed,
                                      );
                                      break;
                                    case 'archive':
                                      ShoppingListService.updateShoppingList(
                                        listId: _controller.listId,
                                        status: ListStatus.archived,
                                      );
                                      break;
                                    case 'activate':
                                      ShoppingListService.updateShoppingList(
                                        listId: _controller.listId,
                                        status: ListStatus.active,
                                      );
                                      break;
                                    case 'delete':
                                      _confirmDeleteList();
                                      break;
                                  }
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit List'),
                                    ),
                                  );
                                  if (_controller.list.status != ListStatus.completed) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'complete',
                                        child: Text('Mark Completed'),
                                      ),
                                    );
                                  }
                                  if (_controller.list.status != ListStatus.archived) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'archive',
                                        child: Text('Archive'),
                                      ),
                                    );
                                  }
                                  if (_controller.list.status == ListStatus.archived) {
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: Text('Reactivate'),
                                      ),
                                    );
                                  }
                                  items.add(const PopupMenuDivider());
                                  items.add(
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                  );
                                  return items;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Reorder confirmation bar.
                  if (!_controller.showCategories &&
                      _controller.itemsController.sortMode == ItemSortMode.manual &&
                      _controller.itemsController.reorderInProgress)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 70,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: LiquidGlass(
                            borderRadius: 18,
                            enableBlur: true,
                            blurSigmaX: 14,
                            blurSigmaY: 22,
                            gradientColors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                            borderColor: Colors.white.withValues(alpha: 0.10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.drag_indicator,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reorder pending',
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  LiquidGlassButton.text(
                                    onTap: () {
                                      _controller.itemsController.cancelReorder();
                                    },
                                    text: 'Discard',
                                    isDestructive: true,
                                  ),
                                  const SizedBox(width: 4),
                                  LiquidGlassButton.text(
                                    onTap: () async {
                                      await _controller.itemsController.commitReorder();
                                    },
                                    text: 'Save order',
                                    accentColor: AppColors.primaryAccentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                  // Bottom notes bar.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ListNotesBar(controller: _controller),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PrettyStoreText extends StatelessWidget {
  final String text;
  const _PrettyStoreText(this.text);
  
  @override
  Widget build(BuildContext context) {
    String pretty;
    switch (text.toLowerCase()) {
      case 'keells':
        pretty = 'Keells';
        break;
      case 'cargills':
        pretty = 'Cargills';
        break;
      case 'unknown':
        pretty = 'Other Stores';
        break;
      default:
        pretty = text;
    }
    return Text(pretty);
  }
}
