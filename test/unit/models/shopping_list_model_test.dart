import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/shopping_lists/shopping_list_model.dart';
import 'package:shopple/models/budget/budget_cadence.dart';

void main() {
  group('ShoppingList Model Tests', () {
    late ShoppingList baseList;

    setUp(() {
      baseList = ShoppingList(
        id: 'test-list-1',
        name: 'Test Shopping List',
        description: 'A test shopping list',
        iconId: 'shopping_cart',
        colorTheme: '#4CAF50',
        createdBy: 'user-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        lastActivity: DateTime(2024, 1, 2),
        status: ListStatus.active,
        budgetLimit: 100.0,
        budgetCadence: BudgetCadence.monthly,
        totalItems: 10,
        completedItems: 5,
        estimatedTotal: 75.50,
        distinctProducts: 8,
        distinctCompleted: 4,
      );
    });

    test('themeColor parses hex color correctly', () {
      expect(baseList.themeColor.toARGB32(), equals(0xFF4CAF50));
    });

    test('themeColor handles invalid hex gracefully', () {
      final listWithBadColor = ShoppingList(
        id: 'test',
        name: 'Test',
        colorTheme: 'invalid',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      // Should fall back to green
      expect(listWithBadColor.themeColor.toARGB32(), equals(0xFF4CAF50));
    });

    test('completionPercentage calculates correctly', () {
      expect(baseList.completionPercentage, equals(50.0));
    });

    test('completionPercentage returns 0 for empty list', () {
      final emptyList = ShoppingList(
        id: 'test',
        name: 'Empty List',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        totalItems: 0,
        completedItems: 0,
      );
      expect(emptyList.completionPercentage, equals(0.0));
    });

    test('isCompleted returns true when all items are completed', () {
      final completedList = ShoppingList(
        id: 'test',
        name: 'Completed List',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        totalItems: 5,
        completedItems: 5,
      );
      expect(completedList.isCompleted, isTrue);
    });

    test('isCompleted returns false when not all items are completed', () {
      expect(baseList.isCompleted, isFalse);
    });

    test('isCompleted returns false when no items exist', () {
      final emptyList = ShoppingList(
        id: 'test',
        name: 'Empty List',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        totalItems: 0,
        completedItems: 0,
      );
      expect(emptyList.isCompleted, isFalse);
    });

    test('toFirestore contains correct data', () {
      final firestoreData = baseList.toFirestore();
      
      expect(firestoreData['name'], equals('Test Shopping List'));
      expect(firestoreData['budgetLimit'], equals(100.0));
      expect(firestoreData['totalItems'], equals(10));
    });

    test('toJson serializes correctly', () {
      final json = baseList.toJson();
      
      expect(json['id'], equals('test-list-1'));
      expect(json['name'], equals('Test Shopping List'));
      expect(json['budgetLimit'], equals(100.0));
      expect(json['totalItems'], equals(10));
      expect(json['completedItems'], equals(5));
      expect(json['estimatedTotal'], equals(75.50));
    });

    test('fromJson deserializes correctly', () {
      final json = baseList.toJson();
      final restored = ShoppingList.fromJson(json);
      
      expect(restored.id, equals(baseList.id));
      expect(restored.name, equals(baseList.name));
      expect(restored.budgetLimit, equals(baseList.budgetLimit));
      expect(restored.totalItems, equals(baseList.totalItems));
      expect(restored.completedItems, equals(baseList.completedItems));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = {'id': 'test-id', 'name': 'Minimal'};
      final restored = ShoppingList.fromJson(json);
      
      expect(restored.id, equals('test-id'));
      expect(restored.name, equals('Minimal'));
      expect(restored.budgetLimit, equals(0.0));
      expect(restored.totalItems, equals(0));
    });

    test('default values are correct', () {
      final minimalList = ShoppingList(
        id: 'minimal',
        name: 'Minimal',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      
      expect(minimalList.description, equals(''));
      expect(minimalList.iconId, equals('shopping_cart'));
      expect(minimalList.colorTheme, equals('#4CAF50'));
      expect(minimalList.status, equals(ListStatus.active));
      expect(minimalList.budgetLimit, equals(0.0));
      expect(minimalList.totalItems, equals(0));
      expect(minimalList.isShared, isFalse);
      expect(minimalList.collaborators, isEmpty);
    });

    test('budget fields are stored correctly', () {
      expect(baseList.budgetLimit, equals(100.0));
      expect(baseList.estimatedTotal, equals(75.50));
      expect(baseList.budgetCadence, equals(BudgetCadence.monthly));
    });

    test('distinct item counts are stored correctly', () {
      expect(baseList.distinctProducts, equals(8));
      expect(baseList.distinctCompleted, equals(4));
    });

    test('member fields are stored correctly', () {
      final listWithMembers = ShoppingList(
        id: 'test',
        name: 'Test',
        createdBy: 'owner',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivity: DateTime.now(),
        memberIds: ['owner', 'member1', 'member2'],
        memberRoles: {
          'owner': 'owner',
          'member1': 'collab',
          'member2': 'viewer',
        },
      );
      
      expect(listWithMembers.memberIds.length, equals(3));
      expect(listWithMembers.memberRoles['owner'], equals('owner'));
      expect(listWithMembers.memberRoles['member1'], equals('collab'));
    });
  });

  group('ListStatus Tests', () {
    test('active status string conversion', () {
      expect(ListStatus.active.toString(), contains('active'));
    });

    test('completed status string conversion', () {
      expect(ListStatus.completed.toString(), contains('completed'));
    });

    test('archived status string conversion', () {
      expect(ListStatus.archived.toString(), contains('archived'));
    });

    test('enum has all expected values', () {
      expect(ListStatus.values.length, equals(3));
      expect(ListStatus.values, contains(ListStatus.active));
      expect(ListStatus.values, contains(ListStatus.completed));
      expect(ListStatus.values, contains(ListStatus.archived));
    });
  });

  group('CollaboratorPermissions Tests', () {
    test('owner has all permissions', () {
      final owner = CollaboratorPermissions.owner();
      
      expect(owner.canEdit, isTrue);
      expect(owner.canInvite, isTrue);
      expect(owner.canDelete, isTrue);
      expect(owner.canManageMembers, isTrue);
      expect(owner.canViewActivity, isTrue);
      expect(owner.canAssignItems, isTrue);
      expect(owner.canManageRoles, isTrue);
      expect(owner.canViewEditHistory, isTrue);
    });

    test('admin has most permissions except delete and manage roles', () {
      final admin = CollaboratorPermissions.admin();
      
      expect(admin.canEdit, isTrue);
      expect(admin.canInvite, isTrue);
      expect(admin.canDelete, isFalse);
      expect(admin.canManageMembers, isTrue);
      expect(admin.canManageRoles, isFalse);
    });

    test('member has limited permissions', () {
      final member = CollaboratorPermissions.member();
      
      expect(member.canEdit, isTrue);
      expect(member.canInvite, isFalse);
      expect(member.canDelete, isFalse);
      expect(member.canManageMembers, isFalse);
    });

    test('viewer has read-only permissions', () {
      final viewer = CollaboratorPermissions.viewer();
      
      expect(viewer.canEdit, isFalse);
      expect(viewer.canInvite, isFalse);
      expect(viewer.canDelete, isFalse);
      expect(viewer.canViewActivity, isTrue);
    });
  });

  group('CollaboratorInfo Tests', () {
    test('creates collaborator with required fields', () {
      final collaborator = CollaboratorInfo(
        userId: 'user-123',
        role: 'admin',
        joinedAt: DateTime(2024, 1, 1),
        invitedBy: 'owner-456',
        permissions: CollaboratorPermissions.admin(),
        displayName: 'John Doe',
      );
      
      expect(collaborator.userId, equals('user-123'));
      expect(collaborator.role, equals('admin'));
      expect(collaborator.displayName, equals('John Doe'));
      expect(collaborator.isActive, isFalse);
      expect(collaborator.profilePicture, isNull);
    });

    test('stores optional fields correctly', () {
      final collaborator = CollaboratorInfo(
        userId: 'user-123',
        role: 'member',
        joinedAt: DateTime(2024, 1, 1),
        invitedBy: 'owner-456',
        permissions: CollaboratorPermissions.member(),
        displayName: 'Jane Doe',
        profilePicture: 'https://example.com/avatar.jpg',
        isActive: true,
        lastActive: DateTime(2024, 1, 15),
      );
      
      expect(collaborator.profilePicture, equals('https://example.com/avatar.jpg'));
      expect(collaborator.isActive, isTrue);
      expect(collaborator.lastActive, isNotNull);
    });
  });

  group('CollaborationSettings Tests', () {
    test('has sensible defaults', () {
      const settings = CollaborationSettings();
      expect(settings, isNotNull);
    });
  });
}
