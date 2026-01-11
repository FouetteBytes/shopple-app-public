import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../values/values.dart';
import 'package:shopple/utils/app_logger.dart';

enum PermissionType { camera, gallery, storage }

class AdvancedPermissionService {
  static final Map<PermissionType, Permission> _permissionMap = {
    PermissionType.camera: Permission.camera,
    PermissionType.gallery: Permission.photos,
    PermissionType.storage: Permission.storage,
  };

  /// Request permission with proper UI feedback using existing app theme.
  static Future<bool> requestPermission(
    BuildContext context,
    PermissionType permissionType, {
    bool showRationale = true,
  }) async {
    try {
      final permission = _permissionMap[permissionType];
      if (permission == null) return false;

      // Check current status.
      final status = await permission.status;
      if (!context.mounted) return false;

      switch (status) {
        case PermissionStatus.granted:
          return true;

        case PermissionStatus.denied:
          if (showRationale) {
            final shouldRequest = await _showPermissionRationaleDialog(
              context,
              permissionType,
            );
            if (!shouldRequest) return false;
          }

          // Request permission.
          final result = await permission.request();
          return result == PermissionStatus.granted;

        case PermissionStatus.permanentlyDenied:
          if (!context.mounted) return false;
          await _showPermissionDeniedDialog(context, permissionType);
          return false;

        case PermissionStatus.restricted:
          if (!context.mounted) return false;
          await _showPermissionRestrictedDialog(context, permissionType);
          return false;

        default:
          return false;
      }
    } catch (e) {
      AppLogger.e('❌ Error requesting permission', error: e);
      if (context.mounted) {
        _showErrorNotification(context, 'Permission request failed');
      }
      return false;
    }
  }

  /// Show permission rationale using existing app UI components.
  static Future<bool> _showPermissionRationaleDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    // Using existing app colors and styling patterns.
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface, // Using existing surface color.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ), // Match existing border radius.
          ),
          title: Row(
            children: [
              Icon(
                _getPermissionIcon(permissionType),
                color: AppColors.primaryAccentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                _getPermissionTitle(permissionType),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            _getPermissionMessage(permissionType),
            style: TextStyle(
              color: AppColors.primaryText70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not Now',
                style: TextStyle(color: AppColors.primaryText70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Allow Access',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Show settings redirect dialog for permanently denied permissions.
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: AppColors.primaryAccentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Permission Required',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Please enable ${_getPermissionName(permissionType)} permission in app settings to upload profile pictures.',
            style: TextStyle(
              color: AppColors.primaryText70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryText70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show restriction dialog.
  static Future<void> _showPermissionRestrictedDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    _showErrorNotification(
      context,
      '${_getPermissionName(permissionType)} access is restricted on this device',
    );
  }

  /// Show error notification using existing notification pattern.
  static void _showErrorNotification(BuildContext context, String message) {
    // Using existing notification pattern from profile pages.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Helper methods for permission messages and icons.
  static IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.gallery:
        return Icons.photo_library;
      case PermissionType.storage:
        return Icons.storage;
    }
  }

  static String _getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera Access';
      case PermissionType.gallery:
        return 'Photo Library Access';
      case PermissionType.storage:
        return 'Storage Access';
    }
  }

  static String _getPermissionMessage(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Shopple needs camera access to take profile pictures. This helps you personalize your shopping experience.';
      case PermissionType.gallery:
        return 'Shopple needs access to your photo library to select profile pictures from your existing photos.';
      case PermissionType.storage:
        return 'Shopple needs storage access to save and manage your profile pictures efficiently.';
    }
  }

  static String _getPermissionName(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'camera';
      case PermissionType.gallery:
        return 'photo library';
      case PermissionType.storage:
        return 'storage';
    }
  }
}
