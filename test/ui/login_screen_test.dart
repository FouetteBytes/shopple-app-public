import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/controllers/auth_controller.dart';
import 'package:shopple/screens/auth/login.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';

import '../firebase_test_helper.dart';

class MockUserController extends GetxController
    with Mock
    implements UserController {
  @override
  Future<bool> loginWithEmailPassword(String email, String password) async {
    return true;
  }
}

class MockAuthController extends GetxController
    with Mock
    implements AuthController {}

void main() {
  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();
  });

  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Arrange
    final mockUserController = MockUserController();
    final mockAuthController = MockAuthController();
    Get.put<UserController>(mockUserController);
    Get.put<AuthController>(mockAuthController);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(
      GetMaterialApp(home: Login(email: 'test@example.com')),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(Login), findsOneWidget);
    expect(find.byType(LabelledFormInput), findsOneWidget);
  });

  testWidgets('Login screen shows password field', (WidgetTester tester) async {
    // Arrange
    final mockUserController = MockUserController();
    final mockAuthController = MockAuthController();
    Get.put<UserController>(mockUserController);
    Get.put<AuthController>(mockAuthController);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(
      GetMaterialApp(home: Login(email: 'user@test.com')),
    );
    await tester.pumpAndSettle();

    // Assert - check for password field
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
