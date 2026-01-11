import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shopple/config/feature_flags.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/ml/teachable_machine_service.dart';
import 'package:shopple/services/product/current_price_cache.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/services/search/autocomplete_service.dart';
import 'package:shopple/services/search/cloud_recent_search_service.dart';
import 'package:shopple/services/search/fast_product_search_service.dart';
import 'package:shopple/services/search/recent_search_service.dart';
import 'package:shopple/services/search/unified_product_search_service.dart';
import 'package:shopple/services/category_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/values/values.dart';

class ProductSearchController extends ChangeNotifier {
  // Controllers
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  // State
  bool isLoading = false;
  bool loadingRecent = false;
  bool isOffline = false;
  bool gridMode = false;
  bool showRecentSearches = false;
  bool showAllRecent = false;
  bool showPersonalizedDefaults = true;
  bool forceCollapsed = false;
  bool isFallbackSuggestions = false;
  
  // Data
  List<ProductWithPrices> searchResults = [];
  List<ProductWithPrices> baseResults = [];
  List<ProductWithPrices> recentlyViewed = [];
  List<String> suggestions = [];
  List<String> allRecentSearches = [];
  List<String> recentSearches = [];
  List<String> matchingRecent = [];
  
  // Filters
  final Set<String> selectedStores = {};
  String selectedProductType = 'all';
  String? activeUnitFilter;
  String? activeBrandFilter;
  String sortBy = 'relevance';
  
  // Internal
  Timer? _searchDebounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<Set<String>>? _priceUpdateSub;
  final Connectivity _connectivity = Connectivity();
  int _searchSeq = 0;
  int _suggestionSeq = 0;
  String? _pendingQuery;

  bool get hasActiveQuickFilter =>
      (activeUnitFilter != null && activeUnitFilter!.isNotEmpty) ||
      (activeBrandFilter != null && activeBrandFilter!.isNotEmpty);

  bool get hasQuickFilterCandidates {
    final source = baseResults.isNotEmpty ? baseResults : searchResults;
    if (source.isEmpty) return false;
    final brands = <String>{};
    final units = <String>{};
    for (final r in source.take(60)) {
      if (r.product.brandName.isNotEmpty) brands.add(r.product.brandName);
      if (r.product.sizeUnit.isNotEmpty) units.add(r.product.sizeUnit);
      if (brands.isNotEmpty || units.isNotEmpty) return true;
    }
    return brands.isNotEmpty || units.isNotEmpty;
  }

  void init() {
    _buildSearchDictionaryInBackground();
    loadRecentlyViewed();
    _initConnectivity();
    _initPriceUpdates();
    
    searchFocusNode.addListener(() {
      if (searchFocusNode.hasFocus) {
        loadRecentHistory();
        updateDropdown();
      } else {
        showRecentSearches = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    _connectivitySub?.cancel();
    _priceUpdateSub?.cancel();
    super.dispose();
  }

  void _initConnectivity() {
    Future.microtask(() async {
      try {
        final initial = await _connectivity.checkConnectivity();
        isOffline = initial.contains(ConnectivityResult.none) && initial.length == 1;
        notifyListeners();
      } catch (_) {}
    });

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final nowOffline = results.contains(ConnectivityResult.none) && results.length == 1;
      if (nowOffline != isOffline) {
        isOffline = nowOffline;
        notifyListeners();
      }
      if (!nowOffline && _pendingQuery != null) {
        final q = _pendingQuery!;
        _pendingQuery = null;
        performIntelligentSearch(q);
      }
    });
  }

  void _initPriceUpdates() {
    _priceUpdateSub = CurrentPriceCache.instance.changedProducts.listen((changedIds) {
      final visibleIds = baseResults.map((p) => p.product.id).toSet();
      if (visibleIds.intersection(changedIds).isNotEmpty) {
        baseResults = baseResults.map((p) {
          if (changedIds.contains(p.product.id)) {
            final prices = CurrentPriceCache.instance.pricesFor(p.product.id);
            return ProductWithPrices(
              product: p.product,
              prices: prices ?? const {},
            );
          }
          return p;
        }).toList();
        applySorting();
      }
    });
  }

  Future<void> loadRecentlyViewed() async {
    try {
      loadingRecent = true;
      notifyListeners();
      recentlyViewed = await RecentlyViewedService.getWithPrices(limit: 20);
    } catch (_) {
      recentlyViewed = [];
    } finally {
      loadingRecent = false;
      notifyListeners();
    }
  }

  Future<void> _buildSearchDictionaryInBackground() async {
    try {
      final products = await EnhancedProductService.getAllProducts();
      await AutocompleteService.buildSearchDictionary(products);
    } catch (e) {
      AppLogger.e('Autocomplete dictionary build failed', error: e);
    }
  }

  void handleSearchChange(String value) {
    _updateTypeaheadSuggestions(value);
    _searchDebounceTimer?.cancel();
    
    if (value.trim().isEmpty) {
      searchResults.clear();
      baseResults.clear();
      showPersonalizedDefaults = true;
      forceCollapsed = false;
      showAllRecent = false;
      updateDropdown();
      notifyListeners();
      return;
    }

    if (!forceCollapsed) {
      forceCollapsed = true;
      notifyListeners();
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 280), () {
      final q = value.trim();
      if (isOffline) {
        _pendingQuery = q;
        return;
      }
      performIntelligentSearch(q);
    });
  }

  Future<void> _updateTypeaheadSuggestions(String raw) async {
    final input = raw.trim();
    if (!forceCollapsed && input.isNotEmpty) {
      forceCollapsed = true;
      notifyListeners();
    }

    if (input.isEmpty || input.length < 2) {
      suggestions = [];
      isFallbackSuggestions = false;
      updateDropdown();
      notifyListeners();
      return;
    }

    final int seq = ++_suggestionSeq;
    final local = AutocompleteService.getSuggestions(input);
    
    final categoryMaps = CategoryService.getCategoriesForUI(includeAll: false);
    final categoryNames = <String>[];
    for (final m in categoryMaps) {
      final name = CategoryService.getDisplayName(m['id']!);
      if (name.toLowerCase().contains(input.toLowerCase())) {
        categoryNames.add(name);
      }
    }

    List<String> merged = [];
    void addAll(Iterable<String> list) {
      for (final s in list) {
        final t = s.trim();
        if (t.isEmpty || t.length < 2) continue;
        if (t.toLowerCase() == input.toLowerCase()) continue;
        
        final isGoodMatch = t.toLowerCase().startsWith(input.toLowerCase()) ||
            t.toLowerCase().contains(' ${input.toLowerCase()}');

        if (isGoodMatch && !merged.any((e) => e.toLowerCase() == t.toLowerCase())) {
          merged.add(t);
        }
      }
    }

    addAll(local);
    addAll(categoryNames);

    if (seq == _suggestionSeq) {
      suggestions = merged.take(6).toList();
      updateDropdown();
      notifyListeners();
    }
  }

  void updateDropdown() {
    if (!searchFocusNode.hasFocus) {
      showRecentSearches = false;
      notifyListeners();
      return;
    }

    final input = searchController.text.trim();
    if (input.isEmpty) {
      recentSearches = showAllRecent ? allRecentSearches : allRecentSearches.take(4).toList();
      matchingRecent = [];
    } else {
      final lower = input.toLowerCase();
      matchingRecent = allRecentSearches.where((r) => r.contains(lower)).take(6).toList();
      recentSearches = matchingRecent;
    }

    final bool shouldShow = suggestions.isNotEmpty || recentSearches.isNotEmpty || input.isEmpty;
    if (suggestions.length > 6) suggestions = suggestions.take(6).toList();
    
    if (!forceCollapsed && shouldShow) {
      forceCollapsed = true;
    }
    showRecentSearches = shouldShow;
    notifyListeners();
  }

  Future<void> performIntelligentSearch(String query) async {
    final int seq = ++_searchSeq;
    isLoading = true;
    showPersonalizedDefaults = false;
    isFallbackSuggestions = false;
    notifyListeners();

    if (isOffline) {
      _pendingQuery = query;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final filters = <String, dynamic>{};
      if (selectedProductType.isNotEmpty && selectedProductType != 'all') {
        filters['category'] = selectedProductType;
      }
      if (selectedStores.isNotEmpty) {
        filters['stores'] = selectedStores.toList();
      }

      List<ProductWithPrices> results = [];
      if (FeatureFlags.enableFastProductSearch) {
        results = await FastProductSearchService.search(
          query,
          filters: filters,
          limit: 20,
        );
      }

      if (results.isEmpty) {
        results = await EnhancedProductService.searchProductsWithPrices(query);
      }

      if (seq != _searchSeq) return;

      baseResults = results;
      isLoading = false;
      applySorting();
      
      try {
        UnifiedProductSearchService.recordExternalSearch(query, results, source: 'ui');
      } catch (_) {}

      if (FeatureFlags.enableFastProductSearch && results.isNotEmpty) {
        final ids = results.map((r) => r.product.id).toList();
        _enrichResultsInBackground(ids, seq, query, results);
      }

      unawaited(RecentSearchService.saveQuery(query));
      unawaited(CloudRecentSearchService.saveQuery(query));
      unawaited(loadRecentHistory(refreshOnly: true));
    } catch (e) {
      if (seq != _searchSeq) return;
      AppLogger.e('Search failed', error: e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _enrichResultsInBackground(List<String> ids, int seq, String query, List<ProductWithPrices> initialResults) async {
    try {
      final batched = await EnhancedProductService.getCurrentPricesForProducts(ids);
      if (seq != _searchSeq) return;
      
      baseResults = initialResults.map((r) => ProductWithPrices(
        product: r.product,
        prices: batched[r.product.id] ?? r.prices,
      )).toList();
      
      applySorting();
      try {
        UnifiedProductSearchService.recordExternalSearch(query, baseResults, source: 'ui_enriched');
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> loadCategoryProducts(String categoryId) async {
    isLoading = true;
    showPersonalizedDefaults = false;
    notifyListeners();
    
    final int seq = ++_searchSeq;
    try {
      final products = await EnhancedProductService.getProductsByCategory(categoryId);
      
      baseResults = products.map((p) => ProductWithPrices(product: p, prices: const {})).toList();
      isLoading = false;
      applySorting();

      _enrichCategoryProductsInBackground(products, seq);
      
      unawaited(RecentSearchService.saveQuery(categoryId));
      unawaited(CloudRecentSearchService.saveQuery(categoryId));
      unawaited(loadRecentHistory(refreshOnly: true));
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _enrichCategoryProductsInBackground(List<Product> products, int seq) async {
    try {
      final ids = products.map((p) => p.id).toList();
      final cheapestMap = await CurrentPriceCache.instance.prime(ids);
      if (seq != _searchSeq) return;
      
      baseResults = products.map((p) {
        final cheap = cheapestMap[p.id];
        return ProductWithPrices(
          product: p,
          prices: cheap == null ? const {} : {
            'cheapest': CurrentPrice(
              id: 'cheapest',
              supermarketId: '',
              productId: p.id,
              price: cheap,
              priceDate: '',
              lastUpdated: '',
            ),
          },
        );
      }).toList();
      applySorting();
    } catch (_) {}
  }

  Future<void> loadRecentHistory({bool refreshOnly = false}) async {
    try {
      final local = await RecentSearchService.getRecent(limit: 50);
      final remote = await CloudRecentSearchService.getAll(limit: 50);
      final seen = <String>{};
      final merged = <String>[];
      for (final q in local) {
        if (seen.add(q)) merged.add(q);
      }
      for (final q in remote) {
        if (seen.add(q)) merged.add(q);
      }
      
      allRecentSearches = merged;
      if (!refreshOnly) {
        showRecentSearches = true;
        showAllRecent = false;
      }
      if (!refreshOnly) updateDropdown();
      notifyListeners();
    } catch (_) {}
  }

  void applySorting() {
    List<ProductWithPrices> sorted = List<ProductWithPrices>.from(baseResults);

    if (selectedStores.isNotEmpty) {
      sorted = sorted.where((p) => p.prices.keys.any((k) => selectedStores.contains(k))).toList();
    }

    if (activeUnitFilter != null && activeUnitFilter!.isNotEmpty) {
      final unit = activeUnitFilter!.toLowerCase();
      sorted = sorted.where((p) => p.product.sizeUnit.toLowerCase() == unit).toList();
    }
    if (activeBrandFilter != null && activeBrandFilter!.isNotEmpty) {
      final brand = activeBrandFilter!.toLowerCase();
      sorted = sorted.where((p) => p.product.brandName.toLowerCase() == brand).toList();
    }

    double? bestFilteredPrice(ProductWithPrices p) {
      final all = p.prices;
      final filtered = selectedStores.isEmpty
          ? all
          : Map<String, CurrentPrice>.fromEntries(
              all.entries.where((e) => selectedStores.contains(e.key)),
            );
      if (filtered.isEmpty) return null;
      return filtered.values.map((cp) => cp.price).reduce((a, b) => a < b ? a : b);
    }

    int priceCompare(ProductWithPrices a, ProductWithPrices b) {
      final pa = bestFilteredPrice(a);
      final pb = bestFilteredPrice(b);
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pa.compareTo(pb);
    }

    switch (sortBy) {
      case 'price_low':
        sorted.sort(priceCompare);
        break;
      case 'price_high':
        sorted.sort((a, b) => -priceCompare(a, b));
        break;
      case 'name':
        sorted.sort((a, b) => a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase()));
        break;
      case 'brand':
        sorted.sort((a, b) => a.product.brandName.toLowerCase().compareTo(b.product.brandName.toLowerCase()));
        break;
      case 'relevance':
      default:
        break;
    }

    searchResults = sorted;
    notifyListeners();
  }

  void clearQuickFilters() {
    activeUnitFilter = null;
    activeBrandFilter = null;
    applySorting();
  }

  void setUnitFilter(String? unit) {
    activeUnitFilter = unit;
    applySorting();
  }

  void setBrandFilter(String? brand) {
    activeBrandFilter = brand;
    applySorting();
  }

  void toggleGridMode() {
    gridMode = !gridMode;
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    isLoading = false;
    isFallbackSuggestions = false;
    showAllRecent = false;
    showPersonalizedDefaults = true;
    searchResults = [];
    baseResults = [];
    forceCollapsed = false;
    notifyListeners();
    loadRecentlyViewed();
  }

  Future<void> handleCameraSearch(BuildContext context) async {
    final service = TeachableMachineService();

    if (!service.isModelLoaded) {
      const modelName = 'item-identifier';
      try {
        if (context.mounted) {
          LiquidSnack.show(
            title: 'Downloading...',
            message: 'Downloading AI model...',
            accentColor: AppColors.primaryAccentColor,
          );
        }
        await service.loadFromFirebase(modelName: modelName);
      } catch (e) {
        AppLogger.e('Error downloading model: $e');
        if (context.mounted) {
          LiquidSnack.error(title: 'Model Error', message: 'Error loading model: $e');
        }
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        if (context.mounted) {
          LiquidSnack.show(
            title: 'Analyzing',
            message: 'Analyzing image...',
            accentColor: AppColors.primaryAccentColor,
          );
        }

        final File imageFile = File(image.path);
        final String? label = await service.classifyImage(imageFile);

        if (label != null) {
          searchController.text = label;
          handleSearchChange(label);
        } else {
          if (context.mounted) {
            LiquidSnack.error(title: 'No Match', message: 'Could not recognize item.');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        LiquidSnack.error(title: 'Error', message: e.toString());
      }
    }
  }
  
  Future<void> clearHistory() async {
    await RecentSearchService.clearAll();
    await CloudRecentSearchService.clearAll();
    allRecentSearches = [];
    recentSearches = [];
    showAllRecent = false;
    updateDropdown();
  }
  
  void toggleShowAllRecent() {
    showAllRecent = !showAllRecent;
    updateDropdown();
  }
}
