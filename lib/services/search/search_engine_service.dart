import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shopple/models/product_model.dart';

class AdvancedSearchEngine {
  // Levenshtein Distance Algorithm for Fuzzy Matching.
  static int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1, // Insertion.
          v0[j + 1] + 1, // Deletion.
          v0[j] + cost, // Substitution.
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  // Advanced Fuzzy Search with Multiple Algorithms.
  static Future<List<Product>> performFuzzySearch({
    required List<Product> products,
    required String query,
    double threshold = 0.6,
    int maxResults = 50,
  }) async {
    // Use compute for heavy operations to avoid UI blocking.
    return await compute(_fuzzySearchSync, {
      'products': products,
      'query': query,
      'threshold': threshold,
      'maxResults': maxResults,
    });
  }

  static List<Product> _fuzzySearchSync(Map<String, dynamic> params) {
    final products = params['products'] as List<Product>;
    final query = (params['query'] as String).toLowerCase().trim();
    final threshold = params['threshold'] as double;
    final maxResults = params['maxResults'] as int;

    if (query.isEmpty) return products.take(maxResults).toList();

    final searchResults = <SearchResult>[];

    for (final product in products) {
      final score = _calculateProductScore(product, query);
      if (score >= threshold) {
        searchResults.add(SearchResult(product: product, score: score));
      }
    }

    // Sort by relevance score (higher is better).
    searchResults.sort((a, b) => b.score.compareTo(a.score));

    return searchResults
        .take(maxResults)
        .map((result) => result.product)
        .toList();
  }

  // Multi-field scoring algorithm.
  static double _calculateProductScore(Product product, String query) {
    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
    double totalScore = 0.0;

    for (final word in queryWords) {
      // Weight different fields by importance.
      double fieldScore = 0.0;

      // Product name (highest weight).
      fieldScore += _getFieldScore(product.name, word) * 1.0;

      // Brand name (high weight).
      fieldScore += _getFieldScore(product.brandName, word) * 0.8;

      // Variety (medium weight).
      fieldScore += _getFieldScore(product.variety, word) * 0.6;

      // Original name (medium weight).
      fieldScore += _getFieldScore(product.originalName, word) * 0.5;

      // Category (low weight).
      fieldScore += _getFieldScore(product.category, word) * 0.3;

      // Size information (low weight).
      fieldScore += _getFieldScore(product.sizeRaw, word) * 0.2;

      totalScore += fieldScore;
    }

    return totalScore / queryWords.length;
  }

  // Field-specific scoring with multiple matching strategies.
  static double _getFieldScore(String field, String query) {
    if (field.isEmpty) return 0.0;

    final fieldLower = field.toLowerCase();
    final queryLower = query.toLowerCase();

    // Exact match (highest score).
    if (fieldLower == queryLower) return 1.0;

    // Starts with (high score).
    if (fieldLower.startsWith(queryLower)) return 0.9;

    // Contains (medium score).
    if (fieldLower.contains(queryLower)) return 0.7;

    // Fuzzy match using Levenshtein distance.
    final distance = levenshteinDistance(fieldLower, queryLower);
    final maxLength = [
      fieldLower.length,
      queryLower.length,
    ].reduce((a, b) => a > b ? a : b);
    final similarity = 1.0 - (distance / maxLength);

    // Only consider fuzzy matches above 70% similarity.
    return similarity > 0.7 ? similarity * 0.6 : 0.0;
  }

  // Phonetic matching for severe misspellings.
  static String soundex(String word) {
    // Simplified Soundex algorithm.
    if (word.isEmpty) return '';

    word = word.toUpperCase();
    String soundexCode = word[0];

    final mapping = {
      'B': '1',
      'F': '1',
      'P': '1',
      'V': '1',
      'C': '2',
      'G': '2',
      'J': '2',
      'K': '2',
      'Q': '2',
      'S': '2',
      'X': '2',
      'Z': '2',
      'D': '3',
      'T': '3',
      'L': '4',
      'M': '5',
      'N': '5',
      'R': '6',
    };

    for (int i = 1; i < word.length && soundexCode.length < 4; i++) {
      final char = word[i];
      final code = mapping[char];
      if (code != null && soundexCode[soundexCode.length - 1] != code) {
        soundexCode += code;
      }
    }

    return soundexCode.padRight(4, '0').substring(0, 4);
  }

  // Spell correction suggestions.
  static List<String> getSpellingSuggestions(
    String query,
    List<String> dictionary,
  ) {
    final suggestions = <String>[];

    for (final word in dictionary) {
      final distance = levenshteinDistance(
        query.toLowerCase(),
        word.toLowerCase(),
      );
      if (distance <= 2) {
        // Allow up to 2 character differences.
        suggestions.add(word);
      }
    }

    // Sort by edit distance.
    suggestions.sort(
      (a, b) => levenshteinDistance(
        query,
        a,
      ).compareTo(levenshteinDistance(query, b)),
    );

    return suggestions.take(5).toList();
  }
}

class SearchResult {
  final Product product;
  final double score;

  SearchResult({required this.product, required this.score});
}
