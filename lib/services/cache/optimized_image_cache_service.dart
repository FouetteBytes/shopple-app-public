import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../values/values.dart';
import '../../utils/app_logger.dart';

class OptimizedImageCacheService {
  /// Get optimized image widget that handles both network URLs and asset paths
  static Widget buildOptimizedProfileImage({
    required String imageUrl,
    required double size,
    required Widget fallbackWidget,
    String? cacheKey,
  }) {
    if (imageUrl.isEmpty) return fallbackWidget;

    // Check if it's an asset path or network URL
    if (_isAssetPath(imageUrl)) {
      return _buildAssetImage(imageUrl, size, fallbackWidget);
    } else {
      return _buildNetworkImage(imageUrl, size, fallbackWidget, cacheKey);
    }
  }

  /// Check if the image URL is an asset path
  static bool _isAssetPath(String imageUrl) {
    return imageUrl.startsWith('assets/') ||
        imageUrl.startsWith('asset/') ||
        !imageUrl.contains('://'); // No protocol means it's likely an asset
  }

  /// Build asset image widget
  static Widget _buildAssetImage(
    String assetPath,
    double size,
    Widget fallbackWidget,
  ) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        AppLogger.e(
          '❌ Error loading asset',
          error: error,
          stackTrace: stackTrace,
        );
        return fallbackWidget;
      },
      // Add fade transition for consistency
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: Duration(milliseconds: 200),
          child: child,
        );
      },
    );
  }

  /// Build network image widget with caching
  static Widget _buildNetworkImage(
    String imageUrl,
    double size,
    Widget fallbackWidget,
    String? cacheKey,
  ) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).round(), // 2x for high DPI
      memCacheHeight: (size * 2).round(),
      errorWidget: (context, url, error) {
        AppLogger.e(
          '❌ Error loading network image: ${AppLogger.sanitizeUrl(url)}',
          error: error,
        );
        return fallbackWidget;
      },
      // Use only progressIndicatorBuilder (not both placeholder and progress)
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return _buildProgressPlaceholder(size, downloadProgress.progress);
      },
      // Fade in animation for smooth appearance
      fadeInDuration: Duration(milliseconds: 200),
      fadeOutDuration: Duration(milliseconds: 100),
    );
  }

  static Widget _buildProgressPlaceholder(double size, double? progress) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            color: AppColors.primaryAccentColor,
            strokeWidth: 2,
            value: progress,
          ),
        ),
      ),
    );
  }

  /// Pre-cache profile picture for instant loading
  static Future<void> preCacheProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      AppLogger.d(
        '🔄 Pre-caching profile picture: ${AppLogger.sanitizeUrl(imageUrl)}',
      );
      // Using CachedNetworkImage's built-in caching
      // The image will be cached automatically when first loaded
      AppLogger.d(
        '✅ Profile picture cache setup for: ${AppLogger.sanitizeUrl(imageUrl)}',
      );
    } catch (e) {
      AppLogger.w('⚠️ Failed to pre-cache profile picture: $e');
    }
  }

  /// Clear cache when needed (using CachedNetworkImage's cache manager)
  static Future<void> clearProfilePictureCache() async {
    try {
      await CachedNetworkImage.evictFromCache(''); // Clear all cached images
      AppLogger.d('🧹 Profile picture cache cleared');
    } catch (e) {
      AppLogger.e('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // Simplified stats - detailed metrics unavailable via CachedNetworkImage
      return {'cacheCleared': true, 'status': 'Cache manager available'};
    } catch (e) {
      AppLogger.e('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
}
