# 🤝 Phase 1: Friend System Foundation + Online Presence
## Complete Step-by-Step Implementation Guide

---

## 🎯 **IMPLEMENTATION OVERVIEW**

**What We're Building in Phase 1:**
- ✅ **Friend Request System** - Send, accept, decline friend requests
- ✅ **Friend Groups Organization** - Family, School, Work, Custom groups  
- ✅ **Real-time Presence Detection** - Show who's online/offline
- ✅ **Enhanced Friend Discovery** - Presence-aware friend search
- ✅ **Friends Management UI** - Complete friends tab integration

**What We're NOT Building Yet:**
- ❌ Collaborative shopping lists (Phase 2)
- ❌ Real-time list editing (Phase 2)
- ❌ Advanced notifications (Phase 2)

---

## 📋 **PREREQUISITES CHECKLIST**

**Before starting, verify you have:**

- [ ] ✅ **Existing contact syncing working** (from your current implementation)
- [ ] ✅ **User search functionality working** (from your current implementation)
- [ ] ✅ **Firebase project set up** with Authentication + Firestore
- [ ] ✅ **Flutter development environment ready**
- [ ] ✅ **Current app navigation pattern understood**

---

## 🏗️ **IMPLEMENTATION PHASES**

### **Week 1: Friend System Foundation**
- Day 1-2: Data models and Firebase setup
- Day 3-4: Friend request system
- Day 5-7: Friend groups and UI integration

### **Week 2: Online Presence System**  
- Day 1-2: Realtime Database setup and presence service
- Day 3-4: Cloud Functions deployment
- Day 5-7: UI integration and testing

---

## 🔧 **PHASE A: FRIEND SYSTEM FOUNDATION**

### **Step A1: Analyze Your Current App Structure**

**⚠️ CRITICAL FIRST STEP: Study your existing code**

**A1.1: Examine Current Navigation**
```bash
# Find your main navigation implementation
find lib/ -name "*.dart" -exec grep -l "BottomNavigationBar\|TabBar\|drawer" {} \;

# Look for notification or contacts tabs
find lib/ -name "*notification*" -o -name "*contact*" -o -name "*tab*"
```

**A1.2: Understand Current Service Patterns**
```bash
# Find your existing services
find lib/services/ -name "*.dart" | head -10

# Study your user search service
find lib/ -name "*.dart" -exec grep -l "UserSearchService\|ContactSyncService" {} \;
```

**A1.3: Document Your Findings**
Create a note file with:
- Current navigation structure (tabs, routes)
- Existing service patterns (how they're structured)
- Current Firebase collections and documents
- UI theme patterns (colors, fonts, spacing)

### **Step A2: Set Up Firebase Collections**

**A2.1: Plan Your Firestore Structure**

Your new collections will be:
```
users/{userId}/
├── friends/{friendId}           # Friend relationships
├── friend_groups/{groupId}      # User's custom groups
└── friend_requests_sent/{requestId}    # Sent requests
└── friend_requests_received/{requestId} # Received requests

friend_requests/{requestId}      # Global friend requests
status/{userId}                  # Presence status (from Phase B)
```

**A2.2: Update Firestore Rules**

Go to Firebase Console → Firestore Database → Rules, and ADD these rules to your existing ones:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Your existing rules stay here...
    
    // NEW: Friend requests
    match /friend_requests/{requestId} {
      // Users can read requests they sent or received
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.fromUserId || 
         request.auth.uid == resource.data.toUserId);
      
      // Users can create requests they're sending
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.fromUserId;
      
      // Users can update requests they received (accept/decline)
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.toUserId &&
        request.resource.data.keys().hasOnly(['status', 'respondedAt']);
    }

    // NEW: User's friends subcollection
    match /users/{userId}/friends/{friendId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }

    // NEW: User's friend groups
    match /users/{userId}/friend_groups/{groupId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }

    // NEW: Friend request tracking subcollections
    match /users/{userId}/friend_requests_sent/{requestId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }

    match /users/{userId}/friend_requests_received/{requestId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

**A2.3: Test Rules in Firebase Console**

1. Go to Firebase Console → Firestore → Rules
2. Click "Rules playground"
3. Test with your user ID to ensure rules work

### **Step A3: Create Friend System Data Models**

**A3.1: Create the models directory**
```bash
mkdir -p lib/models/friends
```

**A3.2: Create FriendRequest model**

Create `lib/models/friends/friend_request.dart`:

```dart
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
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      fromUserEmail: data['fromUserEmail'] as String,
      fromUserProfileImage: data['fromUserProfileImage'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}
```

**A3.3: Create FriendGroup model**

Create `lib/models/friends/friend_group.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendGroup {
  final String id;
  final String name;
  final String userId;
  final String? description;
  final String iconName;
  final int colorValue;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendGroup({
    required this.id,
    required this.name,
    required this.userId,
    this.description,
    required this.iconName,
    required this.colorValue,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get color as Flutter Color object
  Color get color => Color(colorValue);

  // Predefined group templates
  static List<FriendGroup> getDefaultGroupTemplates(String userId) {
    final now = DateTime.now();
    return [
      FriendGroup(
        id: 'temp_family',
        name: 'Family',
        userId: userId,
        description: 'Family members',
        iconName: 'family_restroom',
        colorValue: Colors.orange.value,
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_school',
        name: 'School',
        userId: userId,
        description: 'School friends and classmates',
        iconName: 'school',
        colorValue: Colors.blue.value,
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_work',
        name: 'Work',
        userId: userId,
        description: 'Work colleagues',
        iconName: 'work',
        colorValue: Colors.green.value,
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
      FriendGroup(
        id: 'temp_close',
        name: 'Close Friends',
        userId: userId,
        description: 'Best friends',
        iconName: 'favorite',
        colorValue: Colors.red.value,
        memberIds: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  factory FriendGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendGroup(
      id: doc.id,
      name: data['name'] as String,
      userId: data['userId'] as String,
      description: data['description'] as String?,
      iconName: data['iconName'] as String,
      colorValue: data['colorValue'] as int,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'description': description,
      'iconName': iconName,
      'colorValue': colorValue,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FriendGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    Color? color,
    List<String>? memberIds,
    DateTime? updatedAt,
  }) {
    return FriendGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorValue: color?.value ?? this.colorValue,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
```

**A3.4: Create Friend model**

Create `lib/models/friends/friend.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String userId;
  final String displayName;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final DateTime friendshipDate;
  final FriendshipStatus status;

  Friend({
    required this.userId,
    required this.displayName,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    required this.friendshipDate,
    required this.status,
  });

  factory Friend.fromFirestore(String friendId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      userId: friendId,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      friendshipDate: (data['friendshipDate'] as Timestamp).toDate(),
      status: FriendshipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => FriendshipStatus.active,
      ),
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
    };
  }
}

enum FriendshipStatus {
  active,
  blocked,
}
```

### **Step A4: Create Friend Management Service**

**A4.1: Create services directory**
```bash
mkdir -p lib/services/friends
```

**A4.2: Create the main FriendService**

Create `lib/services/friends/friend_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/friends/friend_request.dart';
import '../../models/friends/friend_group.dart';
import '../../models/friends/friend.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  // ==================== FRIEND REQUESTS ====================

  /// Send a friend request to another user
  static Future<bool> sendFriendRequest({
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
        targetUserId
      );
      if (existingRequest != null) {
        throw Exception('Friend request already sent');
      }

      // Create the friend request
      final request = FriendRequest(
        id: '',
        fromUserId: currentUserId,
        toUserId: targetUserId,
        fromUserName: currentUser.displayName ?? 'User',
        fromUserEmail: currentUser.email ?? '',
        fromUserProfileImage: currentUser.photoURL,
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

      print('✅ Friend request sent successfully to $targetUserName');
      return true;
    } catch (e) {
      print('❌ Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request
  static Future<bool> acceptFriendRequest(String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the friend request
        final requestDoc = await transaction
            .get(_firestore.collection('friend_requests').doc(requestId));
        
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

        // Create friendship for current user (receiver)
        final currentUserData = _auth.currentUser!;
        final receiverFriendData = Friend(
          userId: request.fromUserId,
          displayName: request.fromUserName,
          email: request.fromUserEmail,
          profileImageUrl: request.fromUserProfileImage,
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('friends')
              .doc(request.fromUserId),
          receiverFriendData.toFirestore(),
        );

        // Create friendship for sender
        final senderFriendData = Friend(
          userId: currentUserId,
          displayName: currentUserData.displayName ?? 'User',
          email: currentUserData.email ?? '',
          profileImageUrl: currentUserData.photoURL,
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
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

      print('✅ Friend request accepted successfully');
      return true;
    } catch (e) {
      print('❌ Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  static Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get the friend request
        final requestDoc = await transaction
            .get(_firestore.collection('friend_requests').doc(requestId));
        
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

      print('✅ Friend request declined');
      return true;
    } catch (e) {
      print('❌ Error declining friend request: $e');
      rethrow;
    }
  }

  // ==================== FRIEND GROUPS ====================

  /// Create a new friend group
  static Future<String> createFriendGroup({
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
        colorValue: color.value,
        memberIds: initialMemberIds ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_groups')
          .add(group.toFirestore());

      print('✅ Friend group "$name" created successfully');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating friend group: $e');
      rethrow;
    }
  }

  /// Create default friend groups for new user
  static Future<void> createDefaultFriendGroups() async {
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
      print('✅ Default friend groups created');
    } catch (e) {
      print('❌ Error creating default groups: $e');
      rethrow;
    }
  }

  /// Add friends to a group
  static Future<bool> addFriendsToGroup({
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

      print('✅ Added ${friendIds.length} friends to group');
      return true;
    } catch (e) {
      print('❌ Error adding friends to group: $e');
      rethrow;
    }
  }

  /// Remove friends from a group
  static Future<bool> removeFriendsFromGroup({
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

      print('✅ Removed ${friendIds.length} friends from group');
      return true;
    } catch (e) {
      print('❌ Error removing friends from group: $e');
      rethrow;
    }
  }

  // ==================== STREAMS FOR REAL-TIME UPDATES ====================

  /// Get stream of received friend requests
  static Stream<List<FriendRequest>> getReceivedFriendRequestsStream() {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  /// Get stream of sent friend requests
  static Stream<List<FriendRequest>> getSentFriendRequestsStream() {
    return _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  /// Get stream of user's friends
  static Stream<List<Friend>> getFriendsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc.id, doc))
            .toList());
  }

  /// Get stream of user's friend groups
  static Stream<List<FriendGroup>> getFriendGroupsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friend_groups')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendGroup.fromFirestore(doc))
            .toList());
  }

  /// Get count of pending received friend requests
  static Stream<int> getPendingRequestsCountStream() {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== HELPER METHODS ====================

  static Future<bool> _checkFriendshipExists(String userId) async {
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

  static Future<FriendRequest?> _checkExistingFriendRequest(
    String fromUserId, 
    String toUserId
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
  static Future<bool> removeFriend(String friendId) async {
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

      print('✅ Friend removed successfully');
      return true;
    } catch (e) {
      print('❌ Error removing friend: $e');
      rethrow;
    }
  }
}
```

### **Step A5: Create Friends UI Components**

**A5.1: Create widgets directory**
```bash
mkdir -p lib/widgets/friends
```

**A5.2: Create FriendRequestTile widget**

Create `lib/widgets/friends/friend_request_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/friends/friend_request.dart';
import '../../services/friends/friend_service.dart';

class FriendRequestTile extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback? onRequestHandled;

  const FriendRequestTile({
    Key? key,
    required this.request,
    this.onRequestHandled,
  }) : super(key: key);

  @override
  State<FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<FriendRequestTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.request.fromUserProfileImage != null
                      ? NetworkImage(widget.request.fromUserProfileImage!)
                      : null,
                  child: widget.request.fromUserProfileImage == null
                      ? Text(
                          widget.request.fromUserName[0].toUpperCase(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.fromUserName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.request.fromUserEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sent ${_getTimeAgo(widget.request.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (widget.request.message != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.request.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _acceptRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Accept'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _declineRequest(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                    child: Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FriendService.acceptFriendRequest(widget.request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRequestHandled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FriendService.declineFriendRequest(widget.request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onRequestHandled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
```

**A5.3: Create FriendTile widget**

Create `lib/widgets/friends/friend_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/friends/friend.dart';

class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOnlineStatus;

  const FriendTile({
    Key? key,
    required this.friend,
    this.onTap,
    this.trailing,
    this.showOnlineStatus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: friend.profileImageUrl != null
                ? NetworkImage(friend.profileImageUrl!)
                : null,
            child: friend.profileImageUrl == null
                ? Text(
                    friend.displayName[0].toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          if (showOnlineStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey, // Will be updated in Phase B
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        friend.displayName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            friend.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (showOnlineStatus) ...[
            SizedBox(height: 2),
            Text(
              'Offline', // Will be updated in Phase B
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
```

### **Step A6: Create Friends Tab Screen**

**A6.1: Create screens directory**
```bash
mkdir -p lib/screens/friends
```

**A6.2: Create main FriendsScreen**

Create `lib/screens/friends/friends_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/friends/friend_request.dart';
import '../../models/friends/friend.dart';
import '../../models/friends/friend_group.dart';
import '../../services/friends/friend_service.dart';
import '../../widgets/friends/friend_request_tile.dart';
import '../../widgets/friends/friend_tile.dart';
import 'add_friends_screen.dart';
import 'friend_groups_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFriendsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendGroupsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Friends',
              icon: Icon(Icons.people),
            ),
            Tab(
              text: 'Requests',
              icon: StreamBuilder<int>(
                stream: FriendService.getPendingRequestsCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      Icon(Icons.inbox),
                      if (count > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Tab(
              text: 'Groups',
              icon: Icon(Icons.folder),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<Friend>>(
      stream: FriendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading friends'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Add friends to start building your network!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Add Friends'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return FriendTile(
              friend: friend,
              showOnlineStatus: true, // Will show presence in Phase B
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleFriendAction(value, friend),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove, color: Colors.red),
                      title: Text('Remove Friend'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: FriendService.getReceivedFriendRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading requests'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friend requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Friend requests will appear here when you receive them.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return FriendRequestTile(
              request: requests[index],
              onRequestHandled: () {
                // Refresh handled automatically by stream
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return StreamBuilder<List<FriendGroup>>(
      stream: FriendService.getFriendGroupsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading groups'));
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friend groups',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Create groups to organize your friends by family, work, school, etc.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createDefaultGroups,
                  icon: Icon(Icons.add),
                  label: Text('Create Default Groups'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: group.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getIconData(group.iconName),
                    color: Colors.white,
                  ),
                ),
                title: Text(group.name),
                subtitle: Text(
                  '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
                ),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to group detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group detail screen coming soon!'),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _handleFriendAction(String action, Friend friend) async {
    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${friend.displayName} from your friends list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await FriendService.removeFriend(friend.userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${friend.displayName} removed from friends'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error removing friend: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  void _createDefaultGroups() async {
    try {
      await FriendService.createDefaultFriendGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default friend groups created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'family_restroom':
        return Icons.family_restroom;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.group;
    }
  }
}
```

### **Step A7: Create Add Friends Screen**

**A7.1: Create AddFriendsScreen**

Create `lib/screens/friends/add_friends_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../services/friends/friend_service.dart';
// Import your existing UserSearchService
// import '../../services/user_search_service.dart';
// import '../../models/user_search_result.dart';

class AddFriendsScreen extends StatefulWidget {
  const AddFriendsScreen({Key? key}) : super(key: key);

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = []; // Replace with your UserSearchResult type
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone number',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          if (_isSearching)
            Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for friends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Enter a name, email, or phone number to find friends',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // TODO: Replace this with your actual search result tiles
    // that integrate with your existing UserSearchService
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        // TODO: Replace this with actual UserSearchResult tile
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('Search Result ${index + 1}'),
            subtitle: Text('This will be replaced with your UserSearchResult'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Implement friend request sending
                _sendFriendRequest('user_id_${index}', 'User Name', 'user@email.com');
              },
              child: Text('Add Friend'),
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _performSearch(query);
  }

  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: Replace this with your actual UserSearchService call
      // final results = await UserSearchService.searchUsers(query: query);
      
      // Simulate search delay
      await Future.delayed(Duration(seconds: 1));
      
      // TODO: Replace with actual results
      final simulatedResults = List.generate(
        3, 
        (index) => 'Search result $index for query: $query'
      );

      if (mounted) {
        setState(() {
          _searchResults = simulatedResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendFriendRequest(String userId, String userName, String userEmail) async {
    try {
      await FriendService.sendFriendRequest(
        targetUserId: userId,
        targetUserName: userName,
        targetUserEmail: userEmail,
        message: 'Hi! I\'d like to add you as a friend.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $userName!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

### **Step A8: Create Friend Groups Screen**

**A8.1: Create FriendGroupsScreen**

Create `lib/screens/friends/friend_groups_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../models/friends/friend_group.dart';
import '../../services/friends/friend_service.dart';

class FriendGroupsScreen extends StatefulWidget {
  const FriendGroupsScreen({Key? key}) : super(key: key);

  @override
  State<FriendGroupsScreen> createState() => _FriendGroupsScreenState();
}

class _FriendGroupsScreenState extends State<FriendGroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<FriendGroup>>(
        stream: FriendService.getFriendGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading groups'));
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No friend groups',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create groups to organize your friends',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FriendService.createDefaultFriendGroups();
                    },
                    icon: Icon(Icons.add),
                    label: Text('Create Default Groups'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: group.color,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _getIconData(group.iconName),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  title: Text(group.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.description != null)
                        Text(group.description!),
                      SizedBox(height: 4),
                      Text(
                        '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleGroupAction(value, group),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Group'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Group'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to group detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group detail screen coming in Phase 2!'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedIcon = 'group';
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Friend Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'group',
                    'family_restroom',
                    'school',
                    'work',
                    'favorite',
                    'sports',
                  ].map((iconName) {
                    final isSelected = selectedIcon == iconName;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = iconName;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconData(iconName),
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.red,
                    Colors.purple,
                    Colors.teal,
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected 
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                        child: isSelected 
                            ? Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a group name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FriendService.createFriendGroup(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    iconName: selectedIcon,
                    color: selectedColor,
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${nameController.text.trim()}" created!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGroupAction(String action, FriendGroup group) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Group'),
          content: Text(
            'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // TODO: Implement group deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group deletion coming soon!'),
          ),
        );
      }
    } else if (action == 'edit') {
      // TODO: Implement group editing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group editing coming soon!'),
        ),
      );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'family_restroom':
        return Icons.family_restroom;
      case 'school':
        return Icons.school;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.group;
    }
  }
}
```

### **Step A9: Integrate Friends Tab into Navigation**

**A9.1: Update your main navigation**

Find your main navigation file (usually something like `lib/screens/main_screen.dart` or similar) and add the Friends tab:

```dart
// In your main navigation screen
import 'screens/friends/friends_screen.dart';

// Add to your screens list
final List<Widget> _screens = [
  DashboardScreen(),      // Your existing screens
  ShoppingListsScreen(),  
  FriendsScreen(),        // NEW: Add this
  NotificationsScreen(),  
  ProfileScreen(),        
];

// Add to your bottom navigation items
BottomNavigationBarItem(
  icon: Stack(
    children: [
      Icon(Icons.people),
      // Show friend request badge
      StreamBuilder<int>(
        stream: FriendService.getPendingRequestsCountStream(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox.shrink();
          
          return Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    ],
  ),
  label: 'Friends',
),
```

### **Step A10: Test Friend System**

**A10.1: Manual Testing Checklist**

1. **Navigation Test**
   - [ ] Friends tab appears in bottom navigation
   - [ ] Friends tab shows notification badge when requests exist
   - [ ] Can navigate to Friends screen

2. **Friend Request Test**
   - [ ] Can search for users in Add Friends screen
   - [ ] Can send friend request
   - [ ] Friend request appears in recipient's Requests tab
   - [ ] Can accept friend request
   - [ ] Can decline friend request

3. **Friends List Test**
   - [ ] Friends appear in Friends tab after acceptance
   - [ ] Can remove friends
   - [ ] Friends list updates in real-time

4. **Friend Groups Test**
   - [ ] Can create default friend groups
   - [ ] Can create custom friend groups
   - [ ] Groups appear in Groups tab

**A10.2: Integration Points to Verify**

- [ ] ✅ Uses existing Firebase project
- [ ] ✅ Follows existing UI theme patterns
- [ ] ✅ Integrates with existing authentication
- [ ] ✅ No conflicts with existing services

---

## 🟢 **PHASE B: ONLINE PRESENCE SYSTEM**

### **Step B1: Enable Firebase Realtime Database**

**B1.1: Enable in Firebase Console**

1. Go to Firebase Console → Your Project
2. Click "Build" → "Realtime Database"
3. Click "Create Database"
4. Choose "Start in test mode" (we'll add rules later)
5. Select your region (same as Firestore for consistency)

**B1.2: Add Realtime Database to Flutter**

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_database: ^10.5.0  # Latest version
  # Your existing dependencies...
```

Run:
```bash
flutter pub get
```

**B1.3: Update Firebase Configuration**

1. Download updated `google-services.json` (Android)
2. Download updated `GoogleService-Info.plist` (iOS)  
3. Replace the existing files in your project

### **Step B2: Create Presence Service**

**B2.1: Create presence service directory**
```bash
mkdir -p lib/services/presence
```

**B2.2: Create PresenceService following Firebase documentation**

Create `lib/services/presence/presence_service.dart`:

```dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static late DatabaseReference _database;
  static StreamSubscription? _presenceSubscription;
  static bool _isInitialized = false;

  /// Initialize presence system - call this after user authentication
  /// CRITICAL: This must be called AFTER user signs in successfully
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔄 Initializing presence service...');
      
      // Step 1: Initialize Firebase Realtime Database reference
      // Note: This creates connection to Realtime Database
      _database = FirebaseDatabase.instance.ref();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Step 2: Set up the presence detection system
      await _setupPresenceListeners(user.uid);
      _isInitialized = true;
      
      print('✅ Presence service initialized for user: ${user.uid}');
    } catch (e) {
      print('❌ Failed to initialize presence service: $e');
      rethrow;
    }
  }

  /// Setup presence listeners following Firebase documentation EXACTLY
  /// This implements the pattern from: https://firebase.google.com/docs/firestore/solutions/presence
  static Future<void> _setupPresenceListeners(String uid) async {
    
    print('🔧 Setting up presence listeners for user: $uid');
    
    // STEP 1: Create references to both databases
    // Following documentation: "Create a reference to this user's specific status node"
    final userStatusDatabaseRef = _database.child('status').child(uid);
    final userStatusFirestoreRef = _firestore.collection('status').doc(uid);

    // STEP 2: Define status objects for both databases
    // Note: Realtime Database and Firestore use different timestamp formats
    
    // For Realtime Database (using ServerValue.timestamp)
    final isOfflineForDatabase = {
      'state': 'offline',
      'last_changed': ServerValue.timestamp,  // Realtime DB timestamp
    };

    final isOnlineForDatabase = {
      'state': 'online', 
      'last_changed': ServerValue.timestamp,  // Realtime DB timestamp
    };

    // For Firestore (using FieldValue.serverTimestamp())
    final isOfflineForFirestore = {
      'state': 'offline',
      'last_changed': FieldValue.serverTimestamp(),  // Firestore timestamp
    };

    final isOnlineForFirestore = {
      'state': 'online',
      'last_changed': FieldValue.serverTimestamp(),  // Firestore timestamp
    };

    // STEP 3: Listen to connection changes using .info/connected
    // This is the KEY part of Firebase presence detection
    print('👂 Starting to listen to .info/connected...');
    
    _presenceSubscription = _database
        .child('.info/connected')  // Special Firebase path for connection status
        .onValue
        .listen((event) async {
      
      // Get connection status from the event
      final connected = event.snapshot.value as bool? ?? false;
      
      print('🔄 Connection status changed: ${connected ? "CONNECTED" : "DISCONNECTED"}');
      
      // STEP 4A: Handle disconnection
      if (!connected) {
        // From documentation: "If we're not currently connected, don't do anything"
        // But we DO update Firestore locally so the app knows it's offline
        print('📱 Setting offline status in Firestore (local cache)');
        try {
          await userStatusFirestoreRef.set(isOfflineForFirestore);
        } catch (e) {
          print('⚠️ Error setting offline status in Firestore: $e');
        }
        return;
      }

      // STEP 4B: Handle connection - This is the critical sequence
      print('🌐 Connected! Setting up disconnect handler and going online...');
      
      try {
        // FIRST: Set up the disconnect handler (this runs server-side when connection drops)
        await userStatusDatabaseRef.onDisconnect().set(isOfflineForDatabase);
        print('✅ Disconnect handler set in Realtime Database');
        
        // SECOND: Set online status in Realtime Database
        await userStatusDatabaseRef.set(isOnlineForDatabase);
        print('✅ Online status set in Realtime Database');
        
        // THIRD: Set online status in Firestore
        await userStatusFirestoreRef.set(isOnlineForFirestore);
        print('✅ Online status set in Firestore');
        
      } catch (e) {
        print('❌ Error in presence setup: $e');
      }
    });
    
    print('✅ Presence listeners setup complete');
  }

  /// Get online friends stream - integrates with friend system
  static Stream<List<String>> getOnlineFriendsStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('status')
        .where('state', isEqualTo: 'online')
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        // Get current user's friends
        final friendsSnapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .get();
        
        final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();
        
        // Filter online users to only include friends
        final onlineUsers = snapshot.docs
            .map((doc) => doc.id)
            .where((userId) => friendIds.contains(userId))
            .toList();
        
        print('👥 Online friends: ${onlineUsers.length}');
        return onlineUsers;
      } catch (e) {
        print('❌ Error getting online friends: $e');
        return <String>[];
      }
    });
  }

  /// Get specific user's online status
  static Stream<UserPresenceStatus> getUserPresenceStream(String userId) {
    return _firestore
        .collection('status')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return UserPresenceStatus.offline();
      }

      final data = snapshot.data()!;
      final state = data['state'] as String;
      final lastChanged = data['last_changed'] as Timestamp?;

      return UserPresenceStatus(
        isOnline: state == 'online',
        lastSeen: lastChanged?.toDate(),
      );
    });
  }

  /// Update user's custom status (optional feature)
  static Future<void> updateCustomStatus({
    String? statusMessage,
    String? statusEmoji,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('status').doc(user.uid).update({
        'customStatus': statusMessage,
        'statusEmoji': statusEmoji,
        'last_changed': FieldValue.serverTimestamp(),
      });
      
      print('✅ Custom status updated');
    } catch (e) {
      print('❌ Failed to update custom status: $e');
    }
  }

  /// Cleanup presence listeners
  static Future<void> dispose() async {
    print('🧹 Cleaning up presence service...');
    
    await _presenceSubscription?.cancel();
    _presenceSubscription = null;
    _isInitialized = false;
    
    print('✅ Presence service cleaned up');
  }

  /// Force set user offline (for logout)
  static Future<void> setOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userStatusFirestoreRef = _firestore.collection('status').doc(user.uid);
      
      await userStatusFirestoreRef.set({
        'state': 'offline',
        'last_changed': FieldValue.serverTimestamp(),
      });
      
      print('✅ User manually set offline');
    } catch (e) {
      print('❌ Error setting user offline: $e');
    }
  }
}

class UserPresenceStatus {
  final bool isOnline;
  final DateTime? lastSeen;
  final String? customStatus;
  final String? statusEmoji;

  UserPresenceStatus({
    required this.isOnline,
    this.lastSeen,
    this.customStatus,
    this.statusEmoji,
  });

  factory UserPresenceStatus.offline() {
    return UserPresenceStatus(isOnline: false);
  }

  String get displayText {
    if (isOnline) return 'Online';
    
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 5) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes} min ago';
      if (difference.inDays < 1) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return 'Last seen ${lastSeen!.day}/${lastSeen!.month}';
    }
    
    return 'Offline';
  }
}
```

### **Step B3: Set Up Cloud Functions for Global Presence Sync**

**B3.1: Initialize Cloud Functions**

```bash
# In your project root directory
npm install -g firebase-tools
firebase init functions

# Choose:
# - Use existing project (your Firebase project)
# - JavaScript or TypeScript (recommend TypeScript)
# - ESLint: Yes
# - Install dependencies: Yes
```

**B3.2: Create Presence Sync Function**

Edit `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK (do this only once)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Get Firestore instance
const db = admin.firestore();

/**
 * MAIN PRESENCE SYNC FUNCTION
 * 
 * From Firebase Documentation:
 * "Use a Cloud Function which watches the status/{uid} path in Realtime Database.
 * When the Realtime Database value changes the value will sync to Cloud Firestore 
 * so that all users' statuses are correct."
 * 
 * This function triggers whenever ANY change happens to /status/{uid} in Realtime Database
 */
export const syncPresenceToFirestore = functions.database
  .ref('/status/{uid}')  // Watch the exact path pattern: /status/{userId}
  .onWrite(async (change, context) => {
    
    // Extract user ID from the path parameters
    const uid = context.params.uid;
    console.log(`🔄 Presence change detected for user: ${uid}`);
    
    // Get the current status from Realtime Database
    const statusSnapshot = change.after;
    
    // CASE 1: Status was deleted (user disconnected completely)
    if (!statusSnapshot.exists()) {
      console.log(`❌ Status deleted for user ${uid}, setting as offline in Firestore`);
      
      try {
        await db.collection('status').doc(uid).set({
          state: 'offline',
          last_changed: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Successfully set user ${uid} as offline in Firestore`);
      } catch (error) {
        console.error(`❌ Failed to set offline status for user ${uid}:`, error);
      }
      return;
    }

    // CASE 2: Status exists, sync it to Firestore
    const status = statusSnapshot.val();
    console.log(`📊 Syncing status for user ${uid}:`, status);
    
    try {
      // Update Firestore with the same state, but use Firestore server timestamp
      await db.collection('status').doc(uid).set({
        state: status.state,  // 'online' or 'offline'
        last_changed: admin.firestore.FieldValue.serverTimestamp(),
        // Optional: Include any custom fields from Realtime DB
        ...(status.customStatus && { customStatus: status.customStatus }),
        ...(status.statusEmoji && { statusEmoji: status.statusEmoji }),
      }, { merge: true });  // Use merge to preserve any Firestore-only fields
      
      console.log(`✅ Successfully synced presence for user ${uid}: ${status.state}`);
    } catch (error) {
      console.error(`❌ Failed to sync presence for user ${uid}:`, error);
    }
  });

/**
 * CLEANUP FUNCTION (Optional but Recommended)
 * 
 * This function runs periodically to clean up old presence data
 * Prevents your database from growing infinitely with old offline statuses
 */
export const cleanupPresenceData = functions.pubsub
  .schedule('every 24 hours')  // Run once per day
  .timeZone('UTC')             // Use UTC timezone
  .onRun(async (context) => {
    console.log('🧹 Starting presence data cleanup...');
    
    // Define cutoff time (30 days ago)
    const cutoffTime = new Date();
    cutoffTime.setDate(cutoffTime.getDate() - 30);
    console.log(`📅 Cleaning up statuses older than: ${cutoffTime.toISOString()}`);

    try {
      // Find old offline statuses
      const oldStatusQuery = await db.collection('status')
        .where('state', '==', 'offline')
        .where('last_changed', '<', cutoffTime)
        .limit(500)  // Process in batches to avoid timeouts
        .get();

      if (oldStatusQuery.empty) {
        console.log('✨ No old presence data to clean up');
        return null;
      }

      // Batch delete old statuses
      const batch = db.batch();
      let count = 0;

      oldStatusQuery.docs.forEach(doc => {
        batch.delete(doc.ref);
        count++;
      });

      await batch.commit();
      console.log(`✅ Successfully cleaned up ${count} old presence records`);
      
      return null;
    } catch (error) {
      console.error('❌ Error during presence cleanup:', error);
      return null;
    }
  });
```

**B3.3: Deploy Cloud Functions**

```bash
cd functions
npm run build     # Compile TypeScript
firebase deploy --only functions

# Check deployment
firebase functions:log
```

### **Step B4: Set Up Database Security Rules**

**B4.1: Configure Realtime Database Rules**

Go to Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    "status": {
      "$uid": {
        // Anyone can read presence status (for friend features)
        ".read": true,
        
        // Only the user can write their own status
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

Click "Publish" to deploy the rules.

**B4.2: Update Firestore Rules**

Add to your existing Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Your existing rules...
    
    // NEW: Presence status
    match /status/{userId} {
      // Anyone can read presence status (needed for friend features)
      allow read: if request.auth != null;
      
      // Only the user can write their own status
      // Also allow Cloud Functions to write (for presence sync)
      allow write: if request.auth != null && 
        (request.auth.uid == userId || 
         request.auth.uid == null); // Allow Cloud Functions
    }
  }
}
```

### **Step B5: Initialize Presence Service in App**

**B5.1: Create App Initializer**

Create `lib/services/app_initializer.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'presence/presence_service.dart';
import 'friends/friend_service.dart';

class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize all services after user authentication
  static Future<void> initializeUserServices() async {
    if (_isInitialized) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ Cannot initialize services: User not authenticated');
        return;
      }

      print('🚀 Initializing user services...');

      // Initialize presence detection
      await PresenceService.initialize();
      
      print('✅ All user services initialized successfully');
      _isInitialized = true;
    } catch (e) {
      