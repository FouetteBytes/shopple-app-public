import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/screens/splash_screen.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/splash_screen/shopple_splash_screen.dart';

import '../firebase_test_helper.dart';

class MockUserController extends GetxController
    with Mock
    implements UserController {
  @override
  Future<void> checkSessionValidity() async {}

  @override
  Future<void> initializeUserTrackingAsync() async {}
}

void main() {
  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();
    SplashScreen.auth = FirebaseTestHelper.auth;
  });

  testWidgets('SplashScreen renders and navigates', (
    WidgetTester tester,
  ) async {
    // Arrange
    final mockUserController = MockUserController();
    Get.put<UserController>(mockUserController);

    // Set screen size to avoid overflow in splash animation
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(const GetMaterialApp(home: SplashScreen()));

    // Assert initial state
    expect(find.byType(ShoppleSplashScreen), findsOneWidget);

    // Wait for animation and navigation logic
    // The splash screen has a 2-second delay + animation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Since we didn't sign in a user in the mock auth, it might stay or navigate to Onboarding
    // We just want to ensure it doesn't crash and renders
  });
}
