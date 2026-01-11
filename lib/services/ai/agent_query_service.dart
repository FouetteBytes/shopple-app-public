import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_service.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';

class AgentQueryService {
  Future<void> executeGetProductPrice(String phrase, Function(String, String, {bool success, Map<String, dynamic>? meta}) log) async {
    try {
      log('query', 'Looking up price for "$phrase"');
      final results = await EnhancedProductService.searchProductsWithPrices(
        phrase,
      );
      if (results.isEmpty) {
        log('query', 'No product match for "$phrase"', success: false);
        return;
      }
      final first = results.first;
      if (first.prices.isEmpty) {
        log('query', 'Product ${first.product.name} has no current prices');
      } else {
        final cheapest = first.prices.values.reduce(
          (a, b) => a.price <= b.price ? a : b,
        );
        log(
          'query_result',
          'Lowest current price for ${first.product.name}: ${cheapest.price.toStringAsFixed(2)} at ${cheapest.supermarketId}',
          meta: {'productId': first.product.id},
        );
      }
    } catch (e) {
      log('query', 'Price lookup failed: $e', success: false);
    }
  }

  Future<void> executeGetListItemCount(String listName, Function(String, String, {bool success, Map<String, dynamic>? meta}) log) async {
    try {
      log('query', 'Counting items in list "$listName"');
      final lists = await ShoppingListService.getUserShoppingLists();
      final target = listName.toLowerCase();
      ShoppingList? exact;
      for (final l in lists) {
        if (l.name.toLowerCase() == target) {
          exact = l;
          break;
        }
      }
      ShoppingList? partial;
      if (exact == null) {
        for (final l in lists) {
          if (l.name.toLowerCase().contains(target)) {
            partial = l;
            break;
          }
        }
      }
      final match = exact ?? partial;
      if (match == null) {
        log('query', 'No list found matching "$listName"', success: false);
        return;
      }
      final items = await ShoppingListService.getListItems(match.id);
      log('query_result', 'List "${match.name}" has ${items.length} items');
    } catch (e) {
      log('query', 'Item count failed: $e', success: false);
    }
  }

  Future<void> executeGetProductListCount(String phrase, Function(String, String, {bool success, Map<String, dynamic>? meta}) log) async {
    try {
      log('query', 'Counting lists containing "$phrase"');
      final lists = await ShoppingListService.getUserShoppingLists();
      int hit = 0;
      for (final l in lists) {
        final items = await ShoppingListService.getListItems(l.id);
        if (items.any(
          (it) => it.name.toLowerCase().contains(phrase.toLowerCase()),
        )) {
          hit++;
        }
      }
      log('query_result', 'Product phrase "$phrase" appears in $hit list(s)');
    } catch (e) {
      log('query', 'Product list count failed: $e', success: false);
    }
  }

  Future<void> executeGetListItems(String listName, Function(String, String, {bool success, Map<String, dynamic>? meta}) log) async {
    try {
      log('query', 'Listing items in "$listName"');
      final lists = await ShoppingListService.getUserShoppingLists();
      final target = listName.toLowerCase();
      ShoppingList? exact;
      for (final l in lists) {
        if (l.name.toLowerCase() == target) {
          exact = l;
          break;
        }
      }
      ShoppingList? partial;
      if (exact == null) {
        for (final l in lists) {
          if (l.name.toLowerCase().contains(target)) {
            partial = l;
            break;
          }
        }
      }
      final match = exact ?? partial;
      if (match == null) {
        log('query', 'No list found for "$listName"', success: false);
        return;
      }
      final items = await ShoppingListService.getListItems(match.id);
      final names = items.map((i) => i.name).take(15).join(', ');
      log(
        'query_result',
        'Items in ${match.name}: $names${items.length > 15 ? ' …' : ''}',
        meta: {'count': items.length},
      );
    } catch (e) {
      log('query', 'List items query failed: $e', success: false);
    }
  }
}
