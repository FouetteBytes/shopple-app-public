import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/utils/app_logger.dart';

/// FastProductSearchService
///
/// Uses Cloud Function `fastProductSearchV2` to return product hits with a
/// minimal price preview in well under 500ms. Falls back to an empty list on
/// timeout or any failure so callers can swap to local search.
class FastProductSearchService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  /// Perform a fast search via Cloud Functions with an aggressive timeout.
  /// Returns lightweight ProductWithPrices objects, often including only the
  /// cheapest price preview (one store) to enable instant rendering.
  static Future<List<ProductWithPrices>> search(
    String query, {
    int limit = 20,
    Map<String, dynamic>? filters,
    Duration timeout = const Duration(milliseconds: 400),
  }) async {
    if (query.trim().isEmpty) return const [];

    try {
      AppLogger.d('[FAST_SEARCH] Starting cloud search for: "$query"');

      final callable = _functions.httpsCallable('fastProductSearchV2');
      final fut = callable
          .call({
            'query': query.trim(),
            'limit': limit,
            'filters': filters ?? const {},
          })
          .then((result) {
            AppLogger.d('[FAST_SEARCH] Cloud function responded');

            final data = Map<String, dynamic>.from(result.data as Map);
            final List<dynamic> results =
                (data['results'] as List?) ?? const [];

            AppLogger.d(
              '[FAST_SEARCH] Processing ${results.length} cloud results',
            );

            final out = <ProductWithPrices>[];
            for (final item in results) {
              final m = Map<String, dynamic>.from(item as Map);
              final product = Product(
                id: m['id'] ?? '',
                name: m['name'] ?? '',
                originalName: m['original_name'] ?? '',
                brandName: m['brand_name'] ?? '',
                category: m['category'] ?? '',
                size: (m['size'] ?? 0).toInt(),
                sizeRaw: m['sizeRaw'] ?? '',
                sizeUnit: m['sizeUnit'] ?? '',
                variety: m['variety'] ?? '',
                imageUrl: m['image_url'] ?? '',
                isActive: true,
                createdAt: m['created_at'],
                updatedAt: m['updated_at'],
              );

              // Attach a minimal price preview when present
              final prices = <String, CurrentPrice>{};
              if (m['cheapestPrice'] != null && m['cheapestStore'] != null) {
                final storeId = m['cheapestStore'].toString();
                prices[storeId] = CurrentPrice(
                  id: '${storeId}_${product.id}',
                  supermarketId: storeId,
                  productId: product.id,
                  price: (m['cheapestPrice'] as num).toDouble(),
                  priceDate: m['priceDate'] ?? '',
                  lastUpdated: m['priceLastUpdated'] ?? '',
                );
              }

              out.add(ProductWithPrices(product: product, prices: prices));
            }

            AppLogger.d(
              '[FAST_SEARCH] Returning ${out.length} processed results',
            );
            return out;
          });

      final result = await fut.timeout(
        timeout,
        onTimeout: () {
          AppLogger.w(
            '[FAST_SEARCH] Cloud search timed out after ${timeout.inMilliseconds}ms',
          );
          return const <ProductWithPrices>[];
        },
      );

      return result;
    } catch (e) {
      // Graceful failure: let caller fallback
      AppLogger.e('[FAST_SEARCH] Cloud search failed: $e');
      return const [];
    }
  }
}
