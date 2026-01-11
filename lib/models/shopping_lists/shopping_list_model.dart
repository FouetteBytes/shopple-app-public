import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopple/models/budget/budget_cadence.dart';

enum ListStatus { active, completed, archived }

class ShoppingList {
  final String id;
  final String name;
  final String description;
  final String iconId;
  final String colorTheme;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ListStatus status;
  final double budgetLimit;
  final BudgetCadence budgetCadence;
  final DateTime budgetAnchor;
  final int totalItems;
  final int completedItems;
  final double estimatedTotal;
  final int distinctProducts;
  final int distinctCompleted;
  final DateTime lastActivity;
  final List<String> memberIds; // user IDs assigned to this list
  final Map<String, String>
  memberRoles; // userId -> role code (owner, collab, viewer)
  final DateTime? startDate; // optional planned period
  final DateTime? endDate; // optional planned period

  // NEW: Collaboration fields
  final bool isShared;
  final Map<String, CollaboratorInfo> collaborators;
  final Map<String, InviteInfo> pendingInvites;
  final ActivityInfo? lastCollaborationActivity;
  final CollaborationSettings settings;
  final Map<String, ItemAssignment> itemAssignments;

  ShoppingList({
    required this.id,
    required this.name,
    this.description = '',
    this.iconId = 'shopping_cart',
    this.colorTheme = '#4CAF50',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.status = ListStatus.active,
    this.budgetLimit = 0.0,
    this.budgetCadence = BudgetCadence.none,
    DateTime? budgetAnchor,
    this.totalItems = 0,
    this.completedItems = 0,
    this.estimatedTotal = 0.0,
    this.distinctProducts = 0,
    this.distinctCompleted = 0,
    required this.lastActivity,
    this.memberIds = const [],
    this.memberRoles = const {},
    this.startDate,
    this.endDate,
    // NEW: Collaboration parameters
    this.isShared = false,
    this.collaborators = const {},
    this.pendingInvites = const {},
    this.lastCollaborationActivity,
    this.settings = const CollaborationSettings(),
    this.itemAssignments = const {},
  }) : budgetAnchor = budgetAnchor ?? createdAt;

  factory ShoppingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime toDate(dynamic v, {DateTime? fallback}) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return fallback ?? DateTime.now();
    }

    return ShoppingList(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconId: data['iconId'] ?? 'shopping_cart',
      colorTheme: data['colorTheme'] ?? '#4CAF50',
      createdBy: data['createdBy'] ?? '',
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
      status: ListStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ListStatus.active,
      ),
      budgetLimit: (data['budgetLimit'] ?? 0.0).toDouble(),
      budgetCadence: BudgetCadenceStorage.fromStorage(
        data['budgetCadence']?.toString(),
      ),
      budgetAnchor: data['budgetAnchor'] != null
          ? toDate(data['budgetAnchor'])
          : toDate(data['createdAt']),
      totalItems: data['totalItems'] ?? 0,
      completedItems: data['completedItems'] ?? 0,
      estimatedTotal: (data['estimatedTotal'] ?? 0.0).toDouble(),
      distinctProducts: data['distinctProducts'] ?? 0,
      distinctCompleted: data['distinctCompleted'] ?? 0,
      lastActivity: toDate(data['lastActivity']),
      memberIds:
          (data['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      memberRoles:
          (data['memberRoles'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      startDate: data['startDate'] != null ? toDate(data['startDate']) : null,
      endDate: data['endDate'] != null ? toDate(data['endDate']) : null,
      // NEW: Collaboration fields
      isShared: data['collaboration']?['isShared'] ?? false,
      collaborators: ShoppingList._parseCollaborators(
        data['collaboration']?['members'] ?? {},
      ),
      pendingInvites: ShoppingList._parseInvites(
        data['collaboration']?['pendingInvites'] ?? {},
      ),
      lastCollaborationActivity: data['collaboration']?['lastActivity'] != null
          ? ActivityInfo.fromMap(data['collaboration']['lastActivity'])
          : null,
      settings: CollaborationSettings.fromMap(
        data['collaboration']?['settings'] ?? {},
      ),
      itemAssignments: ShoppingList._parseItemAssignments(
        data['collaboration']?['itemAssignments'] ?? {},
      ),
    );
  }

  // Helper methods for parsing collaboration data
  static Map<String, CollaboratorInfo> _parseCollaborators(
    Map<String, dynamic> data,
  ) {
    final result = <String, CollaboratorInfo>{};
    for (final entry in data.entries) {
      result[entry.key] = CollaboratorInfo.fromMap(
        entry.value as Map<String, dynamic>,
      );
    }
    return result;
  }

  static Map<String, InviteInfo> _parseInvites(Map<String, dynamic> data) {
    final result = <String, InviteInfo>{};
    for (final entry in data.entries) {
      final inviteData = entry.value as Map<String, dynamic>;
      result[entry.key] = InviteInfo(
        userId: entry.key,
        invitedBy: inviteData['invitedBy'] ?? '',
        invitedAt:
            (inviteData['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        role: inviteData['role'] ?? 'viewer',
        message: inviteData['message'],
      );
    }
    return result;
  }

  static Map<String, ItemAssignment> _parseItemAssignments(
    Map<String, dynamic> data,
  ) {
    final result = <String, ItemAssignment>{};
    for (final entry in data.entries) {
      final assignmentData = entry.value as Map<String, dynamic>;
      // Parse history entries (if present) into typed objects
      List<AssignmentHistoryEntry> history = const [];
      final rawHistory = assignmentData['history'];
      if (rawHistory is List) {
        history = rawHistory
            .whereType<Map>()
            .map((m) {
              DateTime? toDate(dynamic v) {
                if (v is Timestamp) return v.toDate();
                if (v is DateTime) return v;
                return null;
              }

              final map = Map<String, dynamic>.from(m);
              return AssignmentHistoryEntry(
                actionType: map['actionType']?.toString() ?? 'unknown',
                userId: map['userId']?.toString() ?? '',
                userName: map['userName']?.toString() ?? 'Unknown',
                timestamp: toDate(map['timestamp']) ?? DateTime.now(),
                previousValue: map['previousValue']?.toString(),
                newValue: map['newValue']?.toString(),
              );
            })
            .toList(growable: false);
      }
      result[entry.key] = ItemAssignment(
        itemId: entry.key,
        assignedToUserId: assignmentData['assignedToUserId'] ?? '',
        assignedByUserId: assignmentData['assignedByUserId'] ?? '',
        assignedAt:
            (assignmentData['assignedAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        notes: assignmentData['notes'],
        status: AssignmentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == assignmentData['status'],
          orElse: () => AssignmentStatus.assigned,
        ),
        completedAt: (assignmentData['completedAt'] as Timestamp?)?.toDate(),
        history: history,
      );
    }
    return result;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconId': iconId,
      'colorTheme': colorTheme,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.toString().split('.').last,
      'budgetLimit': budgetLimit,
      'budgetCadence': budgetCadence.storageValue,
      'budgetAnchor': Timestamp.fromDate(budgetAnchor),
      'totalItems': totalItems,
      'completedItems': completedItems,
      'estimatedTotal': estimatedTotal,
      'distinctProducts': distinctProducts,
      'distinctCompleted': distinctCompleted,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'memberIds': memberIds,
      'memberRoles': memberRoles,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      // NEW: Collaboration data
      'collaboration': {
        'isShared': isShared,
        'members': _collaboratorsToMap(),
        'pendingInvites': _invitesToMap(),
        if (lastCollaborationActivity != null)
          'lastActivity': _activityToMap(lastCollaborationActivity!),
        'settings': _settingsToMap(),
        'itemAssignments': _assignmentsToMap(),
      },
    };
  }

  // Helper methods for converting collaboration data to maps
  Map<String, dynamic> _collaboratorsToMap() {
    final result = <String, dynamic>{};
    for (final entry in collaborators.entries) {
      final collaborator = entry.value;
      result[entry.key] = {
        'userId': collaborator.userId,
        'role': collaborator.role,
        'joinedAt': Timestamp.fromDate(collaborator.joinedAt),
        'invitedBy': collaborator.invitedBy,
        'permissions': _permissionsToMap(collaborator.permissions),
        'displayName': collaborator.displayName,
        'profilePicture': collaborator.profilePicture,
        'isActive': collaborator.isActive,
        if (collaborator.lastActive != null)
          'lastActive': Timestamp.fromDate(collaborator.lastActive!),
      };
    }
    return result;
  }

  Map<String, dynamic> _invitesToMap() {
    final result = <String, dynamic>{};
    for (final entry in pendingInvites.entries) {
      final invite = entry.value;
      result[entry.key] = {
        'invitedBy': invite.invitedBy,
        'invitedAt': Timestamp.fromDate(invite.invitedAt),
        'role': invite.role,
        if (invite.message != null) 'message': invite.message,
      };
    }
    return result;
  }

  Map<String, dynamic> _activityToMap(ActivityInfo activity) {
    return {
      'userId': activity.userId,
      'userName': activity.userName,
      'action': activity.action,
      'timestamp': Timestamp.fromDate(activity.timestamp),
      'details': activity.details,
      'type': activity.type.toString().split('.').last,
    };
  }

  Map<String, dynamic> _settingsToMap() {
    return {
      'allowMemberInvites': settings.allowMemberInvites,
      'requireApprovalForNewMembers': settings.requireApprovalForNewMembers,
      'enableRealTimeSync': settings.enableRealTimeSync,
      'showTypingIndicators': settings.showTypingIndicators,
      'enableItemAssignments': settings.enableItemAssignments,
    };
  }

  Map<String, dynamic> _assignmentsToMap() {
    final result = <String, dynamic>{};
    for (final entry in itemAssignments.entries) {
      final assignment = entry.value;
      result[entry.key] = {
        'assignedToUserId': assignment.assignedToUserId,
        'assignedByUserId': assignment.assignedByUserId,
        'assignedAt': Timestamp.fromDate(assignment.assignedAt),
        if (assignment.notes != null) 'notes': assignment.notes,
        'status': assignment.status.toString().split('.').last,
        if (assignment.completedAt != null)
          'completedAt': Timestamp.fromDate(assignment.completedAt!),
        if (assignment.history.isNotEmpty)
          'history': assignment.history
              .map(
                (h) => {
                  'actionType': h.actionType,
                  'userId': h.userId,
                  'userName': h.userName,
                  'timestamp': Timestamp.fromDate(h.timestamp),
                  if (h.previousValue != null) 'previousValue': h.previousValue,
                  if (h.newValue != null) 'newValue': h.newValue,
                },
              )
              .toList(),
      };
    }
    return result;
  }

  Map<String, dynamic> _permissionsToMap(CollaboratorPermissions permissions) {
    return {
      'canEdit': permissions.canEdit,
      'canInvite': permissions.canInvite,
      'canDelete': permissions.canDelete,
      'canManageMembers': permissions.canManageMembers,
      'canViewActivity': permissions.canViewActivity,
      'canAssignItems': permissions.canAssignItems,
      'canManageRoles': permissions.canManageRoles,
      'canViewEditHistory': permissions.canViewEditHistory,
    };
  }

  double get completionPercentage =>
      totalItems > 0 ? (completedItems / totalItems) * 100 : 0;

  bool get isCompleted => totalItems > 0 && completedItems == totalItems;

  Color get themeColor {
    try {
      return Color(int.parse(colorTheme.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  // --- Local persistence helpers ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconId': iconId,
    'colorTheme': colorTheme,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.toString().split('.').last,
    'budgetLimit': budgetLimit,
    'budgetCadence': budgetCadence.storageValue,
    'budgetAnchor': budgetAnchor.toIso8601String(),
    'totalItems': totalItems,
    'completedItems': completedItems,
    'estimatedTotal': estimatedTotal,
    'distinctProducts': distinctProducts,
    'distinctCompleted': distinctCompleted,
    'lastActivity': lastActivity.toIso8601String(),
    'memberIds': memberIds,
    'memberRoles': memberRoles,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
  };

  static ShoppingList fromJson(Map<String, dynamic> json) {
    DateTime dt(String? v) =>
        v == null ? DateTime.now() : DateTime.tryParse(v) ?? DateTime.now();
    return ShoppingList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconId: json['iconId'] ?? 'shopping_cart',
      colorTheme: json['colorTheme'] ?? '#4CAF50',
      createdBy: json['createdBy'] ?? '',
      createdAt: dt(json['createdAt']),
      updatedAt: dt(json['updatedAt']),
      status: ListStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'active'),
        orElse: () => ListStatus.active,
      ),
      budgetLimit: (json['budgetLimit'] ?? 0.0).toDouble(),
      totalItems: json['totalItems'] ?? 0,
      completedItems: json['completedItems'] ?? 0,
      estimatedTotal: (json['estimatedTotal'] ?? 0.0).toDouble(),
      distinctProducts: json['distinctProducts'] ?? 0,
      distinctCompleted: json['distinctCompleted'] ?? 0,
      lastActivity: dt(json['lastActivity']),
      memberIds:
          (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      memberRoles:
          (json['memberRoles'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      startDate: json['startDate'] != null ? dt(json['startDate']) : null,
      endDate: json['endDate'] != null ? dt(json['endDate']) : null,
      budgetCadence: BudgetCadenceStorage.fromStorage(
        json['budgetCadence']?.toString(),
      ),
      budgetAnchor: json['budgetAnchor'] != null
          ? dt(json['budgetAnchor'])
          : dt(json['createdAt']),
    );
  }
}

// Collaboration support classes
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

  const CollaboratorInfo({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.invitedBy,
    required this.permissions,
    required this.displayName,
    this.profilePicture,
    this.isActive = false,
    this.lastActive,
  });

  factory CollaboratorInfo.fromMap(Map<String, dynamic> map) {
    return CollaboratorInfo(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'viewer',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedBy: map['invitedBy'] ?? '',
      permissions: CollaboratorPermissions.fromMap(map['permissions'] ?? {}),
      // Be resilient to alternate user schema keys to avoid 'Unknown' labels
      displayName:
          (map['displayName'] ??
                  map['name'] ??
                  map['userName'] ??
                  map['fullName'] ??
                  'Unknown')
              as String,
      profilePicture:
          (map['profilePicture'] ?? map['avatarUrl'] ?? map['photoURL'])
              as String?,
      isActive: map['isActive'] ?? false,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
    );
  }
}

class CollaboratorPermissions {
  final bool canEdit;
  final bool canInvite;
  final bool canDelete;
  final bool canManageMembers;
  final bool canViewActivity;
  final bool canAssignItems;
  final bool canManageRoles;
  final bool canViewEditHistory;

  const CollaboratorPermissions({
    required this.canEdit,
    required this.canInvite,
    required this.canDelete,
    required this.canManageMembers,
    required this.canViewActivity,
    required this.canAssignItems,
    required this.canManageRoles,
    required this.canViewEditHistory,
  });

  // Factory methods for different roles
  factory CollaboratorPermissions.owner() => const CollaboratorPermissions(
    canEdit: true,
    canInvite: true,
    canDelete: true,
    canManageMembers: true,
    canViewActivity: true,
    canAssignItems: true,
    canManageRoles: true,
    canViewEditHistory: true,
  );

  factory CollaboratorPermissions.admin() => const CollaboratorPermissions(
    canEdit: true,
    canInvite: true,
    canDelete: false,
    canManageMembers: true,
    canViewActivity: true,
    canAssignItems: true,
    canManageRoles: false,
    canViewEditHistory: true,
  );

  factory CollaboratorPermissions.member() => const CollaboratorPermissions(
    canEdit: true,
    canInvite: false,
    canDelete: false,
    canManageMembers: false,
    canViewActivity: true,
    canAssignItems: false,
    canManageRoles: false,
    canViewEditHistory: false,
  );

  factory CollaboratorPermissions.viewer() => const CollaboratorPermissions(
    canEdit: false,
    canInvite: false,
    canDelete: false,
    canManageMembers: false,
    canViewActivity: true,
    canAssignItems: false,
    canManageRoles: false,
    canViewEditHistory: false,
  );

  factory CollaboratorPermissions.fromMap(Map<String, dynamic> map) {
    return CollaboratorPermissions(
      canEdit: map['canEdit'] ?? false,
      canInvite: map['canInvite'] ?? false,
      canDelete: map['canDelete'] ?? false,
      canManageMembers: map['canManageMembers'] ?? false,
      canViewActivity: map['canViewActivity'] ?? false,
      canAssignItems: map['canAssignItems'] ?? false,
      canManageRoles: map['canManageRoles'] ?? false,
      canViewEditHistory: map['canViewEditHistory'] ?? false,
    );
  }
}

class InviteInfo {
  final String userId;
  final String invitedBy;
  final DateTime invitedAt;
  final String role;
  final String? message;

  const InviteInfo({
    required this.userId,
    required this.invitedBy,
    required this.invitedAt,
    required this.role,
    this.message,
  });
}

class ActivityInfo {
  final String userId;
  final String userName;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> details;
  final ActivityType type;

  const ActivityInfo({
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
    required this.details,
    required this.type,
  });

  factory ActivityInfo.fromMap(Map<String, dynamic> map) {
    return ActivityInfo(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown',
      action: map['action'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ActivityType.itemAdded,
      ),
    );
  }

  factory ActivityInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityInfo.fromMap(data);
  }
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

class CollaborationSettings {
  final bool allowMemberInvites;
  final bool requireApprovalForNewMembers;
  final bool enableRealTimeSync;
  final bool showTypingIndicators;
  final bool enableItemAssignments;

  const CollaborationSettings({
    this.allowMemberInvites = true,
    this.requireApprovalForNewMembers = false,
    this.enableRealTimeSync = true,
    this.showTypingIndicators = true,
    this.enableItemAssignments = true,
  });

  factory CollaborationSettings.fromMap(Map<String, dynamic> map) {
    return CollaborationSettings(
      allowMemberInvites: map['allowMemberInvites'] ?? true,
      requireApprovalForNewMembers:
          map['requireApprovalForNewMembers'] ?? false,
      enableRealTimeSync: map['enableRealTimeSync'] ?? true,
      showTypingIndicators: map['showTypingIndicators'] ?? true,
      enableItemAssignments: map['enableItemAssignments'] ?? true,
    );
  }
}

class ItemAssignment {
  final String itemId;
  final String assignedToUserId;
  final String assignedByUserId;
  final DateTime assignedAt;
  final String? notes;
  final AssignmentStatus status;
  final DateTime? completedAt;
  final List<AssignmentHistoryEntry> history;

  const ItemAssignment({
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
  final String
  actionType; // 'assigned', 'reassigned', 'completed', 'notes_updated'
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String? previousValue;
  final String? newValue;

  const AssignmentHistoryEntry({
    required this.actionType,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.previousValue,
    this.newValue,
  });
}
