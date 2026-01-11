import 'package:get/get.dart';
import 'package:shopple/screens/floating_ai_demo_screen.dart';

/// Utility class for easy access to Floating AI features
class FloatingAIUtils {
  /// Navigate to the Floating AI demo screen
  /// Usage: FloatingAIUtils.openDemo();
  static void openDemo() {
    Get.to(() => const FloatingAIDemoScreen());
  }

  /// Quick navigation helper with transition
  static void openDemoWithTransition() {
    Get.to(
      () => const FloatingAIDemoScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
}

/// Extension to make it easier to access from anywhere
extension FloatingAINavigationExtension on GetInterface {
  /// Open Floating AI demo screen
  /// Usage: Get.toFloatingAIDemo();
  void toFloatingAIDemo() {
    Get.to(() => const FloatingAIDemoScreen());
  }
}
