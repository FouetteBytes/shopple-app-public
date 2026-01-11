import 'dart:async';
import 'package:shopple/models/user_presence_status.dart';

abstract class IPresenceService {
  Stream<UserPresenceStatus> getUserPresenceStream(String userId);
  Future<void> setOffline();
  Future<void> initialize();
  Future<void> dispose();
  Future<void> pulse();
  Future<void> updateCustomStatus({String? statusMessage, String? statusEmoji});
  Stream<List<String>> getOnlineFriendsStream();
  Future<void> updateShoppingListActivity({
    required String listId,
    required String activity,
    String? itemId,
    String? details,
  });
}
