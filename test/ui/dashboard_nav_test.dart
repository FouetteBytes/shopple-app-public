import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/widgets/navigation/dasboard_header.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/services/chat/chat_dependency_injector.dart';

import '../firebase_test_helper.dart';
import '../widget_test_helper.dart';

// Mock Controllers
class MockChatSessionController extends GetxController
    with Mock
    implements ChatSessionController {
  @override
  bool get isConnected => true;
}

class MockChatManagementController extends GetxController
    with Mock
    implements ChatManagementController {
  @override
  int get totalUnreadCount => 5;
}

void main() {
  setUp(() async {
    // Setup Firebase Mocks
    await FirebaseTestHelper.setup();

    // Reset GetX before each test
    Get.reset();

    // Register Mock Controllers
    Get.put<ChatSessionController>(MockChatSessionController());
    Get.put<ChatManagementController>(MockChatManagementController());

    // Set Chat Ready flag
    ChatDependencyInjector.isChatReady.value = true;
  });

  testWidgets('DashboardNav renders correctly with title and icons', (
    WidgetTester tester,
  ) async {
    // Act
    await pumpGetXWidget(
      tester,
      const Scaffold(
        body: DashboardNav(
          title: 'Hello, User',
          image: 'https://example.com/avatar.jpg',
        ),
      ),
    );

    // Assert
    expect(find.text('Hello, User'), findsOneWidget);
    // Only the first icon in SlidableIconButton is visible initially
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
    // The chat icon is separate and should be visible
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

    // These are hidden in SlidableIconButton initially
    // expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    // expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('DashboardNav shows unread chat count badge', (
    WidgetTester tester,
  ) async {
    // Act
    await pumpGetXWidget(
      tester,
      const Scaffold(
        body: DashboardNav(
          title: 'Hello, User',
          image: 'https://example.com/avatar.jpg',
        ),
      ),
    );

    // Assert
    expect(
      find.text('5'),
      findsOneWidget,
    ); // Should show '5' from mock controller
  });
}
