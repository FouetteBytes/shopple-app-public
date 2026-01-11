import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore-backed recent search history per user.
/// Path: users/{uid}/searchHistory/{autoId} { q:String(lowercase), ts:int(epoch ms) }
class CloudRecentSearchService {
  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const int _maxItems = 50;

  static String? _uid() => _auth.currentUser?.uid;
  static CollectionReference<Map<String, dynamic>>? _col() {
    final uid = _uid();
    if (uid == null) return null;
    return _fs.collection('users').doc(uid).collection('searchHistory');
  }

  static Future<void> saveQuery(String query) async {
    final col = _col();
    if (col == null) return;
    final q = query.trim().toLowerCase();
    if (q.length < 2) return;
    try {
      final existing = await col.where('q', isEqualTo: q).limit(1).get();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({'ts': now});
      } else {
        await col.add({'q': q, 'ts': now});
      }
      _trim(col);
    } catch (_) {
      /* non-fatal */
    }
  }

  static Future<List<String>> getAll({int limit = 50}) async {
    final col = _col();
    if (col == null) return const [];
    try {
      final snap = await col.orderBy('ts', descending: true).limit(limit).get();
      return snap.docs
          .map((d) => (d.data()['q'] as String?) ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clearAll() async {
    final col = _col();
    if (col == null) return;
    try {
      final snap = await col.get();
      for (final doc in snap.docs) {
        // ignore: unawaited_futures
        doc.reference.delete();
      }
    } catch (_) {
      /* non-fatal */
    }
  }

  static Future<void> _trim(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    try {
      final snap = await col.orderBy('ts', descending: true).get();
      if (snap.docs.length <= _maxItems) return;
      for (int i = _maxItems; i < snap.docs.length; i++) {
        // ignore: unawaited_futures
        snap.docs[i].reference.delete();
      }
    } catch (_) {
      /* non-fatal */
    }
  }
}
