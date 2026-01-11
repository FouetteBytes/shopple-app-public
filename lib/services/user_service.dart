import 'dart:async';

import 'package:flutter/foundation.dart';

class UserService {
  static final Map<String, UserInfo> _cache = {};
  static final Map<String, Future<UserInfo>> _inFlight = {};
  static final ValueNotifier<int> revision = ValueNotifier<int>(
    0,
  ); // Bump when new user added.
  static final _avatarUrlLru = <String, String?>{}; // userId -> avatarUrl.
  static const int _maxAvatarEntries = 150;

  static UserInfo? maybeGet(String userId) => _cache[userId];

  static Future<UserInfo> getUserInfo(String userId) {
    if (_cache.containsKey(userId)) return Future.value(_cache[userId]);
    if (_inFlight.containsKey(userId)) return _inFlight[userId]!;
    final fut = _fetch(userId);
    _inFlight[userId] = fut;
    return fut;
  }

  static Future<void> prefetch(List<String> userIds) async {
    final missing = userIds
        .where((id) => !_cache.containsKey(id) && !_inFlight.containsKey(id))
        .toList();
    if (missing.isEmpty) return;
    await Future.wait(missing.map(getUserInfo));
  }

  static Future<UserInfo> _fetch(String userId) async {
    await Future.delayed(const Duration(milliseconds: 60));
    final info = UserInfo(
      id: userId,
      displayName: _generateDisplayName(userId),
      email: userId.contains('@') ? userId : '$userId@example.com',
      avatarUrl: null,
    );
    _cache[userId] = info;
    _inFlight.remove(userId);
    if (info.avatarUrl != null) {
      _avatarUrlLru[userId] = info.avatarUrl;
      if (_avatarUrlLru.length > _maxAvatarEntries) {
        _avatarUrlLru.remove(_avatarUrlLru.keys.first);
      }
    }
    revision.value++; // Notify listeners.
    return info;
  }

  static String _generateDisplayName(String userId) {
    final names = [
      'Alex Chen',
      'Sam Rivera',
      'Jordan Taylor',
      'Casey Morgan',
      'Riley Parker',
    ];
    return names[userId.hashCode.abs() % names.length];
  }

  static void clearCache() => _cache.clear();

  // Seed from disk snapshot without triggering network fetch.
  static void seed(UserInfo info) {
    if (info.id.isEmpty) return;
    if (!_cache.containsKey(info.id)) {
      _cache[info.id] = info;
      revision.value++;
      if (info.avatarUrl != null) {
        _avatarUrlLru[info.id] = info.avatarUrl;
        if (_avatarUrlLru.length > _maxAvatarEntries) {
          _avatarUrlLru.remove(_avatarUrlLru.keys.first);
        }
      }
    }
  }

  static Iterable<UserInfo> allCached() => _cache.values;
  static String? cachedAvatarUrl(String userId) => _avatarUrlLru[userId];
}

class UserInfo {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;

  const UserInfo({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });
}
