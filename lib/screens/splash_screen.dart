import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/splash_screen/shopple_splash_screen.dart';

import 'onboarding/onboarding_carousel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static FirebaseAuth? _authOverride;
  static set auth(FirebaseAuth instance) => _authOverride = instance;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _isSplashScreenVisible = ValueNotifier(true);
  final _isAppReady = ValueNotifier(false);

  late final _controller = ShoppleSplashScreen.createController(this);

  Future<void>? _loader;

  @override
  void initState() {
    super.initState();

    _controller.addStatusListener((AnimationStatus status) {
      _isSplashScreenVisible.value = !status.isCompleted;
      if (status.isCompleted) {
        _navigateToApp();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loader ??= _loadAndStartAnimation();
  }

  @override
  void dispose() {
    _isSplashScreenVisible.dispose();
    _isAppReady.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAndStartAnimation() async {
    // Always show splash for minimum 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Prepare navigation destination
    await _prepareNavigation();

    // Mark app as ready and start animation
    _isAppReady.value = true;

    // Start the splash animation
    if (mounted) {
      _controller.forward();
    }
  }

  Future<void> _prepareNavigation() async {
    try {
      // This prepares the navigation target but doesn't navigate yet
      User? currentUser =
          (SplashScreen._authOverride ?? FirebaseAuth.instance).currentUser;

      if (kDebugMode) {
        AppLogger.d("Splash: Current user = ${currentUser?.email}");
      }

      if (currentUser != null) {
        // User is authenticated - prepare UserController
        // OPTIMIZED: Don't block navigation with heavy initialization
        try {
          UserController userController = Get.find<UserController>();
          // Check session validity before allowing navigation
          await userController.checkSessionValidity();
          // Initialize tracking in background to avoid blocking navigation
          userController.initializeUserTrackingAsync();
        } catch (e) {
          // If UserController not found, create one
          Get.put(UserController());
          UserController userController = Get.find<UserController>();
          // Check session validity before allowing navigation
          await userController.checkSessionValidity();
          // Initialize tracking in background to avoid blocking navigation
          userController.initializeUserTrackingAsync();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.w("Splash: Error preparing navigation = $e");
      }
    }
  }

  void _navigateToApp() {
    // Navigate immediately without extra async delays
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is authenticated - use UserController for smart navigation
        UserController userController = Get.find<UserController>();
        userController.navigateAfterAuth(); // Remove await to prevent delay
      } else {
        // No user - go to onboarding
        if (kDebugMode) {
          AppLogger.d("Splash: No user, going to OnboardingCarousel");
        }
        if (!mounted) return;
        Get.offAll(() => OnboardingCarousel(), transition: Transition.fadeIn);
      }
    } catch (e) {
      // On any error, go to onboarding
      if (kDebugMode) {
        AppLogger.w("Splash: Error occurred = $e, going to OnboardingCarousel");
      }
      if (!mounted) return;
      Get.offAll(() => OnboardingCarousel(), transition: Transition.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundColor,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Show the animated splash screen
          ValueListenableBuilder(
            valueListenable: _isSplashScreenVisible,
            builder: (context, isSplashScreenVisible, splashScreen) {
              if (isSplashScreenVisible) {
                return splashScreen!;
              }
              return const SizedBox.shrink();
            },
            child: ShoppleSplashScreen(controller: _controller),
          ),
        ],
      ),
    );
  }
}
