import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Helper function to pump a widget with GetMaterialApp wrapper
/// This is essential for testing widgets that use GetX navigation or state management
Future<void> pumpGetXWidget(
  WidgetTester tester,
  Widget widget, {
  List<GetPage>? getPages,
  String? initialRoute,
}) async {
  await mockNetworkImagesFor(() async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: widget,
        getPages: getPages,
        initialRoute: initialRoute,
      ),
    );
  });
}

/// Helper to pump a standard MaterialApp widget
Future<void> pumpMaterialWidget(WidgetTester tester, Widget widget) async {
  await mockNetworkImagesFor(() async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  });
}
