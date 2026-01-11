import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/models/product_model.dart';

class SavedListsService {
  static final _fs = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? _uid() => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> _quickListRef() {
    final uid = _uid();
    if (uid == null) {
      throw StateError('User not logged in');
    }
    return _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc('quick_saved');
  }

  static CollectionReference<Map<String, dynamic>> _quickItemsRef() {
    return _quickListRef().collection('items');
  }

  static Future<void> ensureQuickList() async {
    final ref = _quickListRef();
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': 'Saved Items',
        'type': 'quick',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> addToQuickList(Product p) async {
    await ensureQuickList();
    final itemRef = _quickItemsRef().doc(p.id);
    await itemRef.set({
      'productId': p.id,
      'name': p.name,
      'brand': p.brandName,
      'imageUrl': p.imageUrl,
      'category': p.category,
      'sizeRaw': p.sizeRaw,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _quickListRef().update({'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> removeFromQuickList(String productId) async {
    await _quickItemsRef().doc(productId).delete();
    await _quickListRef().update({'updatedAt': FieldValue.serverTimestamp()});
  }

  static Stream<List<Map<String, dynamic>>> quickListStream({int limit = 50}) {
    final uid = _uid();
    if (uid == null) {
      // Return empty stream if not logged in
      return const Stream.empty();
    }
    return _quickItemsRef()
        .orderBy('addedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  static Future<bool> isInQuickList(String productId) async {
    final doc = await _quickItemsRef().doc(productId).get();
    return doc.exists;
  }

  static Future<void> clearQuickList() async {
    await ensureQuickList();
    final items = await _quickItemsRef().get();
    final batch = _fs.batch();
    for (final d in items.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    await _quickListRef().update({'updatedAt': FieldValue.serverTimestamp()});
  }

  // List management helpers
  static Future<List<Map<String, dynamic>>> getLists({
    bool includeQuick = true,
  }) async {
    final uid = _uid();
    if (uid == null) return [];
    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .get();
    final out = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      if (!includeQuick && d.id == 'quick_saved') continue;
      final data = d.data();
      out.add({
        'id': d.id,
        'name': data['name'] ?? 'List',
        'type': data['type'] ?? 'named',
      });
    }
    return out;
  }

  static Future<String> createNamedList(String name) async {
    final uid = _uid();
    if (uid == null) {
      throw StateError('User not logged in');
    }
    final ref = _fs.collection('users').doc(uid).collection('lists').doc();
    await ref.set({
      'name': name,
      'type': 'named',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> moveItemToList(
    String productId,
    String targetListId,
  ) async {
    await ensureQuickList();
    final srcDoc = await _quickItemsRef().doc(productId).get();
    if (!srcDoc.exists) return;
    final data = srcDoc.data()!;
    final targetRef = _quickListRef().parent
        .doc(targetListId)
        .collection('items')
        .doc(productId);
    final batch = _fs.batch();
    batch.set(targetRef, {
      ...data,
      'movedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.delete(srcDoc.reference);
    batch.update(_quickListRef(), {'updatedAt': FieldValue.serverTimestamp()});
    batch.update(_quickListRef().parent.doc(targetListId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<String> exportQuickListAsText() async {
    await ensureQuickList();
    final snap = await _quickItemsRef()
        .orderBy('addedAt', descending: true)
        .get();
    if (snap.docs.isEmpty) return 'No saved items.';
    final lines = <String>[];
    lines.add('Saved Items');
    lines.add('');
    for (final d in snap.docs) {
      final m = d.data();
      final brand = (m['brand'] ?? '').toString();
      final name = (m['name'] ?? '').toString();
      final size = (m['sizeRaw'] ?? '').toString();
      final line =
          '• ${brand.isNotEmpty ? '$brand ' : ''}$name${size.isNotEmpty ? ' ($size)' : ''}';
      lines.add(line.trim());
    }
    return lines.join('\n');
  }

  // Named list utilities for management
  static Future<List<Map<String, dynamic>>> getListsWithMeta({
    bool includeQuick = false,
  }) async {
    final uid = _uid();
    if (uid == null) return [];
    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .orderBy('order', descending: false)
        .get();
    final out = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      if (!includeQuick && d.id == 'quick_saved') continue;
      final data = d.data();
      out.add({
        'id': d.id,
        'name': data['name'] ?? 'List',
        'type': data['type'] ?? 'named',
        'order': data['order'] ?? 0,
      });
    }
    return out;
  }

  static Future<void> setListName(String listId, String name) async {
    final uid = _uid();
    if (uid == null) throw StateError('User not logged in');
    final ref = _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(listId);
    await ref.update({'name': name, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> setListsOrder(List<Map<String, dynamic>> ordered) async {
    final uid = _uid();
    if (uid == null) throw StateError('User not logged in');
    final batch = _fs.batch();
    final col = _fs.collection('users').doc(uid).collection('lists');
    for (final e in ordered) {
      final id = e['id'] as String;
      final order = e['order'] as int;
      batch.update(col.doc(id), {
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<String> exportNamedListAsText(String listId) async {
    final uid = _uid();
    if (uid == null) throw StateError('User not logged in');
    final listRef = _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(listId);
    final listDoc = await listRef.get();
    final name = (listDoc.data() ?? const {})['name'] ?? 'List';
    final items = await listRef
        .collection('items')
        .orderBy('addedAt', descending: true)
        .get();
    if (items.docs.isEmpty) return '$name\n\nNo items.';
    final lines = <String>[];
    lines.add(name);
    lines.add('');
    for (final d in items.docs) {
      final m = d.data();
      final brand = (m['brand'] ?? '').toString();
      final title = (m['name'] ?? '').toString();
      final size = (m['sizeRaw'] ?? '').toString();
      final line =
          '• ${brand.isNotEmpty ? '$brand ' : ''}$title${size.isNotEmpty ? ' ($size)' : ''}';
      lines.add(line.trim());
    }
    return lines.join('\n');
  }

  // Delete a named list and its items (cannot delete quick_saved)
  static Future<void> deleteList(String listId) async {
    final uid = _uid();
    if (uid == null) throw StateError('User not logged in');
    if (listId == 'quick_saved') throw StateError('Cannot delete quick list');
    final listRef = _fs
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(listId);
    // Delete items subcollection
    final itemsSnap = await listRef.collection('items').get();
    final batch = _fs.batch();
    for (final d in itemsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(listRef);
    await batch.commit();
  }
}
