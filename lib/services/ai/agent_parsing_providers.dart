import 'dart:convert';

import 'package:shopple/models/ai_agent/agent_intents.dart';
import 'package:shopple/services/ai/gemini_service.dart';
import 'package:shopple/services/ai/pii_sanitizer.dart';
import 'package:shopple/config/feature_flags_ai.dart';

/// Abstraction for parsing a free-form user command into a structured command.
abstract class AgentParsingProvider {
  Future<AgentParsedCommand?> parse(
    String input, {
    void Function(String token)? onStream,
  });
  String get id;
}

/// Heuristic / rule based fallback parser (always available).
class HeuristicParsingProvider implements AgentParsingProvider {
  @override
  String get id => 'heuristic';

  @override
  Future<AgentParsedCommand?> parse(
    String input, {
    void Function(String token)? onStream,
  }) async {
    return AgentCommandParser.parse(input);
  }
}

/// Gemini LLM JSON parser provider (gated by feature flag). Supports optional token streaming.
class GeminiLLMParsingProvider implements AgentParsingProvider {
  @override
  String get id => 'gemini_llm';

  @override
  Future<AgentParsedCommand?> parse(
    String input, {
    void Function(String token)? onStream,
  }) async {
    if (!AIFeatureFlags.llmParsingEnabled) return null;
    // Skip very short prompts to save cost.
    if (input.trim().split(RegExp(r'\s+')).length < 3) return null;
    final sanitized = PIISanitizer.redact(input);
    final prompt = _buildParsingPrompt(sanitized);

    try {
      // If streaming enabled, consume stream and progressively try to parse JSON.
      if (AIFeatureFlags.streamingUIEnabled && onStream != null) {
        final buffer = StringBuffer();
        await for (final token in GeminiService.instance.generateTextStream(
          prompt,
        )) {
          if (token.isEmpty) continue;
          buffer.write(token);
          onStream(token);
          final parsed = _attemptJson(buffer.toString());
          if (parsed != null) {
            return parsed; // Early resolution when JSON complete.
          }
        }
        // Stream ended – final attempt.
        return _attemptJson(buffer.toString());
      }
      // Non-streaming path.
      final raw = await GeminiService.instance.generateText(prompt);
      return _attemptJson(raw);
    } catch (_) {
      return null; // swallow errors – caller will fallback.
    }
  }

  AgentParsedCommand? _attemptJson(String raw) {
    final jsonText = _extractJsonObject(raw);
    if (jsonText == null) return null;
    try {
      final decoded = json.decode(jsonText);
      if (decoded is! Map) return null;
      final listName = (decoded['listName'] as String?)?.trim();
      final create =
          decoded['createList'] == true &&
          listName != null &&
          listName.isNotEmpty;
      final itemsRaw = decoded['items'];
      final List<String> items = itemsRaw is List
          ? itemsRaw
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
      if (listName == null && items.isEmpty) return null;
      // Attempt budget & date fields if LLM returns them (future-proof), else null
      double? budget;
      if (decoded['budget'] is num) {
        budget = (decoded['budget'] as num).toDouble();
      }
      DateTime? startDate;
      DateTime? endDate;
      if (decoded['startDate'] is String) {
        startDate = DateTime.tryParse(decoded['startDate']);
      }
      if (decoded['endDate'] is String) {
        endDate = DateTime.tryParse(decoded['endDate']);
      }
      // Optional quantities map: support future schema field "itemQuantities" map phrase->int
      Map<String, int> itemQuantities = {};
      if (decoded['itemQuantities'] is Map) {
        (decoded['itemQuantities'] as Map).forEach((k, v) {
          final key = k.toString();
          if (v is num) {
            final vi = v.toInt();
            if (vi > 0) itemQuantities[key] = vi;
          }
        });
      }
      return AgentParsedCommand(
        listName: listName,
        rawItemPhrases: items,
        createListRequested: create,
        budgetLimit: budget,
        startDate: startDate,
        endDate: endDate,
        itemQuantities: itemQuantities,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildParsingPrompt(String userInput) {
    return 'You are a strict JSON producing parser for a shopping list assistant.\n'
        'Extract from USER INPUT: optional list name, whether a list should be created, item phrases, OPTIONAL budget limit (number), OPTIONAL date range (start & end).\n'
        'Rules:\n'
        '- Return ONLY a JSON object, no markdown, no commentary.\n'
        '- JSON schema: {"listName": String|null, "createList": Boolean, "items": [String], "budget": Number|null, "startDate": String|null, "endDate": String|null, "itemQuantities": {String: Number}|null }\n'
        '- listName: name of list if user asks to create or references one (e.g. "create a new list called dinner" -> "Dinner"). Capitalize first letter.\n'
        '- createList: true only if user explicitly requests creation (words like create/make/new list/start a list).\n'
        '- items: individual product phrases to attempt to add. Split on commas + conjunctions. Remove filler words (please, kindly).\n'
        '- itemQuantities: map each original item phrase (exact string from items array) to an integer quantity ONLY when user clearly specifies a number or words like "a dozen" (12), "a couple of" (2), "a few" (4 default), "several" (6). Omit or set null when unspecified.\n'
        '- budget: numeric value (no currency symbol) if user sets a budget / limit / cap (e.g. "\$50 budget" => 50). If multiple numbers, choose one closest to the word budget/limit. If none, null.\n'
        '- Date range: detect phrases like "from 5/9 to 7/9", "from monday to wednesday", "next week", "this weekend", "next weekend".\n'
        '- startDate/endDate: ISO format YYYY-MM-DD. For single day like "on 5/9" set both startDate & endDate to that day. If only one boundary present, leave the missing one null.\n'
        '- If brand specific item like "coca cola" include as is.\n'
        '- If user says "a meat type" interpret as a generic item phrase "meat".\n'
        '- If user references an existing list without create verbs, listName may appear but createList should be false.\n'
        'USER INPUT: $userInput\nReturn JSON now.';
  }

  String? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    if (start == -1) return null;
    int depth = 0;
    for (int i = start; i < text.length; i++) {
      final c = text[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }
}
