import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/ai/agentic_product_search_service.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/product/recently_viewed_service.dart';
import 'package:shopple/services/search/fast_product_search_service.dart';
import 'package:shopple/services/search/unified_product_search_service.dart';
import 'package:shopple/services/shopping_lists/list_item_preview_cache.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';

class AgentSearchService {
  bool _cancelRequested = false;

  void requestCancel() {
    _cancelRequested = true;
  }

  void resetCancel() {
    _cancelRequested = false;
  }

  Future<bool> addSingleItem(
    String listId,
    String phrase,
    Map<String, String> added,
    Map<String, String> failures,
    Map<String, String> itemStatuses,
    Map<String, String> itemImages,
    Function(String, String, {bool success, Map<String, dynamic>? meta}) log,
    Function() onTelemetryResolved,
    Function() onTelemetryFailed, {
    int quantity = 1,
  }) async {
    final cleaned = phrase.trim();
    itemStatuses[phrase] = 'searching';
    log(
      'search_item',
      'Starting agentic search for "$cleaned" (qty $quantity)',
    );

    try {
      // Step 1: Check if UI already searched this phrase (quick reuse)
      final prior =
          UnifiedProductSearchService.getExact(cleaned) ??
          UnifiedProductSearchService.getClosest(cleaned);
      if (prior != null && prior.isNotEmpty) {
        final trimmedPrior = prior.take(3).toList();
        log(
          'search_reuse',
          'Found ${trimmedPrior.length} cached results for "$cleaned"',
        );

        // If phrase indicates beverage intent but cached results lack ingredient token hits, inject ingredient-only search results
        try {
          final lowerPhrase = cleaned.toLowerCase();
          final beverageKeywords = [
            'drink',
            'juice',
            'nectar',
            'beverage',
            'soda',
            'water',
          ];
          final phraseHasBeverage = beverageKeywords.any(
            (k) => lowerPhrase.contains(k),
          );
          if (phraseHasBeverage) {
            final stop = {'a', 'an', 'the', 'of', 'for', 'with', 'and'};
            final baseTokens = lowerPhrase
                .split(RegExp(r'\s+'))
                .where((t) => t.isNotEmpty)
                .toList();
            final ingredientTokens = baseTokens
                .where(
                  (t) => !beverageKeywords.contains(t) && !stop.contains(t),
                )
                .toList();
            if (ingredientTokens.isNotEmpty) {
              final hasIngredientCandidate = trimmedPrior.any(
                (r) => ingredientTokens.any(
                  (ing) => r.product.name.toLowerCase().contains(ing),
                ),
              );
              if (!hasIngredientCandidate) {
                final ingTerm = ingredientTokens.join(' ');
                try {
                  var inj = await FastProductSearchService.search(
                    ingTerm,
                    limit: 3,
                  );
                  if (inj.isEmpty) {
                    final enh =
                        await EnhancedProductService.searchProductsWithPrices(
                          ingTerm,
                        );
                    inj = enh.take(3).toList();
                  }
                  if (inj.isNotEmpty) {
                    final merged = <ProductWithPrices>[];
                    final seen = <String>{};
                    for (final p in inj) {
                      if (seen.add(p.product.id)) merged.add(p);
                    }
                    for (final p in trimmedPrior) {
                      if (seen.add(p.product.id)) merged.add(p);
                    }
                    log(
                      'reuse_inject',
                      'Injected ${inj.length} ingredient-only candidates for "$ingTerm" before AI evaluation',
                    );
                    final aiSelected =
                        await AgenticProductSearchService.evaluateSearchResults(
                          cleaned,
                          merged.take(6).toList(),
                        );
                    if (aiSelected != null) {
                      log(
                        'ai_selection',
                        'AI selected cached+injected result: ${aiSelected.product.name}',
                      );
                      final itemId =
                          await ShoppingListService.addProductItemToList(
                            listId: listId,
                            product: aiSelected.product,
                            quantity: quantity,
                          );
                      if (itemId != null) {
                        added[phrase] = itemId;
                        itemStatuses[phrase] = 'added';
                        if (aiSelected.product.imageUrl.isNotEmpty) {
                          itemImages[phrase] = aiSelected.product.imageUrl;
                        }
                        ListItemPreviewCache.instance.subscribeToList(listId);
                        onTelemetryResolved();
                        try {
                          RecentlyViewedService.add(aiSelected.product.id);
                          RecentlyViewedService.addSnapshot(
                            aiSelected.product,
                            cheapest: aiSelected.getBestPrice(),
                          );
                        } catch (_) {}
                        return true;
                      }
                    } else {
                      log(
                        'ai_rejection',
                        'AI rejected cached+injected results, continuing search',
                      );
                    }
                  }
                } catch (e) {
                  log(
                    'reuse_inject_error',
                    'Ingredient injection failed: $e',
                    success: false,
                  );
                }
              }
            }
          }
        } catch (e) {
          log(
            'reuse_inject_exception',
            'Injection logic exception: $e',
            success: false,
          );
        }

        // AI Call 1: Evaluate cached results
        final aiSelected =
            await AgenticProductSearchService.evaluateSearchResults(
              cleaned,
              trimmedPrior,
            );
        if (aiSelected != null) {
          log(
            'ai_selection',
            'AI selected cached result: ${aiSelected.product.name}',
          );
          final itemId = await ShoppingListService.addProductItemToList(
            listId: listId,
            product: aiSelected.product,
            quantity: quantity,
            estimatedPrice: aiSelected.getBestPrice()?.price ?? 0.0,
          );
          if (itemId != null) {
            added[phrase] = itemId;
            itemStatuses[phrase] = 'added';
            if (aiSelected.product.imageUrl.isNotEmpty) {
              itemImages[phrase] = aiSelected.product.imageUrl;
            }
            ListItemPreviewCache.instance.subscribeToList(listId);
            onTelemetryResolved();
            try {
              RecentlyViewedService.add(aiSelected.product.id);
              RecentlyViewedService.addSnapshot(
                aiSelected.product,
                cheapest: aiSelected.getBestPrice(),
              );
            } catch (_) {}
            return true;
          }
        } else {
          log('ai_rejection', 'AI rejected cached results, continuing search');
        }
      }

      // Step 2: AI Call 2 - Generate initial search terms
      log('ai_search_terms', 'Generating AI search terms for "$cleaned"');
      final searchTerms = await AgenticProductSearchService.generateSearchTerms(
        cleaned,
      );
      log(
        'ai_search_terms_result',
        'AI generated ${searchTerms.length} search terms: ${searchTerms.join(", ")}',
      );

      // NEW: Aggregated multi-term fuzzy candidate gathering (before iterative loop)
      try {
        final lowerPhrase = cleaned.toLowerCase();
        final beverageKeywords = [
          'drink',
          'juice',
          'nectar',
          'beverage',
          'soda',
          'water',
        ];
        final phraseHasBeverage = beverageKeywords.any(
          (k) => lowerPhrase.contains(k),
        );

        // Cost-minimized variant strategy: only original phrase + joined ingredient root + limited beverage variants
        final baseTokens = lowerPhrase
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();
        final ingredientsOnly = baseTokens
            .where((t) => !beverageKeywords.contains(t))
            .toList();
        final variantOrdered = <String>[];
        // 1. Ingredient root first (joined with space) if beverage intent (ensures base fruit shows up before water noise)
        if (phraseHasBeverage && ingredientsOnly.isNotEmpty) {
          final ingTerm = ingredientsOnly.join(' ');
          variantOrdered.add(ingTerm);
        }
        // 2. Original phrase (cleaned)
        variantOrdered.add(cleaned);
        // 3. Skip auto-expand when no explicit beverage keywords (cost optimization)
        // 4. If phrase has beverage AND no explicit juice/nectar token, add at most 2 beverage forms for first ingredient
        if (phraseHasBeverage && ingredientsOnly.isNotEmpty) {
          final firstIng = ingredientsOnly.first;
          // Add only if nectar/juice not already part of phrase
          if (!lowerPhrase.contains('juice')) {
            variantOrdered.add('$firstIng juice');
          }
          if (!lowerPhrase.contains('nectar')) {
            variantOrdered.add('$firstIng nectar');
          }
        }
        // 5. AI generated terms: only append those that are short (<=3 words) and not already present, up to 2 extra
        int appended = 0;
        for (final t in searchTerms) {
          if (appended >= 2) {
            break;
          }
          final norm = t.toLowerCase();
          if (!variantOrdered.any((v) => v.toLowerCase() == norm) &&
              norm.split(' ').length <= 3) {
            variantOrdered.add(t);
            appended++;
          }
        }
        final cappedVariants = variantOrdered.take(6).toList();
        log(
          'aggregate_variants',
          'Cost-minimized variants (${cappedVariants.length}): ${cappedVariants.join(' | ')}',
        );

        final candidateMap = <String, ProductWithPrices>{};
        final scoreMap = <String, double>{};

        Future<void> ingestResults(
          String term,
          List<ProductWithPrices> list,
        ) async {
          for (int idx = 0; idx < list.length && idx < 8; idx++) {
            final p = list[idx];
            if (p.product.name.isEmpty) continue;
            candidateMap[p.product.id] = p; // last wins (same instance anyway)
            // Base score: inverse of index
            double score = (8 - idx).toDouble();
            final lname = p.product.name.toLowerCase();
            // Ingredient matches
            for (final ing in ingredientsOnly) {
              if (lname.contains(ing)) {
                score += 4;
              }
            }
            // Beverage preference
            if (phraseHasBeverage &&
                beverageKeywords.any((k) => lname.contains(k))) {
              score += 6;
            }
            // Exact phrase containment
            if (lname.contains(lowerPhrase)) {
              score += 5;
            }
            // Term similarity bonus (simple)
            final lterm = term.toLowerCase();
            if (lterm == lname) {
              score += 3;
            } else if (lname.contains(lterm) || lterm.contains(lname)) {
              score += 2;
            }
            // Penalty: generic water items without ingredient when beverage intent with specific ingredient
            if (phraseHasBeverage) {
              final hasIng = ingredientsOnly.any((ing) => lname.contains(ing));
              final genericWater =
                  (lname.contains('water') ||
                      lname.contains('drinking water')) &&
                  !lname.contains('coconut');
              if (genericWater && !hasIng) {
                score -= 8; // strong penalty
              }
            }
            scoreMap[p.product.id] = (scoreMap[p.product.id] ?? 0) + score;
          }
        }

        // Execute searches sequentially (avoid overloading) until we have enough beverage candidate(s)
        bool haveBeverage = false;
        int searchOps = 0;
        const int maxSearchOps =
            6; // hard cap on distinct search operations for cost control
        bool definitiveFound =
            false; // becomes true when a high-confidence candidate is present
        for (final term in cappedVariants) {
          if (_cancelRequested) {
            break;
          }
          if (searchOps >= maxSearchOps) {
            log(
              'aggregate_cap',
              'Reached max search ops ($maxSearchOps), stopping variant expansion',
            );
            break;
          }
          try {
            final fast = await FastProductSearchService.search(term, limit: 8);
            searchOps++;
            if (fast.isNotEmpty) {
              await ingestResults(term, fast);
            } else {
              final enh = await EnhancedProductService.searchProductsWithPrices(
                term,
              );
              searchOps++;
              await ingestResults(term, enh.take(8).toList());
            }
            if (!haveBeverage && phraseHasBeverage) {
              haveBeverage = candidateMap.values.any(
                (c) => beverageKeywords.any(
                  (k) => c.product.name.toLowerCase().contains(k),
                ),
              );
            }
            // Definitive detection: if beverage intent -> product that includes all ingredient tokens + beverage word
            if (!definitiveFound) {
              if (phraseHasBeverage) {
                definitiveFound = candidateMap.values.any((c) {
                  final n = c.product.name.toLowerCase();
                  final hasBev = beverageKeywords.any((k) => n.contains(k));
                  final allIng =
                      ingredientsOnly.isEmpty ||
                      ingredientsOnly.every((ing) => n.contains(ing));
                  return hasBev && allIng;
                });
              } else {
                definitiveFound = candidateMap.values.any((c) {
                  final n = c.product.name.toLowerCase();
                  return ingredientsOnly.isNotEmpty &&
                      ingredientsOnly.every((ing) => n.contains(ing));
                });
              }
            }
            if (phraseHasBeverage && haveBeverage && candidateMap.length >= 5) {
              // Early stop once we have a decent set including a beverage form
              break;
            }
            if (definitiveFound) {
              log(
                'aggregate_early_cap',
                'Definitive candidate present after term "$term"',
              );
              break;
            }
          } catch (e) {
            log(
              'aggregate_variant_error',
              'Variant term "$term" failed: $e',
              success: false,
            );
          }
        }

        if (candidateMap.isNotEmpty) {
          // Rank candidates
          final ranked = candidateMap.values.toList()
            ..sort(
              (a, b) =>
                  (scoreMap[b.product.id]!.compareTo(scoreMap[a.product.id]!)),
            );
          final topForAI = ranked.take(6).toList();
          log(
            'aggregate_rank',
            'Prepared ${topForAI.length} aggregated candidates for AI evaluation',
          );
          final aiPick =
              await AgenticProductSearchService.evaluateSearchResults(
                cleaned,
                topForAI,
              );
          if (aiPick != null) {
            log(
              'ai_selection',
              'AI selected aggregated candidate: ${aiPick.product.name}',
            );
            final itemId = await ShoppingListService.addProductItemToList(
              listId: listId,
              product: aiPick.product,
              quantity: quantity,
              estimatedPrice: aiPick.getBestPrice()?.price ?? 0.0,
            );
            if (itemId != null) {
              added[phrase] = itemId;
              itemStatuses[phrase] = 'added';
              if (aiPick.product.imageUrl.isNotEmpty) {
                itemImages[phrase] = aiPick.product.imageUrl;
              }
              ListItemPreviewCache.instance.subscribeToList(listId);
              onTelemetryResolved();
              try {
                RecentlyViewedService.add(aiPick.product.id);
                RecentlyViewedService.addSnapshot(
                  aiPick.product,
                  cheapest: aiPick.getBestPrice(),
                );
              } catch (_) {}
              return true; // Done; skip iterative per-term loop
            }
          } else {
            log(
              'ai_rejection',
              'AI rejected aggregated candidates; falling back to iterative loop',
            );
          }
        } else {
          log('aggregate_empty', 'No aggregated candidates produced');
        }
      } catch (e) {
        log(
          'aggregate_exception',
          'Aggregated candidate phase failed: $e',
          success: false,
        );
      }

      // Step 3: Search with AI-generated terms
      for (int i = 0; i < searchTerms.length && i < 3; i++) {
        if (_cancelRequested) break;

        final term = searchTerms[i];
        log('search_attempt', 'Searching with AI term ${i + 1}: "$term"');

        // Get search results (top 3 only)
        List<ProductWithPrices> results = [];
        try {
          final fastResults = await FastProductSearchService.search(
            term,
            limit: 3,
          );
          if (fastResults.isNotEmpty) {
            results = fastResults;
            UnifiedProductSearchService.recordExternalSearch(
              term,
              results,
              source: 'agentic_fast',
            );
          } else {
            final enhancedResults =
                await EnhancedProductService.searchProductsWithPrices(term);
            results = enhancedResults.take(3).toList();
            if (results.isNotEmpty) {
              UnifiedProductSearchService.recordExternalSearch(
                term,
                results,
                source: 'agentic_enhanced',
              );
            }
          }
        } catch (e) {
          log(
            'search_error',
            'Search failed for term "$term": $e',
            success: false,
          );
          continue;
        }

        if (results.isEmpty) {
          log('search_empty', 'No results for term "$term"');
          continue;
        }

        // Beverage intent boosting: if user asked for a beverage but top 3 lack a beverage form, try to surface one
        try {
          final lowerPhrase = cleaned.toLowerCase();
          final beverageKeywords = [
            'drink',
            'juice',
            'nectar',
            'beverage',
            'soda',
          ];
          final phraseHasBeverage = beverageKeywords.any(
            (k) => lowerPhrase.contains(k),
          );
          if (phraseHasBeverage) {
            final resultsHaveBeverage = results.any(
              (r) => beverageKeywords.any(
                (k) => r.product.name.toLowerCase().contains(k),
              ),
            );
            if (!resultsHaveBeverage) {
              // Expand search to find beverage product variants
              final broader =
                  await EnhancedProductService.searchProductsWithPrices(term);
              ProductWithPrices? beverageCandidate;
              // Derive ingredient tokens (exclude beverage words & common stopwords)
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
              for (final p in broader.take(20)) {
                final n = p.product.name.toLowerCase();
                final hasBeverageWord = beverageKeywords.any(
                  (k) => n.contains(k),
                );
                if (!hasBeverageWord) continue;
                final hasIngredient =
                    ingredientTokens.isEmpty ||
                    ingredientTokens.any((ing) => n.contains(ing));
                if (hasIngredient) {
                  beverageCandidate = p;
                  break;
                }
              }
              if (beverageCandidate != null) {
                final already = results.any(
                  (r) => r.product.id == beverageCandidate!.product.id,
                );
                if (!already) {
                  results = [beverageCandidate, ...results].take(5).toList();
                  log(
                    'search_beverage_boost',
                    'Boosted beverage candidate ${beverageCandidate.product.name} into results for "$term"',
                  );
                }
              } else {
                log(
                  'search_beverage_boost',
                  'No beverage variant found in broader search for "$term"',
                );
              }
            }
          }
        } catch (e) {
          log(
            'search_beverage_boost_error',
            'Boost logic failed for "$term": $e',
            success: false,
          );
        }

        log('search_results', 'Found ${results.length} results for "$term"');

        // AI Call 3: Evaluate search results
        final aiSelected =
            await AgenticProductSearchService.evaluateSearchResults(
              cleaned,
              results,
            );
        if (aiSelected != null) {
          log(
            'ai_selection',
            'AI selected: ${aiSelected.product.name} from term "$term"',
          );
          final itemId = await ShoppingListService.addProductItemToList(
            listId: listId,
            product: aiSelected.product,
            quantity: quantity,
            estimatedPrice: aiSelected.getBestPrice()?.price ?? 0.0,
          );
          if (itemId != null) {
            added[phrase] = itemId;
            itemStatuses[phrase] = 'added';
            if (aiSelected.product.imageUrl.isNotEmpty) {
              itemImages[phrase] = aiSelected.product.imageUrl;
            }
            ListItemPreviewCache.instance.subscribeToList(listId);
            onTelemetryResolved();
            try {
              RecentlyViewedService.add(aiSelected.product.id);
              RecentlyViewedService.addSnapshot(
                aiSelected.product,
                cheapest: aiSelected.getBestPrice(),
              );
            } catch (_) {}
            return true;
          }
        } else {
          log('ai_rejection', 'AI rejected results for term "$term"');
        }
      }

      // Step 4: AI Call 4 - Generate semantic refinements if nothing found
      log('ai_refinement', 'Generating semantic refinements for "$cleaned"');
      final refinements =
          await AgenticProductSearchService.generateSemanticRefinements(
            cleaned,
          );
      log(
        'ai_refinement_result',
        'AI generated ${refinements.length} refinements: ${refinements.join(", ")}',
      );

      // Step 5: Search with refinements
      for (int i = 0; i < refinements.length && i < 2; i++) {
        if (_cancelRequested) break;

        final refinement = refinements[i];
        log(
          'search_refinement',
          'Searching with refinement ${i + 1}: "$refinement"',
        );

        List<ProductWithPrices> results = [];
        try {
          final enhancedResults =
              await EnhancedProductService.searchProductsWithPrices(refinement);
          results = enhancedResults.take(3).toList();
          if (results.isNotEmpty) {
            UnifiedProductSearchService.recordExternalSearch(
              refinement,
              results,
              source: 'agentic_refined',
            );
          }
        } catch (e) {
          log(
            'search_error',
            'Refinement search failed for "$refinement": $e',
            success: false,
          );
          continue;
        }

        if (results.isEmpty) continue;

        log(
          'search_results',
          'Found ${results.length} results for refinement "$refinement"',
        );

        // AI Call 5: Evaluate refinement results
        final aiSelected =
            await AgenticProductSearchService.evaluateSearchResults(
              cleaned,
              results,
            );
        if (aiSelected != null) {
          log(
            'ai_selection',
            'AI selected: ${aiSelected.product.name} from refinement "$refinement"',
          );
          final itemId = await ShoppingListService.addProductItemToList(
            listId: listId,
            product: aiSelected.product,
            quantity: quantity,
            estimatedPrice: aiSelected.getBestPrice()?.price ?? 0.0,
          );
          if (itemId != null) {
            added[phrase] = itemId;
            itemStatuses[phrase] = 'added';
            if (aiSelected.product.imageUrl.isNotEmpty) {
              itemImages[phrase] = aiSelected.product.imageUrl;
            }
            ListItemPreviewCache.instance.subscribeToList(listId);
            onTelemetryResolved();
            try {
              RecentlyViewedService.add(aiSelected.product.id);
              RecentlyViewedService.addSnapshot(
                aiSelected.product,
                cheapest: aiSelected.getBestPrice(),
              );
            } catch (_) {}
            return true;
          }
        }
      }

      // Step 6: Final fallback - create custom item
      log('search_exhausted', 'AI search exhausted, creating custom item');
      final customId = await ShoppingListService.addCustomItemToList(
        listId: listId,
        name: cleaned,
        quantity: quantity,
        estimatedPrice: 0.0,
      );
      if (customId != null) {
        added[phrase] = 'custom:$cleaned';
        itemStatuses[phrase] = 'added';
        onTelemetryResolved();
        log('custom_item', 'Created custom item: $cleaned');
        return true;
      }

      // Complete failure
      failures[phrase] = 'agentic_search_failed';
      log(
        'search_failed',
        'Complete agentic search failure for "$phrase"',
        success: false,
      );
      itemStatuses[phrase] = 'failed';
      onTelemetryFailed();
      return false;
    } catch (e) {
      failures[phrase] = e.toString();
      log(
        'search_exception',
        'Agentic search exception for "$phrase": $e',
        success: false,
      );
      itemStatuses[phrase] = 'failed';
      onTelemetryFailed();
      return false;
    }
  }
}
