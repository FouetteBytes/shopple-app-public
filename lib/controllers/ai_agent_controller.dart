import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shopple/config/feature_flags_ai.dart';
import 'package:shopple/models/ai_agent/agent_function_calls.dart';
import 'package:shopple/models/ai_agent/agent_intents.dart';
import 'package:shopple/models/ai_agent/agent_session_models.dart';
import 'package:shopple/models/product_model.dart';
import 'package:shopple/services/ai/agent_history_service.dart';
import 'package:shopple/services/ai/agent_list_service.dart';
import 'package:shopple/services/ai/agent_parsing_providers.dart';
import 'package:shopple/services/ai/agent_query_service.dart';
import 'package:shopple/services/ai/agent_search_service.dart';
import 'package:shopple/services/ai/server_agent_service.dart';
import 'package:shopple/services/analytics/agent_analytics.dart';
import 'package:shopple/services/product/enhanced_product_service.dart';
import 'package:shopple/services/search/unified_product_search_service.dart';
import 'package:shopple/services/shopping_lists/shopping_list_cache.dart';
import 'package:shopple/utils/app_logger.dart';

class AIAgentController extends GetxController {
  // State
  bool _running = false;
  AgentRunResult? _lastResult;
  final List<AgentActionLog> _logs = [];
  String? _activeUid;
  final Set<String> _preferredStores = <String>{};
  
  // Telemetry
  int _telemetryItemsResolved = 0;
  int _telemetryItemsFailed = 0;
  
  // Item tracking
  final Map<String, String> _itemStatuses = {};
  final Map<String, String> _itemImages = {};
  final Stopwatch _runWatch = Stopwatch();
  
  // Session state
  String? _activeSessionHistoryTs;
  List<Product>? _allProductsCache;
  StreamSubscription<UnifiedSearchEvent>? _unifiedSearchSub;
  AgentExecutionSession? _session;
  StreamSubscription<User?>? _authSub;
  final StringBuffer _streamingBuffer = StringBuffer();

  // Services
  final AgentHistoryService _historyService = AgentHistoryService();
  final AgentListService _listService = AgentListService();
  final AgentQueryService _queryService = AgentQueryService();
  final AgentSearchService _searchService = AgentSearchService();

  // Parsers
  late final List<AgentParsingProvider> _parsers = [
    GeminiLLMParsingProvider(),
    HeuristicParsingProvider(),
  ];

  // Getters
  bool get isRunning => _running;
  AgentRunResult? get lastResult => _lastResult;
  List<AgentActionLog> get logs => List.unmodifiable(_logs);
  Map<String, String> get itemStatuses => Map.unmodifiable(_itemStatuses);
  Map<String, String> get itemImages => Map.unmodifiable(_itemImages);
  bool get cancelRequested => false; // Handled internally by services now
  List<Map<String, dynamic>> get history => _historyService.history;
  int get elapsedMs => _runWatch.elapsedMilliseconds;
  bool get sessionActive => _session != null && !_session!.completed;
  AgentExecutionSession? get currentSession => _session;
  bool get remoteHistoryLoaded => _historyService.remoteHistoryLoaded;
  String get streamingParsePreview => _streamingBuffer.toString();

  AIAgentController() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_handleAuthUser);
    _handleAuthUser(FirebaseAuth.instance.currentUser);
    _unifiedSearchSub = UnifiedProductSearchService.events.listen((evt) {
      if (_running) {
        _log(
          'search_observe',
          'Observed UI search "${evt.query}" (${evt.results.length} results)',
        );
      }
    });
  }

  void _log(String type, String description, {bool success = true, Map<String, dynamic>? meta}) {
    _logs.add(AgentActionLog(type: type, description: description, success: success, meta: meta));
    update();
  }

  Future<AgentRunResult> runUserCommand(String input, {bool stepByStep = true}) async {
    if (_running) throw StateError('Agent already running');
    _running = true;
    _resetRunState();
    
    try {
      await ShoppingListCache.instance.ensureSubscribed();
    } catch (_) {}
    update();

    // 1. Server Flow
    if (AIFeatureFlags.serverFlowEnabled) {
      try {
        return await _runServerFlow(input);
      } catch (e) {
        _log('server_delegate', 'Server flow failed, local fallback: $e', success: false);
      }
    }

    // 2. Local Flow
    _searchService.resetCancel();
    _runWatch.reset();
    _runWatch.start();
    _streamingBuffer.clear();

    // 3. Parse
    final parsed = await _parseInput(input);
    _logParsingSteps(parsed);
    _detectStorePreferences(input);
    
    if (AIFeatureFlags.analyticsEnabled) {
      AgentAnalytics.instance.record('agent_run_start', data: {
        'hasListName': parsed.listName != null,
        'itemCount': parsed.rawItemPhrases.length,
        'createList': parsed.createListRequested,
      });
    }

    // 4. Plan
    final plan = AgentExecutionPlan.buildFromParsed(parsed, rawInput: input);
    _logPlanSteps(plan);

    if (stepByStep) {
      return await _runStepByStepSession(input, parsed, plan);
    }

    // 5. Single-shot Execution
    await _ensureProductsLoaded();
    return await _runSingleShotExecution(input, parsed, plan);
  }

  Future<AgentRunResult> _runServerFlow(String input) async {
    _log('server_delegate', 'Delegating to backend flow');
    final result = await ServerAgentService.instance.runShoppingAgent(userInput: input);
    final actions = (result['actions'] as List?)?.cast<Map>() ?? [];
    for (final a in actions) {
      _logs.add(AgentActionLog(type: a['type']?.toString() ?? 'action', description: a.toString()));
    }
    if (result['runId'] != null) {
      _logs.add(AgentActionLog(type: 'run_id', description: 'Run: ${result['runId']}'));
    }
    if (result['quota'] is Map) {
      final q = result['quota'] as Map;
      _logs.add(AgentActionLog(type: 'quota', description: 'Quota remaining: ${q['remaining']} / ${q['limit']}'));
    }
    _running = false;
    _lastResult = AgentRunResult(
      listId: (result['parsed']?['listId'] as String?),
      logs: List.of(_logs),
      addedItems: {},
      failures: {},
    );
    update();
    return _lastResult!;
  }

  Future<AgentParsedCommand> _parseInput(String input) async {
    AgentParsedCommand? parsed;
    for (final p in _parsers) {
      parsed = await p.parse(input, onStream: (tok) {
        _streamingBuffer.write(tok);
        update();
      });
      if (parsed != null) {
        _log('parse_provider', 'Parsed with ${p.id}');
        break;
      }
    }
    return parsed ?? AgentCommandParser.parse(input);
  }

  void _logParsingSteps(AgentParsedCommand parsed) {
    _log('parse_steps', 'Breaking down user request into actionable steps...');
    if (parsed.listName != null) _log('parse_step', '✓ List name: "${parsed.listName}"');
    if (parsed.budgetLimit != null && parsed.budgetLimit! > 0) {
      _log('parse_step', '✓ Budget limit: \$${parsed.budgetLimit!.toStringAsFixed(2)}');
    }
    if (parsed.startDate != null) {
      _log('parse_step', '✓ Start date: ${parsed.startDate!.toLocal().toString().split(' ')[0]}');
    }
    if (parsed.endDate != null) {
      _log('parse_step', '✓ End date: ${parsed.endDate!.toLocal().toString().split(' ')[0]}');
    }
    if (parsed.rawItemPhrases.isNotEmpty) {
      _log('parse_step', '✓ Items to find: ${parsed.rawItemPhrases.join(', ')}');
    }
    _log('parse', 'Parsed: listName=${parsed.listName}, items=${parsed.rawItemPhrases}');
  }

  void _detectStorePreferences(String input) {
    final lowerInput = input.toLowerCase();
    const knownStores = ['cargills', 'keells', 'arpico', 'glomark', 'laughfs', 'laughts', 'laufs', 'spar'];
    for (final s in knownStores) {
      if (lowerInput.contains(s)) _preferredStores.add(s);
    }
    if (_preferredStores.isNotEmpty) {
      _log('parse_step', '✓ Preferred stores: ${_preferredStores.join(', ')}');
      _log('parse', 'Detected store preferences: ${_preferredStores.join(', ')}');
      AppLogger.d('[AGENT] Store preferences: $_preferredStores');
    }
  }

  void _logPlanSteps(AgentExecutionPlan plan) {
    _log('plan', 'Built plan with ${plan.calls.length} calls');
    _log('plan_steps', 'Execution plan created with the following steps:');
    for (int i = 0; i < plan.calls.length; i++) {
      final call = plan.calls[i];
      if (call is CreateListCall) {
        final budgetPart = call.budget != null ? ' with budget \$${call.budget!.toStringAsFixed(2)}' : '';
        _log('plan_step', '${i + 1}. Create shopping list "${call.listName}"$budgetPart');
      } else if (call is AddItemCall) {
        _log('plan_step', '${i + 1}. Find and add "${call.phrase}"${call.quantity > 1 ? ' (qty: ${call.quantity})' : ''}');
      } else {
        _log('plan_step', '${i + 1}. ${call.name}');
      }
    }
  }

  Future<AgentRunResult> _runStepByStepSession(String input, AgentParsedCommand parsed, AgentExecutionPlan plan) async {
    _log('session_mode', 'Step-by-step mode: auto-create list first, then await user trigger for each item.');
    final addedMap = <String, String>{};
    final failuresMap = <String, String>{};
    int startIndex = 0;
    String? createdListId;

    if (plan.calls.isNotEmpty && plan.calls.first is CreateListCall) {
      final first = plan.calls.first as CreateListCall;
      _log('session_step_start', 'Auto-creating list: ${first.listName}');
      createdListId = await _listService.createListWithDetails(first, _log);
      if (createdListId == null) {
        failuresMap['__list__'] = 'create_failed';
        _log('create_list', 'List creation failed in step mode', success: false);
      } else {
        _log('session_list_created', 'List created (id=$createdListId)');
      }
      startIndex = 1;
    }

    try {
      await _ensureProductsLoaded();
    } catch (_) {}

    for (int i = startIndex; i < plan.calls.length; i++) {
      final c = plan.calls[i];
      if (c is AddItemCall) {
        _itemStatuses[c.phrase] = 'pending';
      }
    }

    final session = AgentExecutionSession(
      input: input,
      parsed: parsed,
      plan: plan,
      currentIndex: startIndex,
      added: addedMap,
      failures: failuresMap,
    );
    session.listId = createdListId;
    
    if (startIndex >= plan.calls.length) {
      session.completed = true;
      _log('session_complete', 'Session complete after list creation (no items).');
    } else {
      _log('session_wait', 'Session ready: ${plan.calls.length - startIndex} item steps remaining.');
    }

    _session = session;
    _running = false;
    _runWatch.stop();
    _lastResult = AgentRunResult(
      listId: createdListId,
      logs: List.of(_logs),
      addedItems: addedMap,
      failures: failuresMap,
    );
    update();
    return _lastResult!;
  }

  Future<AgentRunResult> _runSingleShotExecution(String input, AgentParsedCommand parsed, AgentExecutionPlan plan) async {
    String? listId;
    final added = <String, String>{};
    final failures = <String, String>{};

    for (final call in plan.calls) {
      if (call is CreateListCall) {
        _log('execute_step', 'Step: Preparing list creation for "${call.listName}"');
        listId = await _listService.createListWithDetails(call, _log);
        if (listId == null) {
          _log('create_list', 'Failed: could not create list', success: false);
          break;
        }
      } else if (call is AddItemCall) {
        _log('execute_step', 'Step: Finding "${call.phrase}"${call.quantity > 1 ? ' (qty: ${call.quantity})' : ''}...');
        if (listId == null) {
          listId = await _listService.createListWithDetails(
            CreateListCall(
              listName: parsed.listName ?? 'My List',
              budget: parsed.budgetLimit ?? 0.0,
              startDate: parsed.startDate,
              endDate: parsed.endDate,
            ),
            _log,
          );
          if (listId == null) {
            failures[call.phrase] = 'no_list_context';
            continue;
          }
        }
        _itemStatuses[call.phrase] = 'pending';
        update();
        
        final success = await _searchService.addSingleItem(
          listId,
          call.phrase,
          added,
          failures,
          _itemStatuses,
          _itemImages,
          _log,
          () => _telemetryItemsResolved++,
          () => _telemetryItemsFailed++,
          quantity: call.quantity,
        );
        
        if (!success) {
          failures[call.phrase] = failures[call.phrase] ?? 'search_failed';
        }
      } else if (call is GetProductPriceCall) {
        await _queryService.executeGetProductPrice(call.productPhrase, _log);
      } else if (call is GetListItemCountCall) {
        await _queryService.executeGetListItemCount(call.listName, _log);
      } else if (call is GetProductListCountCall) {
        await _queryService.executeGetProductListCount(call.productPhrase, _log);
      } else if (call is GetListItemsCall) {
        await _queryService.executeGetListItems(call.listName, _log);
      } else if (call is FinalizeCall) {
        await Future.delayed(const Duration(milliseconds: 250));
        _log('finalize', 'Planning complete');
      }
    }

    _running = false;
    _runWatch.stop();
    _lastResult = AgentRunResult(
      listId: listId,
      logs: List.of(_logs),
      addedItems: added,
      failures: failures,
    );

    _logCompletionSummary(added.length, failures.length);
    
    try {
      await ShoppingListCache.instance.forceRefreshHydration();
    } catch (_) {}
    
    if (AIFeatureFlags.analyticsEnabled) {
      AgentAnalytics.instance.record('agent_run_complete', data: {
        'durationMs': _runWatch.elapsedMilliseconds,
        'added': added.length,
        'failed': failures.length,
      });
    }
    
    _historyService.persistHistoryEntry(input, _lastResult!, _runWatch.elapsedMilliseconds, _itemImages);
    update();
    return _lastResult!;
  }

  void _logCompletionSummary(int successCount, int failCount) {
    final totalTime = (_runWatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
    if (successCount > 0 && failCount == 0) {
      _log('completion_success', '🎉 Process completed successfully! Added $successCount item${successCount == 1 ? '' : 's'} to your shopping list in ${totalTime}s');
    } else if (successCount > 0 && failCount > 0) {
      _log('completion_partial', '✅ Process completed! Added $successCount item${successCount == 1 ? '' : 's'}, $failCount item${failCount == 1 ? '' : 's'} need${failCount == 1 ? 's' : ''} refinement (${totalTime}s)');
    } else if (failCount > 0) {
      _log('completion_failed', '⚠️ Process completed with issues. $failCount item${failCount == 1 ? '' : 's'} could not be resolved automatically (${totalTime}s)');
    } else {
      _log('completion_empty', '✓ Process completed in ${totalTime}s');
    }
    _log('finalize', 'Completed: added $successCount, failed $failCount in ${_runWatch.elapsedMilliseconds} ms');
  }

  Future<void> startAgentSession(String input) async {
    if (_running) throw StateError('Agent busy');
    if (sessionActive) throw StateError('Session already active');
    
    _resetRunState();
    _session = null;
    update();

    _log('session_start', 'Initializing agent session');
    final parsed = await _parseInput(input);
    _log('parse', 'Parsed (session mode): listName=${parsed.listName}, items=${parsed.rawItemPhrases}');
    
    final plan = AgentExecutionPlan.buildFromParsed(parsed, rawInput: input);
    _log('plan', 'Session plan: ${plan.calls.length} steps');
    
    for (int i = 0; i < plan.calls.length; i++) {
      final c = plan.calls[i];
      if (c is CreateListCall) {
        _log('plan_step', 'Step ${i + 1}: Create list "${c.listName}"');
      } else if (c is AddItemCall) {
        _log('plan_step', 'Step ${i + 1}: Add "${c.phrase}" (qty ${c.quantity})');
        _itemStatuses[c.phrase] = 'pending';
      } else {
        _log('plan_step', 'Step ${i + 1}: ${c.name}');
      }
    }
    
    _session = AgentExecutionSession(
      input: input,
      parsed: parsed,
      plan: plan,
      currentIndex: 0,
      added: <String, String>{},
      failures: <String, String>{},
    );
    update();
  }

  Future<AgentStepResult?> executeNextSessionStep() async {
    final s = _session;
    if (s == null || s.completed) return null;
    if (_running) throw StateError('Already executing a step');
    
    _running = true;
    update();
    
    final call = s.plan.calls[s.currentIndex];
    _log('session_step_start', 'Executing step ${s.currentIndex + 1}/${s.plan.calls.length}: ${call.name}');
    
    try {
      if (call is CreateListCall) {
        final id = await _listService.createListWithDetails(call, _log);
        if (id == null) {
          _log('create_list', 'Failed creating list', success: false);
          s.failures['__list__'] = 'create_failed';
        } else {
          s.listId = id;
        }
      } else if (call is AddItemCall) {
        if (s.listId == null) {
          final id = await _listService.createListWithDetails(
            CreateListCall(
              listName: s.parsed.listName ?? 'My List',
              budget: s.parsed.budgetLimit ?? 0.0,
              startDate: s.parsed.startDate,
              endDate: s.parsed.endDate,
            ),
            _log,
          );
          s.listId = id;
          if (id == null) {
            s.failures[call.phrase] = 'no_list_context';
          }
        }
        if (s.listId != null) {
          final ok = await _searchService.addSingleItem(
            s.listId!,
            call.phrase,
            s.added,
            s.failures,
            _itemStatuses,
            _itemImages,
            _log,
            () => _telemetryItemsResolved++,
            () => _telemetryItemsFailed++,
            quantity: call.quantity,
          );
          if (!ok) {
            s.failures[call.phrase] = s.failures[call.phrase] ?? 'search_failed';
          }
        }
      } else if (call is FinalizeCall) {
        _log('finalize', 'Finalize step');
      } else if (call is GetProductPriceCall) {
        await _queryService.executeGetProductPrice(call.productPhrase, _log);
      } else if (call is GetListItemCountCall) {
        await _queryService.executeGetListItemCount(call.listName, _log);
      } else if (call is GetProductListCountCall) {
        await _queryService.executeGetProductListCount(call.productPhrase, _log);
      } else if (call is GetListItemsCall) {
        await _queryService.executeGetListItems(call.listName, _log);
      }
    } finally {
      s.currentIndex++;
      final done = s.currentIndex >= s.plan.calls.length;
      if (done) {
        s.completed = true;
        _log('session_complete', 'Session complete: added ${s.added.length}, failed ${s.failures.length}');
        try {
          await ShoppingListCache.instance.forceRefreshHydration();
        } catch (_) {}
      } else {
        _log('session_step_ready', 'Ready for next step (${s.currentIndex + 1}/${s.plan.calls.length})');
      }
      _running = false;
      update();
    }
    return AgentStepResult(
      stepIndex: s.currentIndex - 1,
      totalSteps: s.plan.calls.length,
      added: Map.of(s.added),
      failures: Map.of(s.failures),
      completed: s.completed,
    );
  }

  List<String> get sessionPendingItemPhrases {
    final s = _session;
    if (s == null) return const [];
    final pending = <String>[];
    for (final call in s.plan.calls) {
      if (call is AddItemCall) {
        final st = _itemStatuses[call.phrase];
        if (st == null || st == 'pending' || st == 'searching') {
          pending.add(call.phrase);
        }
      }
    }
    return pending;
  }

  Future<AgentStepResult?> executeSessionItemByPhrase(String phrase) async {
    final s = _session;
    if (s == null || s.completed) return null;
    if (_running) throw StateError('Agent busy');
    
    AddItemCall? target;
    for (final call in s.plan.calls) {
      if (call is AddItemCall && call.phrase == phrase) {
        target = call;
        break;
      }
    }
    if (target == null) {
      _log('session_item', 'No item step matches phrase "$phrase"', success: false);
      return null;
    }
    
    final currentStatus = _itemStatuses[phrase];
    if (currentStatus == 'added' || currentStatus == 'failed') {
      _log('session_item', 'Item "$phrase" already resolved (status=$currentStatus)');
      return AgentStepResult(
        stepIndex: s.currentIndex,
        totalSteps: s.plan.calls.length,
        added: Map.of(s.added),
        failures: Map.of(s.failures),
        completed: s.completed,
      );
    }

    if (_allProductsCache == null) {
      try {
        await _ensureProductsLoaded();
      } catch (_) {}
    }

    _running = true;
    update();
    _log('session_item_start', 'Executing item step for "$phrase"');
    
    try {
      if (s.listId == null) {
        final implicit = await _listService.createListWithDetails(
          CreateListCall(
            listName: s.parsed.listName ?? 'My List',
            budget: s.parsed.budgetLimit ?? 0.0,
            startDate: s.parsed.startDate,
            endDate: s.parsed.endDate,
          ),
          _log,
        );
        s.listId = implicit;
        if (implicit == null) {
          s.failures[phrase] = 'no_list_context';
          _itemStatuses[phrase] = 'failed';
        }
      }
      
      if (s.listId != null) {
        final ok = await _searchService.addSingleItem(
          s.listId!,
          phrase,
          s.added,
          s.failures,
          _itemStatuses,
          _itemImages,
          _log,
          () => _telemetryItemsResolved++,
          () => _telemetryItemsFailed++,
          quantity: target.quantity,
        );
        if (!ok) s.failures[phrase] = s.failures[phrase] ?? 'search_failed';
        
        if ((s.added.length + s.failures.length) == 1) {
          _lastResult = AgentRunResult(
            listId: s.listId,
            logs: List.of(_logs),
            addedItems: Map.of(s.added),
            failures: Map.of(s.failures),
          );
          _historyService.persistHistoryEntry(
            s.input,
            _lastResult!,
            _runWatch.elapsedMilliseconds,
            _itemImages,
            requireItems: true,
            onSessionTsUpdate: (ts) => _activeSessionHistoryTs = ts,
          );
        }
      }
    } finally {
      bool remaining = false;
      for (final call in s.plan.calls) {
        if (call is AddItemCall) {
          final st = _itemStatuses[call.phrase];
          if (st == null || st == 'pending' || st == 'searching') {
            remaining = true;
            break;
          }
        }
      }
      
      if (!remaining) {
        s.completed = true;
        _log('session_complete', 'Session complete (all item phrases attempted). Added ${s.added.length}, failed ${s.failures.length}');
        _lastResult = AgentRunResult(
          listId: s.listId,
          logs: List.of(_logs),
          addedItems: Map.of(s.added),
          failures: Map.of(s.failures),
        );
        
        _historyService.persistHistoryEntry(
          s.input,
          _lastResult!,
          _runWatch.elapsedMilliseconds,
          _itemImages,
          requireItems: true,
          overrideTs: _activeSessionHistoryTs,
          updateExisting: _activeSessionHistoryTs != null,
          activeSessionHistoryTs: _activeSessionHistoryTs,
          onSessionTsUpdate: (ts) => _activeSessionHistoryTs = ts,
        );
        _activeSessionHistoryTs = null;
        try {
          await ShoppingListCache.instance.forceRefreshHydration();
        } catch (_) {}
      } else {
        _log('session_wait', '${sessionPendingItemPhrases.length} item steps remaining');
      }
      _running = false;
      update();
    }
    
    return AgentStepResult(
      stepIndex: s.currentIndex,
      totalSteps: s.plan.calls.length,
      added: Map.of(_session!.added),
      failures: Map.of(_session!.failures),
      completed: _session!.completed,
    );
  }

  Future<void> _ensureProductsLoaded() async {
    try {
      _log('product_cache_check', 'Ensuring products are loaded for search...');
      _allProductsCache = await EnhancedProductService.getAllProducts();
      _log('product_cache_ready', 'Product cache ready: ${_allProductsCache?.length ?? 0} products available');
    } catch (e) {
      _log('product_cache_error', 'Failed to load products: $e', success: false);
    }
  }

  void requestCancel() {
    if (_running) {
      _searchService.requestCancel();
      _log('cancel', 'Cancellation requested');
      _itemStatuses.updateAll((key, value) => (value == 'pending' || value == 'searching') ? 'canceled' : value);
      update();
    }
  }

  Future<void> retryFailedItem(String phrase, {int quantity = 1}) async {
    if (_running) return;
    final listId = _lastResult?.listId;
    if (listId == null) return;
    
    _log('retry', 'Retrying item "$phrase"');
    _itemStatuses[phrase] = 'pending';
    update();
    
    final added = <String, String>{};
    final failures = <String, String>{};
    
    final ok = await _searchService.addSingleItem(
      listId,
      phrase,
      added,
      failures,
      _itemStatuses,
      _itemImages,
      _log,
      () {},
      () {},
      quantity: quantity,
    );
    
    if (ok) {
      _lastResult?.addedItems[phrase] = added[phrase]!;
      _lastResult?.failures.remove(phrase);
      _log('retry', 'Retry success for "$phrase"');
    } else {
      _lastResult?.failures[phrase] = failures[phrase] ?? 'retry_failed';
      _log('retry', 'Retry failed for "$phrase"', success: false);
    }
    update();
  }

  void _handleAuthUser(User? user) {
    final newUid = user?.uid;
    if (newUid != _activeUid) {
      _running = false;
      _searchService.resetCancel();
      _logs.clear();
      _itemStatuses.clear();
      _preferredStores.clear();
      _runWatch.stop();
      _runWatch.reset();
      _streamingBuffer.clear();
      _lastResult = null;
      _session = null;
      _activeSessionHistoryTs = null;
      _telemetryItemsResolved = 0;
      _telemetryItemsFailed = 0;
      _historyService.clearLocalState();
      update();
    }
    _activeUid = newUid;

    if (user == null) {
      update();
      return;
    }
    _historyService.loadHistory(user.uid).then((_) => update());
    _historyService.initCloudHistory(user.uid, update);
  }

  void _resetRunState() {
    _logs.clear();
    _itemStatuses.clear();
    _preferredStores.clear();
    _telemetryItemsResolved = 0;
    _telemetryItemsFailed = 0;
  }

  Future<void> clearHistory() => _historyService.clearHistory();
  Future<void> deleteHistoryEntry(String timestamp) => _historyService.deleteHistoryEntry(timestamp);

  @override
  void dispose() {
    _authSub?.cancel();
    _unifiedSearchSub?.cancel();
    _historyService.dispose();
    super.dispose();
  }
}
