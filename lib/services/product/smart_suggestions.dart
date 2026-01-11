import 'package:shopple/config/feature_flags_ai.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/models/product_model.dart';

class SmartSuggestionEngine {
  static Future<List<Product>> findAlternatives(String original) async {
    if (!AIFeatureFlags.smartSuggestionsEnabled) return [];
    final lower = original.toLowerCase();
    // 1. simple synonym map
    final syns = _synonyms[lower] ?? const [];
    for (final s in syns) {
      final res = await EnhancedProductService.searchProductsWithPrices(s);
      if (res.isNotEmpty) return res.map((e) => e.product).toList();
    }
    // 2. category tokens
    final cat = _predictCategory(lower);
    if (cat != null) {
      // Try first word inside category heuristics by stripping descriptors
      final first = lower.split(' ').first;
      final res = await EnhancedProductService.searchProductsWithPrices(first);
      if (res.isNotEmpty) return res.map((e) => e.product).toList();
    }
    return [];
  }

  static String? _predictCategory(String name) {
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (name.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  static const Map<String, List<String>> _synonyms = {
    'coca cola': ['cola', 'soft drink', 'soda'],
    'coke': ['cola', 'soft drink'],
    'soda': ['soft drink', 'cola'],
    'ground beef': ['minced meat', 'beef'],
  };

  static const Map<String, List<String>> _categoryKeywords = {
    'fruits': ['apple', 'banana', 'orange', 'grape', 'berry'],
    'meat': ['beef', 'chicken', 'pork', 'lamb', 'fish'],
    'beverages': ['cola', 'juice', 'soda', 'tea', 'coffee'],
  };
}
