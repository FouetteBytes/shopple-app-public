import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String? fromUserProfileImage;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    this.fromUserProfileImage,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  // Convert from Firestore document
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? 'Unknown User',
      fromUserEmail: data['fromUserEmail'] as String? ?? '',
      fromUserProfileImage: data['fromUserProfileImage'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      message: data['message'] as String?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'fromUserProfileImage': fromUserProfileImage,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'message': message,
    };
  }

  // Helper methods
  bool get isPending => status == FriendRequestStatus.pending;
  bool get isAccepted => status == FriendRequestStatus.accepted;
  bool get isDeclined => status == FriendRequestStatus.declined;

  FriendRequest copyWith({
    String? id,
    FriendRequestStatus? status,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUserName: fromUserName,
      fromUserEmail: fromUserEmail,
      fromUserProfileImage: fromUserProfileImage,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message,
    );
  }
}

enum FriendRequestStatus { pending, accepted, declined }
