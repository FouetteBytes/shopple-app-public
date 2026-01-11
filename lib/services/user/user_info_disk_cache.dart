import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_service.dart';

/// Persists a tiny subset of UserInfo for fast cold start avatar rendering.
class UserInfoDiskCache {
  UserInfoDiskCache._();
  static final UserInfoDiskCache instance = UserInfoDiskCache._();
  static const _key = 'user_info_cache_v1';
  bool _hydrated = false;

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (final m in list) {
        final map = m as Map<String, dynamic>;
        final info = UserInfo(
          id: map['id'] ?? '',
          displayName: map['displayName'] ?? '',
          email: map['email'] ?? '',
          avatarUrl: map['avatarUrl'],
        );
        UserService.seed(info);
      }
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> persistSnapshot(Iterable<UserInfo> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = users
          .map(
            (u) => {
              'id': u.id,
              'displayName': u.displayName,
              'email': u.email,
              'avatarUrl': u.avatarUrl,
            },
          )
          .toList();
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {}
  }
}
