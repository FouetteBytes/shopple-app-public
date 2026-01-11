import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/utils/app_logger.dart';

class ListHydrationService {
  static final _func = FirebaseFunctions.instanceFor(region: 'asia-south1');
  static final _firestore = FirebaseFirestore.instance;

  /// Fetch tiny hydration previews for a batch of list IDs.
  /// Returns map: listId -> { totalItems, completedItems, estimatedTotal }.
  ///
  /// If Cloud Function returns zero values for a list that should have items,
  /// falls back to computing aggregates directly from items subcollection.
  static Future<Map<String, Map<String, dynamic>>> fetchBatch(
    List<String> listIds,
  ) async {
    if (listIds.isEmpty) return {};
    try {
      AppLogger.d(
        '[HYDRATION_DEBUG] Calling Cloud Function getListHydrationBatch with listIds: $listIds',
      );
      final callable = _func.httpsCallable('getListHydrationBatch');
      final res = await callable.call({'listIds': listIds});
      AppLogger.d('[HYDRATION_DEBUG] Cloud Function raw response: ${res.data}');
      final data =
          (res.data as Map<String, dynamic>)['results'] as List<dynamic>?;
      final out = <String, Map<String, dynamic>>{};
      final needsFallback = <String>[];
      
      for (final e in data ?? const []) {
        final m = Map<String, dynamic>.from(e as Map);
        final id = m['id']?.toString();
        if (id == null) continue;
        
        final totalItems = (m['totalItems'] ?? 0) as int;
        final completedItems = (m['completedItems'] ?? 0) as int;
        final estimatedTotal = (m['estimatedTotal'] ?? 0.0) is int
            ? (m['estimatedTotal'] as int).toDouble()
            : (m['estimatedTotal'] ?? 0.0) as double;
        final distinctProducts = (m['distinctProducts'] ?? 0) as int;
        final distinctCompleted = (m['distinctCompleted'] ?? 0) as int;
        
        // If all values are 0, the hydration doc might not exist yet.
        // Mark for fallback computation.
        if (totalItems == 0 && completedItems == 0 && estimatedTotal == 0.0) {
          needsFallback.add(id);
        }
        
        out[id] = {
          'totalItems': totalItems,
          'completedItems': completedItems,
          'estimatedTotal': estimatedTotal,
          'distinctProducts': distinctProducts,
          'distinctCompleted': distinctCompleted,
          'updatedAt': m['updatedAt'],
        };
      }
      
      // For lists with zero values, compute directly from items.
      if (needsFallback.isNotEmpty) {
        AppLogger.d('[HYDRATION_DEBUG] Running fallback hydration for ${needsFallback.length} lists');
        final fallbackResults = await _computeAggregatesFromItems(needsFallback);
        for (final entry in fallbackResults.entries) {
          // Only update if fallback found actual items.
          if (entry.value['totalItems'] as int > 0) {
            out[entry.key] = entry.value;
          }
        }
      }
      
      AppLogger.d('[HYDRATION_DEBUG] Processed hydration result: $out');
      return out;
    } catch (e) {
      AppLogger.e('[HYDRATION_DEBUG] Error calling Cloud Function: $e');
      // On cloud function failure, try direct computation as fallback.
      return _computeAggregatesFromItems(listIds);
    }
  }
  
  /// Compute aggregates directly from items subcollection.
  /// Used as fallback when hydration doc doesn't exist or cloud function fails.
  static Future<Map<String, Map<String, dynamic>>> _computeAggregatesFromItems(
    List<String> listIds,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    
    // Process in parallel for speed.
    await Future.wait(listIds.map((listId) async {
      try {
        final itemsSnap = await _firestore
            .collection('shopping_lists')
            .doc(listId)
            .collection('items')
            .get();
        
        int totalItems = 0;
        int completedItems = 0;
        double estimatedTotal = 0.0;
        int distinctProducts = 0;
        int distinctCompleted = 0;
        
        for (final doc in itemsSnap.docs) {
          final data = doc.data();
          final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
          final price = (data['estimatedPrice'] as num?)?.toDouble() ?? 0.0;
          final isCompleted = data['isCompleted'] as bool? ?? false;
          
          totalItems += quantity;
          distinctProducts += 1;
          
          if (isCompleted) {
            completedItems += quantity;
            distinctCompleted += 1;
          }
          
          estimatedTotal += quantity * price;
        }
        
        out[listId] = {
          'totalItems': totalItems,
          'completedItems': completedItems,
          'estimatedTotal': estimatedTotal,
          'distinctProducts': distinctProducts,
          'distinctCompleted': distinctCompleted,
          'updatedAt': null,
        };
        
        AppLogger.d('[HYDRATION_DEBUG] Fallback computed for $listId: $totalItems items, Rs $estimatedTotal');
      } catch (e) {
        AppLogger.w('[HYDRATION_DEBUG] Failed to compute fallback for $listId: $e');
        out[listId] = {
          'totalItems': 0,
          'completedItems': 0,
          'estimatedTotal': 0.0,
          'distinctProducts': 0,
          'distinctCompleted': 0,
          'updatedAt': null,
        };
      }
    }));
    
    return out;
  }
}
