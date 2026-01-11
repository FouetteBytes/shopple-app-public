import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget to show when an AI feature is disabled via Remote Config
/// Displays "Coming Soon" with animated icon
class AIFeatureComingSoon extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const AIFeatureComingSoon({
    super.key,
    required this.featureName,
    required this.description,
    this.icon = Icons.auto_awesome,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 48.0 : 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon Container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: isTablet ? 120 : 100,
                    height: isTablet ? 120 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isTablet ? 60 : 50,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Coming Soon Badge
            _AnimatedBadge(isTablet: isTablet),

            SizedBox(height: isTablet ? 24 : 16),

            // Feature Name
            Text(
              featureName,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 28 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Description
            Text(
              description,
              style: GoogleFonts.lato(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white60,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Sparkle Animation
            _SparkleAnimation(),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBadge extends StatefulWidget {
  final bool isTablet;

  const _AnimatedBadge({required this.isTablet});

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isTablet ? 24 : 20,
              vertical: widget.isTablet ? 12 : 10,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch,
                  size: widget.isTablet ? 20 : 16,
                  color: Colors.white,
                ),
                SizedBox(width: widget.isTablet ? 10 : 8),
                Text(
                  'COMING SOON',
                  style: GoogleFonts.poppins(
                    fontSize: widget.isTablet ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SparkleAnimation extends StatefulWidget {
  @override
  State<_SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<_SparkleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 120,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final opacity = ((_controller.value + delay) % 1.0);
                  return Opacity(
                    opacity: opacity > 0.5 ? 1.0 - opacity : opacity * 2,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: Colors.amber,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
