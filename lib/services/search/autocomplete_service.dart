import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/category_service.dart';

class AutocompleteService {
  static final _cache = <String, List<String>>{};
  static const int maxSuggestions = 12;
  static const int minQueryLength = 1;

  // Build search dictionary from products
  static Future<void> buildSearchDictionary(List<Product> products) async {
    final dictionary = <String>{};
    final phrases = <String>{};

    for (final product in products) {
      // Add product names
      dictionary.addAll(_extractWords(product.name));
      dictionary.addAll(_extractWords(product.brandName));
      dictionary.addAll(_extractWords(product.variety));
      dictionary.addAll(_extractWords(product.originalName));

      // Add helpful phrases for better suggestions
      final brand = product.brandName.trim();
      final name = product.name.trim();
      final size = product.sizeRaw.trim();
      if (brand.isNotEmpty && name.isNotEmpty) {
        phrases.add('$brand $name');
        phrases.add('$name $brand');
      }
      if (name.isNotEmpty && size.isNotEmpty) {
        phrases.add('$name $size');
      }
      if (brand.isNotEmpty && size.isNotEmpty) {
        phrases.add('$brand $size');
      }
    }

    // Include category display names
    final categories = CategoryService.getCategoriesForUI(includeAll: false)
        .map((m) => CategoryService.getDisplayName(m['id']!))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    dictionary.addAll(categories.map((e) => e.toLowerCase()));
    phrases.addAll(categories);

    // Cache common searches (single-token words)
    for (final word in dictionary) {
      final w = word.toLowerCase();
      if (w.length >= minQueryLength) {
        _cache[w] = [word];
      }
    }

    // Cache phrases for richer suggestions
    for (final phrase in phrases) {
      final p = phrase.toLowerCase();
      if (p.length >= minQueryLength) {
        _cache[p] = [phrase];
      }
    }
  }

  // Get autocomplete suggestions
  static List<String> getSuggestions(String query) {
    if (query.trim().length < minQueryLength) return [];
    final q = query.toLowerCase();

    // Score function: higher is better
    int scoreKey(String key) {
      final isPhrase = key.contains(' ');
      if (key.startsWith(q)) {
        // Boost phrases that start with the query
        return 100 +
            (isPhrase ? 20 : 0) +
            (50 - (key.length - q.length).clamp(0, 50));
      }
      if (key.contains(q)) {
        return 50 + (isPhrase ? 10 : 0) - (key.indexOf(q)).clamp(0, 30);
      }
      return 0;
    }

    final scored = <MapEntry<String, int>>[];
    for (final key in _cache.keys) {
      final s = scoreKey(key);
      if (s > 0) scored.add(MapEntry(key, s));
    }

    // Fuzzy pass: add close matches for misspellings (distance <= 2),
    // restricted by simple prefilters to keep it fast.
    if (q.length >= 3) {
      for (final key in _cache.keys) {
        // Prefilter by length difference and first character hint
        if ((key.length - q.length).abs() > 2) continue;
        if (key.isEmpty || q.isEmpty) continue;
        if (key[0] != q[0]) continue; // cheap early prune
        final dist = _levenshtein(key, q, maxDistance: 2);
        if (dist <= 2) {
          // Score: higher for closer distance and prefix alignment
          final bonus = key.startsWith(q) ? 20 : 0;
          final fuzzyScore =
              60 + bonus - (dist * 15) - ((key.length - q.length).abs() * 2);
          scored.add(MapEntry(key, fuzzyScore));
        }
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final out = <String>[];
    for (final entry in scored) {
      final word = _cache[entry.key]!.first;
      if (!out.contains(word)) out.add(word);
      if (out.length >= maxSuggestions) break;
    }

    return out;
  }

  // Clear cache for refresh functionality
  static void clearCache() {
    _cache.clear();
  }

  static List<String> _extractWords(String text) {
    if (text.isEmpty) return [];
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(' ')
        .where((word) => word.length > 1)
        .toList();
  }

  // Lightweight Levenshtein with optional early exit via maxDistance
  static int _levenshtein(String a, String b, {int? maxDistance}) {
    if (a == b) return 0;
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    if (maxDistance != null && (la - lb).abs() > maxDistance) {
      return maxDistance + 1;
    }
    // Ensure a is shorter
    if (la > lb) {
      final t = a;
      a = b;
      b = t;
    }
    final rows = List<int>.generate(b.length + 1, (i) => i);
    for (int i = 1; i <= a.length; i++) {
      int prev = rows[0];
      rows[0] = i;
      int bestInRow = rows[0];
      for (int j = 1; j <= b.length; j++) {
        final temp = rows[j];
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        rows[j] = [
          rows[j] + 1, // deletion
          rows[j - 1] + 1, // insertion
          prev + cost, // substitution
        ].reduce((v, e) => v < e ? v : e);
        prev = temp;
        if (rows[j] < bestInRow) bestInRow = rows[j];
      }
      if (maxDistance != null && bestInRow > maxDistance) {
        return maxDistance + 1; // early exit when row already exceeds
      }
    }
    return rows[b.length];
  }
}
