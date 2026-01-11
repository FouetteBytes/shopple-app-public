import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/shopping_lists/shopping_list_model.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/friends/friend_service.dart';
import 'package:shopple/utils/app_logger.dart';

/// Enhanced shopping list service with real-time collaboration features
/// Extends the basic ShoppingListService with Google Docs-style collaboration
class CollaborativeShoppingListService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Share list with collaborators
  static Future<bool> shareList({
    required String listId,
    required List<String> userIds,
    required String role,
    String? message,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    final listRef = _firestore.doc('shopping_lists/$listId');
    final updateData = <String, dynamic>{
      'collaboration.isShared': true,
      'updatedAt': timestamp,
      'lastActivity': timestamp,
      // Denormalized activity for header
      'collaboration.lastActivity': {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'action': 'list_shared',
        'timestamp': timestamp,
        'details': {
          'sharedWith': userIds.length,
          'role': role,
          'message': message,
        },
        'type': 'listShared',
      },
      // Keep a denormalized list of member IDs
      'memberIds': FieldValue.arrayUnion(userIds),
    };

    // For each user, fill collaborator entry and grant rules-backed memberRoles
    for (final userId in userIds) {
      final userDoc = await _firestore.doc('users/$userId').get();
      final userData = userDoc.data() ?? {};
      // Collaboration rich member record
      updateData['collaboration.members.$userId'] = {
        'userId': userId,
        'role': role,
        'joinedAt': timestamp,
        'invitedBy': currentUser.uid,
        'permissions': _getPermissionsForRole(role),
        'displayName': userData['displayName'] ?? 'Unknown',
        'profilePicture': userData['photoURL'],
        'isActive': false,
        'lastActive': timestamp,
      };
      // Security rules rely on memberRoles: grant appropriate minimal role
      updateData['memberRoles.$userId'] = _memberRoleForRules(role);
    }

    batch.update(listRef, updateData);
    await batch.commit();

    // Log activity for each new collaborator
    await _logActivity(listId, 'members_added', {
      'count': userIds.length,
      'role': role,
    });

    return true;
  }

  /// Get real-time collaborative lists stream
  static Stream<List<ShoppingList>> getCollaborativeListsStream(String userId) {
    return _firestore
        .collection('shopping_lists')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final lists = snapshot.docs
              .map((doc) => ShoppingList.fromFirestore(doc))
              .toList();
          lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return lists;
        });
  }

  /// Add item with real-time collaboration tracking
  static Future<String?> addItemWithRealTimeSync({
    required String listId,
    required Map<String, dynamic> itemData,
    bool notifyCollaborators = true,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // Show typing indicator
    await _showTypingIndicator(listId, 'adding_item');

    try {
      final batch = _firestore.batch();

      // Create item with optimistic update support
      final itemRef = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc();

      final itemWithMetadata = {
        ...itemData,
        'id': itemRef.id,
        'listId': listId,
        'addedBy': currentUser.uid,
        'addedAt': FieldValue.serverTimestamp(),
        'version': 1, // For conflict resolution
        'lastModifiedBy': currentUser.uid,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      };

      batch.set(itemRef, itemWithMetadata);

      // Update list metadata
      batch.update(_firestore.doc('shopping_lists/$listId'), {
        'totalItems': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': 'item_added',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {'itemName': itemData['name'], 'itemId': itemRef.id},
          'type': 'itemAdded',
        },
      });

      // Log detailed activity
      if (notifyCollaborators) {
        await _logActivity(listId, 'item_added', {
          'itemId': itemRef.id,
          'itemName': itemData['name'],
          'category': itemData['category'],
          'quantity': itemData['quantity'],
        });
      }

      await batch.commit();

      // Hide typing indicator
      await _hideTypingIndicator(listId);

      return itemRef.id;
    } catch (e) {
      await _hideTypingIndicator(listId);
      rethrow;
    }
  }

  /// Toggle item completion with optimistic updates
  static Future<bool> toggleItemCompletionWithSync({
    required String listId,
    required String itemId,
    required bool isCompleted,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final batch = _firestore.batch();

      // Update item
      batch.update(
        _firestore
            .collection('shopping_lists')
            .doc(listId)
            .collection('items')
            .doc(itemId),
        {
          'isCompleted': isCompleted,
          'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
          'completedBy': isCompleted ? currentUser.uid : null,
          'version': FieldValue.increment(1),
          'lastModifiedBy': currentUser.uid,
          'lastModifiedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update list statistics
      batch.update(_firestore.doc('shopping_lists/$listId'), {
        'completedItems': FieldValue.increment(isCompleted ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': isCompleted ? 'item_completed' : 'item_uncompleted',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {'itemId': itemId},
          'type': isCompleted ? 'itemCompleted' : 'itemEdited',
        },
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Assign item to specific member
  static Future<bool> assignItemToMember({
    required String listId,
    required String itemId,
    required String assignToUserId,
    String? notes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    // Client-side timestamp for array fields (serverTimestamp not allowed in arrays)
    final historyNow = Timestamp.now();

    // Verify assignee access via security rules
    final assigneeDoc = await _firestore.doc('users/$assignToUserId').get();
    final assigneeData = assigneeDoc.data() ?? {};
    batch.update(_firestore.doc('shopping_lists/$listId'), {
      'collaboration.isShared': true,
      'collaboration.members.$assignToUserId': {
        'userId': assignToUserId,
        'role': 'member',
        'joinedAt': timestamp,
        'invitedBy': currentUser.uid,
        'permissions': _getPermissionsForRole('member'),
        'displayName': assigneeData['displayName'] ?? 'Unknown',
        'profilePicture': assigneeData['photoURL'],
        'isActive': false,
        'lastActive': timestamp,
      },
      'memberIds': FieldValue.arrayUnion([assignToUserId]),
      'memberRoles.$assignToUserId': _memberRoleForRules('member'),
    });

    // Create assignment record
    final assignmentData = {
      'itemId': itemId,
      'assignedToUserId': assignToUserId,
      'assignedByUserId': currentUser.uid,
      'assignedAt': timestamp,
      'notes': notes,
      'status': 'assigned',
      'completedAt': null,
      'history': [
        {
          'actionType': 'assigned',
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'timestamp': historyNow,
          'newValue': assignToUserId,
        },
      ],
    };

    // Update list with assignment
    batch.update(_firestore.doc('shopping_lists/$listId'), {
      'collaboration.itemAssignments.$itemId': assignmentData,
      'collaboration.lastActivity': {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'action': 'item_assigned',
        'type': 'itemAssigned',
        'timestamp': timestamp,
        'details': {
          'itemId': itemId,
          'assignedToUserId': assignToUserId,
          'notes': notes,
        },
      },
    });

    // Update item with assignment info
    batch.update(
      _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId),
      {
        'assignedToUserId': assignToUserId,
        'assignedAt': timestamp,
        'assignmentStatus': 'assigned',
        'lastModifiedBy': currentUser.uid,
        'lastModifiedAt': timestamp,
      },
    );

    await batch.commit();

    // Log detailed activity
    await _logActivity(listId, 'item_assigned', {
      'itemId': itemId,
      'assignedToUserId': assignToUserId,
      'assignedByUserId': currentUser.uid,
    });

    return true;
  }

  /// Unassign item from member
  static Future<bool> unassignItem({
    required String listId,
    required String itemId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    final historyNow = Timestamp.now();

    // Append history and mark unassigned (keep history for UI)
    final listRef = _firestore.doc('shopping_lists/$listId');
    final listSnap = await listRef.get();
    final listData = listSnap.data() ?? {};
    final existing =
        (listData['collaboration']?['itemAssignments']
                as Map<String, dynamic>?)?[itemId]
            as Map<String, dynamic>?;
    final history = List<Map<String, dynamic>>.from(
      existing?['history'] ?? const [],
    );
    history.add({
      'actionType': 'unassigned',
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Unknown',
      'timestamp': historyNow,
    });
    batch.update(listRef, {
      'collaboration.itemAssignments.$itemId.history': history,
      'collaboration.itemAssignments.$itemId.status': 'assigned',
      'collaboration.itemAssignments.$itemId.assignedToUserId':
          FieldValue.delete(),
      'collaboration.itemAssignments.$itemId.assignedByUserId':
          FieldValue.delete(),
      'collaboration.itemAssignments.$itemId.assignedAt': FieldValue.delete(),
      'collaboration.itemAssignments.$itemId.completedAt': FieldValue.delete(),
      'collaboration.lastActivity': {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'action': 'item_unassigned',
        'type': 'itemEdited',
        'timestamp': timestamp,
        'details': {'itemId': itemId},
      },
    });

    // Update item to remove assignment info
    batch.update(
      _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId),
      {
        'assignedToUserId': FieldValue.delete(),
        'assignedAt': FieldValue.delete(),
        'assignmentStatus': FieldValue.delete(),
        'lastModifiedBy': currentUser.uid,
        'lastModifiedAt': timestamp,
      },
    );

    await batch.commit();
    return true;
  }

  /// Update assignment notes for an item
  static Future<bool> updateAssignmentNotes({
    required String listId,
    required String itemId,
    String? notes,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final timestamp = FieldValue.serverTimestamp();
    final historyNow = Timestamp.now();

    final listRef = _firestore.doc('shopping_lists/$listId');
    final listSnap = await listRef.get();
    final listData = listSnap.data() ?? {};
    final existing =
        (listData['collaboration']?['itemAssignments']
                as Map<String, dynamic>?)?[itemId]
            as Map<String, dynamic>?;
    final history = List<Map<String, dynamic>>.from(
      existing?['history'] ?? const [],
    );
    history.add({
      'actionType': 'notes_updated',
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Unknown',
      'timestamp': historyNow,
      'newValue': (notes ?? '').toString(),
    });
    await listRef.update({
      'collaboration.itemAssignments.$itemId.notes': notes,
      'collaboration.itemAssignments.$itemId.history': history,
      'collaboration.lastActivity': {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'action': 'assignment_notes_updated',
        'type': 'itemEdited',
        'timestamp': timestamp,
        'details': {
          'itemId': itemId,
          'hasNotes': notes != null && notes.isNotEmpty,
        },
      },
    });

    return true;
  }

  /// Get real-time activity feed for a list
  static Stream<List<ActivityInfo>> getActivityFeedStream(
    String listId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActivityInfo.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get real-time edit history for transparency
  static Stream<List<EditHistoryEntry>> getEditHistoryStream(
    String listId, {
    int limit = 100,
  }) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('edit_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EditHistoryEntry.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get active viewers for Google Docs-style presence
  static Stream<List<ActiveViewer>> getActiveViewersStream(String listId) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('presence')
        .where('isOnline', isEqualTo: true)
        .where(
          'lastSeen',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(Duration(minutes: 5)),
          ),
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ActiveViewer.fromFirestore(doc))
              .toList(),
        );
  }

  /// Update user presence for real-time collaboration
  static Future<void> updatePresence({
    required String listId,
    required String activity,
    String? itemId,
    String? details,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('presence')
        .doc(currentUser.uid)
        .set({
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'activity': activity,
          'itemId': itemId,
          'details': details,
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true));
  }

  /// Remove user presence when leaving the list
  static Future<void> removePresence(String listId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('presence')
          .doc(currentUser.uid)
          .delete();
    } catch (e) {
      // Silently handle errors when removing presence
      AppLogger.w('Error removing presence: $e');
    }
  }

  /// Show typing indicator
  static Future<void> _showTypingIndicator(String listId, String action) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await updatePresence(listId: listId, activity: action);
  }

  /// Hide typing indicator
  static Future<void> _hideTypingIndicator(String listId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await updatePresence(listId: listId, activity: 'viewing');
  }

  /// Mark assigned item as completed by the assigned member (or editors)
  static Future<bool> completeAssignedItem({
    required String listId,
    required String itemId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final listRef = _firestore.doc('shopping_lists/$listId');
      final listSnap = await listRef.get();
      final listData = listSnap.data() ?? <String, dynamic>{};
      final assignments =
          (listData['collaboration']?['itemAssignments']
              as Map<String, dynamic>?) ??
          {};
      final assignment = assignments[itemId] as Map<String, dynamic>?;
      if (assignment == null) return false;

      final assignedToUserId = assignment['assignedToUserId'] as String?;
      final memberRoles = Map<String, dynamic>.from(
        listData['memberRoles'] ?? const {},
      );
      final role = (memberRoles[currentUser.uid] as String?) ?? 'viewer';
      final canEdit = role == 'editor';
      if (assignedToUserId != currentUser.uid && !canEdit) return false;

      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();
      final historyNow = Timestamp.now();

      // Update assignment status on list and append history
      final listSnap2 = await listRef.get();
      final listData2 = listSnap2.data() ?? {};
      final existing2 =
          (listData2['collaboration']?['itemAssignments']
                  as Map<String, dynamic>?)?[itemId]
              as Map<String, dynamic>?;
      final history2 = List<Map<String, dynamic>>.from(
        existing2?['history'] ?? const [],
      );
      history2.add({
        'actionType': 'completed',
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'timestamp': historyNow,
      });
      batch.update(listRef, {
        'collaboration.itemAssignments.$itemId.status': 'completed',
        'collaboration.itemAssignments.$itemId.completedAt': timestamp,
        'collaboration.itemAssignments.$itemId.history': history2,
        'completedItems': FieldValue.increment(1),
        'updatedAt': timestamp,
        'lastActivity': timestamp,
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': 'assigned_item_completed',
          'type': 'itemCompleted',
          'timestamp': timestamp,
          'details': {'itemId': itemId},
        },
      });

      // Update the item document itself
      final itemRef = listRef.collection('items').doc(itemId);
      batch.update(itemRef, {
        'isCompleted': true,
        'completedAt': timestamp,
        'completedBy': currentUser.uid,
        'assignmentStatus': 'completed',
        'version': FieldValue.increment(1),
        'lastModifiedBy': currentUser.uid,
        'lastModifiedAt': timestamp,
      });

      await batch.commit();

      // Log activity for feed
      await _logActivity(listId, 'item_completed', {
        'itemId': itemId,
        'completedVia': 'assignment',
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove a collaborator from a shared list (admin/owner only as enforced by rules)
  static Future<bool> removeCollaborator({
    required String listId,
    required String userId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final listRef = _firestore.doc('shopping_lists/$listId');
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      batch.update(listRef, {
        'collaboration.members.$userId': FieldValue.delete(),
        'memberRoles.$userId': FieldValue.delete(),
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': timestamp,
        'lastActivity': timestamp,
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': 'member_removed',
          'type': 'memberRemoved',
          'timestamp': timestamp,
          'details': {'removedUserId': userId},
        },
      });

      batch.update(listRef.collection('presence').doc(userId), {
        'isOnline': false,
      });

      await batch.commit();

      await _logActivity(listId, 'member_removed', {'removedUserId': userId});

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Log activity for collaboration transparency
  static Future<void> _logActivity(
    String listId,
    String action,
    Map<String, dynamic> details,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final activityRef = _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('activities')
        .doc();

    await activityRef.set({
      'id': activityRef.id,
      'listId': listId,
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Unknown',
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Track edit history for transparency (lite)
  static Future<void> _trackEditHistory({
    required String listId,
    required String itemId,
    required String field,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final historyRef = _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('edit_history')
        .doc();
    await historyRef.set({
      'id': historyRef.id,
      'listId': listId,
      'itemId': itemId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'editedBy': currentUser.uid,
      'editedByName': currentUser.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Update an item with simple conflict detection via version number
  static Future<bool> updateItemWithConflictResolution({
    required String listId,
    required String itemId,
    required Map<String, dynamic> updates,
    required int expectedVersion,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    try {
      final itemRef = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(itemRef);
        final data = Map<String, dynamic>.from(snap.data() ?? {});
        final currentVersion = (data['version'] as int?) ?? 0;
        if (currentVersion != expectedVersion) {
          throw StateError('Version conflict');
        }
        // Track changes
        for (final e in updates.entries) {
          if (data[e.key] != e.value) {
            await _trackEditHistory(
              listId: listId,
              itemId: itemId,
              field: e.key,
              oldValue: data[e.key],
              newValue: e.value,
            );
          }
        }
        tx.update(itemRef, {
          ...updates,
          'version': currentVersion + 1,
          'lastModifiedBy': currentUser.uid,
          'lastModifiedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream items assigned to a specific user within a list
  static Stream<List<ShoppingListItem>> getAssignedItemsStream({
    required String listId,
    required String userId,
  }) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('items')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('assignedAt')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ShoppingListItem.fromFirestore(d)).toList(),
        );
  }

  /// Get permissions for role
  static Map<String, bool> _getPermissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return {
          'canEdit': true,
          'canInvite': true,
          'canDelete': true,
          'canManageMembers': true,
          'canViewActivity': true,
          'canAssignItems': true,
          'canManageRoles': true,
          'canViewEditHistory': true,
        };
      case 'admin':
        return {
          'canEdit': true,
          'canInvite': true,
          'canDelete': false,
          'canManageMembers': true,
          'canViewActivity': true,
          'canAssignItems': true,
          'canManageRoles': false,
          'canViewEditHistory': true,
        };
      case 'member':
        return {
          'canEdit': true,
          'canInvite': false,
          'canDelete': false,
          'canManageMembers': false,
          'canViewActivity': true,
          'canAssignItems': false,
          'canManageRoles': false,
          'canViewEditHistory': false,
        };
      case 'viewer':
        return {
          'canEdit': false,
          'canInvite': false,
          'canDelete': false,
          'canManageMembers': false,
          'canViewActivity': true,
          'canAssignItems': false,
          'canManageRoles': false,
          'canViewEditHistory': false,
        };
      default:
        return {
          'canEdit': false,
          'canInvite': false,
          'canDelete': false,
          'canManageMembers': false,
          'canViewActivity': false,
          'canAssignItems': false,
          'canManageRoles': false,
          'canViewEditHistory': false,
        };
    }
  }

  /// Map rich collaboration roles to Firestore security roles
  static String _memberRoleForRules(String role) {
    switch (role.toLowerCase()) {
      case 'viewer':
        return 'viewer';
      case 'editor':
        return 'editor';
      case 'admin':
      case 'member':
      case 'owner': // do not reassign true ownership, but for rules treat as editor
        return 'editor';
      default:
        return 'viewer';
    }
  }

  /// Integrate with existing friends system
  static Future<List<Map<String, dynamic>>> getAvailableFriendsForList(
    String listId,
  ) async {
    try {
      // Get current collaborators to exclude them
      final listDoc = await _firestore.doc('shopping_lists/$listId').get();
      final listData = listDoc.data() ?? {};
      final currentCollaborators = Set<String>.from(
        (listData['collaboration']?['members'] as Map<String, dynamic>?)
                ?.keys ??
            [],
      );

      // Get user's friends
      final friendsStream = FriendService.getFriendsStream();
      final friends = await friendsStream.first;

      // Filter out existing collaborators
      final availableFriends = friends
          .where((friend) => !currentCollaborators.contains(friend.userId))
          .map(
            (friend) => {
              'userId': friend.userId,
              'displayName': friend.displayName,
              'email': friend.email,
              'profileImageUrl': friend.profileImageUrl,
            },
          )
          .toList();

      return availableFriends;
    } catch (e) {
      AppLogger.e('Error getting available friends: $e');
      return [];
    }
  }
}

/// Helper class for active viewer presence
class ActiveViewer {
  final String userId;
  final String displayName;
  final String? profilePicture;
  final String currentActivity; // 'viewing', 'editing', 'adding_item'
  final DateTime lastSeen;
  final String? activeItemId; // Which item they're currently editing

  ActiveViewer({
    required this.userId,
    required this.displayName,
    this.profilePicture,
    required this.currentActivity,
    required this.lastSeen,
    this.activeItemId,
  });

  factory ActiveViewer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ActiveViewer(
      userId: doc.id,
      displayName: data['userName'] ?? 'Unknown',
      currentActivity: data['activity'] ?? 'viewing',
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activeItemId: data['itemId'],
    );
  }
}

/// Lightweight edit history entry for list collaboration transparency
class EditHistoryEntry {
  final String id;
  final String listId;
  final String itemId;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final String editedBy;
  final String editedByName;
  final DateTime timestamp;

  EditHistoryEntry({
    required this.id,
    required this.listId,
    required this.itemId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.editedBy,
    required this.editedByName,
    required this.timestamp,
  });

  factory EditHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EditHistoryEntry(
      id: data['id'] ?? doc.id,
      listId: data['listId'] ?? '',
      itemId: data['itemId'] ?? '',
      field: data['field'] ?? '',
      oldValue: data['oldValue'],
      newValue: data['newValue'],
      editedBy: data['editedBy'] ?? '',
      editedByName: data['editedByName'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
