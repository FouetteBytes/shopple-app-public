import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String userId;
  final String displayName;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final DateTime friendshipDate;
  final FriendshipStatus status;
  final String? signInMethod; // 'phone' | 'email' | 'google' | null (legacy)

  Friend({
    required this.userId,
    required this.displayName,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    required this.friendshipDate,
    required this.status,
    this.signInMethod,
  });

  factory Friend.fromFirestore(String friendId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      userId: friendId,
      displayName: data['displayName'] as String,
      email: (data['email'] ?? '') as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      friendshipDate: (data['friendshipDate'] as Timestamp).toDate(),
      status: FriendshipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => FriendshipStatus.active,
      ),
      signInMethod: data['signInMethod'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'friendshipDate': Timestamp.fromDate(friendshipDate),
      'status': status.toString().split('.').last,
      if (signInMethod != null) 'signInMethod': signInMethod,
    };
  }
}

enum FriendshipStatus { active, blocked }
