import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchService {
  static const String _legacyPrefsKey = 'recent_searches_v1';
  static const int _maxItems = 25;

  static String _uid() => FirebaseAuth.instance.currentUser?.uid ?? 'anon';
  static String _prefsKeyForUser() => '${_uid()}:recent_searches_v1';

  static Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    // Migrate legacy key to user-scoped key (anon only) to prevent cross-account leakage
    final userKey = _prefsKeyForUser();
    if (!prefs.containsKey(userKey) && prefs.containsKey(_legacyPrefsKey)) {
      try {
        final uid = _uid();
        final legacy = prefs.getString(_legacyPrefsKey);
        if ((uid == 'anon') && legacy != null) {
          await prefs.setString(userKey, legacy);
        }
        // Remove legacy key to prevent re-import
        await prefs.remove(_legacyPrefsKey);
      } catch (_) {
        /* non-fatal */
      }
    }
  }

  // Save a query locally if it passes quality checks
  static Future<void> saveQuery(String query) async {
    final q = _normalize(query);
    if (!_isHighQuality(q)) return;
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = await _loadRaw(prefs);

    // De-duplicate by query
    list.removeWhere((e) => (e['q'] as String).toLowerCase() == q);
    list.insert(0, {'q': q, 'ts': now});
    while (list.length > _maxItems) {
      list.removeLast();
    }
    // Fire-and-forget to avoid blocking UI on fsync; acceptable risk for history
    // ignore: unawaited_futures
    prefs.setString(_prefsKeyForUser(), jsonEncode(list));
  }

  static Future<List<String>> getRecent({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded(prefs);
    final list = await _loadRaw(prefs);
    list.sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));
    return list.map((e) => e['q'] as String).take(limit).toList();
  }

  // Merge local recents with cloud top queries and return curated list
  static Future<List<String>> getCuratedRecent(
    List<String> cloudTop, {
    int limit = 8,
  }) async {
    final local = await getRecent(limit: _maxItems);
    final seen = <String>{};
    final result = <String>[];

    void addAll(Iterable<String> items) {
      for (final it in items) {
        final q = _normalize(it);
        if (_isHighQuality(q) && !seen.contains(q)) {
          seen.add(q);
          result.add(q);
          if (result.length >= limit) return;
        }
      }
    }

    addAll(local);
    if (result.length < limit) addAll(cloudTop);
    return result.take(limit).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyForUser());
    // Also remove legacy global if still present
    await prefs.remove(_legacyPrefsKey);
  }

  static String _normalize(String q) =>
      q.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool _isHighQuality(String q) {
    if (q.isEmpty) return false;
    if (q.length < 2) return false; // avoid single letters
    // Disallow queries with too many non-word chars
    final alnum = RegExp(r'[a-z0-9]');
    final alnumCount = q.split('').where((c) => alnum.hasMatch(c)).length;
    if (alnumCount / q.length < 0.6) return false;
    // Avoid repeated single-char spam like 'aaa' or '1111'
    if (RegExp(r'^(.)\1{2,}$').hasMatch(q)) return false;
    return true;
  }

  // Clear all local search history
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyForUser());
    await prefs.remove(_legacyPrefsKey);
  }

  static Future<List<Map<String, dynamic>>> _loadRaw(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_prefsKeyForUser());
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
