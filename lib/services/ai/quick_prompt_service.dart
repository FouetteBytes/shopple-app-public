import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:shopple/models/ai_agent/quick_prompt.dart';

class QuickPromptService {
  static const _ns = 'ai.quick_prompts';
  static String _keyFor(String uid) => '$_ns.$uid';

  // Enhanced caching for faster access
  static final Map<String, List<QuickPrompt>> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  /// Pre-warm cache for current user to enable instant access
  static Future<void> warmCacheForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await loadForUser(uid);
    }
  }

  /// Check if cache is still valid for user
  static bool _isCacheValid(String uid) {
    final timestamp = _cacheTimestamps[uid];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  static Future<List<QuickPrompt>> loadForUser([String? uid]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    // Return from memory cache if valid
    if (_memoryCache.containsKey(uid) && _isCacheValid(uid)) {
      return List.from(_memoryCache[uid]!);
    }

    // Load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(uid));
    final List<QuickPrompt> prompts;

    if (raw == null || raw.isEmpty) {
      prompts = [];
    } else {
      prompts = QuickPrompt.decodeList(raw);
    }

    // Update memory cache
    _memoryCache[uid] = List.from(prompts);
    _cacheTimestamps[uid] = DateTime.now();

    return prompts;
  }

  /// Load with optimistic caching - returns cached data immediately if available,
  /// then updates in background
  static Future<List<QuickPrompt>> loadForUserOptimistic([String? uid]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    // If we have cached data, return it immediately
    if (_memoryCache.containsKey(uid)) {
      // Return cached data immediately
      final cachedData = List<QuickPrompt>.from(_memoryCache[uid]!);

      // Refresh in background if cache is old
      if (!_isCacheValid(uid)) {
        _refreshCacheInBackground(uid);
      }

      return cachedData;
    }

    // No cache available, load normally
    return _loadForUserFromStorage(uid);
  }

  static void _refreshCacheInBackground(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(uid));

      if (raw != null && raw.isNotEmpty) {
        final prompts = QuickPrompt.decodeList(raw);
        _memoryCache[uid] = List.from(prompts);
        _cacheTimestamps[uid] = DateTime.now();
      }
    } catch (e) {
      // Silent background refresh failure
    }
  }

  /// Check if memory cache has data for user (synchronous, instant)
  static bool hasMemoryCache([String? uid]) {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return _memoryCache.containsKey(uid) && _memoryCache[uid]!.isNotEmpty;
  }

  /// Peek at memory cache data instantly (synchronous, no await)
  /// Returns empty list if no cache available
  static List<QuickPrompt> peekMemory([String? uid]) {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    if (_memoryCache.containsKey(uid)) {
      return List<QuickPrompt>.from(_memoryCache[uid]!);
    }
    return [];
  }

  static Future<List<QuickPrompt>> _loadForUserFromStorage([
    String? uid,
  ]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(uid));
    if (raw == null || raw.isEmpty) return [];
    return QuickPrompt.decodeList(raw);
  }

  static Future<void> saveForUser(List<QuickPrompt> list, [String? uid]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Update memory cache first for immediate UI updates
    _memoryCache[uid] = List.from(list);
    _cacheTimestamps[uid] = DateTime.now();

    // Then persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(uid), QuickPrompt.encodeList(list));
  }

  static Future<QuickPrompt> create(
    String title,
    String prompt, {
    List<String>? tags,
    String? color,
    String? uid,
  }) async {
    final id = const Uuid().v4();
    final qp = QuickPrompt(
      id: id,
      title: title,
      prompt: prompt,
      tags: tags ?? [],
      color: color,
    );
    final list = await loadForUser(uid);
    list.add(qp);
    await saveForUser(list, uid);
    return qp;
  }

  static Future<void> update(QuickPrompt qp, {String? uid}) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Update memory cache immediately
    if (_memoryCache.containsKey(uid)) {
      final cached = _memoryCache[uid]!;
      final idx = cached.indexWhere((e) => e.id == qp.id);
      if (idx >= 0) {
        cached[idx] = qp;
        _cacheTimestamps[uid] = DateTime.now();
      }
    }

    // Update storage
    final list = await loadForUser(uid);
    final idx = list.indexWhere((e) => e.id == qp.id);
    if (idx >= 0) {
      list[idx] = qp;
      await saveForUser(list, uid);
    }
  }

  static Future<void> remove(String id, {String? uid}) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Update memory cache immediately
    if (_memoryCache.containsKey(uid)) {
      _memoryCache[uid]!.removeWhere((e) => e.id == id);
      _cacheTimestamps[uid] = DateTime.now();
    }

    // Update storage
    final list = await loadForUser(uid);
    list.removeWhere((e) => e.id == id);
    await saveForUser(list, uid);
  }

  /// Clear memory cache for user (useful when user logs out)
  static void clearCacheForUser([String? uid]) {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _memoryCache.remove(uid);
      _cacheTimestamps.remove(uid);
    }
  }

  /// Clear all cached data
  static void clearAllCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }
}
