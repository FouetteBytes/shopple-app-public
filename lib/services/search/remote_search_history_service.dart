import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemoteSearchHistoryService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-south1',
  );

  static Future<void> save(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // only for signed-in users
    if (query.trim().isEmpty) return;
    try {
      final callable = _functions.httpsCallable('saveRecentSearchV2');
      await callable.call({
        'q': query,
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // non-fatal
    }
  }

  static Future<List<String>> getRecent({int limit = 12}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final callable = _functions.httpsCallable('getRecentSearchesV2');
      final res = await callable.call({'limit': limit});
      final data = (res.data as Map)['items'] as List? ?? [];
      return data.map((e) => (e as String)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> clearRemote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final callable = _functions.httpsCallable('clearRecentSearchesV2');
      final res = await callable.call({});
      return (res.data as Map)['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
