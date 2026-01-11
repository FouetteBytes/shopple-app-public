import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore sync for recently viewed products (ordered ids + minimal snapshots).
class CloudRecentlyViewedService {
  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const int _maxItems = 30;

  static String? _uid() => _auth.currentUser?.uid;
  static DocumentReference<Map<String, dynamic>>? _metaDoc() {
    final uid = _uid();
    if (uid == null) return null;
    return _fs
        .collection('users')
        .doc(uid)
        .collection('recentlyViewed')
        .doc('metadata');
  }

  static CollectionReference<Map<String, dynamic>>? _snapshotsCol() {
    final uid = _uid();
    if (uid == null) return null;
    return _fs
        .collection('users')
        .doc(uid)
        .collection('recentlyViewedSnapshots');
  }

  static Future<void> pushIds(List<String> ids) async {
    final doc = _metaDoc();
    if (doc == null) return;
    try {
      await doc.set({
        'ids': ids.take(_maxItems).toList(),
        'updated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  static Future<List<String>> fetchIds() async {
    final doc = _metaDoc();
    if (doc == null) return const [];
    try {
      final snap = await doc.get();
      if (!snap.exists) return const [];
      final data = snap.data();
      final list =
          (data?['ids'] as List?)?.map((e) => e.toString()).toList() ??
          <String>[];
      return list.take(_maxItems).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveSnapshot(
    String productId,
    Map<String, dynamic> snapshot,
  ) async {
    final col = _snapshotsCol();
    if (col == null) return;
    try {
      await col.doc(productId).set(snapshot, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<Map<String, Map<String, dynamic>>> fetchSnapshots(
    List<String> ids,
  ) async {
    final col = _snapshotsCol();
    if (col == null || ids.isEmpty) return {};
    final result = <String, Map<String, dynamic>>{};
    try {
      final snaps = await Future.wait(ids.map((id) => col.doc(id).get()));
      for (final s in snaps) {
        if (s.exists) result[s.id] = s.data() ?? {};
      }
    } catch (_) {}
    return result;
  }

  static Future<void> clearAll() async {
    final doc = _metaDoc();
    final col = _snapshotsCol();
    if (doc == null || col == null) return;
    try {
      await doc.delete();
      final batch = _fs.batch();
      final snaps = await col.get();
      for (final d in snaps.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (_) {}
  }
}
