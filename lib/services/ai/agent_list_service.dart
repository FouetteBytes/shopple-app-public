import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/models/ai_agent/agent_function_calls.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';

class AgentListService {
  Future<String?> createListWithDetails(CreateListCall call, Function(String, String, {bool success, Map<String, dynamic>? meta}) log) async {
    try {
      final lower = call.listName.toLowerCase();
      String icon = 'shopping_cart';
      String color = '#4CAF50';
      if (lower.contains('travel') || lower.contains('trip')) {
        icon = 'flight';
        color = '#1976D2';
      } else if (lower.contains('party')) {
        icon = 'celebration';
        color = '#9C27B0';
      } else if (lower.contains('week') || lower.contains('weekly')) {
        icon = 'calendar_today';
        color = '#009688';
      } else if (lower.contains('bbq')) {
        icon = 'outdoor_grill';
        color = '#FF5722';
      } else if (lower.contains('school')) {
        icon = 'school';
        color = '#3F51B5';
      } else if (lower.contains('gym') || lower.contains('fitness')) {
        icon = 'fitness_center';
        color = '#E91E63';
      }
      final id = await ShoppingListService.createShoppingList(
        name: call.listName,
        iconId: icon,
        colorTheme: color,
        budgetLimit: call.budget ?? 0.0,
        startDate: call.startDate,
        endDate: call.endDate,
      );
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final now = DateTime.now();
          final optimistic = ShoppingList(
            id: id,
            name: call.listName,
            description: '',
            iconId: icon,
            colorTheme: color,
            createdBy: user.uid,
            createdAt: now,
            updatedAt: now,
            lastActivity: now,
            budgetLimit: call.budget ?? 0.0,
            memberIds: const [],
            memberRoles: const {},
            startDate: call.startDate,
            endDate: call.endDate,
          );
          ShoppingListCache.instance.optimisticInsert(optimistic);
          ShoppingListCache.instance.markListForHydration(id);
          await ShoppingListCache.instance.reconcileHydrationFor([id]);
        }
      } catch (_) {}
      log(
        'create_list',
        'Created list ${call.listName}',
        meta: call.toJson(),
      );
      return id;
    } catch (e) {
      log('create_list', 'Create list failed: $e', success: false);
      return null;
    }
  }
}
