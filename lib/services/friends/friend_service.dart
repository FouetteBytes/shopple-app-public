import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/friends/friend_request.dart';
import '../../models/friends/friend_group.dart';
import '../../models/friends/friend.dart';
import 'package:shopple/utils/app_logger.dart';
import 'i_friend_service.dart';

class FriendService {
  static IFriendService instance = FriendServiceImpl();

  static String get currentUserId => instance.currentUserId;

  // ==================== FRIEND REQUESTS ====================

  /// Send a friend request to another user
  static Future<bool> sendFriendRequest({
    required String targetUserId,
    required String targetUserName,
    required String targetUserEmail,
    String? message,
  }) => instance.sendFriendRequest(
    targetUserId: targetUserId,
    targetUserName: targetUserName,
    targetUserEmail: targetUserEmail,
    message: message,
  );

  /// Accept a friend request
  static Future<bool> acceptFriendRequest(String requestId) =>
      instance.acceptFriendRequest(requestId);

  /// Decline a friend request
  static Future<bool> declineFriendRequest(String requestId) =>
      instance.declineFriendRequest(requestId);

  // ==================== FRIEND GROUPS ====================

  /// Create a new friend group
  static Future<String> createFriendGroup({
    required String name,
    String? description,
    required String iconName,
    required Color color,
    List<String>? friendIds,
  }) => instance.createFriendGroup(
    name: name,
    description: description,
    iconName: iconName,
    color: color,
    initialMemberIds: friendIds,
  );

  /// Create default friend groups for new user
  static Future<void> createDefaultFriendGroups() =>
      instance.createDefaultFriendGroups();

  /// Add friends to a group
  static Future<bool> addFriendsToGroup({
    required String groupId,
    required List<String> friendIds,
  }) => instance.addFriendsToGroup(groupId: groupId, friendIds: friendIds);

  /// Remove friends from a group
  static Future<bool> removeFriendsFromGroup({
    required String groupId,
    required List<String> friendIds,
  }) => instance.removeFriendsFromGroup(groupId: groupId, friendIds: friendIds);

  // ==================== STREAMS FOR REAL-TIME UPDATES ====================

  /// Get stream of received friend requests
  static Stream<List<FriendRequest>> getReceivedFriendRequestsStream() =>
      instance.getReceivedFriendRequestsStream();

  /// Get stream of sent friend requests
  static Stream<List<FriendRequest>> getSentFriendRequestsStream() =>
      instance.getSentFriendRequestsStream();

  /// Get stream of user's friends
  static Stream<List<Friend>> getFriendsStream() => instance.getFriendsStream();

  /// Get stream of user's friend groups
  static Stream<List<FriendGroup>> getFriendGroupsStream() =>
      instance.getFriendGroupsStream();

  /// Get count of pending received friend requests
  static Stream<int> getPendingRequestsCountStream() =>
      instance.getPendingRequestsCountStream();

  // ==================== HELPER METHODS ====================

  /// Remove a friend (unfriend)
  static Future<bool> removeFriend(String friendId) =>
      instance.removeFriend(friendId);

  // ==================== HELPER METHODS FOR SEARCH/ADD FRIENDS ====================

  /// Get the current user ID (helper method for search screen)
  static String getCurrentUserId() => instance.getCurrentUserId();

  /// Check if a user is already a friend
  static Future<bool> isFriend(String userId) => instance.isFriend(userId);

  /// Check if a friend request has been sent to a user
  static Future<bool> hasSentFriendRequest(String targetUserId) =>
      instance.hasSentFriendRequest(targetUserId);

  /// Check if a friend request has been received from a user
  static Future<bool> hasReceivedFriendRequest(String fromUserId) =>
      instance.hasReceivedFriendRequest(fromUserId);

  /// Accept friend request by user ID (helper for search screen)
  static Future<bool> acceptFriendRequestByUserId(String fromUserId) =>
      instance.acceptFriendRequestByUserId(fromUserId);
}

class FriendServiceImpl implements IFriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  // ==================== FRIEND REQUESTS ====================

  /// Send a friend request to another user
  @override
  Future<bool> sendFriendRequest({
    required String targetUserId,
    required String targetUserName,
    required String targetUserEmail,
    String? message,
  }) async {
    try {
      final currentUser = _auth.currentUser!;

      // Check if friendship already exists
      final friendshipExists = await _checkFriendshipExists(targetUserId);
      if (friendshipExists) {
        throw Exception('You are already friends with this user');
      }

      // Check if request already exists
      final existingRequest = await _checkExistingFriendRequest(
        currentUserId,
        targetUserId,
      );
      if (existingRequest != null) {
        throw Exception('Friend request already sent');
      }

      // Get current user's profile data from Firestore for proper name
      String fromUserName = currentUser.displayName ?? 'User';
      String fromUserEmail = currentUser.email ?? '';
      String? fromUserProfileImage = currentUser.photoURL;

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Build proper display name from Firestore data
          final firstName = userData['firstName'] as String?;
          final lastName = userData['lastName'] as String?;

          if (firstName != null && firstName.isNotEmpty) {
            if (lastName != null && lastName.isNotEmpty) {
              fromUserName = '$firstName $lastName';
            } else {
              fromUserName = firstName;
            }
          }

          // Use Firestore email if available
          if (userData['email'] != null &&
              userData['email'].toString().isNotEmpty) {
            fromUserEmail = userData['email'];
          }

          // Use custom profile image if available
          if (userData['customPhotoURL'] != null &&
              userData['customPhotoURL'].toString().isNotEmpty) {
            fromUserProfileImage = userData['customPhotoURL'];
          } else if (userData['photoURL'] != null &&
              userData['photoURL'].toString().isNotEmpty) {
            fromUserProfileImage = userData['photoURL'];
          }
        }
      } catch (e) {
        // If Firestore fetch fails, continue with Firebase Auth data
        AppLogger.w('Could not fetch user profile data from Firestore: $e');
      }

      // Create the friend request with proper user data
      final request = FriendRequest(
        id: '',
        fromUserId: currentUserId,
        toUserId: targetUserId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        fromUserProfileImage: fromUserProfileImage,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
        message: message,
      );

      // Write to global friend_requests collection
      final docRef = await _firestore
          .collection('friend_requests')
          .add(request.toFirestore());

      // Write to sender's sent requests tracking
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests_sent')
          .doc(docRef.id)
          .set({
            'requestId': docRef.id,
            'toUserId': targetUserId,
            'toUserName': targetUserName,
            'toUserEmail': targetUserEmail,
            'status': 'pending',
            'sentAt': FieldValue.serverTimestamp(),
          });

      // Write to recipient's received requests tracking
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friend_requests_received')
          .doc(docRef.id)
          .set({
            'requestId': docRef.id,
            'fromUserId': currentUserId,
            'fromUserName': currentUser.displayName ?? 'User',
            'fromUserEmail': currentUser.email ?? '',
            'status': 'pending',
            'receivedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.d('✅ Friend request sent successfully to $targetUserName');
      return true;
    } catch (e) {
      AppLogger.e('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request
  @override
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the friend request
        final requestDoc = await transaction.get(
          _firestore.collection('friend_requests').doc(requestId),
        );

        if (!requestDoc.exists) {
          throw Exception('Friend request not found');
        }

        final request = FriendRequest.fromFirestore(requestDoc);

        if (request.toUserId != currentUserId) {
          throw Exception('You can only accept requests sent to you');
        }

        // Update request status
        transaction.update(requestDoc.reference, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Fetch fresh user data for the sender (request.fromUserId)
        final senderUserDoc = await transaction.get(
          _firestore.collection('users').doc(request.fromUserId),
        );
        final senderUserData = senderUserDoc.data();
        
        // Build sender's display name from fresh Firestore data
        String senderDisplayName = request.fromUserName;
        String senderEmail = request.fromUserEmail;
        String? senderPhone;
        String? senderProfileImage = request.fromUserProfileImage;
        String? senderSignInMethod;
        
        if (senderUserData != null) {
          final firstName = senderUserData['firstName'] as String?;
          final lastName = senderUserData['lastName'] as String?;
          final fullName = senderUserData['fullName'] as String?;
          
          if (fullName != null && fullName.isNotEmpty) {
            senderDisplayName = fullName;
          } else if (firstName != null && firstName.isNotEmpty) {
            senderDisplayName = lastName != null && lastName.isNotEmpty
                ? '$firstName $lastName'
                : firstName;
          } else if (senderUserData['displayName'] != null) {
            senderDisplayName = senderUserData['displayName'] as String;
          }
          
          if (senderUserData['email'] != null && (senderUserData['email'] as String).isNotEmpty) {
            senderEmail = senderUserData['email'] as String;
          }
          senderPhone = senderUserData['phoneNumber'] as String?;
          senderSignInMethod = senderUserData['signInMethod'] as String?;
          
          // Get profile image (prefer custom, then Google)
          if (senderUserData['customPhotoURL'] != null && (senderUserData['customPhotoURL'] as String).isNotEmpty) {
            senderProfileImage = senderUserData['customPhotoURL'] as String;
          } else if (senderUserData['photoURL'] != null && (senderUserData['photoURL'] as String).isNotEmpty) {
            senderProfileImage = senderUserData['photoURL'] as String;
          }
        }

        // Create friendship for current user (receiver) with fresh sender data
        final receiverFriendData = Friend(
          userId: request.fromUserId,
          displayName: senderDisplayName,
          email: senderEmail,
          phoneNumber: senderPhone,
          profileImageUrl: senderProfileImage,
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: senderSignInMethod,
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(request.fromUserId),
          receiverFriendData.toFirestore(),
        );

        // Fetch fresh user data for the current user (receiver)
        final receiverUserDoc = await transaction.get(
          _firestore.collection('users').doc(currentUserId),
        );
        final receiverUserData = receiverUserDoc.data();
        
        // Build receiver's display name from fresh Firestore data
        final currentUserData = _auth.currentUser!;
        String receiverDisplayName = currentUserData.displayName ?? 'User';
        String receiverEmail = currentUserData.email ?? '';
        String? receiverPhone;
        String? receiverProfileImage = currentUserData.photoURL;
        String? receiverSignInMethod;
        
        if (receiverUserData != null) {
          final firstName = receiverUserData['firstName'] as String?;
          final lastName = receiverUserData['lastName'] as String?;
          final fullName = receiverUserData['fullName'] as String?;
          
          if (fullName != null && fullName.isNotEmpty) {
            receiverDisplayName = fullName;
          } else if (firstName != null && firstName.isNotEmpty) {
            receiverDisplayName = lastName != null && lastName.isNotEmpty
                ? '$firstName $lastName'
                : firstName;
          } else if (receiverUserData['displayName'] != null) {
            receiverDisplayName = receiverUserData['displayName'] as String;
          }
          
          if (receiverUserData['email'] != null && (receiverUserData['email'] as String).isNotEmpty) {
            receiverEmail = receiverUserData['email'] as String;
          }
          receiverPhone = receiverUserData['phoneNumber'] as String?;
          receiverSignInMethod = receiverUserData['signInMethod'] as String?;
          
          // Get profile image (prefer custom, then Google)
          if (receiverUserData['customPhotoURL'] != null && (receiverUserData['customPhotoURL'] as String).isNotEmpty) {
            receiverProfileImage = receiverUserData['customPhotoURL'] as String;
          } else if (receiverUserData['photoURL'] != null && (receiverUserData['photoURL'] as String).isNotEmpty) {
            receiverProfileImage = receiverUserData['photoURL'] as String;
          }
        }

        // Create friendship for sender with fresh receiver data
        final senderFriendData = Friend(
          userId: currentUserId,
          displayName: receiverDisplayName,
          email: receiverEmail,
          phoneNumber: receiverPhone,
          profileImageUrl: receiverProfileImage,
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: receiverSignInMethod,
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(request.fromUserId)
              .collection('friends')
              .doc(currentUserId),
          senderFriendData.toFirestore(),
        );

        // Update tracking collections
        transaction.update(
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friend_requests_received')
              .doc(requestId),
          {'status': 'accepted'},
        );

        transaction.update(
          _firestore
              .collection('users')
              .doc(request.fromUserId)
              .collection('friend_requests_sent')
              .doc(requestId),
          {'status': 'accepted'},
        );
      });

      AppLogger.d('✅ Friend request accepted successfully');
      return true;
    } catch (e) {
      AppLogger.e('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  @override
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the friend request
        final requestDoc = await transaction.get(
          _firestore.collection('friend_requests').doc(requestId),
        );

        if (!requestDoc.exists) {
          throw Exception('Friend request not found');
        }

        final request = FriendRequest.fromFirestore(requestDoc);

        if (request.toUserId != currentUserId) {
          throw Exception('You can only decline requests sent to you');
        }

        // Update request status
        transaction.update(requestDoc.reference, {
          'status': 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Update tracking collections
        transaction.update(
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friend_requests_received')
              .doc(requestId),
          {'status': 'declined'},
        );

        transaction.update(
          _firestore
              .collection('users')
              .doc(request.fromUserId)
              .collection('friend_requests_sent')
              .doc(requestId),
          {'status': 'declined'},
        );
      });

      AppLogger.d('✅ Friend request declined');
      return true;
    } catch (e) {
      AppLogger.e('Error declining friend request: $e');
      rethrow;
    }
  }

  // ==================== FRIEND GROUPS ====================

  /// Create a new friend group
  @override
  Future<String> createFriendGroup({
    required String name,
    String? description,
    required String iconName,
    required Color color,
    List<String>? initialMemberIds,
  }) async {
    try {
      final group = FriendGroup(
        id: '',
        name: name,
        userId: currentUserId,
        description: description,
        iconName: iconName,
        colorValue: color.toARGB32(),
        memberIds: initialMemberIds ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_groups')
          .add(group.toFirestore());

      AppLogger.d('✅ Friend group "$name" created successfully');
      return docRef.id;
    } catch (e) {
      AppLogger.e('Error creating friend group: $e');
      rethrow;
    }
  }

  /// Create default friend groups for new user
  @override
  Future<void> createDefaultFriendGroups() async {
    try {
      final templates = FriendGroup.getDefaultGroupTemplates(currentUserId);
      final batch = _firestore.batch();

      for (final template in templates) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friend_groups')
            .doc();

        batch.set(docRef, template.toFirestore());
      }

      await batch.commit();
      AppLogger.d('✅ Default friend groups created');
    } catch (e) {
      AppLogger.e('Error creating default groups: $e');
      rethrow;
    }
  }

  /// Add friends to a group
  @override
  Future<bool> addFriendsToGroup({
    required String groupId,
    required List<String> friendIds,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_groups')
          .doc(groupId)
          .update({
            'memberIds': FieldValue.arrayUnion(friendIds),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.d('✅ Added ${friendIds.length} friends to group');
      return true;
    } catch (e) {
      AppLogger.e('Error adding friends to group: $e', error: e);
      rethrow;
    }
  }

  /// Remove friends from a group
  @override
  Future<bool> removeFriendsFromGroup({
    required String groupId,
    required List<String> friendIds,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_groups')
          .doc(groupId)
          .update({
            'memberIds': FieldValue.arrayRemove(friendIds),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.d('✅ Removed ${friendIds.length} friends from group');
      return true;
    } catch (e) {
      AppLogger.e('Error removing friends from group: $e', error: e);
      rethrow;
    }
  }

  // ==================== STREAMS FOR REAL-TIME UPDATES ====================

  /// Get stream of received friend requests
  @override
  Stream<List<FriendRequest>> getReceivedFriendRequestsStream() {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get stream of sent friend requests
  @override
  Stream<List<FriendRequest>> getSentFriendRequestsStream() {
    return _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get stream of user's friends
  @override
  Stream<List<Friend>> getFriendsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Friend.fromFirestore(doc.id, doc))
              .toList(),
        );
  }

  /// Get stream of user's friend groups
  @override
  Stream<List<FriendGroup>> getFriendGroupsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_groups')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendGroup.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get count of pending received friend requests
  @override
  Stream<int> getPendingRequestsCountStream() {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== HELPER METHODS ====================

  Future<bool> _checkFriendshipExists(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<FriendRequest?> _checkExistingFriendRequest(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      final query = await _firestore
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return query.docs.isNotEmpty
          ? FriendRequest.fromFirestore(query.docs.first)
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Remove a friend (unfriend)
  @override
  Future<bool> removeFriend(String friendId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Remove from current user's friends
        transaction.delete(
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(friendId),
        );

        // Remove from friend's friends
        transaction.delete(
          _firestore
              .collection('users')
              .doc(friendId)
              .collection('friends')
              .doc(currentUserId),
        );

        // Remove from all friend groups
        final groupsSnapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friend_groups')
            .where('memberIds', arrayContains: friendId)
            .get();

        for (final groupDoc in groupsSnapshot.docs) {
          transaction.update(groupDoc.reference, {
            'memberIds': FieldValue.arrayRemove([friendId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      AppLogger.d('Friend removed successfully');
      return true;
    } catch (e) {
      AppLogger.e('Error removing friend: $e', error: e);
      rethrow;
    }
  }

  // ==================== HELPER METHODS FOR SEARCH/ADD FRIENDS ====================

  /// Get the current user ID (helper method for search screen)
  @override
  String getCurrentUserId() {
    return currentUserId;
  }

  /// Check if a user is already a friend
  @override
  Future<bool> isFriend(String userId) async {
    try {
      return await _checkFriendshipExists(userId);
    } catch (e) {
      AppLogger.e('Error checking friendship: $e', error: e);
      return false;
    }
  }

  /// Check if a friend request has been sent to a user
  @override
  Future<bool> hasSentFriendRequest(String targetUserId) async {
    try {
      final request = await _checkExistingFriendRequest(
        currentUserId,
        targetUserId,
      );
      return request != null && request.fromUserId == currentUserId;
    } catch (e) {
      AppLogger.e('Error checking sent request: $e', error: e);
      return false;
    }
  }

  /// Check if a friend request has been received from a user
  @override
  Future<bool> hasReceivedFriendRequest(String fromUserId) async {
    try {
      final request = await _checkExistingFriendRequest(
        fromUserId,
        currentUserId,
      );
      return request != null && request.fromUserId == fromUserId;
    } catch (e) {
      AppLogger.e('Error checking received request: $e', error: e);
      return false;
    }
  }

  /// Accept friend request by user ID (helper for search screen)
  @override
  Future<bool> acceptFriendRequestByUserId(String fromUserId) async {
    try {
      // Find the request first
      final request = await _checkExistingFriendRequest(
        fromUserId,
        currentUserId,
      );
      if (request == null) {
        throw Exception('Friend request not found');
      }

      // Accept using the request ID
      return await acceptFriendRequest(request.id);
    } catch (e) {
      AppLogger.e('Error accepting friend request by user ID: $e', error: e);
      rethrow;
    }
  }
}
