import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/shopping_lists/shopping_list_cards.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart'; // Standardized bottom sheet styling.
import 'package:shopple/widgets/shopping_lists/create_shopping_list_sheet.dart';
import '../../widgets/common/page_header.dart';
import '../../widgets/common/segmented_button_picker.dart';

import '../../models/shopping_lists/shopping_list_model.dart';
import '../shopping_lists/list_detail_screen.dart'; // Detail view.
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../services/shopping_lists/shopping_list_cache.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});
  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen>
    with TickerProviderStateMixin {
  final ValueNotifier<int> settingsButtonTrigger = ValueNotifier(0);
  final ValueNotifier<bool> switchGridLayout = ValueNotifier(false);
  bool _showingCreateSheet = false; // Prevent double-open.
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPrefs();
    // Warm cache on build.
    // Hydration handled internally.
    ShoppingListCache.instance.ensureSubscribed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool('shopping_lists_layout_grid') ?? false;
    final tab = prefs.getInt('shopping_lists_tab') ?? 0;
    switchGridLayout.value = isGrid;
    settingsButtonTrigger.value = tab;
  }

  Future<void> _persistLayout(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shopping_lists_layout_grid', isGrid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: "Shopping Lists",
                    actions: [
                      PageHeaderAction.iconButton(
                        icon: Icons.add,
                        onPressed: () => _openAddSheet(context),
                        tooltip: 'Add Shopping List',
                      ),
                      ValueListenableBuilder(
                        valueListenable: switchGridLayout,
                        builder: (BuildContext context, _, __) {
                          return PageHeaderAction.iconButton(
                            icon: switchGridLayout.value
                                ? FeatherIcons.clipboard
                                : FeatherIcons.grid,
                            onPressed: () {
                              switchGridLayout.value = !switchGridLayout.value;
                              _persistLayout(switchGridLayout.value);
                            },
                            tooltip: switchGridLayout.value
                                ? 'List View'
                                : 'Grid View',
                          );
                        },
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  SegmentedButtonPicker(
                    controller: _tabController,
                    tabs: [
                      SegmentedTabFactory.simple(
                        text: 'Active',
                        icon: Icons.list_alt,
                      ),
                      SegmentedTabFactory.simple(
                        text: 'Completed',
                        icon: Icons.check_circle_outline,
                      ),
                      SegmentedTabFactory.simple(
                        text: 'All Lists',
                        icon: Icons.folder_outlined,
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildShoppingListsTab(0), // Active
                        _buildShoppingListsTab(1), // Completed
                        _buildShoppingListsTab(2), // All Lists
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListsTab(int tabIndex) {
    return ValueListenableBuilder(
      valueListenable: switchGridLayout,
      builder: (context, isGridView, __) {
        return RefreshIndicator(
          onRefresh: () async {
            // Trigger smart hydration for all lists when user manually refreshes
            await ShoppingListCache.instance.forceRefreshHydration();
          },
          child: _buildShoppingListsContent(context, tabIndex, isGridView),
        );
      },
    );
  }

  void _openAddSheet(BuildContext context) {
    if (_showingCreateSheet) return; // debounce to avoid double load
    _showingCreateSheet = true;
    showAppBottomSheet(
      const CreateShoppingListSheet(),
      title: 'Create Shopping List',
      isScrollControlled: true,
    ).whenComplete(() {
      _showingCreateSheet = false;
    });
  }

  Widget _buildShoppingListsContent(
    BuildContext context,
    int selectedTab,
    bool isGridView,
  ) {
    return ValueListenableBuilder<List<ShoppingList>>(
      valueListenable: ShoppingListCache.instance.listenable,
      builder: (context, lists, _) {
        if (lists.isEmpty) {
          return _buildEmptyState(context);
        }
        final filteredLists = _filterListsByTab(lists, selectedTab);
        if (filteredLists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[500]),
                  const SizedBox(height: 12),
                  Text(
                    selectedTab == 0
                        ? 'No Active Lists'
                        : selectedTab == 1
                        ? 'No Completed Lists'
                        : 'No Lists',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: isGridView
              ? _buildGridView(context, filteredLists)
              : _buildListView(context, filteredLists),
        );
      },
    );
  }

  List<ShoppingList> _filterListsByTab(List<ShoppingList> lists, int tabIndex) {
    switch (tabIndex) {
      case 0: // Active
        return lists.where((list) => list.status == ListStatus.active).toList();
      case 1: // Completed
        return lists
            .where((list) => list.status == ListStatus.completed)
            .toList();
      case 2: // All Lists
      default:
        return lists;
    }
  }

  Widget _buildGridView(BuildContext context, List<ShoppingList> lists) {
    final width = MediaQuery.of(context).size.width;
    // Adjust crossAxisCount for very wide layouts (tablets) for better density
    int crossAxisCount = 2;
    if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 800) {
      crossAxisCount = 3;
    }
    // Lower aspect ratio for grid cards to accommodate budget progress bar and prevent overflow
    final aspectRatio = width < 400 ? 0.65 : 0.7;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        return ShoppingListCardVertical(
          key: ValueKey(lists[index].id),
          list: lists[index],
          compact: true,
          onTap: () => _navigateToListDetail(context, lists[index]),
          onDelete: () => _handleDeleteList(context, lists[index]),
          onArchive: () => _handleArchiveList(context, lists[index]),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<ShoppingList> lists) {
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        return ShoppingListCardHorizontal(
          key: ValueKey(lists[index].id),
          list: lists[index],
          onTap: () => _navigateToListDetail(context, lists[index]),
          onDelete: () => _handleDeleteList(context, lists[index]),
          onArchive: () => _handleArchiveList(context, lists[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Shopping Lists',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first shopping list to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          LiquidGlassButton.primary(
            onTap: () => _openAddSheet(context),
            icon: Icons.add,
            text: 'Create List',
            gradientColors: [AppColors.primaryAccentColor, AppColors.primaryAccentColor.withValues(alpha: 0.8)],
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }

  void _navigateToListDetail(BuildContext context, ShoppingList shoppingList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: shoppingList),
      ),
    ).then((_) {
      // Mark list for hydration refresh.
      // Ensure card shows latest aggregates.
      ShoppingListCache.instance.markListForHydration(shoppingList.id);
      ShoppingListCache.instance.smartHydrationCheck();
    });
  }

  Future<void> _handleDeleteList(
    BuildContext context,
    ShoppingList list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HexColor.fromHex("262A34"),
        title: const Text('Delete List', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context, false),
            text: 'Cancel',
          ),
          LiquidGlassButton.text(
            onTap: () => Navigator.pop(context, true),
            text: 'Delete',
            isDestructive: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ShoppingListService.deleteShoppingList(list.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${list.name} deleted'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete list: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleArchiveList(
    BuildContext context,
    ShoppingList list,
  ) async {
    try {
      final newStatus = list.status == ListStatus.archived
          ? ListStatus.active
          : ListStatus.archived;

      await ShoppingListService.updateShoppingList(
        listId: list.id,
        status: newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == ListStatus.archived
                  ? '${list.name} archived'
                  : '${list.name} unarchived',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update list: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

// Backward compatibility: old code referencing ProjectScreen still works
class ProjectScreen extends ShoppingListsScreen {
  const ProjectScreen({super.key});
}
