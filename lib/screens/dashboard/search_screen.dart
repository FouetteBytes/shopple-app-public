import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/controllers/search/product_search_controller.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_tab_buttons.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/search/all_categories_sheet.dart';
import 'package:shopple/widgets/search/animated_categories_header.dart';
import 'package:shopple/widgets/search/animated_categories_header_delegate.dart';
import 'package:shopple/widgets/search/results/search_results_view.dart';
import 'package:shopple/widgets/search/results/search_suggestions_view.dart';
import 'package:shopple/widgets/search/search_header.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  late final ProductSearchController _controller;
  final ValueNotifier<int> settingsButtonTrigger = ValueNotifier(-1);
  final GlobalKey _searchHeaderKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _collapseController;
  late Animation<double> _collapseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = ProductSearchController();
    _controller.init();

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 380),
    );
    
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeOutCubic,
    );

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_controller.forceCollapsed && _collapseController.status != AnimationStatus.completed) {
      _collapseController.animateTo(1, curve: Curves.easeOutBack);
    } else if (!_controller.forceCollapsed && _collapseController.status != AnimationStatus.dismissed) {
      _collapseController.animateTo(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    settingsButtonTrigger.dispose();
    _collapseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            DarkRadialBackground(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
              position: 'topLeft',
            ),
            if (_controller.isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'You are offline. Check your connection. We\'ll resume automatically.',
                            style: GoogleFonts.poppins(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTapDown: (details) {
                    final box = _searchHeaderKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final rect = box.localToGlobal(Offset.zero) & box.size;
                      if (!rect.inflate(4).contains(details.globalPosition)) {
                        if (_controller.showRecentSearches) {
                          _controller.showRecentSearches = false;
                        }
                        if (_controller.searchFocusNode.hasFocus) {
                          _controller.searchFocusNode.unfocus();
                        }
                      }
                    }
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification || n is UserScrollNotification) {
                        if (_controller.showRecentSearches) {
                          _controller.showRecentSearches = false;
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      key: const PageStorageKey('search_scroll'),
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  key: _searchHeaderKey,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.06)),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: SearchHeader(
                                    controller: _controller.searchController,
                                    focusNode: _controller.searchFocusNode,
                                    isLoading: _controller.isLoading,
                                    onChanged: _controller.handleSearchChange,
                                    onCameraTap: () => _controller.handleCameraSearch(context),
                                    onCancel: () {
                                      _controller.clearSearch();
                                      FocusScope.of(context).unfocus();
                                      // Animation handled by listener
                                    },
                                  ),
                                ),
                                SearchSuggestionsView(controller: _controller),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      PrimaryTabButton(
                                        buttonText: 'All Categories',
                                        itemIndex: 0,
                                        notifier: settingsButtonTrigger,
                                        callback: () async {
                                          settingsButtonTrigger.value = 0;
                                          final id = await showAppBottomSheet(
                                            const AllCategoriesSheet(),
                                            isScrollControlled: true,
                                            maxHeightFactor: 0.92,
                                          ) as String?;
                                          
                                          if (id != null && id.isNotEmpty) {
                                            _controller.selectedProductType = id;
                                            _controller.searchController.clear();
                                            _controller.suggestions.clear();
                                            await _controller.loadCategoryProducts(id);
                                          } else {
                                            settingsButtonTrigger.value = -1;
                                          }
                                        },
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                        child: _controller.selectedProductType != 'all'
                                            ? Padding(
                                                key: const ValueKey('clearCat'),
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Tooltip(
                                                  message: 'Clear category filter',
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(32),
                                                    onTap: () {
                                                      _controller.selectedProductType = 'all';
                                                      _controller.baseResults.clear();
                                                      _controller.searchResults.clear();
                                                      _controller.showPersonalizedDefaults = true;
                                                      _controller.forceCollapsed = false;
                                                      settingsButtonTrigger.value = -1;
                                                      _controller.loadRecentlyViewed();
                                                      // Animation handled by listener
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.surface,
                                                        borderRadius: BorderRadius.circular(32),
                                                        border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.08)),
                                                      ),
                                                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.primaryText),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      const Spacer(),
                                      Tooltip(
                                        message: _controller.gridMode ? 'Switch to list view' : 'Switch to grid view',
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: _controller.toggleGridMode,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            curve: Curves.easeOut,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.08)),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 150),
                                              child: Icon(
                                                _controller.gridMode ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                                                key: ValueKey(_controller.gridMode),
                                                size: 20,
                                                color: AppColors.primaryText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: AnimatedCategoriesHeaderDelegate(
                            minExtentHeight: 72,
                            maxExtentHeight: (_controller.selectedProductType != 'all' && _controller.hasQuickFilterCandidates) ? 410 : 340,
                            rebuildToken: _controller.forceCollapsed ? 1 : 0,
                            forceCollapsed: _controller.forceCollapsed,
                            builder: (context, shrinkOffset, overlaps) => AnimatedCategoriesHeader(
                              controller: _controller,
                              shrinkOffset: shrinkOffset,
                              collapseAnimation: _collapseAnimation,
                            ),
                          ),
                        ),
                        if (_controller.forceCollapsed &&
                            _controller.searchResults.isEmpty &&
                            _controller.searchController.text.isEmpty &&
                            !_controller.isLoading)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.06)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.search_rounded, size: 48, color: AppColors.primaryAccentColor.withValues(alpha: 0.7)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Start typing to search',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Search for products, brands, or categories',
                                    style: GoogleFonts.poppins(color: AppColors.primaryText70, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SearchResultsView(controller: _controller),
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
