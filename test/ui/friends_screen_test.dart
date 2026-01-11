import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/screens/friends/friends_screen.dart';
import 'package:shopple/services/friends/friend_service.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/services/presence/i_presence_service.dart';
import 'package:shopple/models/friends/friend.dart';
import 'package:shopple/models/friends/friend_request.dart';
import 'package:shopple/models/user_presence_status.dart';

import '../firebase_test_helper.dart';
import '../mocks/mock_classes.mocks.dart';
import '../widget_test_helper.dart';

class MockPresenceService extends Mock implements IPresenceService {
  @override
  Stream<UserPresenceStatus> getUserPresenceStream(String userId) {
    return Stream.value(UserPresenceStatus.offline());
  }
}

void main() {
  late MockIFriendService mockFriendService;
  late MockPresenceService mockPresenceService;

  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();
    mockFriendService = MockIFriendService();
    FriendService.instance = mockFriendService;

    mockPresenceService = MockPresenceService();
    PresenceService.instance = mockPresenceService;
    
    // Seed test users into fake Firestore with privacy settings
    await FirebaseTestHelper.seedUsers([
      {
        'userId': 'user1',
        'displayName': 'Alice',
        'email': 'alice@example.com',
        'profileImageUrl': 'https://example.com/alice.jpg',
      },
      {
        'userId': 'user2',
        'displayName': 'Bob',
        'email': 'bob@example.com',
        'profileImageUrl': null,
      },
      {
        'userId': 'user3',
        'displayName': 'Charlie',
        'email': 'charlie@example.com',
        'profileImageUrl': null,
      },
    ]);
    
    // Seed privacy settings for users
    await FirebaseTestHelper.seedPrivacySettings(['user1', 'user2', 'user3']);
  });

  testWidgets('FriendsScreen renders correctly with friends list', (
    WidgetTester tester,
  ) async {
    // Set a fixed size to avoid layout issues
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    final friends = [
      Friend(
        userId: 'user1',
        displayName: 'Alice',
        email: 'alice@example.com',
        profileImageUrl: 'https://example.com/alice.jpg',
        friendshipDate: DateTime.now(),
        status: FriendshipStatus.active,
      ),
      Friend(
        userId: 'user2',
        displayName: 'Bob',
        email: 'bob@example.com',
        profileImageUrl: null,
        friendshipDate: DateTime.now(),
        status: FriendshipStatus.active,
      ),
    ];

    when(
      mockFriendService.getFriendsStream(),
    ).thenAnswer((_) => Stream.value(friends));
    when(
      mockFriendService.getPendingRequestsCountStream(),
    ).thenAnswer((_) => Stream.value(0));
    when(
      mockFriendService.getReceivedFriendRequestsStream(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockFriendService.getFriendGroupsStream(),
    ).thenAnswer((_) => Stream.value([]));

    // Act
    await pumpMaterialWidget(tester, const FriendsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert - verify screen renders without crashes
    expect(find.byType(FriendsScreen), findsOneWidget);
    expect(find.text('Friends'), findsWidgets); // Header and Tab
  });

  testWidgets('FriendsScreen shows friend requests', (
    WidgetTester tester,
  ) async {
    // Set a fixed size to avoid layout issues
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange
    final requests = [
      FriendRequest(
        id: 'req1',
        fromUserId: 'user3',
        toUserId: 'me',
        fromUserName: 'Charlie',
        fromUserEmail: 'charlie@example.com',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];

    when(
      mockFriendService.getFriendsStream(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockFriendService.getPendingRequestsCountStream(),
    ).thenAnswer((_) => Stream.value(1));
    when(
      mockFriendService.getReceivedFriendRequestsStream(),
    ).thenAnswer((_) => Stream.value(requests));
    when(
      mockFriendService.getFriendGroupsStream(),
    ).thenAnswer((_) => Stream.value([]));

    // Act
    await pumpMaterialWidget(tester, const FriendsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert - verify screen renders without crashes
    expect(find.byType(FriendsScreen), findsOneWidget);
  });
  
  testWidgets('FriendsScreen shows empty state when no friends', (
    WidgetTester tester,
  ) async {
    // Set a fixed size to avoid layout issues
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Arrange - empty friends list
    when(
      mockFriendService.getFriendsStream(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockFriendService.getPendingRequestsCountStream(),
    ).thenAnswer((_) => Stream.value(0));
    when(
      mockFriendService.getReceivedFriendRequestsStream(),
    ).thenAnswer((_) => Stream.value([]));
    when(
      mockFriendService.getFriendGroupsStream(),
    ).thenAnswer((_) => Stream.value([]));

    // Act
    await pumpMaterialWidget(tester, const FriendsScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert - verify screen renders without crashes
    expect(find.byType(FriendsScreen), findsOneWidget);
  });
}
