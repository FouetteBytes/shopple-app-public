import 'package:flutter_test/flutter_test.dart';
import 'package:shopple/models/friends/friend.dart';
import 'package:shopple/models/friends/friend_request.dart';

/// Unit tests for Friend and FriendRequest models.
/// These tests verify friend model behavior without touching Firebase.
/// All data is created in-memory and isolated.

void main() {
  group('Friend Model Tests', () {
    late Friend baseFriend;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      baseFriend = Friend(
        userId: 'user-123',
        displayName: 'John Doe',
        email: 'john.doe@example.com',
        profileImageUrl: 'https://example.com/avatar.jpg',
        phoneNumber: '+1234567890',
        friendshipDate: testDate,
        status: FriendshipStatus.active,
        signInMethod: 'email',
      );
    });

    group('Basic Properties', () {
      test('creates friend with all fields', () {
        expect(baseFriend.userId, equals('user-123'));
        expect(baseFriend.displayName, equals('John Doe'));
        expect(baseFriend.email, equals('john.doe@example.com'));
        expect(baseFriend.profileImageUrl, equals('https://example.com/avatar.jpg'));
        expect(baseFriend.phoneNumber, equals('+1234567890'));
        expect(baseFriend.friendshipDate, equals(testDate));
        expect(baseFriend.status, equals(FriendshipStatus.active));
        expect(baseFriend.signInMethod, equals('email'));
      });

      test('creates friend with minimal fields', () {
        final minimalFriend = Friend(
          userId: 'user-456',
          displayName: 'Jane Doe',
          email: 'jane@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
        );

        expect(minimalFriend.userId, equals('user-456'));
        expect(minimalFriend.profileImageUrl, isNull);
        expect(minimalFriend.phoneNumber, isNull);
        expect(minimalFriend.signInMethod, isNull);
      });

      test('handles different sign in methods', () {
        final googleFriend = Friend(
          userId: 'google-user',
          displayName: 'Google User',
          email: 'google@gmail.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: 'google',
        );

        expect(googleFriend.signInMethod, equals('google'));

        final phoneFriend = Friend(
          userId: 'phone-user',
          displayName: 'Phone User',
          email: '',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: 'phone',
        );

        expect(phoneFriend.signInMethod, equals('phone'));
      });
    });

    group('Friendship Status', () {
      test('active status is correct', () {
        expect(baseFriend.status, equals(FriendshipStatus.active));
      });

      test('blocked status works', () {
        final blockedFriend = Friend(
          userId: 'blocked-user',
          displayName: 'Blocked User',
          email: 'blocked@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.blocked,
        );

        expect(blockedFriend.status, equals(FriendshipStatus.blocked));
      });

      test('FriendshipStatus enum has all values', () {
        expect(FriendshipStatus.values.length, equals(2));
        expect(FriendshipStatus.values, contains(FriendshipStatus.active));
        expect(FriendshipStatus.values, contains(FriendshipStatus.blocked));
      });
    });

    group('toFirestore', () {
      test('serializes all fields correctly', () {
        final data = baseFriend.toFirestore();

        expect(data['displayName'], equals('John Doe'));
        expect(data['email'], equals('john.doe@example.com'));
        expect(data['profileImageUrl'], equals('https://example.com/avatar.jpg'));
        expect(data['phoneNumber'], equals('+1234567890'));
        expect(data['status'], equals('active'));
        expect(data['signInMethod'], equals('email'));
      });

      test('excludes null signInMethod from serialization', () {
        final friendWithoutSignIn = Friend(
          userId: 'legacy-user',
          displayName: 'Legacy User',
          email: 'legacy@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: null,
        );

        final data = friendWithoutSignIn.toFirestore();

        expect(data.containsKey('signInMethod'), isFalse);
      });

      test('serializes blocked status correctly', () {
        final blockedFriend = Friend(
          userId: 'blocked-user',
          displayName: 'Blocked User',
          email: 'blocked@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.blocked,
        );

        final data = blockedFriend.toFirestore();

        expect(data['status'], equals('blocked'));
      });
    });

    group('Edge Cases', () {
      test('handles empty email', () {
        final phoneOnlyFriend = Friend(
          userId: 'phone-only',
          displayName: 'Phone Only User',
          email: '',
          phoneNumber: '+1987654321',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
          signInMethod: 'phone',
        );

        expect(phoneOnlyFriend.email, isEmpty);
        expect(phoneOnlyFriend.phoneNumber, isNotEmpty);
      });

      test('handles special characters in display name', () {
        final specialFriend = Friend(
          userId: 'special-user',
          displayName: "José María O'Brien-García",
          email: 'jose@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
        );

        expect(specialFriend.displayName, contains('é'));
        expect(specialFriend.displayName, contains("'"));
        expect(specialFriend.displayName, contains('-'));
      });

      test('handles Unicode in display name', () {
        final unicodeFriend = Friend(
          userId: 'unicode-user',
          displayName: '田中太郎 🇯🇵',
          email: 'tanaka@example.com',
          friendshipDate: DateTime.now(),
          status: FriendshipStatus.active,
        );

        expect(unicodeFriend.displayName, contains('田中'));
        expect(unicodeFriend.displayName, contains('🇯🇵'));
      });
    });
  });

  group('FriendRequest Model Tests', () {
    late FriendRequest baseRequest;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      baseRequest = FriendRequest(
        id: 'req-123',
        fromUserId: 'user-sender',
        toUserId: 'user-receiver',
        fromUserName: 'Sender Name',
        fromUserEmail: 'sender@example.com',
        status: FriendRequestStatus.pending,
        createdAt: testDate,
      );
    });

    group('Basic Properties', () {
      test('creates request with all required fields', () {
        expect(baseRequest.id, equals('req-123'));
        expect(baseRequest.fromUserId, equals('user-sender'));
        expect(baseRequest.toUserId, equals('user-receiver'));
        expect(baseRequest.fromUserName, equals('Sender Name'));
        expect(baseRequest.fromUserEmail, equals('sender@example.com'));
        expect(baseRequest.status, equals(FriendRequestStatus.pending));
        expect(baseRequest.createdAt, equals(testDate));
      });
    });

    group('Request Status', () {
      test('pending status works', () {
        expect(baseRequest.status, equals(FriendRequestStatus.pending));
      });

      test('accepted status works', () {
        final acceptedRequest = FriendRequest(
          id: 'req-accepted',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          fromUserName: 'User One',
          fromUserEmail: 'user1@example.com',
          status: FriendRequestStatus.accepted,
          createdAt: DateTime.now(),
        );

        expect(acceptedRequest.status, equals(FriendRequestStatus.accepted));
      });

      test('rejected status works', () {
        final declinedRequest = FriendRequest(
          id: 'req-declined',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          fromUserName: 'User One',
          fromUserEmail: 'user1@example.com',
          status: FriendRequestStatus.declined,
          createdAt: DateTime.now(),
        );

        expect(declinedRequest.status, equals(FriendRequestStatus.declined));
      });

      test('FriendRequestStatus enum has all values', () {
        expect(FriendRequestStatus.values.length, equals(3));
        expect(FriendRequestStatus.values, contains(FriendRequestStatus.pending));
        expect(FriendRequestStatus.values, contains(FriendRequestStatus.accepted));
        expect(FriendRequestStatus.values, contains(FriendRequestStatus.declined));
      });
    });

    group('toFirestore', () {
      test('serializes request correctly', () {
        final data = baseRequest.toFirestore();

        expect(data['fromUserId'], equals('user-sender'));
        expect(data['toUserId'], equals('user-receiver'));
        expect(data['fromUserName'], equals('Sender Name'));
        expect(data['fromUserEmail'], equals('sender@example.com'));
        expect(data['status'], equals('pending'));
      });

      test('serializes different statuses correctly', () {
        final acceptedRequest = FriendRequest(
          id: 'req-accepted',
          fromUserId: 'user-1',
          toUserId: 'user-2',
          fromUserName: 'User One',
          fromUserEmail: 'user1@example.com',
          status: FriendRequestStatus.accepted,
          createdAt: DateTime.now(),
        );

        final data = acceptedRequest.toFirestore();
        expect(data['status'], equals('accepted'));
      });
    });
  });
}
