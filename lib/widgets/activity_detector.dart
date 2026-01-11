import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shopple/controllers/user_controller.dart';

class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    return GestureDetector(
      onTap: () => userController.recordActivity(),
      onScaleUpdate: (_) => userController.recordActivity(),
      child: Listener(
        onPointerDown: (_) => userController.recordActivity(),
        onPointerMove: (_) => userController.recordActivity(),
        child: child,
      ),
    );
  }
}
