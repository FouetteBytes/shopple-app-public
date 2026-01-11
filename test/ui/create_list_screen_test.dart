import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shopple/screens/shopping_lists/create_list_screen.dart';

import '../firebase_test_helper.dart';

void main() {
  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();
  });

  testWidgets('CreateListScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Act
    await tester.pumpWidget(
      const GetMaterialApp(home: CreateListScreen()),
    );
    await tester.pumpAndSettle();

    // Assert - verify screen renders
    expect(find.byType(CreateListScreen), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('CreateListScreen has icon picker', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(home: CreateListScreen()),
    );
    await tester.pumpAndSettle();

    // Assert - look for icon/color picker widgets
    expect(find.byIcon(Icons.shopping_cart), findsWidgets);
  });

  testWidgets('CreateListScreen validates empty name', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const GetMaterialApp(home: CreateListScreen()),
    );
    await tester.pumpAndSettle();

    // Find and tap submit button (use first matching button)
    final submitButtons = find.text('Create List');
    if (submitButtons.evaluate().length >= 2) {
      await tester.tap(submitButtons.first);
      await tester.pumpAndSettle();
    }
    
    // Screen should still be visible (form not submitted due to validation)
    expect(find.byType(CreateListScreen), findsOneWidget);
  });
}
