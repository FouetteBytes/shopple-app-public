import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserTagService {
  static const _ns = 'ai.user_tags';
  static String _keyFor(String uid) => '$_ns.$uid';

  static Future<List<String>> load([String? uid]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyFor(uid));
    return raw?.toList() ?? [];
  }

  static Future<void> save(List<String> tags, [String? uid]) async {
    uid ??= FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Normalize & dedupe
    final norm = <String>{};
    for (final t in tags) {
      final s = t.trim();
      if (s.isNotEmpty) norm.add(s);
    }
    await prefs.setStringList(_keyFor(uid), norm.toList());
  }

  static Future<void> add(String tag, [String? uid]) async {
    final tags = await load(uid);
    final t = tag.trim();
    if (t.isEmpty) return;
    if (!tags.contains(t)) {
      tags.add(t);
      await save(tags, uid);
    }
  }

  static Future<void> remove(String tag, [String? uid]) async {
    final tags = await load(uid);
    tags.removeWhere((e) => e.trim().toLowerCase() == tag.trim().toLowerCase());
    await save(tags, uid);
  }
}
