import 'package:cloud_firestore/cloud_firestore.dart';

class ListNote {
  final String id;
  final String listId;
  final String?
  itemId; // null for general list notes, itemId for item-specific notes
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final String? replyToNoteId; // for threaded notes
  final Map<String, dynamic> metadata; // for future extensions

  ListNote({
    required this.id,
    required this.listId,
    this.itemId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.replyToNoteId,
    this.metadata = const {},
  });

  factory ListNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime toDate(dynamic v, {DateTime? fallback}) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return fallback ?? DateTime.now();
    }

    return ListNote(
      id: doc.id,
      listId: data['listId'] ?? '',
      itemId: data['itemId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      content: data['content'] ?? '',
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
      isEdited: data['isEdited'] ?? false,
      replyToNoteId: data['replyToNoteId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'itemId': itemId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
      'replyToNoteId': replyToNoteId,
      'metadata': metadata,
    };
  }

  ListNote copyWith({
    String? id,
    String? listId,
    String? itemId,
    String? userId,
    String? userName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? replyToNoteId,
    Map<String, dynamic>? metadata,
  }) {
    return ListNote(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      replyToNoteId: replyToNoteId ?? this.replyToNoteId,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isGeneralNote => itemId == null;
  bool get isItemNote => itemId != null;
  bool get isReply => replyToNoteId != null;
}
