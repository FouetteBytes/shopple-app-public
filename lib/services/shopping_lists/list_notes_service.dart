import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/shopping_lists/list_note_model.dart';
import '../../utils/app_logger.dart';

class ListNotesService extends GetxService {
  static ListNotesService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'list_notes';

  // Real-time stream of notes for a specific list
  Stream<List<ListNote>> getListNotesStream(String listId) {
    AppLogger.d('Starting notes stream for list: $listId');

    return _firestore
        .collection(_collection)
        .where('listId', isEqualTo: listId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          AppLogger.d(
            'Received ${snapshot.docs.length} notes for list: $listId',
          );
          return snapshot.docs
              .map((doc) => ListNote.fromFirestore(doc))
              .toList();
        });
  }

  // Real-time stream of notes for a specific item
  Stream<List<ListNote>> getItemNotesStream(String listId, String itemId) {
    AppLogger.d('Starting notes stream for item: $itemId in list: $listId');

    return _firestore
        .collection(_collection)
        .where('listId', isEqualTo: listId)
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          AppLogger.d(
            'Received ${snapshot.docs.length} notes for item: $itemId',
          );
          return snapshot.docs
              .map((doc) => ListNote.fromFirestore(doc))
              .toList();
        });
  }

  // Add a new note
  Future<String?> addNote({
    required String listId,
    String? itemId,
    required String userId,
    required String userName,
    required String content,
    String? replyToNoteId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.d(
        'Adding note to list: $listId ${itemId != null ? 'for item: $itemId' : '(general)'}',
      );

      final now = DateTime.now();
      final noteData = {
        'listId': listId,
        'itemId': itemId,
        'userId': userId,
        'userName': userName,
        'content': content.trim(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isEdited': false,
        'replyToNoteId': replyToNoteId,
        'metadata': metadata ?? {},
      };

      final docRef = await _firestore.collection(_collection).add(noteData);
      AppLogger.d('Note added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.w('Failed to add note: $e');
      return null;
    }
  }

  // Update an existing note
  Future<bool> updateNote(String noteId, String newContent) async {
    try {
      AppLogger.d('Updating note: $noteId');

      await _firestore.collection(_collection).doc(noteId).update({
        'content': newContent.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isEdited': true,
      });

      AppLogger.d('Note updated successfully: $noteId');
      return true;
    } catch (e) {
      AppLogger.w('Failed to update note: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      AppLogger.d('Deleting note: $noteId');

      await _firestore.collection(_collection).doc(noteId).delete();

      AppLogger.d('Note deleted successfully: $noteId');
      return true;
    } catch (e) {
      AppLogger.w('Failed to delete note: $e');
      return false;
    }
  }

  // Get notes count for a list
  Future<int> getNotesCount(String listId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('listId', isEqualTo: listId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.w('Failed to get notes count: $e');
      return 0;
    }
  }

  // Get item notes count
  Future<int> getItemNotesCount(String listId, String itemId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('listId', isEqualTo: listId)
          .where('itemId', isEqualTo: itemId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.w('Failed to get item notes count: $e');
      return 0;
    }
  }

  // Search notes by content
  Stream<List<ListNote>> searchNotes(String listId, String searchQuery) {
    AppLogger.d('Searching notes in list: $listId for: $searchQuery');

    return _firestore
        .collection(_collection)
        .where('listId', isEqualTo: listId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final allNotes = snapshot.docs
              .map((doc) => ListNote.fromFirestore(doc))
              .toList();

          // Client-side filtering for content search
          final filteredNotes = allNotes
              .where(
                (note) => note.content.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();

          AppLogger.d(
            'Found ${filteredNotes.length} notes matching: $searchQuery',
          );
          return filteredNotes;
        });
  }
}
