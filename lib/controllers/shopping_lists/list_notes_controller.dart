import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/shopping_lists/list_note_model.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/shopping_lists/list_notes_service.dart';
import '../../utils/app_logger.dart';
import '../../services/product/product_image_cache.dart';

class ListNotesController extends GetxController {
  final ListNotesService _notesService = ListNotesService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable state
  final RxList<ListNote> _notes = <ListNote>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _totalNotesCount = 0.obs;

  // Text controllers
  final TextEditingController noteContentController = TextEditingController();
  final FocusNode noteContentFocus = FocusNode();

  // Stream subscription
  StreamSubscription<List<ListNote>>? _notesSubscription;

  // Current context
  String? _currentListId;
  String? _currentItemId;
  // Reply target is reactive to support Obx without GetBuilder
  final RxnString _replyToNoteId = RxnString();
  // Selected item for linking
  ShoppingListItem? _linkedItem;

  // Getters
  List<ListNote> get notes => _notes;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get totalNotesCount => _totalNotesCount.value;
  bool get hasNotes => _notes.isNotEmpty;
  bool get isReplying => _replyToNoteId.value != null;

  // Get current user info
  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _currentUserName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'Unknown';

  @override
  void onClose() {
    _notesSubscription?.cancel();
    noteContentController.dispose();
    noteContentFocus.dispose();
    super.onClose();
  }

  // Load notes for a list
  void loadListNotes(String listId) {
    if (_currentListId == listId && _currentItemId == null) {
      AppLogger.d('Already loading notes for list: $listId');
      return;
    }

    AppLogger.d('Loading notes for list: $listId');
    _currentListId = listId;
    _currentItemId = null;
    _clearReply();
    _startNotesStream();
  }

  // Load notes for a specific item
  void loadItemNotes(String listId, String itemId) {
    if (_currentListId == listId && _currentItemId == itemId) {
      AppLogger.d('Already loading notes for item: $itemId');
      return;
    }

    AppLogger.d('Loading notes for item: $itemId in list: $listId');
    _currentListId = listId;
    _currentItemId = itemId;
    _clearReply();
    _startNotesStream();
  }

  // Start the appropriate notes stream
  void _startNotesStream() {
    _notesSubscription?.cancel();
    _isLoading.value = true;
    _error.value = '';

    if (_currentListId == null) {
      AppLogger.w('Cannot start notes stream: no list ID');
      _isLoading.value = false;
      return;
    }

    Stream<List<ListNote>> notesStream;
    if (_currentItemId != null) {
      notesStream = _notesService.getItemNotesStream(
        _currentListId!,
        _currentItemId!,
      );
    } else {
      notesStream = _notesService.getListNotesStream(_currentListId!);
    }

    _notesSubscription = notesStream.listen(
      (notesList) {
        AppLogger.d('Received ${notesList.length} notes');
        _notes.value = notesList;
        _totalNotesCount.value = notesList.length;
        _isLoading.value = false;
        _error.value = '';

        // Prefetch any product images referenced by notes for snappy rendering
        try {
          final productIds = <String>[];
          for (final n in notesList) {
            final pid = n.metadata['linkedProductId'];
            if (pid is String && pid.isNotEmpty) productIds.add(pid);
          }
          if (productIds.isNotEmpty) {
            ProductImageCache.instance.prefetch(productIds);
          }
        } catch (_) {}
      },
      onError: (error) {
        AppLogger.w('Notes stream error: $error');
        _error.value = 'Failed to load notes: $error';
        _isLoading.value = false;
      },
    );
  }

  // Seed initial notes to render immediately before network stream emits
  void seedInitialNotes(List<ListNote> notes) {
    if (notes.isEmpty) return;
    _notes.value = notes;
    _totalNotesCount.value = notes.length;
    _isLoading.value = false;
    _error.value = '';
  }

  // Add a new note
  Future<void> addNote() async {
    final content = noteContentController.text.trim();
    if (content.isEmpty || _currentListId == null) {
      AppLogger.w('Cannot add note: empty content or no list ID');
      return;
    }

    if (_currentUserId.isEmpty) {
      AppLogger.w('Cannot add note: no current user');
      Get.snackbar('Error', 'Please sign in to add notes');
      return;
    }

    AppLogger.d(
      'Adding note: ${content.substring(0, content.length.clamp(0, 50))}...',
    );

    try {
      final noteId = await _notesService.addNote(
        listId: _currentListId!,
        itemId: _currentItemId,
        userId: _currentUserId,
        userName: _currentUserName,
        content: content,
        replyToNoteId: _replyToNoteId.value,
        metadata: _linkedItem != null
            ? {
                'linkedItemId': _linkedItem!.id,
                'productName': _linkedItem!.name,
                if (_linkedItem!.productId != null)
                  'linkedProductId': _linkedItem!.productId,
              }
            : (_currentItemId == null
                  ? null
                  : {
                      // lightweight context for UI preview; resolved cheaply on server if needed
                      'linkedItemId': _currentItemId,
                      // productName can be appended by caller UI if available; left null otherwise
                    }),
      );

      if (noteId != null) {
        AppLogger.d('Note added successfully: $noteId');
        noteContentController.clear();
        _clearReply();
        // Clear linked item after successful note
        clearLinkedItem();
        // Auto-scroll to bottom when new note is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        Get.snackbar('Error', 'Failed to add note');
      }
    } catch (e) {
      AppLogger.w('Error adding note: $e');
      Get.snackbar('Error', 'Failed to add note: $e');
    }
  }

  // Update an existing note
  Future<void> updateNote(String noteId, String newContent) async {
    if (newContent.trim().isEmpty) {
      AppLogger.w('Cannot update note: empty content');
      return;
    }

    AppLogger.d('Updating note: $noteId');

    try {
      final success = await _notesService.updateNote(noteId, newContent);
      if (success) {
        AppLogger.d('Note updated successfully: $noteId');
      } else {
        Get.snackbar('Error', 'Failed to update note');
      }
    } catch (e) {
      AppLogger.w('Error updating note: $e');
      Get.snackbar('Error', 'Failed to update note: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    AppLogger.d('Deleting note: $noteId');

    try {
      final success = await _notesService.deleteNote(noteId);
      if (success) {
        AppLogger.d('Note deleted successfully: $noteId');
      } else {
        Get.snackbar('Error', 'Failed to delete note');
      }
    } catch (e) {
      AppLogger.w('Error deleting note: $e');
      Get.snackbar('Error', 'Failed to delete note: $e');
    }
  }

  // Set reply target
  void setReplyTarget(ListNote note) {
    _replyToNoteId.value = note.id;
    noteContentFocus.requestFocus();
    AppLogger.d('Set reply target: ${note.id}');
  }

  // Clear reply target
  void _clearReply() {
    _replyToNoteId.value = null;
  }

  void cancelReply() {
    _clearReply();
    AppLogger.d('Cancelled reply');
  }

  // Get the note being replied to
  ListNote? get replyTargetNote {
    final id = _replyToNoteId.value;
    if (id == null) return null;
    return _notes.firstWhereOrNull((note) => note.id == id);
  }

  // Get notes in chronological order (all notes mixed, not threaded)
  List<List<ListNote>> get threadedNotes {
    // Sort all notes by creation time for chronological display
    final sortedNotes = List<ListNote>.from(_notes)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Return each note as its own "thread" for consistent UI rendering
    return sortedNotes.map((note) => [note]).toList();
  }

  // Set linked item for next note
  void setLinkedItem(ShoppingListItem item) {
    _linkedItem = item;
    AppLogger.d('Set linked item: ${item.name}');
  }

  // Check if current user can edit/delete a note
  bool canEditNote(ListNote note) {
    return note.userId == _currentUserId;
  }

  // Clear linked item
  void clearLinkedItem() {
    _linkedItem = null;
  }

  // Scroll to bottom (for auto-scroll when new notes are added)
  final ScrollController scrollController = ScrollController();

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize scroll controller
    ever(_notes, (_) {
      // Auto-scroll when notes change (new note added)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    });
  }
}
