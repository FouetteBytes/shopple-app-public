import 'package:flutter/material.dart';
import '../../services/media/pattern_background_service.dart';
import '../../services/cache/optimized_image_cache_service.dart';
import '../../values/values.dart';

/// Phase 4.2.C: Preview Component
/// Extends existing profile picture widget patterns
/// Uses existing CircleAvatar styling patterns
/// Maintains existing shadow and border effects
/// Applies existing loading state animations

class PatternBackgroundPreview extends StatefulWidget {
  final ProfileBackgroundOption? backgroundOption;
  final double size;
  final String? userInitial;
  final String? profileImageUrl;
  final String?
  profileImageType; // NEW: Determine if background should be shown

  const PatternBackgroundPreview({
    super.key,
    this.backgroundOption,
    this.size = 100.0,
    this.userInitial,
    this.profileImageUrl,
    this.profileImageType,
  });

  @override
  State<PatternBackgroundPreview> createState() =>
      _PatternBackgroundPreviewState();
}

class _PatternBackgroundPreviewState extends State<PatternBackgroundPreview>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Existing shadow effects
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // Background pattern or gradient - ONLY for memoji/default images
            if (_shouldShowBackground()) _buildBackgroundLayer(),

            // Profile content (image or initial)
            if (widget.profileImageUrl != null)
              _buildProfileImage()
            else
              _buildInitialAvatar(),
          ],
        ),
      ),
    );
  }

  /// Determine if background pattern should be shown
  /// Only show for memoji/default images, not for custom uploaded images
  bool _shouldShowBackground() {
    // Show background for:
    // 1. No profile image (showing initials)
    // 2. Memoji/default images
    // 3. When profileImageType is not 'custom'
    if (widget.profileImageUrl == null) return true;

    return widget.profileImageType != 'custom';
  }

  Widget _buildBackgroundLayer() {
    if (widget.backgroundOption == null) {
      // Default gradient using existing colors
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.ballColors[0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    final option = widget.backgroundOption!;

    switch (option.type) {
      case BackgroundType.pattern:
        // Use static patterns only (no animations)
        return PatternBackgroundService.createGeometricPattern(option);

      case BackgroundType.gradient:
      case BackgroundType.solid:
      case BackgroundType.animated: // Convert animated to static
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: option.colors.isNotEmpty
                  ? option.colors
                  : AppColors.ballColors[0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
    }
  }

  Widget _buildProfileImage() {
    // For custom uploaded images, don't add overlay to keep them clear
    if (widget.profileImageType == 'custom') {
      return OptimizedImageCacheService.buildOptimizedProfileImage(
        imageUrl: widget.profileImageUrl!,
        size: widget.size,
        fallbackWidget: _buildInitialAvatar(),
        cacheKey: 'profile_${widget.profileImageUrl.hashCode}',
      );
    }

    // For memoji/default images, add subtle overlay for pattern visibility
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.1,
        ), // Subtle overlay for pattern backgrounds
      ),
      child: OptimizedImageCacheService.buildOptimizedProfileImage(
        imageUrl: widget.profileImageUrl!,
        size: widget.size,
        fallbackWidget: _buildInitialAvatar(),
        cacheKey: 'profile_${widget.profileImageUrl.hashCode}',
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3), // Background for text
      ),
      child: Center(
        child: Text(
          widget.userInitial ?? 'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
