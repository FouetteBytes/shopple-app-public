# Collaborative Shopping Lists Implementation Guide
**GitHub Copilot Instructions for State-of-the-Art Real-Time Collaboration**

## 🔍 **MANDATORY FIRST STEP: COMPREHENSIVE CODEBASE ANALYSIS**

### **CRITICAL INSTRUCTION: READ AND UNDERSTAND BEFORE CODING**

Before implementing any collaborative features, you MUST thoroughly analyze the existing Shopple app infrastructure:

**Step 1: Study Current Shopping List Implementation**
```bash
# Read these files completely and understand their patterns:
lib/services/shopping_lists/shopping_list_service.dart
lib/services/shopping_lists/shopping_list_cache.dart  
lib/models/shopping_lists/shopping_list_model.dart
lib/models/shopping_lists/shopping_list_item_model.dart
lib/widgets/shopping_lists/multi_add_to_lists_sheet.dart

# Understand current Firebase integration:
lib/services/auth/auth_service.dart
lib/services/user/user_profile_service.dart

# Study existing UI patterns:
lib/Screens/modern_product_details_screen.dart
lib/widgets/
lib/Values/values.dart
```

**Step 2: Document Current Architecture**
Create a comprehensive analysis document covering:
- Current Firebase collections structure
- Existing CRUD operations and their patterns
- Current state management approach (caching, real-time streams)
- UI component patterns and styling system
- Error handling and performance optimization patterns
- Current user authentication and profile management

**Step 3: Identify Enhancement Points**
- Where collaboration features should integrate
- Which existing methods to extend vs create new ones
- How to maintain backward compatibility
- Performance implications of real-time features

---

## 🏗️ **IMPLEMENTATION PRINCIPLES**

### **CRITICAL RULES - FOLLOW EXACTLY:**

1. **ENHANCE, DON'T REPLACE**: Extend existing `ShoppingListService`, `ShoppingList` model, and UI components
2. **PRESERVE FUNCTIONALITY**: All current shopping list features must continue working
3. **FOLLOW EXISTING PATTERNS**: Use same coding style, naming conventions, and architecture
4. **MAINTAIN PERFORMANCE**: Build on existing caching system and optimization patterns
5. **USE EXISTING UI SYSTEM**: Follow current `GoogleFonts.inter()`, `AppColors`, and widget patterns

---

## 📦 **DEPENDENCIES SETUP**

### **Step 1: Add Required Packages**
Add these to your existing `pubspec.yaml` (DO NOT remove existing packages):

```yaml
dependencies:
  # ... keep ALL existing dependencies ...
  
  # ADD these new ones for collaboration:
  firebase_database: ^10.5.7           # For real-time presence detection
  animated_reorderable_list: ^1.0.5    # For advanced drag-and-drop
  flutter_slidable: ^3.0.1            # For swipe actions
  animations: ^2.0.7                  # For smooth transitions
```

### **Step 2: Firebase Realtime Database Setup**
1. Enable Realtime Database in Firebase Console
2. Set initial rules to test mode:
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

---

## 📡 **PHASE 1: ANALYZE EXISTING PRESENCE SYSTEM**

### **CRITICAL FIRST STEP: Study Your Current Presence Implementation**

**INSTRUCTION**: You already have a presence detection system. Before implementing any new features, you MUST:

1. **Find and Analyze Current Presence System:**
```bash
# Search for existing presence-related files:
find lib/ -name "*.dart" -exec grep -l "presence\|online\|offline\|activity" {} \;
find lib/services/ -name "*presence*" -o -name "*activity*" -o -name "*online*"
grep -r "user_presence\|userPresence" lib/
grep -r "currentActivity\|current_activity" lib/
```

2. **Document Current Implementation:**
- How is presence currently tracked?
- What collections/documents are used?
- How are online/offline states managed?
- What activity tracking exists?
- How is real-time sync implemented?

3. **Identify Integration Points:**
- Which services handle presence updates?
- How can we extend for shopping list collaboration?
- What data structures are already in place?
- How can we enhance without breaking current functionality?

### **Step 1.1: Extend Existing Presence System for Shopping Lists**

**INSTRUCTION**: Based on your analysis of the existing presence system, EXTEND it with shopping list collaboration features:

```dart
// FIND your existing presence service and ADD these methods:

/// Update activity context for shopping list collaboration
static Future<void> updateShoppingListActivity({
  required String listId,
  required String activity,
  String? itemId,
  String? details,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  // Use your existing presence update method and extend it
  await [YourExistingPresenceService].updateActivity({
    'type': 'shopping_list',
    'listId': listId,
    'activity': activity,
    'itemId': itemId,
    'details': details,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

/// Get active viewers for a specific shopping list (Google Docs style)
static Stream<List<ActiveViewer>> getActiveViewersStream(String listId) {
  // Build on your existing presence queries
  return [YourExistingPresenceCollection]
      .where('currentActivity.type', isEqualTo: 'shopping_list')
      .where('currentActivity.listId', isEqualTo: listId)
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ActiveViewer.fromFirestore(doc))
          .toList());
}
```

### **Step 1.2: Google Docs-Style Active Viewer System**

**INSTRUCTION**: Implement active viewer avatars using your existing presence infrastructure:

```dart
class ActiveViewer {
  final String userId;
  final String displayName;
  final String? profilePicture;
  final String currentActivity; // 'viewing', 'editing', 'adding_item'
  final DateTime lastSeen;
  final String? activeItemId; // Which item they're currently editing
  
  // Build from your existing presence data structure
  factory ActiveViewer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final activityData = data['currentActivity'] as Map<String, dynamic>? ?? {};
    
    return ActiveViewer(
      userId: doc.id,
      displayName: data['displayName'] ?? 'Unknown',
      profilePicture: data['profilePicture'],
      currentActivity: activityData['activity'] ?? 'viewing',
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activeItemId: activityData['itemId'],
    );
  }
}

---

## 🤝 **PHASE 2: COLLABORATIVE SHOPPING LIST FEATURES**

### **Research References:**
Study these real-time collaboration patterns:
- Google Docs collaboration architecture
- Firebase real-time best practices
- Operational Transform algorithms
- Optimistic UI patterns

### **Step 2.1: Extend Current ShoppingList Model with Friend Assignment System**

**INSTRUCTION**: Open `lib/models/shopping_lists/shopping_list_model.dart` and ADD collaboration fields:

```dart
// FIND your existing ShoppingList class and ADD these fields:
class ShoppingList {
  // ... keep all existing fields exactly as they are ...
  
  // ADD collaboration fields
  final bool isShared;
  final Map<String, CollaboratorInfo> collaborators;
  final Map<String, InviteInfo> pendingInvites;
  final List<String> authorizedGroupIds;
  final ActivityInfo? lastActivity;
  final CollaborationSettings settings;
  final Map<String, ItemAssignment> itemAssignments; // NEW: Item assignments
  
  // UPDATE constructor to include new fields
  ShoppingList({
    // ... keep all existing parameters ...
    
    // ADD new parameters with defaults
    this.isShared = false,
    this.collaborators = const {},
    this.pendingInvites = const {},
    this.authorizedGroupIds = const [],
    this.lastActivity,
    this.settings = const CollaborationSettings(),
    this.itemAssignments = const {}, // NEW
  });
  
  // UPDATE fromFirestore method
  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get existing metadata
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    
    // Get new collaboration data
    final collaboration = data['collaboration'] as Map<String, dynamic>? ?? {};
    
    return ShoppingList(
      // ... keep all existing field mappings ...
      
      // ADD collaboration mappings
      isShared: collaboration['isShared'] ?? false,
      collaborators: _parseCollaborators(collaboration['members'] ?? {}),
      pendingInvites: _parseInvites(collaboration['pendingInvites'] ?? {}),
      authorizedGroupIds: List<String>.from(collaboration['authorizedGroups'] ?? []),
      lastActivity: collaboration['lastActivity'] != null 
          ? ActivityInfo.fromMap(collaboration['lastActivity']) 
          : null,
      settings: CollaborationSettings.fromMap(collaboration['settings'] ?? {}),
      itemAssignments: _parseItemAssignments(collaboration['itemAssignments'] ?? {}), // NEW
    );
  }
}

// ADD helper classes for collaboration with role-based permissions
class CollaboratorInfo {
  final String userId;
  final String role; // 'owner', 'admin', 'member', 'viewer'
  final DateTime joinedAt;
  final String invitedBy;
  final CollaboratorPermissions permissions;
  final String displayName;
  final String? profilePicture;
  final bool isActive; // Currently viewing the list
  final DateTime? lastActive;
  
  // Constructor and fromMap/toMap methods...
}

class CollaboratorPermissions {
  final bool canEdit;
  final bool canInvite;
  final bool canDelete;
  final bool canManageMembers;
  final bool canViewActivity;
  final bool canAssignItems; // NEW: Can assign items to members
  final bool canManageRoles; // NEW: Can change member roles
  final bool canViewEditHistory; // NEW: Can see edit history
  
  // Factory methods for different roles
  factory CollaboratorPermissions.owner() => CollaboratorPermissions(
    canEdit: true, canInvite: true, canDelete: true, 
    canManageMembers: true, canViewActivity: true,
    canAssignItems: true, canManageRoles: true, canViewEditHistory: true,
  );
  
  factory CollaboratorPermissions.admin() => CollaboratorPermissions(
    canEdit: true, canInvite: true, canDelete: false, 
    canManageMembers: true, canViewActivity: true,
    canAssignItems: true, canManageRoles: false, canViewEditHistory: true,
  );
  
  factory CollaboratorPermissions.member() => CollaboratorPermissions(
    canEdit: true, canInvite: false, canDelete: false, 
    canManageMembers: false, canViewActivity: true,
    canAssignItems: false, canManageRoles: false, canViewEditHistory: false,
  );
  
  factory CollaboratorPermissions.viewer() => CollaboratorPermissions(
    canEdit: false, canInvite: false, canDelete: false, 
    canManageMembers: false, canViewActivity: true,
    canAssignItems: false, canManageRoles: false, canViewEditHistory: false,
  );
}

// NEW: Item assignment system
class ItemAssignment {
  final String itemId;
  final String assignedToUserId;
  final String assignedByUserId;
  final DateTime assignedAt;
  final String? notes;
  final AssignmentStatus status; // 'assigned', 'in_progress', 'completed'
  final DateTime? completedAt;
  final List<AssignmentHistoryEntry> history;
  
  ItemAssignment({
    required this.itemId,
    required this.assignedToUserId,
    required this.assignedByUserId,
    required this.assignedAt,
    this.notes,
    this.status = AssignmentStatus.assigned,
    this.completedAt,
    this.history = const [],
  });
}

enum AssignmentStatus { assigned, inProgress, completed }

class AssignmentHistoryEntry {
  final String actionType; // 'assigned', 'reassigned', 'completed', 'notes_updated'
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String? previousValue;
  final String? newValue;
  
  // Constructor and serialization methods...
}

class ActivityInfo {
  final String userId;
  final String userName;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> details;
  final ActivityType type; // NEW: Categorize activities
  
  ActivityInfo({
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
    required this.details,
    required this.type,
  });
}

enum ActivityType {
  itemAdded,
  itemEdited,
  itemCompleted,
  itemAssigned,
  itemReassigned,
  memberAdded,
  memberRemoved,
  roleChanged,
  listShared,
  listEdited,
}
```

### **Step 2.2: Extend Current ShoppingListService**

**INSTRUCTION**: Open `lib/services/shopping_lists/shopping_list_service.dart` and ADD these methods:

```dart
// ADD these imports
import 'dart:async';
import '../auth/auth_service.dart';

// ADD these methods to your existing ShoppingListService class
class ShoppingListService {
  // ... keep all existing code exactly as is ...
  
  /// Share list with collaborators
  static Future<bool> shareList({
    required String listId,
    required List<String> userIds,
    required String role,
    String? message,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    
    // Add collaborators to list
    for (final userId in userIds) {
      // Get user info for denormalization
      final userDoc = await _firestore.doc('users/$userId').get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      
      batch.update(_firestore.doc('shopping_lists/$listId'), {
        'collaboration.isShared': true,
        'collaboration.members.$userId': {
          'role': role,
          'joinedAt': timestamp,
          'invitedBy': currentUser.uid,
          'permissions': _getPermissionsForRole(role),
          'displayName': userData['displayName'] ?? 'Unknown',
          'profilePicture': userData['photoURL'],
        },
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
        },
      });
    }
    
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
        .where('collaboration.members.$userId', isNotEqualTo: null)
        .orderBy('metadata.updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingList.fromFirestore(doc))
            .toList());
  }
  
  /// Add item with real-time collaboration tracking
  static Future<String?> addItemWithRealTimeSync({
    required String listId,
    required Map<String, dynamic> itemData,
    bool notifyCollaborators = true,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
        'metadata.itemCount': FieldValue.increment(1),
        'metadata.updatedAt': FieldValue.serverTimestamp(),
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': 'item_added',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {
            'itemName': itemData['name'],
            'itemId': itemRef.id,
          },
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
    final currentUser = FirebaseAuth.instance.currentUser;
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
        'metadata.completedCount': FieldValue.increment(isCompleted ? 1 : -1),
        'metadata.updatedAt': FieldValue.serverTimestamp(),
        'collaboration.lastActivity': {
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? 'Unknown',
          'action': isCompleted ? 'item_completed' : 'item_uncompleted',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {'itemId': itemId},
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    
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
          'timestamp': timestamp,
          'newValue': assignToUserId,
        }
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
  
  /// Mark assigned item as completed by assigned member
  static Future<bool> completeAssignedItem({
    required String listId,
    required String itemId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // Verify user is assigned to this item or has permission
    final listDoc = await _firestore.doc('shopping_lists/$listId').get();
    final listData = listDoc.data() as Map<String, dynamic>? ?? {};
    final assignments = listData['collaboration']?['itemAssignments'] as Map<String, dynamic>? ?? {};
    final assignment = assignments[itemId] as Map<String, dynamic>?;
    
    if (assignment == null) return false;
    
    final assignedToUserId = assignment['assignedToUserId'] as String?;
    final hasPermission = assignedToUserId == currentUser.uid || 
                         _hasEditPermission(listData, currentUser.uid);
    
    if (!hasPermission) return false;
    
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    
    // Update assignment status
    batch.update(_firestore.doc('shopping_lists/$listId'), {
      'collaboration.itemAssignments.$itemId.status': 'completed',
      'collaboration.itemAssignments.$itemId.completedAt': timestamp,
      'collaboration.lastActivity': {
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Unknown',
        'action': 'assigned_item_completed',
        'type': 'itemCompleted',
        'timestamp': timestamp,
        'details': {'itemId': itemId},
      },
    });
    
    // Mark item as completed
    batch.update(
      _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId),
      {
        'isCompleted': true,
        'completedAt': timestamp,
        'completedBy': currentUser.uid,
        'assignmentStatus': 'completed',
      },
    );
    
    await batch.commit();
    return true;
  }
  
  /// Get items assigned to specific user
  static Stream<List<ShoppingListItem>> getAssignedItemsStream({
    required String listId,
    required String userId,
  }) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('items')
        .where('assignedToUserId', isEqualTo: userId)
        .orderBy('assignedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingListItem.fromFirestore(doc))
            .toList());
  }
  
  /// Integrate with existing friends system
  static Future<List<Map<String, dynamic>>> getAvailableFriendsForList(String listId) async {
    // This should integrate with your existing friends system
    // Find your existing friends service and use it here
    
    // Example integration pattern:
    // final friends = await YourExistingFriendsService.getUserFriends();
    // final currentCollaborators = await _getCurrentCollaborators(listId);
    // return friends.where((friend) => !currentCollaborators.contains(friend.id));
    
    // For now, return empty list - replace with your actual friends integration
    return [];
  }
  
  /// Get real-time edit history for transparency
  static Stream<List<EditHistoryEntry>> getEditHistoryStream(String listId) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('edit_history')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EditHistoryEntry.fromFirestore(doc))
            .toList());
  }
  
  /// Track edit history for advanced collaboration features
  static Future<void> _trackEditHistory({
    required String listId,
    required String itemId,
    required String field,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
      'changeType': _getChangeType(oldValue, newValue),
    });
  }
  
  /// Advanced conflict resolution for simultaneous edits
  static Future<bool> updateItemWithConflictResolution({
    required String listId,
    required String itemId,
    required Map<String, dynamic> updates,
    required int expectedVersion,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    try {
      final itemRef = _firestore
          .collection('shopping_lists')
          .doc(listId)
          .collection('items')
          .doc(itemId);
      
      // Use transaction for conflict detection
      await _firestore.runTransaction((transaction) async {
        final itemDoc = await transaction.get(itemRef);
        final currentData = itemDoc.data() as Map<String, dynamic>? ?? {};
        final currentVersion = currentData['version'] as int? ?? 0;
        
        // Check for conflicts
        if (currentVersion != expectedVersion) {
          throw ConflictException('Item was modified by another user');
        }
        
        // Track edit history for each field change
        for (final entry in updates.entries) {
          if (currentData[entry.key] != entry.value) {
            await _trackEditHistory(
              listId: listId,
              itemId: itemId,
              field: entry.key,
              oldValue: currentData[entry.key],
              newValue: entry.value,
            );
          }
        }
        
        // Apply updates with version increment
        final updatedData = {
          ...updates,
          'version': currentVersion + 1,
          'lastModifiedBy': currentUser.uid,
          'lastModifiedAt': FieldValue.serverTimestamp(),
        };
        
        transaction.update(itemRef, updatedData);
      });
      
      return true;
    } on ConflictException {
      // Handle conflict - could show conflict resolution dialog
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get real-time activity feed for a list
  static Stream<List<ActivityInfo>> getActivityFeedStream(String listId, {int limit = 50}) {
    return _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityInfo.fromFirestore(doc))
            .toList());
  }
  
  /// Show typing indicator
  static Future<void> _showTypingIndicator(String listId, String action) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    await _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('presence')
        .doc(currentUser.uid)
        .set({
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Unknown',
      'currentAction': action,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  /// Hide typing indicator
  static Future<void> _hideTypingIndicator(String listId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    await _firestore
        .collection('shopping_lists')
        .doc(listId)
        .collection('presence')
        .doc(currentUser.uid)
        .update({
      'currentAction': 'browsing',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  /// Log activity for collaboration transparency
  static Future<void> _logActivity(
    String listId, 
    String action, 
    Map<String, dynamic> details
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
  
  /// Get permissions for role
  static Map<String, bool> _getPermissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return {'canEdit': true, 'canInvite': true, 'canDelete': true, 'canManageMembers': true, 'canViewActivity': true};
      case 'editor':
        return {'canEdit': true, 'canInvite': true, 'canDelete': false, 'canManageMembers': false, 'canViewActivity': true};
      case 'viewer':
        return {'canEdit': false, 'canInvite': false, 'canDelete': false, 'canManageMembers': false, 'canViewActivity': true};
      default:
        return {'canEdit': false, 'canInvite': false, 'canDelete': false, 'canManageMembers': false, 'canViewActivity': false};
    }
  }
}

// ADD helper classes
class CollaboratorPresence {
  final String userId;
  final String displayName;
  final String? profilePicture;
  final bool isOnline;
  final String currentActivity;
  final String? activeListId;
  final DateTime? lastSeen;
  
  CollaboratorPresence({
    required this.userId,
    required this.displayName,
    this.profilePicture,
    required this.isOnline,
    required this.currentActivity,
    this.activeListId,
    this.lastSeen,
  });
}
```

---

## 🎨 **PHASE 3: OPTIMISTIC UPDATES & CONFLICT RESOLUTION**

### **Research References:**
- Operational Transform algorithms
- Google's real-time collaboration patterns
- Firebase optimistic updates best practices

### **Step 3.1: Create Optimistic Update Controller**

**INSTRUCTION**: Create new file `lib/controllers/optimistic_update_controller.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/shopping_lists/shopping_list_item_model.dart';
import '../services/shopping_lists/shopping_list_service.dart';

class OptimisticUpdateController extends ChangeNotifier {
  final Map<String, ShoppingListItem> _pendingUpdates = {};
  final Map<String, Timer> _updateTimers = {};
  final Map<String, int> _retryCounters = {};
  
  /// Add item optimistically with automatic rollback on failure
  Future<void> addItemOptimistically({
    required String listId,
    required ShoppingListItem item,
    required Function(ShoppingListItem) onLocalAdd,
    required Function(String) onLocalRemove,
  }) async {
    final operationId = '${listId}_${item.id}_add';
    
    try {
      // 1. Apply change locally immediately
      onLocalAdd(item);
      _pendingUpdates[operationId] = item;
      
      // 2. Set timeout for rollback
      _updateTimers[operationId] = Timer(Duration(seconds: 10), () {
        _rollbackOperation(operationId, onLocalRemove);
      });
      
      // 3. Attempt server sync
      final result = await ShoppingListService.addItemWithRealTimeSync(
        listId: listId,
        itemData: item.toFirestore(),
      );
      
      if (result != null) {
        // 4. Success: clean up pending state
        _cleanupOperation(operationId);
      } else {
        // 5. Failure: rollback
        _rollbackOperation(operationId, onLocalRemove);
      }
    } catch (e) {
      // 6. Error: rollback with retry option
      _rollbackOperationWithRetry(operationId, listId, item, onLocalRemove, onLocalAdd);
    }
  }
  
  /// Update item with conflict resolution
  Future<void> updateItemOptimistically({
    required String listId,
    required String itemId,
    required Map<String, dynamic> updates,
    required Function(String, Map<String, dynamic>) onLocalUpdate,
    required Function(String) onRollback,
  }) async {
    final operationId = '${listId}_${itemId}_update';
    
    try {
      // Apply locally first
      onLocalUpdate(itemId, updates);
      _pendingUpdates[operationId] = ShoppingListItem.fromFirestore({
        'id': itemId,
        'listId': listId,
        ...updates,
      } as DocumentSnapshot);
      
      // Sync to server with version checking for conflict detection
      final success = await ShoppingListService.updateItemWithVersionControl(
        listId: listId,
        itemId: itemId,
        updates: updates,
      );
      
      if (success) {
        _cleanupOperation(operationId);
      } else {
        _rollbackOperation(operationId, () => onRollback(itemId));
      }
    } catch (e) {
      _rollbackOperation(operationId, () => onRollback(itemId));
    }
  }
  
  void _rollbackOperation(String operationId, Function onRollback) {
    onRollback();
    _cleanupOperation(operationId);
    
    // Show user-friendly error
    _showErrorMessage('Update failed. Please try again.');
  }
  
  void _rollbackOperationWithRetry(
    String operationId,
    String listId,
    ShoppingListItem item,
    Function(String) onLocalRemove,
    Function(ShoppingListItem) onLocalAdd,
  ) {
    final retryCount = _retryCounters[operationId] ?? 0;
    
    if (retryCount < 3) {
      _retryCounters[operationId] = retryCount + 1;
      
      // Show retry option
      _showRetryDialog(
        message: 'Failed to sync changes. Retry?',
        onRetry: () => addItemOptimistically(
          listId: listId,
          item: item,
          onLocalAdd: onLocalAdd,
          onLocalRemove: onLocalRemove,
        ),
        onCancel: () => _rollbackOperation(operationId, () => onLocalRemove(item.id)),
      );
    } else {
      _rollbackOperation(operationId, () => onLocalRemove(item.id));
    }
  }
  
  void _cleanupOperation(String operationId) {
    _pendingUpdates.remove(operationId);
    _updateTimers[operationId]?.cancel();
    _updateTimers.remove(operationId);
    _retryCounters.remove(operationId);
  }
  
  void _showErrorMessage(String message) {
    // Implement using your existing snackbar/notification system
  }
  
  void _showRetryDialog({
    required String message,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    // Implement using your existing dialog system
  }
}
```

---

## 🎭 **PHASE 4: REAL-TIME UI COMPONENTS**

### **Research References:**
- Google Docs-style collaboration indicators
- Slack's typing indicators implementation
- Real-time presence UI patterns

### **Step 4.1: Google Docs-Style Active Viewer Avatars**

**INSTRUCTION**: Create `lib/widgets/shopping_lists/google_docs_style_avatars.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../Values/values.dart';

class GoogleDocsStyleAvatars extends StatelessWidget {
  final String listId;
  final double avatarSize;
  final int maxVisible;
  
  const GoogleDocsStyleAvatars({
    Key? key,
    required this.listId,
    this.avatarSize = 32.0,
    this.maxVisible = 5,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActiveViewer>>(
      stream: ShoppingListService.getActiveViewersStream(listId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }
        
        final activeViewers = snapshot.data!;
        final visibleViewers = activeViewers.take(maxVisible).toList();
        final overflowCount = activeViewers.length - maxVisible;
        
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active viewers text
              Text(
                '${activeViewers.length} viewing',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Stacked avatars (Google Docs style)
              Stack(
                children: [
                  ...visibleViewers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final viewer = entry.value;
                    
                    return Positioned(
                      left: index * (avatarSize * 0.7), // Overlap avatars
                      child: _buildViewerAvatar(viewer, context),
                    );
                  }),
                  
                  // Overflow indicator
                  if (overflowCount > 0)
                    Positioned(
                      left: visibleViewers.length * (avatarSize * 0.7),
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '+$overflowCount',
                            style: GoogleFonts.inter(
                              fontSize: avatarSize * 0.3,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(width: (visibleViewers.length + (overflowCount > 0 ? 1 : 0)) * avatarSize * 0.7 + 8),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildViewerAvatar(ActiveViewer viewer, BuildContext context) {
    final activityColor = _getActivityColor(viewer.currentActivity);
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activityColor,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Main avatar
          CircleAvatar(
            radius: (avatarSize - 4) / 2,
            backgroundImage: viewer.profilePicture != null
                ? NetworkImage(viewer.profilePicture!)
                : null,
            backgroundColor: _getAvatarColor(viewer.displayName),
            child: viewer.profilePicture == null
                ? Text(
                    viewer.displayName.isNotEmpty 
                        ? viewer.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontSize: avatarSize * 0.4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          // Activity indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: avatarSize * 0.3,
              height: avatarSize * 0.3,
              decoration: BoxDecoration(
                color: activityColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(
                _getActivityIcon(viewer.currentActivity),
                size: avatarSize * 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getActivityColor(String activity) {
    switch (activity) {
      case 'editing':
        return Colors.orange;
      case 'adding_item':
        return Colors.blue;
      case 'viewing':
        return Colors.green;
      case 'reordering':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }
  
  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'editing':
        return Icons.edit;
      case 'adding_item':
        return Icons.add;
      case 'reordering':
        return Icons.reorder;
      default:
        return Icons.visibility;
    }
  }
  
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.red[600]!,
      Colors.teal[600]!,
    ];
    
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}
```

### **Step 4.2: Item Assignment UI Components**

**INSTRUCTION**: Create `lib/widgets/shopping_lists/item_assignment_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shopping_lists/shopping_list_model.dart';
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../Values/values.dart';

class ItemAssignmentWidget extends StatelessWidget {
  final String listId;
  final ShoppingListItem item;
  final List<CollaboratorInfo> collaborators;
  final ItemAssignment? assignment;
  final bool canAssign;
  
  const ItemAssignmentWidget({
    Key? key,
    required this.listId,
    required this.item,
    required this.collaborators,
    this.assignment,
    required this.canAssign,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (assignment == null && !canAssign) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Assignment icon
          Icon(
            assignment != null ? Icons.assignment_ind : Icons.assignment,
            size: 16,
            color: assignment != null ? Colors.orange[600] : Colors.grey[400],
          ),
          
          SizedBox(width: 8),
          
          // Assignment content
          Expanded(
            child: assignment != null
                ? _buildAssignmentInfo(context)
                : _buildUnassignedState(context),
          ),
          
          // Action button
          if (canAssign)
            _buildActionButton(context),
        ],
      ),
    );
  }
  
  Widget _buildAssignmentInfo(BuildContext context) {
    final assignedMember = collaborators.firstWhere(
      (c) => c.userId == assignment!.assignedToUserId,
      orElse: () => CollaboratorInfo(
        userId: assignment!.assignedToUserId,
        role: 'member',
        joinedAt: DateTime.now(),
        invitedBy: '',
        permissions: CollaboratorPermissions.member(),
        displayName: 'Unknown User',
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Assigned member avatar
            CircleAvatar(
              radius: 10,
              backgroundImage: assignedMember.profilePicture != null
                  ? NetworkImage(assignedMember.profilePicture!)
                  : null,
              backgroundColor: Colors.orange[100],
              child: assignedMember.profilePicture == null
                  ? Text(
                      assignedMember.displayName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    )
                  : null,
            ),
            
            SizedBox(width: 8),
            
            // Assigned text
            Expanded(
              child: Text(
                'Assigned to ${assignedMember.displayName}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Status badge
            _buildStatusBadge(),
          ],
        ),
        
        // Assignment notes
        if (assignment!.notes != null && assignment!.notes!.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            assignment!.notes!,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildUnassignedState(BuildContext context) {
    return Text(
      'Not assigned',
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }
  
  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    
    switch (assignment!.status) {
      case AssignmentStatus.assigned:
        badgeColor = Colors.orange;
        statusText = 'Assigned';
        break;
      case AssignmentStatus.inProgress:
        badgeColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case AssignmentStatus.completed:
        badgeColor = Colors.green;
        statusText = 'Done';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: 8,
          color: badgeColor[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: Colors.grey[600],
      ),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        if (assignment == null)
          PopupMenuItem(
            value: 'assign',
            child: Row(
              children: [
                Icon(Icons.assignment_ind, size: 16),
                SizedBox(width: 8),
                Text('Assign to member'),
              ],
            ),
          ),
        if (assignment != null) ...[
          PopupMenuItem(
            value: 'reassign',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 16),
                SizedBox(width: 8),
                Text('Reassign'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'unassign',
            child: Row(
              children: [
                Icon(Icons.assignment_late, size: 16),
                SizedBox(width: 8),
                Text('Remove assignment'),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'assign':
      case 'reassign':
        _showAssignmentDialog(context);
        break;
      case 'unassign':
        _unassignItem();
        break;
    }
  }
  
  void _showAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AssignmentDialog(
        listId: listId,
        item: item,
        collaborators: collaborators,
        currentAssignment: assignment,
      ),
    );
  }
  
  void _unassignItem() {
    ShoppingListService.unassignItem(
      listId: listId,
      itemId: item.id,
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  final String listId;
  final ShoppingListItem item;
  final List<CollaboratorInfo> collaborators;
  final ItemAssignment? currentAssignment;
  
  const _AssignmentDialog({
    required this.listId,
    required this.item,
    required this.collaborators,
    this.currentAssignment,
  });
  
  @override
  _AssignmentDialogState createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  String? selectedUserId;
  final TextEditingController notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    selectedUserId = widget.currentAssignment?.assignedToUserId;
    notesController.text = widget.currentAssignment?.notes ?? '';
  }
  
  @override
  Widget build(BuildContext context) {
    final eligibleCollaborators = widget.collaborators
        .where((c) => c.permissions.canEdit)
        .toList();
    
    return AlertDialog(
      title: Text(
        widget.currentAssignment == null ? 'Assign Item' : 'Reassign Item',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Member selection
          Text(
            'Assign to:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          
          ...eligibleCollaborators.map((collaborator) =>
            RadioListTile<String>(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: collaborator.profilePicture != null
                        ? NetworkImage(collaborator.profilePicture!)
                        : null,
                    child: collaborator.profilePicture == null
                        ? Text(
                            collaborator.displayName[0].toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 12),
                          )
                        : null,
                  ),
                  SizedBox(width: 12),
                  Text(
                    collaborator.displayName,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
              value: collaborator.userId,
              groupValue: selectedUserId,
              onChanged: (value) => setState(() => selectedUserId = value),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Notes
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any specific instructions...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedUserId != null ? _assignItem : null,
          child: Text('Assign'),
        ),
      ],
    );
  }
  
  void _assignItem() {
    if (selectedUserId == null) return;
    
    ShoppingListService.assignItemToMember(
      listId: widget.listId,
      itemId: widget.item.id,
      assignToUserId: selectedUserId!,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
    
    Navigator.of(context).pop();
  }
}
```

### **Step 4.2: Real-Time Activity Feed Widget**

**INSTRUCTION**: Create `lib/widgets/shopping_lists/activity_feed_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../Values/values.dart';

class ActivityFeedWidget extends StatelessWidget {
  final String listId;
  final bool showAsChips;
  
  const ActivityFeedWidget({
    Key? key,
    required this.listId,
    this.showAsChips = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityInfo>>(
      stream: ShoppingListService.getActivityFeedStream(listId, limit: 20),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }
        
        final recentActivities = snapshot.data!.take(5).toList();
        
        if (showAsChips) {
          return _buildChipsFeed(recentActivities);
        } else {
          return _buildListFeed(recentActivities);
        }
      },
    );
  }
  
  Widget _buildChipsFeed(List<ActivityInfo> activities) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          final timeAgo = _getTimeAgo(activity.timestamp);
          
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getActivityColor(activity.action).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getActivityColor(activity.action).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getActivityIcon(activity.action),
                    size: 14,
                    color: _getActivityColor(activity.action),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${activity.userName} ${_getActivityDescription(activity)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: _getActivityColor(activity.action),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildListFeed(List<ActivityInfo> activities) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          ...activities.map((activity) => _buildActivityListItem(activity)),
        ],
      ),
    );
  }
  
  Widget _buildActivityListItem(ActivityInfo activity) {
    final timeAgo = _getTimeAgo(activity.timestamp);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.action).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(activity.action),
              size: 16,
              color: _getActivityColor(activity.action),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    children: [
                      TextSpan(
                        text: activity.userName,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' ${_getActivityDescription(activity)}',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'item_added':
        return Icons.add_circle_outline;
      case 'item_completed':
        return Icons.check_circle_outline;
      case 'item_uncompleted':
        return Icons.radio_button_unchecked;
      case 'item_removed':
        return Icons.remove_circle_outline;
      case 'list_shared':
        return Icons.share_outlined;
      case 'member_added':
        return Icons.person_add_outlined;
      case 'item_edited':
        return Icons.edit_outlined;
      default:
        return Icons.update;
    }
  }
  
  Color _getActivityColor(String action) {
    switch (action) {
      case 'item_added':
        return Colors.green;
      case 'item_completed':
        return Colors.blue;
      case 'item_removed':
        return Colors.red;
      case 'list_shared':
        return Colors.purple;
      case 'member_added':
        return Colors.orange;
      case 'item_edited':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
  
  String _getActivityDescription(ActivityInfo activity) {
    switch (activity.action) {
      case 'item_added':
        return 'added "${activity.details['itemName']}"';
      case 'item_completed':
        return 'completed "${activity.details['itemName'] ?? 'an item'}"';
      case 'item_uncompleted':
        return 'unchecked "${activity.details['itemName'] ?? 'an item'}"';
      case 'item_removed':
        return 'removed "${activity.details['itemName'] ?? 'an item'}"';
      case 'list_shared':
        return 'shared this list with ${activity.details['sharedWith']} people';
      case 'member_added':
        return 'added ${activity.details['count']} new members';
      case 'item_edited':
        return 'edited "${activity.details['itemName'] ?? 'an item'}"';
      default:
        return 'updated the list';
    }
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
```

---

## 🔄 **PHASE 5: ADVANCED REORDERABLE LISTS**

### **Step 5.1: Enhanced Reorderable List Widget**

**INSTRUCTION**: Create `lib/widgets/shopping_lists/collaborative_reorderable_list.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import '../../models/shopping_lists/shopping_list_item_model.dart';
import '../../services/shopping_lists/shopping_list_service.dart';
import '../../services/auth/auth_service.dart';

class CollaborativeReorderableList extends StatefulWidget {
  final String listId;
  final List<ShoppingListItem> items;
  final Function(ShoppingListItem) onItemTap;
  final Function(ShoppingListItem, bool) onItemToggle;
  
  const CollaborativeReorderableList({
    Key? key,
    required this.listId,
    required this.items,
    required this.onItemTap,
    required this.onItemToggle,
  }) : super(key: key);
  
  @override
  _CollaborativeReorderableListState createState() => _CollaborativeReorderableListState();
}

class _CollaborativeReorderableListState extends State<CollaborativeReorderableList> {
  List<ShoppingListItem> _localItems = [];
  bool _isReordering = false;
  
  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }
  
  @override
  void didUpdateWidget(CollaborativeReorderableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReordering) {
      _localItems = List.from(widget.items);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedReorderableListView(
      items: _localItems,
      itemBuilder: (context, index) {
        final item = _localItems[index];
        return _buildListItem(item, index);
      },
      enterTransition: [
        FadeIn(duration: Duration(milliseconds: 300)),
        SlideInDown(duration: Duration(milliseconds: 300)),
      ],
      exitTransition: [
        FadeOut(duration: Duration(milliseconds: 300)),
        SlideInUp(duration: Duration(milliseconds: 300)),
      ],
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      onReorderStarted: (index) => _handleReorderStarted(),
      onReorderCompleted: () => _handleReorderCompleted(),
    );
  }
  
  Widget _buildListItem(ShoppingListItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onItemTap(item),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
                
                // Completion checkbox
                GestureDetector(
                  onTap: () => _handleToggleCompletion(item),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isCompleted 
                            ? Colors.green 
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: item.isCompleted 
                          ? Colors.green 
                          : Colors.transparent,
                    ),
                    child: item.isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Item content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: item.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: item.isCompleted 
                              ? Colors.grey[500] 
                              : Colors.black87,
                        ),
                      ),
                      if (item.notes.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          item.notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Quantity and price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (item.estimatedPrice > 0) ...[
                      SizedBox(height: 2),
                      Text(
                        'Rs. ${item.estimatedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _localItems.removeAt(oldIndex);
      _localItems.insert(newIndex, item);
    });
    
    // Sync reordering to server
    _syncReorderToServer();
  }
  
  void _handleReorderStarted() {
    setState(() {
      _isReordering = true;
    });
    
    // Show reordering indicator to other users
    AuthService.updateActivity('reordering', listId: widget.listId);
  }
  
  void _handleReorderCompleted() {
    setState(() {
      _isReordering = false;
    });
    
    // Hide reordering indicator
    AuthService.updateActivity('browsing', listId: widget.listId);
  }
  
  void _handleToggleCompletion(ShoppingListItem item) {
    // Optimistic update
    widget.onItemToggle(item, !item.isCompleted);
    
    // Sync to server
    ShoppingListService.toggleItemCompletionWithSync(
      listId: widget.listId,
      itemId: item.id,
      isCompleted: !item.isCompleted,
    );
  }
  
  Future<void> _syncReorderToServer() async {
    // Create batch update for all item orders
    final batch = FirebaseFirestore.instance.batch();
    
    for (int i = 0; i < _localItems.length; i++) {
      final item = _localItems[i];
      final itemRef = FirebaseFirestore.instance
          .collection('shopping_lists')
          .doc(widget.listId)
          .collection('items')
          .doc(item.id);
      
      batch.update(itemRef, {
        'order': i,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Update list activity
    batch.update(
      FirebaseFirestore.instance.doc('shopping_lists/${widget.listId}'),
      {
        'collaboration.lastActivity': {
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
          'action': 'items_reordered',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {'itemCount': _localItems.length},
        },
      },
    );
    
    try {
      await batch.commit();
    } catch (e) {
      // Handle error - could revert to server order
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync order changes')),
      );
    }
  }
}
```

---

## 📱 **PHASE 6: INTEGRATE WITH EXISTING SCREENS**

### **Step 6.1: Extend Existing Shopping List Detail Screen**

**INSTRUCTION**: Find your existing shopping list detail screen and ADD these components:

```dart
// ADD these imports
import '../widgets/shopping_lists/collaborator_presence_widget.dart';
import '../widgets/shopping_lists/activity_feed_widget.dart';
import '../widgets/shopping_lists/collaborative_reorderable_list.dart';

// ADD these widgets to your existing build method:
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... keep your existing app bar and other widgets ...
    
    body: Column(
      children: [
        // ... keep existing widgets ...
        
        // ADD collaborator presence indicator
        CollaboratorPresenceWidget(listId: widget.listId),
        
        // ADD activity feed
        ActivityFeedWidget(
          listId: widget.listId,
          showAsChips: true,
        ),
        
        // REPLACE your existing list with collaborative version
        Expanded(
          child: CollaborativeReorderableList(
            listId: widget.listId,
            items: _items, // your existing items list
            onItemTap: _handleItemTap,
            onItemToggle: _handleItemToggle,
          ),
        ),
      ],
    ),
  );
}

// ADD sharing functionality
void _shareList() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _buildShareListSheet(),
  );
}

Widget _buildShareListSheet() {
  return Container(
    height: MediaQuery.of(context).size.height * 0.8,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Share List',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
        ),
        
        // Friend selection UI
        Expanded(
          child: _buildFriendSelectionList(),
        ),
        
        // Share button
        Container(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _handleShareWithSelectedFriends,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Share List',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## 🚀 **DEPLOYMENT & TESTING INSTRUCTIONS**

### **Step 1: Testing Checklist**
- [ ] Real-time presence detection works across devices
- [ ] Collaborator indicators update in real-time
- [ ] Item additions sync immediately to all collaborators
- [ ] Optimistic updates rollback correctly on failure
- [ ] Activity feed shows relevant actions
- [ ] Drag-and-drop reordering syncs properly
- [ ] Typing indicators appear and disappear correctly
- [ ] Conflict resolution works for simultaneous edits

### **Step 2: Performance Optimization**
- [ ] Implement debouncing for rapid updates
- [ ] Add pagination for large activity feeds
- [ ] Optimize presence query frequency
- [ ] Cache collaborator information
- [ ] Implement efficient list diff algorithms

### **Step 3: Error Handling**
- [ ] Network connectivity issues
- [ ] Firebase quota exceeded
- [ ] Simultaneous edit conflicts
- [ ] Invalid user permissions
- [ ] Malformed data recovery

---

## 🎯 **SUCCESS METRICS**

**Technical Performance:**
- Real-time sync latency < 500ms
- Optimistic update response < 100ms
- Presence detection accuracy > 95%
- Conflict resolution success > 99%

**User Experience:**
- Seamless integration with existing UI
- Intuitive collaboration indicators
- Smooth drag-and-drop interactions
- Clear activity visibility

**State-of-the-Art Features Implemented:**
- Google Docs-level real-time collaboration
- Operational Transform-inspired conflict resolution  
- Live presence awareness with typing indicators
- Optimistic updates with automatic rollback
- Advanced drag-and-drop with real-time sync
- Comprehensive activity feeds and notifications

This implementation creates a state-of-the-art collaborative shopping list system that rivals the best real-time collaboration tools while building seamlessly on your existing Shopple app infrastructure.