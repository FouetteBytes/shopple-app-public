import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// UserProfileStreamService
///
/// Centralized service that manages Firestore listeners to user documents and
/// exposes cached broadcast streams per userId. This ensures multiple widgets
/// (e.g., many UnifiedProfileAvatar instances) share a single listener and
/// receive updates efficiently, reducing redundant network and rebuild work.
class UserProfileStreamService {
  UserProfileStreamService._();
  static final UserProfileStreamService instance = UserProfileStreamService._();

  FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  @visibleForTesting
  set firestore(FirebaseFirestore fs) => _injectedFirestore = fs;

  final Map<String, StreamController<Map<String, dynamic>?>> _controllers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Map<String, dynamic>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache validity window for quick-look data before the stream emits
  final Duration cacheTimeout = const Duration(minutes: 5);

  /// Subscribe to updates for a given userId. Returns a broadcast stream that
  /// emits `Map<String, dynamic>` of user data (null if document missing).
  /// Maintains single Firestore subscription per userId.
  Stream<Map<String, dynamic>?> watchUser(String userId) {
    // Reuse an existing controller if present
    final existing = _controllers[userId];
    if (existing != null) {
      return existing.stream;
    }

    // Create a new broadcast controller to multiplex listeners
    final controller = StreamController<Map<String, dynamic>?>.broadcast();
    // Assign callbacks after creation to avoid reference-before-declare issues
    controller.onListen = () {
      // When first listener attaches and no subscription exists, start one
      _ensureSubscription(userId);
      // Push cached value immediately (even if time-expired) to avoid blanks
      final cached = _cache[userId];
      if (cached != null) {
        controller.add(Map<String, dynamic>.from(cached));
      }
    };
    controller.onCancel = () async {
      // If no more listeners, tear down to save resources
      if (!controller.hasListener) {
        await _disposeUser(userId);
      }
    };

    _controllers[userId] = controller;
    // Also ensure subscription in case listeners are added later
    _ensureSubscription(userId);

    return controller.stream;
  }

  /// Get a shallow copy of the cached user data, if any and valid.
  Map<String, dynamic>? getCached(String userId) {
    final data = _cache[userId];
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Force set/refresh the cache for a user. Typically internal use.
  void _setCache(String userId, Map<String, dynamic> data) {
    _cache[userId] = Map<String, dynamic>.from(data);
    _cacheTimestamps[userId] = DateTime.now();
  }

  // Cache timestamps retained for diagnostics; UI renders last-known values

  void _ensureSubscription(String userId) {
    if (_subscriptions.containsKey(userId)) return;

    final sub = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            final controller = _controllers[userId];
            if (controller == null || controller.isClosed) return;

            if (!snapshot.exists) {
              controller.add(null);
              return;
            }

            try {
              final data = snapshot.data() as Map<String, dynamic>;
              _setCache(userId, data);
              controller.add(data);
            } catch (_) {
              // If parsing fails, emit last-known cache to avoid UI blanks
              final cached = _cache[userId];
              controller.add(
                cached != null ? Map<String, dynamic>.from(cached) : null,
              );
            }
          },
          onError: (error, stackTrace) {
            final controller = _controllers[userId];
            if (controller == null || controller.isClosed) return;
            // Emit last-known value on error to avoid flicker/blanks
            final cached = _cache[userId];
            controller.add(
              cached != null ? Map<String, dynamic>.from(cached) : null,
            );
          },
        );

    _subscriptions[userId] = sub;
  }

  /// Prefetch a set of users (warms cache and streams)
  Future<void> prefetchUsers(Iterable<String> userIds) async {
    for (final uid in userIds) {
      // Start subscription and attempt to fetch once to populate cache
      _ensureSubscription(uid);
      try {
        final snap = await _firestore.collection('users').doc(uid).get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          _setCache(uid, data);
          _controllers[uid]?.add(data);
        }
      } catch (_) {
        // ignore
      }
    }
  }

  /// Clear cache for a user and close its stream/subscription (if no listeners)
  Future<void> clearUser(String userId) async {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
    await _disposeUser(userId);
  }

  /// Clear all cache and dispose all subscriptions/controllers
  Future<void> clearAll() async {
    _cache.clear();
    _cacheTimestamps.clear();
    final keys = _controllers.keys.toList();
    for (final k in keys) {
      await _disposeUser(k, force: true);
    }
  }

  Future<void> _disposeUser(String userId, {bool force = false}) async {
    // Only dispose if there are no listeners or forced
    final controller = _controllers[userId];
    if (controller != null && (force || !controller.hasListener)) {
      await _subscriptions[userId]?.cancel();
      _subscriptions.remove(userId);
      await controller.close();
      _controllers.remove(userId);
    }
  }
}
