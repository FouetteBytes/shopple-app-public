/// Structured function call abstraction for AI agent actions.
/// Enables parser (LLM or heuristic) to emit executable actions.
/// Built locally from parsed commands; extensible for server/LLM planners.

library;

import 'package:shopple/models/ai_agent/agent_intents.dart';

/// Enum-like type constants for known function names the agent can execute.
class AgentFunctionNames {
  static const createList = 'create_list';
  static const addItem = 'add_item';
  static const finalize = 'finalize';
  static const getProductPrice = 'get_product_price';
  static const getListItemCount = 'get_list_item_count';
  static const getProductListCount = 'get_product_list_count';
  static const getListItems = 'get_list_items';
}

/// Base interface for a function call.
abstract class AgentFunctionCall {
  String get name; // one of AgentFunctionNames.*
  Map<String, dynamic> toJson();
}

class CreateListCall implements AgentFunctionCall {
  final String listName;
  final double? budget;
  final DateTime? startDate;
  final DateTime? endDate;
  CreateListCall({
    required this.listName,
    this.budget,
    this.startDate,
    this.endDate,
  });
  @override
  String get name => AgentFunctionNames.createList;
  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'listName': listName,
    if (budget != null) 'budget': budget,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
  };
}

class AddItemCall implements AgentFunctionCall {
  final String phrase; // original phrase for logging
  final int quantity;
  AddItemCall({required this.phrase, this.quantity = 1});
  @override
  String get name => AgentFunctionNames.addItem;
  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'phrase': phrase,
    'quantity': quantity,
  };
}

class FinalizeCall implements AgentFunctionCall {
  @override
  String get name => AgentFunctionNames.finalize;
  @override
  Map<String, dynamic> toJson() => {'name': name};
}

class GetProductPriceCall implements AgentFunctionCall {
  final String productPhrase;
  GetProductPriceCall(this.productPhrase);
  @override
  String get name => AgentFunctionNames.getProductPrice;
  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'productPhrase': productPhrase,
  };
}

class GetListItemCountCall implements AgentFunctionCall {
  final String listName;
  GetListItemCountCall(this.listName);
  @override
  String get name => AgentFunctionNames.getListItemCount;
  @override
  Map<String, dynamic> toJson() => {'name': name, 'listName': listName};
}

class GetProductListCountCall implements AgentFunctionCall {
  final String productPhrase;
  GetProductListCountCall(this.productPhrase);
  @override
  String get name => AgentFunctionNames.getProductListCount;
  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'productPhrase': productPhrase,
  };
}

class GetListItemsCall implements AgentFunctionCall {
  final String listName;
  GetListItemsCall(this.listName);
  @override
  String get name => AgentFunctionNames.getListItems;
  @override
  Map<String, dynamic> toJson() => {'name': name, 'listName': listName};
}

/// A simple plan composed of function calls in execution order.
class AgentExecutionPlan {
  final List<AgentFunctionCall> calls;
  AgentExecutionPlan(this.calls);
  Map<String, dynamic> toJson() => {
    'calls': calls.map((c) => c.toJson()).toList(),
  };

  static AgentExecutionPlan buildFromParsed(
    AgentParsedCommand parsed, {
    String? rawInput,
  }) {
    final calls = <AgentFunctionCall>[];
    if (parsed.createListRequested && parsed.listName != null) {
      calls.add(
        CreateListCall(
          listName: parsed.listName!,
          budget: parsed.budgetLimit,
          startDate: parsed.startDate,
          endDate: parsed.endDate,
        ),
      );
    }
    for (final p in parsed.rawItemPhrases) {
      final qty = parsed.itemQuantities[p] ?? 1;
      calls.add(AddItemCall(phrase: p, quantity: qty));
    }
    // Query inference heuristics from raw input
    if (rawInput != null) {
      final lower = rawInput.toLowerCase();
      // Current price query
      final priceMatch = RegExp(
        r'(?:current )?price of (.+)',
      ).firstMatch(lower);
      if (priceMatch != null) {
        final prod = priceMatch.group(1)!.trim();
        if (prod.isNotEmpty) calls.add(GetProductPriceCall(prod));
      }
      // How many items in list
      final countMatch = RegExp(
        r'how many items (?:are )?in (.+?)$',
      ).firstMatch(lower);
      if (countMatch != null) {
        final ln = countMatch.group(1)!.replaceAll(RegExp(r'list'), '').trim();
        if (ln.isNotEmpty) calls.add(GetListItemCountCall(ln));
      }
      // Product list count
      final prodListMatch =
          RegExp(
            r'in how many lists (?:does|do) (.+?) (?:appear|exist)',
          ).firstMatch(lower) ??
          RegExp(r'how many lists .*?(?:has|with) (.+)').firstMatch(lower);
      if (prodListMatch != null) {
        final phrase = prodListMatch.group(prodListMatch.groupCount)!.trim();
        if (phrase.isNotEmpty) calls.add(GetProductListCountCall(phrase));
      }
      // Show list items
      final showListMatch = RegExp(
        r'(?:what (?:is|are) in|show (?:me )?items in|show (?:me )?the items in) (.+)',
      ).firstMatch(lower);
      if (showListMatch != null) {
        final ln = showListMatch
            .group(1)!
            .replaceAll(RegExp(r'list'), '')
            .trim();
        if (ln.isNotEmpty) calls.add(GetListItemsCall(ln));
      }
    }
    calls.add(FinalizeCall());
    return AgentExecutionPlan(calls);
  }
}

/// Specification metadata for each callable agent function (for introspection / LLM tool schemas).
class AgentFunctionSpec {
  final String name;
  final String description;
  final Map<String, dynamic> parameters; // simple JSON-schema-like structure
  const AgentFunctionSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

class AgentFunctionRegistry {
  static final List<AgentFunctionSpec> specs = [
    AgentFunctionSpec(
      name: AgentFunctionNames.createList,
      description:
          'Create a shopping list (idempotent within a run) before adding items.',
      parameters: {
        'type': 'object',
        'required': ['listName'],
        'properties': {
          'listName': {
            'type': 'string',
            'description': 'Name of the list to create',
          },
          'budget': {'type': 'number', 'description': 'Optional budget limit'},
          'startDate': {'type': 'string', 'format': 'date-time'},
          'endDate': {'type': 'string', 'format': 'date-time'},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.addItem,
      description:
          'Resolve a user item phrase to a concrete product (iterative search) and add it to the active list.',
      parameters: {
        'type': 'object',
        'required': ['phrase'],
        'properties': {
          'phrase': {'type': 'string'},
          'quantity': {'type': 'integer', 'minimum': 1, 'default': 1},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.getProductPrice,
      description: 'Lookup current lowest known price for a product phrase.',
      parameters: {
        'type': 'object',
        'required': ['productPhrase'],
        'properties': {
          'productPhrase': {'type': 'string'},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.getListItemCount,
      description:
          'Return number of items contained in a list (exact or partial name match).',
      parameters: {
        'type': 'object',
        'required': ['listName'],
        'properties': {
          'listName': {'type': 'string'},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.getProductListCount,
      description:
          'Count user lists containing an item whose name includes the given phrase.',
      parameters: {
        'type': 'object',
        'required': ['productPhrase'],
        'properties': {
          'productPhrase': {'type': 'string'},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.getListItems,
      description: 'List (sample) items within a named list.',
      parameters: {
        'type': 'object',
        'required': ['listName'],
        'properties': {
          'listName': {'type': 'string'},
        },
      },
    ),
    AgentFunctionSpec(
      name: AgentFunctionNames.finalize,
      description: 'Marks end of execution plan. No parameters.',
      parameters: {'type': 'object', 'properties': {}},
    ),
  ];

  static AgentFunctionSpec? byName(String name) => specs.firstWhere(
    (s) => s.name == name,
    orElse: () => const AgentFunctionSpec(
      name: '__missing__',
      description: 'Unknown function',
      parameters: {'type': 'object'},
    ),
  );
}
