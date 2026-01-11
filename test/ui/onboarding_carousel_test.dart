import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/screens/onboarding/onboarding_carousel.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

import '../firebase_test_helper.dart';

class MockUserController extends GetxController
    with Mock
    implements UserController {}

void main() {
  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();
  });

  testWidgets('OnboardingCarousel renders correctly', (
    WidgetTester tester,
  ) async {
    // Arrange
    final mockUserController = MockUserController();
    Get.put<UserController>(mockUserController);

    // Set screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(const GetMaterialApp(home: OnboardingCarousel()));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(OnboardingCarousel), findsOneWidget);
    expect(find.byType(LiquidGlassButton), findsWidgets);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.byIcon(Icons.phone), findsOneWidget);
  });
}
