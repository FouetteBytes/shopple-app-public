import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/services/performance/firebase_realtime_database_optimizer.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/shopping_lists/collaborative_shopping_list_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'i_presence_service.dart';

class PresenceServiceImpl implements IPresenceService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  FirebaseFirestore get _firestore => _firestoreInstance;

  // For testing
  set firestore(FirebaseFirestore instance) {
    _firestoreInstance = instance;
  }

  late DatabaseReference _database;
  StreamSubscription? _presenceSubscription;
  bool _isInitialized = false;
  Timer? _heartbeatTimer;
  String?
  _lastUid; // track last known uid to mark offline on logout even if currentUser is null
  bool _useRealtimeDatabase =
      true; // allow Firestore-only mode if RTDB is not available
  // Configurable heartbeat intervals
  Duration _hbWhenRtdb = const Duration(minutes: 10);
  Duration _hbWhenFsOnly = const Duration(minutes: 1);
  bool _disableHeartbeatWhenRtdb = false;
  bool _debugPresenceLogs = false;

  /// Configure presence behavior (call early during app init if you want overrides)
  void configure({
    Duration? heartbeatWhenRtdb,
    Duration? heartbeatWhenFsOnly,
    bool? disableHeartbeatWhenRtdb,
    bool? debugLogging,
  }) {
    if (heartbeatWhenRtdb != null) _hbWhenRtdb = heartbeatWhenRtdb;
    if (heartbeatWhenFsOnly != null) _hbWhenFsOnly = heartbeatWhenFsOnly;
    if (disableHeartbeatWhenRtdb != null) {
      _disableHeartbeatWhenRtdb = disableHeartbeatWhenRtdb;
    }
    if (debugLogging != null) _debugPresenceLogs = debugLogging;
  }

  /// Initialize presence system - call this after user authentication
  /// CRITICAL: This must be called AFTER user signs in successfully
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.d('🔄 Initializing presence service...');

      // Step 1: Initialize RTDB connection (falls back to default if optimizer unavailable)
      try {
        if (FirebaseRealtimeDatabaseOptimizer.isInitialized) {
          _database = FirebaseRealtimeDatabaseOptimizer.getOptimizedReference();
        } else {
          // Fallback to default connection if optimizer not ready
          _database = FirebaseDatabase.instance.ref();
        }
        // Ensure we are online in case a previous logout took RTDB offline
        try {
          await FirebaseDatabase.instance.goOnline();
        } catch (_) {}
        _useRealtimeDatabase = true;
      } catch (e) {
        // RTDB likely not configured/enabled; run in Firestore-only mode
        _useRealtimeDatabase = false;
        AppLogger.w(
          'Realtime Database unavailable, running Firestore-only presence. Reason: $e',
        );
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      _lastUid = user.uid;

      // Step 2: Set up the presence detection system
      await _setupPresenceListeners(user.uid);
      _isInitialized = true;

      AppLogger.d('✅ Presence service initialized for user: ${user.uid}');
      final hbMode = _useRealtimeDatabase
          ? (_disableHeartbeatWhenRtdb ? 'disabled' : _hbWhenRtdb.toString())
          : _hbWhenFsOnly.toString();
      AppLogger.d(
        'ℹ️ Presence mode=${_useRealtimeDatabase ? 'RTDB' : 'Firestore-only'}, heartbeat=$hbMode, debug=${_debugPresenceLogs ? 'on' : 'off'}',
      );
    } catch (e) {
      AppLogger.e('Failed to initialize presence service: $e');
      rethrow;
    }
  }

  /// Setup presence listeners following Firebase documentation EXACTLY
  /// This implements the pattern from: https://firebase.google.com/docs/firestore/solutions/presence
  Future<void> _setupPresenceListeners(String uid) async {
    AppLogger.d('🔧 Setting up presence listeners for user: $uid');

    // STEP 1: Create references to both databases
    // Following documentation: "Create a reference to this user's specific status node"
    final userStatusDatabaseRef = _useRealtimeDatabase
        ? _database.child('status').child(uid)
        : null;
    final userStatusFirestoreRef = _firestore.collection('status').doc(uid);
    final userDocRef = _firestore.collection('users').doc(uid);

    // STEP 2: Define status objects (RTDB vs Firestore timestamp formats)

    // Realtime Database format
    final isOfflineForDatabase = {
      'state': 'offline',
      'last_changed': ServerValue.timestamp, // Realtime DB timestamp
    };

    final isOnlineForDatabase = {
      'state': 'online',
      'last_changed': ServerValue.timestamp, // Realtime DB timestamp
    };

    // For Firestore (using FieldValue.serverTimestamp())
    final isOnlineForFirestore = {
      'state': 'online',
      'last_changed': FieldValue.serverTimestamp(), // Firestore timestamp
    };

    // STEP 3: Listen to .info/connected for connection state
    AppLogger.d('👂 Starting to listen to .info/connected...');

    if (_useRealtimeDatabase) {
      _presenceSubscription = _database
          .child(
            '.info/connected',
          ) // Special Firebase path for connection status
          .onValue
          .listen((event) async {
            // Get connection status from the event
            final connected = event.snapshot.value as bool? ?? false;

            AppLogger.d(
              '🔄 Connection status changed: ${connected ? "CONNECTED" : "DISCONNECTED"}',
            );

            // STEP 4A: Handle disconnection
            if (!connected) {
            // Server-side onDisconnect handles offline state; skip local write to prevent UI flicker
              return;
            }

            // STEP 4B: Handle connection - This is the critical sequence
            AppLogger.d(
              '🌐 Connected! Setting up disconnect handler and going online...',
            );

            try {
              // FIRST: Set up the disconnect handler (this runs server-side when connection drops)
              await userStatusDatabaseRef!.onDisconnect().set(
                isOfflineForDatabase,
              );
              AppLogger.d('✅ Disconnect handler set in Realtime Database');

              // SECOND: Set online status in Realtime Database
              await userStatusDatabaseRef.set(isOnlineForDatabase);
              AppLogger.d('✅ Online status set in Realtime Database');

              // THIRD: Set online status in Firestore (single doc to minimize writes)
              await userStatusFirestoreRef.set(
                isOnlineForFirestore,
                SetOptions(merge: true),
              );
              await userDocRef.set({
                'presence': {
                  'state': 'online',
                  'last_changed': FieldValue.serverTimestamp(),
                },
              }, SetOptions(merge: true));
              AppLogger.d('✅ Online status set in Firestore');
            } catch (e) {
              AppLogger.e('Error in presence setup: $e');
            }
          });
    } else {
      // Firestore-only: write online immediately on init
      try {
        await userStatusFirestoreRef.set(
          isOnlineForFirestore,
          SetOptions(merge: true),
        );
        await userDocRef.set({
          'presence': {
            'state': 'online',
            'last_changed': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
        AppLogger.d('✅ Firestore-only presence set online');
      } catch (e) {
        AppLogger.e('Firestore-only presence error: $e');
      }
    }

    AppLogger.d('✅ Presence listeners setup complete');

    // Heartbeat frequency: longer with RTDB (instant presence), shorter for Firestore-only
    final heartbeatInterval = _useRealtimeDatabase
        ? _hbWhenRtdb
        : _hbWhenFsOnly;
    if (_useRealtimeDatabase && _disableHeartbeatWhenRtdb) {
      // RTDB provides instant presence, skip Firestore heartbeat
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      return;
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      try {
        await _firestore.collection('status').doc(uid).set({
          'state': 'online',
          'last_changed': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Skip users/{uid}.presence on heartbeat (updated on connect/disconnect)
      } catch (e) {
        AppLogger.w('Presence heartbeat failed: $e');
      }
    });
  }

  /// Get online friends stream - integrates with friend system
  @override
  Stream<List<String>> getOnlineFriendsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('status')
        .where('state', isEqualTo: 'online')
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            // Get current user's friends
            final friendsSnapshot = await _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('friends')
                .get();

            final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();

            // Filter online users to only include friends
            final onlineUsers = snapshot.docs
                .map((doc) => doc.id)
                .where((userId) => friendIds.contains(userId))
                .toList();

            AppLogger.d('👥 Online friends: ${onlineUsers.length}');
            return onlineUsers;
          } catch (e) {
            AppLogger.e('Error getting online friends: $e');
            return <String>[];
          }
        });
  }

  /// Get specific user's online status
  @override
  Stream<UserPresenceStatus> getUserPresenceStream(String userId) {
    // If initialize() hasn't run yet, fall back to Firestore-only stream to avoid touching RTDB.
    if (!_isInitialized) {
      return _firestore.collection('status').doc(userId).snapshots().map((
        snapshot,
      ) {
        if (!snapshot.exists) return UserPresenceStatus.offline();
        final data = snapshot.data()!;
        final state = data['state'] as String? ?? 'offline';
        final lastChanged = data['last_changed'] as Timestamp?;
        return UserPresenceStatus(
          isOnline: state == 'online',
          lastSeen: lastChanged?.toDate(),
          customStatus: data['customStatus'] as String?,
          statusEmoji: data['statusEmoji'] as String?,
        );
      });
    }
    // Merge a fast realtime signal (RTDB) with Firestore document for lastSeen and cross-device consistency.
    final firestorePresence$ = _firestore
        .collection('status')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return UserPresenceStatus.offline();
          final data = snapshot.data()!;
          final state = data['state'] as String? ?? 'offline';
          final lastChanged = data['last_changed'] as Timestamp?;
          // If Firestore explicitly says 'offline', do not infer online from recency here.
          return UserPresenceStatus(
            isOnline: state == 'online',
            lastSeen: lastChanged?.toDate(),
            customStatus: data['customStatus'] as String?,
            statusEmoji: data['statusEmoji'] as String?,
          );
        });

    // Realtime DB node: /status/{uid}/state -> online|offline. This flips instantly when connection changes
    // Use it as an override for isOnline to make the UI dot responsive.
    // Guard it behind auth state and swallow permission errors after sign-out.
    final Stream<UserPresenceStatus>? rtdbPresence$ = _useRealtimeDatabase
        ? (() {
            // Build a stream that attaches to RTDB only when user is authenticated
            final controller = StreamController<UserPresenceStatus>();
            StreamSubscription<User?>? authSub;
            StreamSubscription<DatabaseEvent>? dbSub;

            void attachDbListener(User? user) {
              // Cancel existing listener first
              dbSub?.cancel();
              dbSub = null;
              if (user == null) {
                return; // do not listen to RTDB when signed out
              }
              dbSub = _database
                  .child('status')
                  .child(userId)
                  .onValue
                  // Handle errors such as permission-denied gracefully to avoid crashing
                  .handleError((error) {
                    if (_debugPresenceLogs) {
                      AppLogger.w('Presence RTDB error for $userId: $error');
                    }
                  })
                  .listen((event) {
                    final map = (event.snapshot.value as Map?) ?? const {};
                    final state = map['state'] as String?;
                    final serverMs = map['last_changed'] as num?;
                    controller.add(
                      UserPresenceStatus(
                        isOnline: state == 'online',
                        lastSeen: serverMs != null
                            ? DateTime.fromMillisecondsSinceEpoch(
                                serverMs.toInt(),
                              )
                            : null,
                      ),
                    );
                  });
            }

            // Start listening to auth changes
            authSub = _auth.authStateChanges().listen(attachDbListener);
            // Also seed with current auth state immediately
            attachDbListener(_auth.currentUser);

            controller.onCancel = () async {
              await dbSub?.cancel();
              await authSub?.cancel();
            };

            return controller.stream;
          })()
        : null;

    // Firestore users doc synced via Cloud Function; RTDB is source of truth

    // CombineLatest manually (without RxDart) by using a StreamController that listens to both
    final controller = StreamController<UserPresenceStatus>();
    UserPresenceStatus? latestFs;
    UserPresenceStatus? latestDb;

    void emit() {
      // Prefer RTDB online flag when true for snappy green dot; fallback to Firestore otherwise
      final online =
          (latestDb?.isOnline == true) || (latestFs?.isOnline == true);
      // Choose the most recent lastSeen among sources
      final candidates = [
        latestDb?.lastSeen,
        latestFs?.lastSeen,
      ].whereType<DateTime>().toList();
      candidates.sort((a, b) => b.compareTo(a));
      final lastSeen = candidates.isNotEmpty ? candidates.first : null;
      final merged = UserPresenceStatus(
        isOnline: online,
        lastSeen: lastSeen,
        customStatus: latestFs?.customStatus,
        statusEmoji: latestFs?.statusEmoji,
      );
      if (_debugPresenceLogs) {
        AppLogger.d(
          '🧩 Presence[MERGE:$userId] online=${merged.isOnline} last=${merged.lastSeen?.toIso8601String() ?? 'null'}',
        );
      }
      controller.add(merged);
    }

    // Subscriptions
    late final StreamSubscription subFs;
    StreamSubscription? subDb;
    // Users doc presence synced via Cloud Function
    subFs = firestorePresence$.listen((v) {
      latestFs = v;
      if (_debugPresenceLogs) {
        AppLogger.d(
          '📡 Presence[Firestore:$userId] online=${v.isOnline} last=${v.lastSeen?.toIso8601String() ?? 'null'}',
        );
      }
      emit();
    });
    if (rtdbPresence$ != null) {
      subDb = rtdbPresence$.listen((v) {
        latestDb = v;
        if (_debugPresenceLogs) {
          AppLogger.d(
            '⚡ Presence[RTDB:$userId] online=${v.isOnline} last=${v.lastSeen?.toIso8601String() ?? 'null'}',
          );
        }
        emit();
      });
    }
    // Skip usersPresence$ to avoid duplicate merge operations

    controller.onCancel = () async {
      await subFs.cancel();
      await subDb?.cancel();
      // No subUser to cancel
    };

    // Seed an immediate optimistic state for the current user to avoid UI lag
    final selfId = _auth.currentUser?.uid;
    if (selfId != null && selfId == userId) {
      scheduleMicrotask(() {
        controller.add(
          UserPresenceStatus(isOnline: true, lastSeen: DateTime.now()),
        );
      });
    }

    return controller.stream;
  }

  /// Update user's custom status (optional feature)
  @override
  Future<void> updateCustomStatus({
    String? statusMessage,
    String? statusEmoji,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('status').doc(user.uid).update({
        'customStatus': statusMessage,
        'statusEmoji': statusEmoji,
        'last_changed': FieldValue.serverTimestamp(),
      });

      AppLogger.d('✅ Custom status updated');
    } catch (e) {
      AppLogger.e('Failed to update custom status: $e');
    }
  }

  /// Cleanup presence listeners
  @override
  Future<void> dispose() async {
    AppLogger.d('🧹 Cleaning up presence service...');

    await _presenceSubscription?.cancel();
    _presenceSubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    // Drop RTDB connection to ensure all underlying listeners detach when user signs out
    try {
      if (_useRealtimeDatabase) {
        await FirebaseDatabase.instance.goOffline();
      }
    } catch (e) {
      if (_debugPresenceLogs) {
        AppLogger.w('Error taking RTDB offline: $e');
      }
    }
    _isInitialized = false;

    AppLogger.d('✅ Presence service cleaned up');
  }

  /// Force set user offline (for logout)
  @override
  Future<void> setOffline() async {
    // Use current user if available, otherwise the last known uid captured during initialize
    final uid = _auth.currentUser?.uid ?? _lastUid;
    if (uid == null) {
      AppLogger.w('setOffline called but no uid available');
      return;
    }

    try {
      // Firestore: status/{uid}
      final userStatusFirestoreRef = _firestore.collection('status').doc(uid);
      await userStatusFirestoreRef.set({
        'state': 'offline',
        'last_changed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Firestore: users/{uid}.presence
      await _firestore.collection('users').doc(uid).set({
        'presence': {
          'state': 'offline',
          'last_changed': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // RTDB: /status/{uid}
      if (_useRealtimeDatabase) {
        final db = _isInitialized ? _database : FirebaseDatabase.instance.ref();
        await db.child('status').child(uid).set({
          'state': 'offline',
          'last_changed': ServerValue.timestamp,
        });
      }

      AppLogger.d('✅ User manually set offline for uid=$uid');
    } catch (e) {
      AppLogger.e('Error setting user offline: $e');
    }
  }

  /// Manual pulse to update Firestore last_seen without waiting for heartbeat
  @override
  Future<void> pulse() async {
    final uid = _auth.currentUser?.uid ?? _lastUid;
    if (uid == null) return;
    try {
      await _firestore.collection('status').doc(uid).set({
        'state': 'online',
        'last_changed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.w('Presence pulse failed: $e');
    }
  }

  // Lightweight wrapper to align with collaboration guide terminology
  // Delegates to the collaborative list presence updates under list-scoped presence
  @override
  Future<void> updateShoppingListActivity({
    required String listId,
    required String activity,
    String? itemId,
    String? details,
  }) async {
    await CollaborativeShoppingListService.updatePresence(
      listId: listId,
      activity: activity,
      itemId: itemId,
      details: details,
    );
  }
}
