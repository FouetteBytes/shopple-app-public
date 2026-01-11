/// AI Agent intent and parsing models.
/// Lightweight, rule-based until LLM (Genkit) integration is added.
/// Keeps dependencies minimal and avoids breaking existing flows.
library;

class AgentParsedCommand {
  final String? listName;
  final List<String> rawItemPhrases; // as extracted from user text
  final bool createListRequested;
  final double? budgetLimit;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> itemQuantities; // phrase -> quantity (>=1)

  AgentParsedCommand({
    required this.listName,
    required this.rawItemPhrases,
    required this.createListRequested,
    required this.budgetLimit,
    required this.startDate,
    required this.endDate,
    required this.itemQuantities,
  });

  bool get hasItems => rawItemPhrases.isNotEmpty;
}

class AgentActionLog {
  final DateTime timestamp;
  final String type; // e.g. parse, create_list, search_item, add_item
  final String description;
  final bool success;
  final Map<String, dynamic>? meta;

  AgentActionLog({
    required this.type,
    required this.description,
    this.success = true,
    this.meta,
  }) : timestamp = DateTime.now();
}

class AgentRunResult {
  final String? listId;
  final List<AgentActionLog> logs;
  final Map<String, String> addedItems; // original phrase -> itemId/custom
  final Map<String, String> failures; // phrase -> reason

  AgentRunResult({
    this.listId,
    required this.logs,
    required this.addedItems,
    required this.failures,
  });
}

/// Extremely lightweight parser; improves iteratively.
class AgentCommandParser {
  static AgentParsedCommand parse(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();

    // Detect create list intent
    bool createList = lower.contains('create') && lower.contains('list');
    String? listName;

    // Patterns: "list called X", "list named X", "create a new list X"
    final calledIdx = lower.indexOf('list called');
    if (calledIdx != -1) {
      listName = _extractAfter(text, calledIdx + 'list called'.length);
    }
    if (listName == null) {
      final namedIdx = lower.indexOf('list named');
      if (namedIdx != -1) {
        listName = _extractAfter(text, namedIdx + 'list named'.length);
      }
    }
    if (listName == null && createList) {
      // fallback: word after 'create' up to 'list'
      final parts = text.split(RegExp(r'list', caseSensitive: false));
      if (parts.length > 1) {
        // Try to find 'called' or 'named' tokens
        final afterList = parts.last.trim();
        if (afterList.isNotEmpty) {
          // If sentence includes 'add', cut before it
          final addIdx = afterList.toLowerCase().indexOf('add ');
          final candidate = addIdx == -1
              ? afterList
              : afterList.substring(0, addIdx);
          if (candidate.isNotEmpty) {
            listName = candidate.split(RegExp(r'[,.]')).first.trim();
          }
        }
      }
    }
    if (listName != null) {
      // Truncate at common continuation phrases
      listName = listName
          .split(RegExp(r'\band add\b', caseSensitive: false))
          .first;
      listName = listName.split(RegExp(r'\badd\b', caseSensitive: false)).first;
      listName = _sanitizeListName(listName);
    }

    // Extract items after keywords 'add', 'and add'
    List<String> items = [];
    // Look for 'add ' occurrences
    final addRegex = RegExp(r'add ([^.;]+)', caseSensitive: false);
    for (final match in addRegex.allMatches(text)) {
      final segment = match.group(1) ?? '';
      if (segment.isEmpty) continue;
      // Split by ' and ' or commas
      final splits = segment.split(RegExp(r',| and '));
      for (var s in splits) {
        final cleaned = s.trim();
        if (cleaned.isEmpty) continue;
        // Stop words indicating new sentence
        if (cleaned.startsWith('to the') || cleaned.startsWith('into the')) {
          continue;
        }
        items.add(cleaned);
      }
    }
    // Deduplicate preserve order
    final seen = <String>{};
    items = items.where((e) => seen.add(e.toLowerCase())).toList();

    final budget = _extractBudget(lower);
    final dateRange = _extractDateRange(lower);
    final quantities = _extractQuantities(items);

    return AgentParsedCommand(
      listName: listName,
      rawItemPhrases: items,
      createListRequested: createList && listName != null,
      budgetLimit: budget,
      startDate: dateRange?['start'],
      endDate: dateRange?['end'],
      itemQuantities: quantities,
    );
  }

  static String _extractAfter(String original, int start) {
    if (start >= original.length) return '';
    final sub = original.substring(start).trim();
    // Cut at separators
    final cutIdx = sub.indexOf(RegExp(r'[.!]'));
    final candidate = cutIdx == -1 ? sub : sub.substring(0, cutIdx);
    return candidate.trim();
  }

  static String _sanitizeListName(String name) {
    var n = name.trim();
    // Strip leading articles
    n = n.replaceFirst(RegExp(r'^(a|an|the)\s+', caseSensitive: false), '');
    // Remove trailing filler words
    n = n
        .replaceAll(RegExp(r'\b(list|please)\b', caseSensitive: false), '')
        .trim();
    if (n.isEmpty) return 'My List';
    // Capitalize first letter
    return n[0].toUpperCase() + n.substring(1);
  }

  static Map<String, int> _extractQuantities(List<String> items) {
    final map = <String, int>{};
    final numberWords = {
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
    };
    for (final original in items) {
      var phrase = original.trim();
      int? qty;
      // Leading numeric
      final m = RegExp(r'^(\d+)\s+(.+)$').firstMatch(phrase);
      if (m != null) {
        qty = int.tryParse(m.group(1)!);
        phrase = m.group(2)!;
      }
      // Word based quantities
      final lower = phrase.toLowerCase();
      if (qty == null) {
        if (lower.startsWith('a couple of ')) {
          qty = 2;
          phrase = phrase.substring(12);
        } else if (lower.startsWith('couple of ')) {
          qty = 2;
          phrase = phrase.substring(10);
        } else if (lower.startsWith('a few ')) {
          qty = 4;
          phrase = phrase.substring(6);
        } else if (lower.startsWith('few ')) {
          qty = 4;
          phrase = phrase.substring(4);
        } else if (lower.startsWith('a dozen ')) {
          qty = 12;
          phrase = phrase.substring(8);
        } else if (lower.startsWith('half dozen ')) {
          qty = 6;
          phrase = phrase.substring(11);
        } else if (lower.startsWith('several ')) {
          qty = 6;
          phrase = phrase.substring(8);
        } else {
          for (final w in numberWords.keys) {
            if (lower.startsWith('$w ')) {
              qty = numberWords[w];
              phrase = phrase.substring(w.length + 1);
              break;
            }
          }
        }
      }
      if (qty != null && qty > 0) {
        final cleanedPhrase = phrase.trim();
        if (cleanedPhrase.isNotEmpty) {
          map[original] = qty; // keep key as original phrase reference
        }
      }
    }
    return map;
  }

  // Very lightweight budget extraction: looks for the first number near 'budget' or 'limit'
  static double? _extractBudget(String lower) {
    final budgetIdx = lower.indexOf('budget');
    final limitIdx = lower.indexOf('limit');
    int anchor = -1;
    if (budgetIdx != -1) {
      anchor = budgetIdx;
      // ignore: curly_braces_in_flow_control_structures
    } else if (limitIdx != -1)
      // ignore: curly_braces_in_flow_control_structures
      anchor = limitIdx;
    if (anchor == -1) return null;
    final tail = lower.substring(anchor, (anchor + 40).clamp(0, lower.length));
    final match = RegExp(r'(\d+[\.,]?\d*)').firstMatch(tail);
    if (match != null) {
      final raw = match.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    return null;
  }

  // Date range extraction heuristics: supports phrases like 'from 5/9 to 7/9', 'from monday to wednesday', 'from today to tomorrow', 'next week', 'this weekend'
  static Map<String, DateTime>? _extractDateRange(String lower) {
    DateTime now = DateTime.now();
    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

    DateTime? parseToken(String token) {
      token = token.trim();
      if (token.isEmpty) return null;
      if (token == 'today') return normalize(now);
      if (token == 'tomorrow') {
        return normalize(now.add(const Duration(days: 1)));
      }
      if (token == 'yesterday') {
        return normalize(now.subtract(const Duration(days: 1)));
      }
      const weekdays = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      final wIdx = weekdays.indexOf(token);
      if (wIdx != -1) {
        final currentWeekday = now.weekday; // 1=Mon
        int delta = (wIdx + 1) - currentWeekday;
        if (delta < 0) delta += 7; // next upcoming
        return normalize(now.add(Duration(days: delta)));
      }
      // dd/mm or dd-mm
      final dmMatch = RegExp(
        r'^(\d{1,2})[\/-](\d{1,2})(?:[\/-](\d{2,4}))?$',
      ).firstMatch(token);
      if (dmMatch != null) {
        final d = int.parse(dmMatch.group(1)!);
        final m = int.parse(dmMatch.group(2)!);
        final y = dmMatch.group(3) != null
            ? int.parse(dmMatch.group(3)!)
            : now.year;
        return DateTime.tryParse(
          '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
        );
      }
      // Month name patterns
      final monthNames = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'sept': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final monthPattern = RegExp(r'^(\d{1,2})\s+([a-z]+)$');
      final m1 = monthPattern.firstMatch(token);
      if (m1 != null) {
        final day = int.parse(m1.group(1)!);
        final mon = monthNames[m1.group(2)!];
        if (mon != null) {
          return DateTime(now.year, mon, day);
        }
      }
      final pattern2 = RegExp(r'^([a-z]+)\s+(\d{1,2})$');
      final m2 = pattern2.firstMatch(token);
      if (m2 != null) {
        final mon = monthNames[m2.group(1)!];
        final day = int.parse(m2.group(2)!);
        if (mon != null) {
          return DateTime(now.year, mon, day);
        }
      }
      return null;
    }

    // from X to Y
    final rangeMatch = RegExp(
      r'from ([^\n]+?) to ([^\n\.,]+)',
    ).firstMatch(lower);
    if (rangeMatch != null) {
      final startRaw = rangeMatch.group(1)!.trim();
      final endRaw = rangeMatch.group(2)!.trim();
      final s = parseToken(startRaw);
      final e = parseToken(endRaw);
      if (s != null && e != null) {
        return {'start': normalize(s), 'end': normalize(e)};
      }
    }
    // next week => Monday to Sunday next week
    if (lower.contains('next week')) {
      final nextWeekStart = normalize(
        now.add(Duration(days: 8 - now.weekday)),
      ); // next Monday
      final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
      return {'start': nextWeekStart, 'end': nextWeekEnd};
    }
    if (lower.contains('this weekend')) {
      // weekend: Saturday & Sunday of current week
      final sat = normalize(
        now.add(Duration(days: (6 - now.weekday).clamp(0, 6))),
      );
      final sun = sat.add(const Duration(days: 1));
      return {'start': sat, 'end': sun};
    }
    if (lower.contains('next weekend')) {
      final sat = normalize(
        now.add(Duration(days: (6 - now.weekday).clamp(0, 6) + 7)),
      );
      final sun = sat.add(const Duration(days: 1));
      return {'start': sat, 'end': sun};
    }
    return null;
  }
}
