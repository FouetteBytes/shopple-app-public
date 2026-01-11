import 'package:flutter/material.dart';
import 'package:shopple/utils/app_logger.dart';
import '../models/app_user.dart';
import '../values/values.dart';

class UnsavedChangesService {
  static AppUser? _originalData;
  static AppUser? _currentData;
  static bool _hasUnsavedChanges = false;

  /// Initialize tracking for unsaved changes
  static void startTracking(AppUser originalData) {
    _originalData = originalData;
    _currentData = originalData;
    _hasUnsavedChanges = false;
  }

  /// Update current data and check for changes
  static void updateCurrentData(AppUser newData) {
    _currentData = newData;
    _checkForChanges();
  }

  /// Check if there are changes between original and current data (generic version)
  static bool hasChanges({
    required Map<String, dynamic> originalData,
    required Map<String, dynamic> currentData,
  }) {
    // Compare each field
    for (String key in originalData.keys) {
      final originalValue = originalData[key];
      final currentValue = currentData[key];

      // Handle null comparisons
      if (originalValue != currentValue) {
        // Special handling for strings - trim whitespace
        if (originalValue is String && currentValue is String) {
          if (originalValue.trim() != currentValue.trim()) {
            return true;
          }
        } else {
          return true;
        }
      }
    }

    return false;
  }

  /// Check if there are unsaved changes
  static bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Get current data
  static AppUser? get currentData => _currentData;

  /// Get original data
  static AppUser? get originalData => _originalData;

  /// Clear tracking
  static void clearTracking() {
    _originalData = null;
    _currentData = null;
    _hasUnsavedChanges = false;
  }

  /// Show save confirmation dialog when user tries to leave
  static Future<bool?> showSaveConfirmationDialog(BuildContext context) async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.save_outlined,
                color: AppColors.primaryAccentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Unsaved Changes',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. Do you want to save them before leaving?',
            style: TextStyle(
              color: AppColors.primaryText70,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Discard changes
              child: Text(
                'Discard',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(null), // Cancel, stay on page
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryText70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Save and leave
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result;
  }

  /// Save changes and show success notification
  static Future<bool> saveChanges(
    BuildContext context,
    Future<void> Function(AppUser) saveFunction,
  ) async {
    if (_currentData == null) return false;

    try {
      await saveFunction(_currentData!);

      // Update original data to current data
      _originalData = _currentData;
      _hasUnsavedChanges = false;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryAccentColor,
          ),
        );
      }

      return true;
    } catch (e) {
      AppLogger.e('❌ Error saving changes', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  static void _checkForChanges() {
    if (_originalData == null || _currentData == null) {
      _hasUnsavedChanges = false;
      return;
    }

    // Compare relevant fields for changes
    _hasUnsavedChanges =
        _originalData!.displayName != _currentData!.displayName ||
        _originalData!.firstName != _currentData!.firstName ||
        _originalData!.lastName != _currentData!.lastName ||
        _originalData!.phoneNumber != _currentData!.phoneNumber ||
        _originalData!.profileImageType != _currentData!.profileImageType ||
        _originalData!.customPhotoURL != _currentData!.customPhotoURL ||
        _originalData!.defaultImageId != _currentData!.defaultImageId;
  }
}
