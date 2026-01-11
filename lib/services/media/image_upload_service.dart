import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../advanced_permission_service.dart';
import '../../utils/app_logger.dart';

/// Result enum for image upload operations
enum ImageUploadResult {
  success,
  error,
  cancelled,
  permissionDenied,
  sizeTooLarge,
}

/// Response model for image upload operations
class ImageUploadResponse {
  final ImageUploadResult result;
  final String? downloadUrl;
  final String? errorMessage;
  final double? compressionRatio;

  ImageUploadResponse({
    required this.result,
    this.downloadUrl,
    this.errorMessage,
    this.compressionRatio,
  });
}

/// Service for handling image upload, compression, and Firebase Storage operations
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  // Configuration constants
  static const int _maxFileSizeMB = 10;
  static const int _maxFileSizeBytes = _maxFileSizeMB * 1024 * 1024;

  /// Pick and compress image from camera or gallery
  static Future<XFile?> pickImage({
    required ImageSource source,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      AppLogger.d('🎯 Picking image from ${source.name}...');

      // Pick image with size constraints
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
        preferredCameraDevice:
            CameraDevice.front, // Default to front camera for profile pics
      );

      if (pickedFile == null) {
        AppLogger.w('🚫 No image selected');
        return null;
      }

      // Check file size
      final int fileSize = await pickedFile.length();
      final double fileSizeMB = fileSize / (1024 * 1024);

      AppLogger.d('📏 Original image: ${fileSizeMB.toStringAsFixed(2)} MB');

      if (fileSize > _maxFileSizeBytes) {
        AppLogger.w(
          '❌ File too large: ${fileSizeMB.toStringAsFixed(2)} MB (max: $_maxFileSizeMB MB)',
        );
        throw Exception(
          'Image size too large. Maximum size is $_maxFileSizeMB MB.',
        );
      }

      // Compress image if needed
      final XFile compressedImage = await _compressImage(
        pickedFile,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final int compressedSize = await compressedImage.length();
      final double compressedSizeMB = compressedSize / (1024 * 1024);
      final double compressionRatio =
          ((fileSize - compressedSize) / fileSize * 100);

      AppLogger.d(
        '✅ Image prepared: ${compressedSizeMB.toStringAsFixed(2)} MB (${compressionRatio.toStringAsFixed(1)}% reduction)',
      );

      return compressedImage;
    } catch (e, st) {
      AppLogger.e('❌ Error picking image', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Enhanced pick image with proper permission handling
  static Future<XFile?> pickImageWithPermissions({
    required BuildContext context,
    required ImageSource source,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      // Step 1: Request appropriate permission
      final permissionType = source == ImageSource.camera
          ? PermissionType.camera
          : PermissionType.gallery;

      final hasPermission = await AdvancedPermissionService.requestPermission(
        context,
        permissionType,
      );

      if (!hasPermission) {
        AppLogger.w('❌ Permission denied for ${permissionType.toString()}');
        return null;
      }

      // Step 2: Proceed with existing image picking logic
      return await pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    } catch (e, st) {
      AppLogger.e(
        '❌ Error in pickImageWithPermissions',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Compress image to reduce file size
  static Future<XFile> _compressImage(
    XFile originalImage, {
    int quality = 85,
    int maxWidth = 800,
    int maxHeight = 800,
  }) async {
    try {
      final int originalSize = await originalImage.length();
      final double originalSizeMB = originalSize / (1024 * 1024);

      AppLogger.d(
        '🗜️ Compressing image (${originalSizeMB.toStringAsFixed(2)} MB)...',
      );

      // Create temporary directory for compression
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = '${tempDir.path}/compressed_${_uuid.v4()}.jpg';

      // Compress the image
      final XFile? compressedImage =
          await FlutterImageCompress.compressAndGetFile(
            originalImage.path,
            targetPath,
            quality: quality,
            minWidth: maxWidth,
            minHeight: maxHeight,
            format: CompressFormat.jpeg,
            keepExif: false, // Remove EXIF data to reduce size
            autoCorrectionAngle: true, // Auto-rotate based on EXIF
          );

      if (compressedImage != null) {
        // Calculate compression results
        final int compressedSize = await File(compressedImage.path).length();
        final double compressedSizeMB = compressedSize / (1024 * 1024);
        final double compressionRatio =
            ((originalSize - compressedSize) / originalSize * 100);

        AppLogger.d('✅ Compression complete:');
        AppLogger.d('   Original: ${originalSizeMB.toStringAsFixed(2)} MB');
        AppLogger.d('   Compressed: ${compressedSizeMB.toStringAsFixed(2)} MB');
        AppLogger.d('   Reduction: ${compressionRatio.toStringAsFixed(1)}%');

        return compressedImage;
      }

      AppLogger.w('⚠️ Compression failed, using original image');
      return originalImage;
    } catch (e, st) {
      AppLogger.e('❌ Error compressing image', error: e, stackTrace: st);
      return originalImage; // Return original if compression fails
    }
  }

  /// Upload custom profile picture to Firebase Storage
  static Future<ImageUploadResponse> uploadCustomProfilePicture(
    XFile imageFile,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return ImageUploadResponse(
          result: ImageUploadResult.error,
          errorMessage: 'User not authenticated',
        );
      }

      AppLogger.d('🚀 Starting upload for user: ${user.uid}');

      // Create unique filename with timestamp
      final String fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'users/${user.uid}/profile_pictures/$fileName';

      // Delete old custom profile pictures first
      await _deleteOldCustomProfilePictures(user.uid);

      // Create Firebase Storage reference
      final Reference storageRef = _storage.ref().child(filePath);

      // Prepare upload metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'custom_profile_picture',
          'version': '1.0',
        },
      );

      // Read image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final double imageSizeMB = imageBytes.length / (1024 * 1024);

      AppLogger.d('📤 Uploading image: ${imageSizeMB.toStringAsFixed(2)} MB');

      // Upload to Firebase Storage with progress tracking
      final UploadTask uploadTask = storageRef.putData(imageBytes, metadata);

      // Optional: Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        AppLogger.d(
          '📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
      });

      // Wait for upload completion
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      AppLogger.d('✅ Custom profile picture uploaded successfully');
      AppLogger.d('🔗 Download URL: ${AppLogger.sanitizeUrl(downloadUrl)}');

      return ImageUploadResponse(
        result: ImageUploadResult.success,
        downloadUrl: downloadUrl,
      );
    } catch (e, st) {
      AppLogger.e(
        '❌ Error uploading custom profile picture',
        error: e,
        stackTrace: st,
      );
      return ImageUploadResponse(
        result: ImageUploadResult.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Delete old custom profile pictures to save storage space
  static Future<void> _deleteOldCustomProfilePictures(String userId) async {
    try {
      AppLogger.d('🗑️ Cleaning up old profile pictures for user: $userId');

      final Reference userProfileDir = _storage.ref().child(
        'users/$userId/profile_pictures',
      );
      final ListResult result = await userProfileDir.listAll();

      // Delete all existing profile pictures
      for (Reference item in result.items) {
        await item.delete();
        AppLogger.d('🗑️ Deleted old profile picture: ${item.name}');
      }
      AppLogger.d('✅ Old profile pictures cleaned up');
    } catch (e) {
      AppLogger.w('⚠️ Error cleaning up old profile pictures: $e');
      // Don't throw - this is not critical for the upload process
    }
  }

  /// Remove all custom profile pictures for a user (when switching to default)
  static Future<void> removeAllCustomProfilePictures() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _deleteOldCustomProfilePictures(user.uid);
      AppLogger.d(
        '✅ All custom profile pictures removed for user: ${user.uid}',
      );
    } catch (e, st) {
      AppLogger.e(
        '❌ Error removing custom profile pictures',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get the effective profile picture URL for display
  /// This determines which image to show based on the user's profile settings
  static String? getEffectiveProfilePictureUrl({
    String? profileImageType,
    String? customPhotoURL,
    String? photoURL,
    String? defaultImageId,
  }) {
    switch (profileImageType) {
      case 'custom':
        return customPhotoURL;
      case 'memoji':
      case 'default':
        return defaultImageId; // This will be the asset path like 'assets/memoji/1.png'
      case 'google':
        return photoURL;
      default:
        // Fallback logic for existing users without profileImageType
        if (customPhotoURL != null && customPhotoURL.isNotEmpty) {
          return customPhotoURL;
        }
        if (photoURL != null && photoURL.isNotEmpty) {
          return photoURL;
        }
        return defaultImageId;
    }
  }

  /// Check if a URL is a custom uploaded image (Firebase Storage)
  static bool isCustomImage(String? url) {
    return url != null && url.contains('firebasestorage.googleapis.com');
  }

  /// Check if a URL is a Google profile image
  static bool isGoogleImage(String? url) {
    return url != null && url.contains('googleusercontent.com');
  }

  /// Check if a URL is a local asset (memoji/default avatar)
  static bool isAssetImage(String? url) {
    return url != null && url.startsWith('assets/');
  }
}
