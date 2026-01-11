import 'dart:async';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/search/fast_product_search_service.dart';
import 'package:shopple/utils/app_logger.dart';

/// A lightweight shared search layer so both UI and AI agent see the same recent queries/results.
/// Maintains an in-memory LRU map of recent search results and exposes a broadcast stream.
class UnifiedProductSearchService {
  static final Map<String, List<ProductWithPrices>> _recent =
      <String, List<ProductWithPrices>>{};
  static const int _maxEntries = 30;
  static final StreamController<UnifiedSearchEvent> _events =
      StreamController.broadcast();

  static Stream<UnifiedSearchEvent> get events => _events.stream;

  /// Perform unified search (fast remote + fallback local) and record results.
  static Future<List<ProductWithPrices>> search(
    String query, {
    Map<String, dynamic>? filters,
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    List<ProductWithPrices> results = [];
    try {
      // Fast path
      try {
        results = await FastProductSearchService.search(
          q,
          filters: filters ?? const {},
          limit: limit,
        );
      } catch (e) {
        AppLogger.w('[UNIFIED_SEARCH] Fast search failed, falling back: $e');
      }
      if (results.isEmpty) {
        results = await EnhancedProductService.searchProductsWithPrices(q);
      }
    } catch (e) {
      AppLogger.e('[UNIFIED_SEARCH] Search failed: $e');
      results = [];
    }
    _record(q, results, source: 'unified');
    return results;
  }

  /// Record results coming from an external search implementation (UI, analytics, etc.).
  static void recordExternalSearch(
    String query,
    List<ProductWithPrices> results, {
    String source = 'external',
  }) {
    final q = query.trim();
    if (q.isEmpty) return;
    _record(q, results, source: source);
  }

  static void _record(
    String query,
    List<ProductWithPrices> results, {
    required String source,
  }) {
    if (results.isEmpty) return; // skip empty to avoid noise
    // LRU behavior: move to end by removing then re-inserting
    if (_recent.containsKey(query)) {
      _recent.remove(query);
    }
    // Store only a trimmed subset (top 8) to reduce memory + agent visibility scope
    _recent[query] = results.take(8).toList();
    while (_recent.length > _maxEntries) {
      _recent.remove(_recent.keys.first);
    }
    _events.add(
      UnifiedSearchEvent(
        query: query,
        results: _recent[query]!,
        source: source,
      ),
    );
  }

  /// Get results for an exact query if present.
  static List<ProductWithPrices>? getExact(String query) =>
      _recent[query.trim()];

  /// Attempt to find the closest prior query within Levenshtein distance <=2.
  static List<ProductWithPrices>? getClosest(String query) {
    final q = query.trim();
    if (q.isEmpty) return null;
    int bestDist = 3;
    String? bestKey;
    for (final k in _recent.keys) {
      final d = _levenshtein(q, k, cap: 3);
      if (d < bestDist) {
        bestDist = d;
        bestKey = k;
        if (bestDist == 0) break;
      }
    }
    if (bestKey != null && bestDist <= 2) return _recent[bestKey];
    return null;
  }

  static int _levenshtein(String a, String b, {int cap = 3}) {
    if ((a.length - b.length).abs() > cap) return cap + 1;
    if (a == b) return 0;
    if (a.length > b.length) {
      final tmp = a;
      a = b;
      b = tmp;
    }
    final prev = List<int>.generate(a.length + 1, (i) => i);
    final curr = List<int>.filled(a.length + 1, 0);
    for (int j = 1; j <= b.length; j++) {
      curr[0] = j;
      int rowMin = curr[0];
      final bj = b.codeUnitAt(j - 1);
      for (int i = 1; i <= a.length; i++) {
        final cost = a.codeUnitAt(i - 1) == bj ? 0 : 1;
        final del = prev[i] + 1;
        final ins = curr[i - 1] + 1;
        final sub = prev[i - 1] + cost;
        final v = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
        curr[i] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > cap) return cap + 1;
      for (int i = 0; i < prev.length; i++) {
        prev[i] = curr[i];
      }
    }
    return prev[a.length];
  }
}

class UnifiedSearchEvent {
  final String query;
  final List<ProductWithPrices> results;
  final String source; // unified | external | agent
  UnifiedSearchEvent({
    required this.query,
    required this.results,
    required this.source,
  });
}
