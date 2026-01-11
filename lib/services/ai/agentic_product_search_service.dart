import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/ai/gemini_service.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/search/fast_product_search_service.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'dart:convert';

/// Agentic product search service that uses AI to iteratively find products
/// by making separate AI calls for search evaluation and semantic refinement.
class AgenticProductSearchService {
  /// Step 1: Generate search terms for a product phrase using AI
  static Future<List<String>> generateSearchTerms(String phrase) async {
    // Short phrases: deterministic expansion without AI call
    final tokens = phrase
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    // Roots that reasonably have drink/juice/nectar forms
    const beverageEligibleRoots = {
      'apple',
      'mango',
      'orange',
      'woodapple',
      'wood-apple',
      'coconut',
      'king',
      'kingcoconut',
      'pineapple',
      'grape',
      'berry',
      'strawberry',
      'blueberry',
      'raspberry',
      'lemon',
      'lime',
      'guava',
      'passion',
      'passionfruit',
      'papaya',
      'aloe',
      'aloevera',
      'tamarind',
      'pomegranate',
      'carrot',
      'beet',
      'tomato',
      'melon',
      'watermelon',
      'banana',
    };
    if (tokens.length <= 2) {
      final set = <String>{phrase};
      if (tokens.length == 2) set.add(tokens.join(''));
      // beverage expansions if beverage intent keywords present
      final bevKeys = ['drink', 'juice', 'nectar', 'beverage', 'water'];
      final hasBev = tokens.any((t) => bevKeys.contains(t));
      final root = tokens.isNotEmpty ? tokens.first : '';
      final eligible = beverageEligibleRoots.contains(root.replaceAll('-', ''));
      if (!hasBev && eligible) {
        for (final k in ['drink', 'juice', 'nectar']) {
          set.add('$root $k');
        }
      } else if (!hasBev && !eligible) {
        AppLogger.d('[AGENTIC_SEARCH] skip_bev_expansion_short root=$root');
      }
      return set.take(6).toList();
    }

    // For longer phrases add deterministic beverage variants BEFORE AI to stabilize
    final bevKeys = ['drink', 'juice', 'nectar', 'beverage', 'water'];
    final stop = {'a', 'an', 'the', 'of', 'for', 'with', 'and'};
    final ingredientTokens = tokens
        .where((t) => !bevKeys.contains(t) && !stop.contains(t))
        .toList();
    final phraseHasBeverage = tokens.any((t) => bevKeys.contains(t));
    final heuristicSet = <String>{phrase};
    if (ingredientTokens.isNotEmpty) {
      // Join + compact forms
      if (ingredientTokens.length > 1) {
        heuristicSet.add(ingredientTokens.join(' '));
        heuristicSet.add(ingredientTokens.join(''));
      }
      // Add beverage variants only if user explicitly requested beverage OR ingredient is beverage-eligible
      for (final ing in ingredientTokens.take(2)) {
        final eligible = beverageEligibleRoots.contains(
          ing.replaceAll('-', ''),
        );
        if (phraseHasBeverage || eligible) {
          for (final b in ['nectar', 'juice', 'drink']) {
            heuristicSet.add('$ing $b');
          }
        } else {
          AppLogger.d('[AGENTIC_SEARCH] skip_bev_variant_long ing=$ing');
        }
      }
    }

    final prompt =
        'Return JSON array of 3-5 concise search terms for: "$phrase"';
    try {
      final response = await GeminiService.instance.generateText(
        prompt,
        lite: true,
      );
      if (response.isNotEmpty) {
        try {
          final cleaned = _extractJsonFromResponse(response);
          final decoded = json.decode(cleaned);
          if (decoded is List) {
            for (final s in decoded.cast<String>()) {
              heuristicSet.add(s);
            }
            return heuristicSet.take(8).toList();
          }
        } catch (e) {
          AppLogger.w('[AGENTIC_SEARCH] term_parse_fail: $e');
        }
      }
    } catch (e) {
      AppLogger.w('[AGENTIC_SEARCH] term_ai_error: $e');
    }
    return heuristicSet.isEmpty ? [phrase] : heuristicSet.take(8).toList();
  }

  /// Step 2: Evaluate search results using AI and select best match
  static Future<ProductWithPrices?> evaluateSearchResults(
    String originalPhrase,
    List<ProductWithPrices> searchResults,
  ) async {
    if (searchResults.isEmpty) return null;

    // --- Candidate preparation & contextual prioritization ---
    final lowerPhrase = originalPhrase.toLowerCase();
    final beverageKeywords = [
      'drink',
      'juice',
      'nectar',
      'beverage',
      'soda',
      'water',
      'milk',
    ];
    final phraseHasBeverage = beverageKeywords.any(
      (k) => lowerPhrase.contains(k),
    );

    // Reorder candidates to surface beverage forms first if user asked for a beverage
    List<ProductWithPrices> candidates = searchResults;
    if (phraseHasBeverage) {
      final beverageMatches = searchResults.where((r) {
        final n = r.product.name.toLowerCase();
        return beverageKeywords.any((k) => n.contains(k));
      }).toList();
      if (beverageMatches.isNotEmpty) {
        final seen = <String>{};
        final reordered = <ProductWithPrices>[];
        for (final r in beverageMatches) {
          if (seen.add(r.product.id)) reordered.add(r);
        }
        for (final r in searchResults) {
          if (seen.add(r.product.id)) reordered.add(r);
        }
        candidates = reordered;
      }
    }

    // If beverage requested but we still lack a beverage candidate containing the ingredient tokens, try targeted variant searches
    if (phraseHasBeverage) {
      final stop = {'a', 'an', 'the', 'of', 'for', 'with', 'and'};
      final baseTokens = lowerPhrase
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      final ingredientTokens = baseTokens
          .where((t) => !beverageKeywords.contains(t) && !stop.contains(t))
          .toList();
      bool hasIngredientBeverage = candidates.any((c) {
        final n = c.product.name.toLowerCase();
        final hasBev = beverageKeywords.any((k) => n.contains(k));
        final hasIng =
            ingredientTokens.isEmpty ||
            ingredientTokens.any((ing) => n.contains(ing));
        return hasBev && hasIng;
      });
      if (!hasIngredientBeverage && ingredientTokens.isNotEmpty) {
        try {
          final injections = <ProductWithPrices>[];
          for (final ing in ingredientTokens.take(2)) {
            for (final b in ['nectar', 'juice', 'drink']) {
              final term = '$ing $b';
              List<ProductWithPrices> found = [];
              try {
                found = await FastProductSearchService.search(term, limit: 4);
                if (found.isEmpty) {
                  final enh =
                      await EnhancedProductService.searchProductsWithPrices(
                        term,
                      );
                  found = enh.take(4).toList();
                }
              } catch (_) {}
              for (final p in found) {
                final lname = p.product.name.toLowerCase();
                final hasBev = beverageKeywords.any((k) => lname.contains(k));
                final hasIng = lname.contains(ing);
                if (hasBev &&
                    hasIng &&
                    !candidates.any((c) => c.product.id == p.product.id) &&
                    !injections.any((i) => i.product.id == p.product.id)) {
                  injections.add(p);
                  break; // Only need one per beverage type
                }
              }
              if (injections.length >= 2) break;
            }
            if (injections.length >= 2) break;
          }
          if (injections.isNotEmpty) {
            candidates = [...injections, ...candidates];
            AppLogger.d(
              '[AGENTIC_SEARCH] beverage_inject: injected ${injections.length} variant(s) for "$originalPhrase"',
            );
          }
        } catch (e) {
          AppLogger.w('[AGENTIC_SEARCH] beverage_inject_fail: $e');
        }
      }
    }

    // Heuristic early exit now uses confidence gating; default is to defer to AI unless certainty is high.
    final shown = candidates.take(6).toList();
    if (shown.isNotEmpty) {
      final stop = {'a', 'an', 'the', 'of', 'for', 'with', 'and'};
      final ingredientTokens = lowerPhrase
          .split(RegExp(r'\s+'))
          .where(
            (t) =>
                t.length > 2 &&
                !stop.contains(t) &&
                !beverageKeywords.contains(t),
          )
          .toList();
      final firstLower = shown.first.product.name.toLowerCase();
      // Count how many candidates look like beverages when phrase had beverage intent
      int beverageCount = 0;
      if (phraseHasBeverage) {
        for (final c in shown) {
          final n = c.product.name.toLowerCase();
          if (beverageKeywords.any((k) => n.contains(k))) beverageCount++;
        }
      }
      // Compute ingredient coverage (all ingredient tokens should appear for high confidence)
      int covered = 0;
      for (final ing in ingredientTokens) {
        if (firstLower.contains(ing)) covered++;
      }
      final hasAllIngredients =
          ingredientTokens.isEmpty || (covered == ingredientTokens.length);
      final hasAnyIngredient = ingredientTokens.isEmpty || covered > 0;
      final firstIsBeverage = beverageKeywords.any(
        (k) => firstLower.contains(k),
      );
      final genericWater =
          firstLower.contains('water') &&
          !firstLower.contains('coconut') &&
          !firstLower.contains('king coconut') &&
          ingredientTokens.any((t) => t != 'water');
      // Confidence scoring (simple additive heuristic)
      double score = 0;
      if (shown.length == 1) score += 0.35; // uniqueness
      if (firstIsBeverage && phraseHasBeverage) {
        score += 0.30; // beverage alignment
      }
      if (hasAllIngredients) {
        score += 0.40;
      } else if (hasAnyIngredient) {
        score += 0.15;
      } // ingredient coverage
      if (beverageCount > 1) score -= 0.25; // ambiguity among beverages
      if (genericWater) score -= 0.60; // penalize plain water mismatch
      // Threshold for confident auto-select
      const threshold =
          0.96; // tightened per request to rely on AI unless near-certain
      if (score >= threshold && hasAllIngredients && !genericWater) {
        AppLogger.d(
          '[AGENTIC_SEARCH] Heuristic early select (score=${score.toStringAsFixed(2)} >= $threshold) -> ${shown.first.product.name}',
        );
        return shown.first;
      } else {
        AppLogger.d(
          '[AGENTIC_SEARCH] Heuristic defer to AI (score=${score.toStringAsFixed(2)} < $threshold, beverageCount=$beverageCount, allIng=$hasAllIngredients, genericWater=$genericWater)',
        );
      }
    }

    final numbered = List.generate(
      shown.length,
      (i) => '${i + 1}) ${shown[i].product.name}',
    ).join('\n');
    final compactPrompt =
        'Request: "$originalPhrase"\nChoices:\n$numbered\nRules: pick closest semantic/ingredient match${phraseHasBeverage ? ' prefer beverage form (juice/nectar if fruit mentioned)' : ''}. Return JSON {"p":"exact name"} or {"p":null,"r":"reason"} only.';

    try {
      final response = await GeminiService.instance.generateText(
        compactPrompt,
        lite: true,
      );
      AppLogger.d('[AGENTIC_SEARCH] AI evaluation raw response: $response');

      if (response.isNotEmpty) {
        try {
          final cleanedResponse = _extractJsonFromResponse(response);
          AppLogger.d(
            '[AGENTIC_SEARCH] Cleaned JSON response: $cleanedResponse',
          );
          final decoded = json.decode(cleanedResponse);
          if (decoded is Map) {
            final selected = decoded['selectedProduct'] ?? decoded['p'];
            AppLogger.d('[AGENTIC_SEARCH] AI selected product: $selected');

            if (selected == null) {
              AppLogger.d(
                '[AGENTIC_SEARCH] AI rejected all results: ${decoded['reason'] ?? decoded['r']}',
              );
              return null;
            }

            // Find matching product in shown candidate list first
            for (final result in shown) {
              AppLogger.d(
                '[AGENTIC_SEARCH] Comparing "${result.product.name}" with "$selected"',
              );
              if (result.product.name == selected) {
                AppLogger.d(
                  '[AGENTIC_SEARCH] AI selected: ${result.product.name}',
                );
                return result;
              }
            }
            AppLogger.w(
              '[AGENTIC_SEARCH] No product matched AI selection: $selected',
            );

            // Post-selection heuristic: if user asked for beverage but AI picked a non-beverage form while a beverage form exists
            if (phraseHasBeverage) {
              final lowerSelected = (selected ?? '').toLowerCase();
              final selectedHasBeverage = beverageKeywords.any(
                (k) => lowerSelected.contains(k),
              );
              if (!selectedHasBeverage) {
                // Identify ingredient tokens (exclude stopwords & beverage words)
                final stop = {'a', 'an', 'the', 'of', 'for', 'with', 'and'};
                final ingredientTokens = lowerPhrase
                    .split(RegExp(r'\s+'))
                    .where(
                      (t) =>
                          t.length > 2 &&
                          !stop.contains(t) &&
                          !beverageKeywords.contains(t),
                    )
                    .toList();
                ProductWithPrices? fallback;
                for (final c in candidates) {
                  final n = c.product.name.toLowerCase();
                  final hasBeverageWord = beverageKeywords.any(
                    (k) => n.contains(k),
                  );
                  if (!hasBeverageWord) continue;
                  final hasIngredient =
                      ingredientTokens.isEmpty ||
                      ingredientTokens.any((ing) => n.contains(ing));
                  if (hasIngredient) {
                    fallback = c;
                    break;
                  }
                }
                if (fallback != null) {
                  AppLogger.d(
                    '[AGENTIC_SEARCH] Beverage preference override: using ${fallback.product.name}',
                  );
                  return fallback;
                }
              }
            }
          }
        } catch (e) {
          AppLogger.w('[AGENTIC_SEARCH] Failed to parse evaluation JSON: $e');
          AppLogger.w('[AGENTIC_SEARCH] Raw response: $response');
        }
      }
    } catch (e) {
      AppLogger.e('[AGENTIC_SEARCH] Error evaluating results: $e');
    }

    return null;
  }

  /// Step 3: Generate semantic refinement terms when initial search fails
  static Future<List<String>> generateSemanticRefinements(
    String originalPhrase,
  ) async {
    final prompt =
        '''
You are a shopping assistant that helps refine search terms when products aren't found.
Original phrase: "$originalPhrase"

Generate 3-4 alternative search terms that are more specific or use different wording.
Focus on synonyms, brand names, or more specific product categories.

Return only a JSON array:
["alternative 1", "alternative 2", "alternative 3"]
''';

    try {
      final response = await GeminiService.instance.generateText(prompt);
      if (response.isNotEmpty) {
        try {
          final cleanedResponse = _extractJsonFromResponse(response);
          final decoded = json.decode(cleanedResponse);
          if (decoded is List) {
            return decoded.cast<String>().take(4).toList();
          }
        } catch (e) {
          AppLogger.w('[AGENTIC_SEARCH] Failed to parse refinement JSON: $e');
          AppLogger.w('[AGENTIC_SEARCH] Raw response: $response');
        }
      }
    } catch (e) {
      AppLogger.e('[AGENTIC_SEARCH] Error generating refinements: $e');
    }

    // Fallback refinements
    return [
      '$originalPhrase brand',
      originalPhrase.toLowerCase().replaceAll(' ', ''),
      '$originalPhrase product',
    ];
  }

  /// Extracts JSON content from responses that may be wrapped in markdown code blocks
  static String _extractJsonFromResponse(String response) {
    final cleanedResponse = response.trim();

    // Check if response is wrapped in markdown code blocks
    if (cleanedResponse.startsWith('```json') &&
        cleanedResponse.endsWith('```')) {
      // Extract content between ```json and ```
      final startIndex = cleanedResponse.indexOf('```json') + 7;
      final endIndex = cleanedResponse.lastIndexOf('```');
      if (startIndex < endIndex) {
        return cleanedResponse.substring(startIndex, endIndex).trim();
      }
    }

    // Also handle just ``` without json specifier
    if (cleanedResponse.startsWith('```') && cleanedResponse.endsWith('```')) {
      final startIndex = cleanedResponse.indexOf('```') + 3;
      final endIndex = cleanedResponse.lastIndexOf('```');
      if (startIndex < endIndex) {
        return cleanedResponse.substring(startIndex, endIndex).trim();
      }
    }

    // Return as-is if no markdown formatting found
    return cleanedResponse;
  }
}
