import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'i_presence_service.dart';
import 'presence_service_impl.dart';

class PresenceService {
  static IPresenceService? _instance;

  static set instance(IPresenceService service) {
    _instance = service;
  }

  static IPresenceService get instance {
    _instance ??= PresenceServiceImpl();
    return _instance!;
  }

  // For testing
  static set firestore(FirebaseFirestore instance) {
    if (_instance is PresenceServiceImpl) {
      (_instance as PresenceServiceImpl).firestore = instance;
    }
  }

  static void configure({
    Duration? heartbeatWhenRtdb,
    Duration? heartbeatWhenFsOnly,
    bool? disableHeartbeatWhenRtdb,
    bool? debugLogging,
  }) {
    if (_instance is PresenceServiceImpl) {
      (_instance as PresenceServiceImpl).configure(
        heartbeatWhenRtdb: heartbeatWhenRtdb,
        heartbeatWhenFsOnly: heartbeatWhenFsOnly,
        disableHeartbeatWhenRtdb: disableHeartbeatWhenRtdb,
        debugLogging: debugLogging,
      );
    }
  }

  static Future<void> initialize() => instance.initialize();

  static Stream<List<String>> getOnlineFriendsStream() =>
      instance.getOnlineFriendsStream();

  static Stream<UserPresenceStatus> getUserPresenceStream(String userId) =>
      instance.getUserPresenceStream(userId);

  static Future<void> updateCustomStatus({
    String? statusMessage,
    String? statusEmoji,
  }) => instance.updateCustomStatus(
    statusMessage: statusMessage,
    statusEmoji: statusEmoji,
  );

  static Future<void> dispose() => instance.dispose();

  static Future<void> setOffline() => instance.setOffline();

  static Future<void> pulse() => instance.pulse();

  static Future<void> updateShoppingListActivity({
    required String listId,
    required String activity,
    String? itemId,
    String? details,
  }) => instance.updateShoppingListActivity(
    listId: listId,
    activity: activity,
    itemId: itemId,
    details: details,
  );
}
