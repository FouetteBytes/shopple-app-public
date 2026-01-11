import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/ai_agent_bottom_sheet.dart';
import 'package:shopple/utils/app_logger.dart';

/// Service to manage the global floating AI assistant button
/// Features:
/// - Smart context-aware visibility (hides during loading/onboarding)
/// - Draggable and repositionable across main app screens
/// - Persists position in SharedPreferences
/// - Modern liquid glass design with sophisticated animations
/// - Smart positioning to avoid UI conflicts
/// - Elegant micro-interactions with sparkle effects
class FloatingAIService extends GetxService {
  static FloatingAIService get instance => Get.find<FloatingAIService>();

  // Reactive state
  final RxBool _isVisible = false.obs; // Start hidden by default
  final RxDouble _xPosition = 300.0.obs;
  final RxDouble _yPosition = 500.0.obs;
  final RxBool _isDragging = false.obs;
  final RxBool _isHovered = false.obs;
  final RxBool _isExpanded = false.obs;
  final RxBool _isContextAllowed = false.obs; // New: context-aware visibility

  // Constants
  static const double buttonSize = 56.0;
  static const double expandedWidth = 180.0;
  static const double cornerPadding = 16.0;
  static const String _positionKey = 'ai_floating_button_position';
  static const String _visibilityKey = 'ai_floating_button_visible';

  // Screen contexts where AI button should NOT appear
  static const List<String> _excludedRoutes = [
    '/splash',
    '/onboarding',
    '/login',
    '/signup',
    '/loading',
  ];

  // Getters
  bool get isVisible => _isVisible.value && _isContextAllowed.value;
  double get xPosition => _xPosition.value;
  double get yPosition => _yPosition.value;
  bool get isDragging => _isDragging.value;
  bool get isHovered => _isHovered.value;
  bool get isExpanded => _isExpanded.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedPosition();
    _setupRouteListener();
  }

  void _setupRouteListener() {
    // Check visibility periodically based on current route
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!Get.isRegistered<FloatingAIService>()) {
        timer.cancel();
        return;
      }
      _updateContextVisibility();
    });
  }

  void _updateContextVisibility([String? route]) {
    final currentRoute = route ?? Get.currentRoute;
    final shouldShow = !_excludedRoutes.any(
      (excluded) => currentRoute.contains(excluded),
    );
    _isContextAllowed.value = shouldShow;

    // Auto-show on main app screens if user preference allows
    if (shouldShow && _isVisible.value) {
      // Button will appear due to reactive getter
    }
  }

  /// Enable AI button for main app screens (call after onboarding/login complete)
  void enableForMainApp() {
    AppLogger.d('FloatingAI: Enabling for main app');
    _isContextAllowed.value = true;
    _isVisible.value = true;
    AppLogger.d(
      'FloatingAI: _isVisible=${_isVisible.value}, _isContextAllowed=${_isContextAllowed.value}',
    );
    _savePosition();
  }

  /// Disable AI button for loading/onboarding screens
  void disableForSpecialScreens() {
    _isContextAllowed.value = false;
  }

  /// Temporarily hide AI button (e.g., when modal/bottom sheet is open)
  void hideTemporarily() {
    _isVisible.value = false;
  }

  /// Show AI button again after temporary hide
  void showAfterHide() {
    _isVisible.value = true;
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPosition = prefs.getString(_positionKey);
      final savedVisibility = prefs.getBool(_visibilityKey);

      if (savedPosition != null) {
        final parts = savedPosition.split(',');
        if (parts.length == 2) {
          _xPosition.value = double.tryParse(parts[0]) ?? 300.0;
          _yPosition.value = double.tryParse(parts[1]) ?? 500.0;
        }
      }

      if (savedVisibility != null) {
        _isVisible.value = savedVisibility;
      }
    } catch (e) {
      // Use default position if loading fails
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _positionKey,
        '${_xPosition.value},${_yPosition.value}',
      );
      await prefs.setBool(_visibilityKey, _isVisible.value);
    } catch (e) {
      // Ignore save errors
    }
  }

  void updatePosition(double x, double y) {
    // Constrain position to screen bounds with padding
    final screenSize = Get.size;
    final constrainedX = math.max(
      cornerPadding,
      math.min(x, screenSize.width - buttonSize - cornerPadding),
    );
    final constrainedY = math.max(
      cornerPadding + kToolbarHeight,
      math.min(y, screenSize.height - buttonSize - cornerPadding - 100),
    );

    _xPosition.value = constrainedX;
    _yPosition.value = constrainedY;
    _savePosition();
  }

  void setDragging(bool dragging) {
    _isDragging.value = dragging;
    if (dragging) {
      HapticFeedback.lightImpact();
    }
  }

  void setHovered(bool hovered) {
    _isHovered.value = hovered;
  }

  void setExpanded(bool expanded) {
    _isExpanded.value = expanded;
  }

  void toggleVisibility() {
    _isVisible.value = !_isVisible.value;
    _savePosition();
  }

  void hide() {
    _isVisible.value = false;
    _savePosition();
  }

  void show() {
    _isVisible.value = true;
    _savePosition();
  }

  void openAIAssistant() {
    HapticFeedback.mediumImpact();
    setExpanded(false);

    // Hide the floating button while bottom sheet is open
    hideTemporarily();

    // Show AI assistant bottom sheet with proper backdrop blur
    Get.bottomSheet(
      const AIAgentBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      // Add backdrop filter for blur effect
      settings: const RouteSettings(name: '/ai-assistant'),
    ).then((_) {
      // Show the button again when bottom sheet closes
      showAfterHide();
    });
  }
}

/// Widget that displays the floating AI button
class FloatingAIButton extends StatefulWidget {
  const FloatingAIButton({super.key});

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _expandController;
  late AnimationController _glowController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500), // Slower, more elegant
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _expandAnimation =
        Tween<double>(
          begin: FloatingAIService.buttonSize,
          end: FloatingAIService.expandedWidth,
        ).animate(
          CurvedAnimation(
            parent: _expandController,
            curve: Curves.easeOutCubic,
          ),
        );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Only start the subtle glow animation (no pulsing)
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _expandController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final service = FloatingAIService.instance;

      AppLogger.d('FloatingAI Widget: isVisible=${service.isVisible}');

      if (!service.isVisible) {
        AppLogger.d(
          'FloatingAI Widget: Not visible, returning SizedBox.shrink()',
        );
        return const SizedBox.shrink();
      }

      AppLogger.d(
        'FloatingAI Widget: Rendering button at (${service.xPosition}, ${service.yPosition})',
      );

      // Update expand animation based on service state
      if (service.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }

      // Update hover animation based on service state
      if (service.isHovered && !service.isDragging) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }

      return Positioned(
        left: service.xPosition,
        top: service.yPosition,
        child: GestureDetector(
          onPanStart: (_) => service.setDragging(true),
          onPanUpdate: (details) {
            service.updatePosition(
              service.xPosition + details.delta.dx,
              service.yPosition + details.delta.dy,
            );
          },
          onPanEnd: (_) => service.setDragging(false),
          onTap: service.openAIAssistant,
          onLongPress: () => service.setExpanded(!service.isExpanded),
          child: MouseRegion(
            onEnter: (_) => service.setHovered(true),
            onExit: (_) => service.setHovered(false),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _hoverController,
                _expandController,
                _glowController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _hoverAnimation.value,
                  child: _buildAIButton(service),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAIButton(FloatingAIService service) {
    return Container(
      width: service.isExpanded
          ? _expandAnimation.value
          : FloatingAIService.buttonSize,
      height: FloatingAIService.buttonSize,
      decoration: _buildButtonDecoration(service),
      child: service.isExpanded
          ? _buildExpandedContent()
          : _buildCollapsedContent(),
    );
  }

  BoxDecoration _buildButtonDecoration(FloatingAIService service) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: _buildAIGradient(service),
      boxShadow: _buildAIShadows(service),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
    );
  }

  LinearGradient _buildAIGradient(FloatingAIService service) {
    final glowIntensity = _glowAnimation.value;
    final hoverIntensity = service.isHovered ? 0.3 : 0.0;
    double clampAlpha(double a) => a.clamp(0.0, 1.0);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryAccentColor.withValues(
          alpha: clampAlpha(0.9 + hoverIntensity),
        ),
        AppColors.lightMauveBackgroundColor.withValues(
          alpha: clampAlpha(0.8 + hoverIntensity),
        ),
        AppColors.primaryAccentColor.withValues(
          alpha: clampAlpha(0.7 + glowIntensity * 0.2),
        ),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  List<BoxShadow> _buildAIShadows(FloatingAIService service) {
    final glowIntensity = _glowAnimation.value;
    final hoverMultiplier = service.isHovered ? 1.5 : 1.0;
    double clampAlpha(double a) => a.clamp(0.0, 1.0);

    return [
      // Inner glow
      BoxShadow(
        color: AppColors.primaryAccentColor.withValues(
          alpha: clampAlpha(0.4 * glowIntensity * hoverMultiplier),
        ),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(0, 2),
      ),
      // Outer glow
      BoxShadow(
        color: AppColors.lightMauveBackgroundColor.withValues(
          alpha: clampAlpha(0.3 * glowIntensity * hoverMultiplier),
        ),
        blurRadius: 12,
        spreadRadius: 2,
        offset: const Offset(0, 0),
      ),
      // Ambient glow
      BoxShadow(
        color: AppColors.primaryAccentColor.withValues(
          alpha: clampAlpha(0.2 * glowIntensity),
        ),
        blurRadius: 24,
        spreadRadius: 4,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildCollapsedContent() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle background pattern
          CustomPaint(size: const Size(32, 32), painter: _SparklePainter()),
          // Sparkle AI Icon
          const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Ask AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for sparkle pattern
class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final sparkleSize = size.width * 0.15;

    // Draw multiple sparkles at different positions
    final sparklePositions = [
      Offset(center.dx - sparkleSize * 1.5, center.dy - sparkleSize),
      Offset(center.dx + sparkleSize * 1.2, center.dy - sparkleSize * 0.8),
      Offset(center.dx - sparkleSize * 0.8, center.dy + sparkleSize * 1.3),
      Offset(center.dx + sparkleSize * 0.5, center.dy + sparkleSize * 0.7),
    ];

    for (final pos in sparklePositions) {
      _drawSparkle(canvas, paint, pos, sparkleSize * 0.6);
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    // Draw a 4-pointed star/sparkle
    final path = Path();

    // Vertical line
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx, center.dy + size);

    // Horizontal line
    path.moveTo(center.dx - size, center.dy);
    path.lineTo(center.dx + size, center.dy);

    canvas.drawPath(path, paint);

    // Add a small circle in the center
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.15, paint);
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget to be used in app's main scaffold or root widget
class FloatingAIOverlay extends StatelessWidget {
  final Widget child;

  const FloatingAIOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    AppLogger.d('FloatingAIOverlay: Building overlay');
    return Stack(children: [child, const FloatingAIButton()]);
  }
}
