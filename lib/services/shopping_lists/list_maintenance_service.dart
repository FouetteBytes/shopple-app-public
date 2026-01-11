import 'package:cloud_functions/cloud_functions.dart';

/// Maintenance utilities for shopping lists (admin/debug flows).
///
/// Currently exposes a callable to backfill missing estimatedPrice values for
/// items in a list by looking up the cheapest price in current_prices.
class ListMaintenanceService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  /// Calls the Cloud Function `backfillItemPrices`.
  ///
  /// Params:
  /// - listId: target shopping list ID
  /// - dryRun: when true (default), the function reports what it WOULD change
  ///           without applying updates. Set to false to perform updates.
  ///
  /// Returns the function response as a Map, e.g. { message, updated, updates? }.
  static Future<Map<String, dynamic>> backfillItemPrices({
    required String listId,
    bool dryRun = true,
  }) async {
    try {
      final callable = _functions.httpsCallable('backfillItemPrices');
      final resp = await callable.call({'listId': listId, 'dryRun': dryRun});
      final data = resp.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'message': 'OK', 'raw': data};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
