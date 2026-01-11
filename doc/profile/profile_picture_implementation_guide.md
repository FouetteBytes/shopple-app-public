# Profile Picture Upload Implementation Guide

## 📋 Overview

This guide provides comprehensive step-by-step instructions for implementing a profile picture upload feature in the Shopple app. The implementation will **preserve existing profile image selection functionality** while adding custom image upload capabilities. Users will have options to:

1. **Keep existing profile image selection** (default avatars/built-in images)
2. **Upload custom images** (camera/gallery with compression and cloud storage)
3. **Switch between both options** seamlessly

## 🎯 Features to Implement

- ✅ **Preserve Existing System** - Keep current profile image selection intact
- ✅ **Custom Image Upload** - Camera & gallery selection with compression
- ✅ **Hybrid Selection UI** - Combined interface for both options
- ✅ **Firebase Storage Integration** - Cloud storage for custom images only
- ✅ **Smart Caching** - Efficient loading for both image types
- ✅ **Auto Cleanup** - Remove old custom images when new ones are uploaded
- ✅ **Seamless Integration** - Works with existing profile screens
- ✅ **Robust Error Handling** - Comprehensive error handling and user feedback

## 🔍 Pre-Implementation Analysis

### Step 1: Analyze Current Profile Image System

Before implementing, you need to understand your current system:

```bash
# 1. Locate existing profile image functionality
find lib/ -name "*.dart" -exec grep -l "photoURL\|profile.*image\|avatar" {} \;

# 2. Find existing profile image selection screens
find lib/screens/ -name "*profile*" -o -name "*avatar*" -o -name "*image*"

# 3. Check for existing image widgets
find lib/widgets/ -name "*profile*" -o -name "*image*" -o -name "*avatar*"
```

**What to look for:**
- How current profile images are stored (local assets vs URLs)
- Where profile image selection happens
- How profile images are displayed across the app
- Current user model structure for image data

### Step 2: Examine shopple_previous_build Folder

```bash
# Navigate to shopple_previous_build folder
cd shopple_previous_build/

# Look for profile/avatar related files
find . -name "*.dart" -exec grep -l "profile\|avatar\|image" {} \;

# Check for existing UI components you can reuse
ls -la lib/widgets/
ls -la lib/screens/profile/
```

**Document findings:**
- Existing UI patterns for profile images
- Color schemes and styling used
- Widget structures you should follow
- Navigation patterns for profile screens

## 📚 Dependencies Setup

### Step 3: Add Required Dependencies

Open `pubspec.yaml` and add these dependencies:

```yaml
dependencies:
  # Existing dependencies...
  
  # Image handling
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  
  # Firebase Storage (if not already added)
  firebase_storage: ^11.6.0
  
  # Image caching and optimization
  cached_network_image: ^3.3.1
  
  # Utilities
  path_provider: ^2.1.2
  permission_handler: ^11.2.0
  uuid: ^4.3.3

dev_dependencies:
  # Existing dev dependencies...
```

**Install dependencies:**
```bash
cd /path/to/your/shopple-app
flutter pub get
```

### Step 4: Platform-Specific Configuration

#### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml` (inside `<manifest>` tag):

```xml
<!-- Add before <application> tag -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS Configuration
Add to `ios/Runner/Info.plist` (inside `<dict>` tag):

```xml
<key>NSCameraUsageDescription</key>
<string>Shopple needs camera access to take profile pictures</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Shopple needs photo library access to select profile pictures</string>
```

### Step 5: Firebase Storage Setup

1. **Enable Firebase Storage** in Firebase Console:
   - Go to Firebase Console → Your Project → Storage
   - Click "Get Started" and follow setup

2. **Update Firebase Storage Rules** (in Firebase Console → Storage → Rules):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to read/write their own profile pictures
    match /users/{userId}/profile_pictures/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow users to read other users' profile pictures (for collaboration)
    match /users/{userId}/profile_pictures/{allPaths=**} {
      allow read: if request.auth != null;
    }
    
    // File size and type restrictions
    match /{allPaths=**} {
      allow write: if request.auth != null 
        && resource.size < 5 * 1024 * 1024  // 5MB limit
        && resource.contentType.matches('image/.*');  // Images only
    }
  }
}
```

## 🏗️ Detailed Implementation

### Step 6: Enhance User Model (Preserve Existing Data)

**IMPORTANT:** This step enhances your existing `AppUser` model without breaking current functionality.

Open your existing `lib/models/app_user.dart` and add these fields:

```dart
class AppUser {
  // ... ALL your existing fields remain unchanged ...
  
  // NEW FIELDS for enhanced profile picture functionality
  final String? profileImageType;     // 'default', 'custom', 'google'
  final String? customPhotoURL;       // Firebase Storage URL for custom uploads
  final String? defaultImageId;       // ID for built-in avatar selection
  final DateTime? photoUpdatedAt;     // When photo was last updated
  
  const AppUser({
    // ... ALL your existing parameters remain unchanged ...
    
    // NEW PARAMETERS
    this.profileImageType = 'default',  // Default to built-in selection
    this.customPhotoURL,
    this.defaultImageId,
    this.photoUpdatedAt,
  });

  /// Enhanced factory constructor - EXTENDS your existing one
  factory AppUser.fromFirebaseAndFirestore({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    bool emailVerified = false,
    String? signInMethod,
    Map<String, dynamic>? firestoreData,
  }) {
    final data = firestoreData ?? {};
    
    // ... ALL your existing logic remains the same ...
    
    return AppUser(
      // ... ALL your existing fields remain unchanged ...
      uid: uid,
      email: email,
      displayName: displayName ?? data['displayName'],
      // ... continue with all existing fields ...
      
      // NEW FIELDS with backward compatibility
      profileImageType: data['profileImageType'] ?? 'default',
      customPhotoURL: data['customPhotoURL'],
      defaultImageId: data['defaultImageId'],
      photoUpdatedAt: data['photoUpdatedAt']?.toDate(),
    );
  }

  /// Enhanced Firestore conversion - EXTENDS your existing one
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      // ... ALL your existing fields remain unchanged ...
      'email': email,
      'displayName': displayName,
      // ... continue with all existing fields ...
      
      // NEW FIELDS
      'profileImageType': profileImageType,
      'customPhotoURL': customPhotoURL,
      'defaultImageId': defaultImageId,
      'photoUpdatedAt': photoUpdatedAt != null ? Timestamp.fromDate(photoUpdatedAt!) : null,
      
      'lastUpdated': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
    
    return data;
  }

  /// NEW: Get the correct photo URL based on type
  String? get effectivePhotoURL {
    switch (profileImageType) {
      case 'custom':
        return customPhotoURL;
      case 'google':
        return photoURL; // Your existing Google photo URL
      case 'default':
      default:
        return null; // Will show default avatar with initials
    }
  }

  /// NEW: Check if user has custom uploaded image
  bool get hasCustomImage => profileImageType == 'custom' && customPhotoURL != null;

  /// NEW: Enhanced copyWith that preserves all existing functionality
  AppUser copyWith({
    // ... ALL your existing copyWith parameters ...
    String? uid,
    String? email,
    // ... continue with all existing parameters ...
    
    // NEW PARAMETERS
    String? profileImageType,
    String? customPhotoURL,
    String? defaultImageId,
    DateTime? photoUpdatedAt,
  }) {
    return AppUser(
      // ... ALL your existing field assignments ...
      uid: uid ?? this.uid,
      email: email ?? this.email,
      // ... continue with all existing assignments ...
      
      // NEW FIELD ASSIGNMENTS
      profileImageType: profileImageType ?? this.profileImageType,
      customPhotoURL: customPhotoURL ?? this.customPhotoURL,
      defaultImageId: defaultImageId ?? this.defaultImageId,
      photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
    );
  }
}
```

### Step 7: Create Enhanced Image Upload Service

Create `lib/services/image_upload_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ImageUploadResult {
  success,
  cancelled,
  error,
}

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

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// Pick image from gallery or camera with intelligent compression
  static Future<XFile?> pickImage({
    required ImageSource source,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      print('📸 Starting image picker - Source: ${source.toString()}');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
        preferredCameraDevice: CameraDevice.front, // Front camera for selfies
      );

      if (image == null) {
        print('❌ Image picker cancelled by user');
        return null;
      }

      print('✅ Image picked: ${image.path}');
      
      // Check file size and apply additional compression if needed
      final File imageFile = File(image.path);
      final int fileSizeInBytes = await imageFile.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      print('📊 Original image size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      // If file is larger than 1MB, apply aggressive compression
      if (fileSizeInMB > 1.0) {
        print('🔄 Applying additional compression...');
        return await _compressImage(image);
      }

      return image;
      
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Intelligent image compression based on file size
  static Future<XFile?> _compressImage(XFile originalImage) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = '${tempDir.path}/compressed_${_uuid.v4()}.jpg';
      
      // Get original file size
      final File originalFile = File(originalImage.path);
      final int originalSize = await originalFile.length();
      final double originalSizeMB = originalSize / (1024 * 1024);
      
      // Determine compression settings based on original size
      int quality;
      int minWidth, minHeight;
      
      if (originalSizeMB > 5.0) {
        // Very large image: aggressive compression
        quality = 60;
        minWidth = 500;
        minHeight = 500;
      } else if (originalSizeMB > 2.0) {
        // Large image: moderate compression
        quality = 70;
        minWidth = 600;
        minHeight = 600;
      } else {
        // Medium image: light compression
        quality = 80;
        minWidth = 700;
        minHeight = 700;
      }
      
      print('🔧 Compression settings: Quality: $quality%, Min size: ${minWidth}x$minHeight');

      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        originalImage.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
        keepExif: false, // Remove EXIF data to reduce size
        autoCorrectionAngle: true, // Auto-rotate based on EXIF
      );

      if (compressedImage != null) {
        // Calculate compression results
        final int compressedSize = await File(compressedImage.path).length();
        final double compressedSizeMB = compressedSize / (1024 * 1024);
        final double compressionRatio = ((originalSize - compressedSize) / originalSize * 100);
        
        print('✅ Compression complete:');
        print('   Original: ${originalSizeMB.toStringAsFixed(2)} MB');
        print('   Compressed: ${compressedSizeMB.toStringAsFixed(2)} MB');
        print('   Reduction: ${compressionRatio.toStringAsFixed(1)}%');
        
        return compressedImage;
      }

      print('⚠️ Compression failed, using original image');
      return originalImage;
      
    } catch (e) {
      print('❌ Error compressing image: $e');
      return originalImage; // Return original if compression fails
    }
  }

  /// Upload custom profile picture to Firebase Storage
  static Future<ImageUploadResponse> uploadCustomProfilePicture(XFile imageFile) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return ImageUploadResponse(
          result: ImageUploadResult.error,
          errorMessage: 'User not authenticated',
        );
      }

      print('🚀 Starting upload for user: ${user.uid}');

      // Create unique filename with timestamp
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      
      print('📤 Uploading image: ${imageSizeMB.toStringAsFixed(2)} MB');

      // Upload to Firebase Storage with progress tracking
      final UploadTask uploadTask = storageRef.putData(imageBytes, metadata);

      // Optional: Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload completion
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('✅ Custom profile picture uploaded successfully');
      print('🔗 Download URL: $downloadUrl');

      return ImageUploadResponse(
        result: ImageUploadResult.success,
        downloadUrl: downloadUrl,
      );

    } catch (e) {
      print('❌ Error uploading custom profile picture: $e');
      return ImageUploadResponse(
        result: ImageUploadResult.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Delete old custom profile pictures from Firebase Storage
  static Future<void> _deleteOldCustomProfilePictures(String userId) async {
    try {
      print('🗑️ Cleaning up old custom profile pictures...');
      
      // List all files in user's profile pictures folder
      final Reference profilePicturesRef = _storage.ref().child('users/$userId/profile_pictures');
      final ListResult result = await profilePicturesRef.listAll();

      // Delete all existing custom profile pictures
      for (Reference ref in result.items) {
        try {
          await ref.delete();
          print('✅ Deleted old custom profile picture: ${ref.name}');
        } catch (e) {
          print('⚠️ Failed to delete old profile picture: ${ref.name} - $e');
          // Continue with other deletions even if one fails
        }
      }
      
      if (result.items.isNotEmpty) {
        print('🧹 Cleanup complete: ${result.items.length} old images removed');
      }

    } catch (e) {
      print('⚠️ Error during cleanup (continuing with upload): $e');
      // Don't throw error - upload should continue even if cleanup fails
    }
  }

  /// Remove all custom profile pictures for user
  static Future<bool> removeAllCustomProfilePictures() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      print('🗑️ Removing all custom profile pictures for user: ${user.uid}');
      
      await _deleteOldCustomProfilePictures(user.uid);
      
      print('✅ All custom profile pictures removed successfully');
      return true;

    } catch (e) {
      print('❌ Error removing custom profile pictures: $e');
      return false;
    }
  }

  /// Get storage usage for user's profile pictures
  static Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return {'error': 'User not authenticated'};

      final Reference profilePicturesRef = _storage.ref().child('users/${user.uid}/profile_pictures');
      final ListResult result = await profilePicturesRef.listAll();
      
      int totalFiles = result.items.length;
      int totalSizeBytes = 0;
      
      for (Reference ref in result.items) {
        try {
          final FullMetadata metadata = await ref.getMetadata();
          totalSizeBytes += metadata.size ?? 0;
        } catch (e) {
          print('⚠️ Could not get metadata for: ${ref.name}');
        }
      }
      
      final double totalSizeMB = totalSizeBytes / (1024 * 1024);
      
      return {
        'fileCount': totalFiles,
        'totalSizeBytes': totalSizeBytes,
        'totalSizeMB': totalSizeMB,
      };
      
    } catch (e) {
      print('❌ Error getting storage usage: $e');
      return {'error': e.toString()};
    }
  }
}
```

### Step 8: Create Enhanced Profile Picture Widget (Hybrid System)

Create `lib/widgets/enhanced_profile_picture_widget.dart`:

**This widget combines your existing profile image selection with new custom upload functionality.**

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../services/user_service.dart'; // Your existing user service
import '../values/app_colors.dart'; // Your existing app colors
import '../models/app_user.dart'; // Your existing user model

/// Enhanced widget that supports BOTH existing and custom profile pictures
class EnhancedProfilePictureWidget extends StatefulWidget {
  final AppUser? userData;
  final double size;
  final bool isEditable;
  final Function(AppUser)? onUserDataChanged;
  final List<String>? availableDefaultImages; // Your existing default image options

  const EnhancedProfilePictureWidget({
    Key? key,
    this.userData,
    this.size = 100,
    this.isEditable = true,
    this.onUserDataChanged,
    this.availableDefaultImages,
  }) : super(key: key);

  @override
  State<EnhancedProfilePictureWidget> createState() => _EnhancedProfilePictureWidgetState();
}

class _EnhancedProfilePictureWidgetState extends State<EnhancedProfilePictureWidget> {
  bool _isUploading = false;
  AppUser? _currentUserData;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
  }

  @override
  void didUpdateWidget(EnhancedProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _currentUserData = widget.userData;
      });
    }
  }

  /// Show comprehensive image selection modal
  Future<void> _showImageSelectionModal() async {
    if (!widget.isEditable) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTextColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Choose Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // SECTION 1: Custom Upload Options
                          _buildSectionHeader('Upload Custom Picture'),
                          _buildCustomUploadOptions(),
                          
                          SizedBox(height: 30),
                          
                          // SECTION 2: Default Avatar Selection (Your existing system)
                          _buildSectionHeader('Choose Default Avatar'),
                          _buildDefaultAvatarSelection(),
                          
                          SizedBox(height: 30),
                          
                          // SECTION 3: Remove/Reset Options
                          if (_currentUserData?.effectivePhotoURL != null)
                            _buildRemoveOptions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 10),
              height: 1,
              color: AppColors.secondaryTextColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomUploadOptions() {
    return Column(
      children: [
        // Camera option
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.camera_alt,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            'Take Photo',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Capture a new profile picture with camera',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _pickCustomImage(ImageSource.camera);
          },
        ),
        
        // Gallery option
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.photo_library,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            'Choose from Gallery',
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Select from your photo gallery',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _pickCustomImage(ImageSource.gallery);
          },
        ),
      ],
    );
  }

  Widget _buildDefaultAvatarSelection() {
    // This integrates with your EXISTING default avatar system
    // You should replace this with your actual default avatar selection logic
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15),
        itemCount: _getDefaultAvatarOptions().length,
        itemBuilder: (context, index) {
          final avatarOption = _getDefaultAvatarOptions()[index];
          final isSelected = _currentUserData?.defaultImageId == avatarOption['id'] && 
                           _currentUserData?.profileImageType == 'default';
          
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _selectDefaultAvatar(avatarOption['id'], avatarOption['url']);
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: avatarOption['url'] != null
                    ? Image.asset(
                        avatarOption['url'],
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: avatarOption['color'] ?? AppColors.primaryColor.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            avatarOption['initials'] ?? '?',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemoveOptions() {
    return Column(
      children: [
        _buildSectionHeader('Remove Picture'),
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: Text(
            'Remove Current Picture',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Reset to default avatar with initials',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _removeCurrentPicture();
          },
        ),
      ],
    );
  }

  /// Handle custom image upload from camera/gallery
  Future<void> _pickCustomImage(ImageSource source) async {
    setState(() => _isUploading = true);

    try {
      // Step 1: Pick and compress image
      final XFile? imageFile = await ImageUploadService.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        quality: 85,
      );

      if (imageFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Step 2: Upload to Firebase Storage
      final ImageUploadResponse response = await ImageUploadService.uploadCustomProfilePicture(imageFile);

      if (response.result == ImageUploadResult.success && response.downloadUrl != null) {
        // Step 3: Update user data with custom image
        final updatedUserData = _currentUserData?.copyWith(
          profileImageType: 'custom',
          customPhotoURL: response.downloadUrl,
          photoUpdatedAt: DateTime.now(),
        );

        // Step 4: Save to Firestore
        if (updatedUserData != null) {
          await UserService.updateUserProfileImage(updatedUserData);
          
          setState(() {
            _currentUserData = updatedUserData;
          });

          // Step 5: Notify parent widget
          widget.onUserDataChanged?.call(updatedUserData);

          _showSuccessMessage('Custom profile picture updated successfully!');
        }
      } else {
        throw Exception(response.errorMessage ?? 'Upload failed');
      }

    } catch (e) {
      print('Error uploading custom image: $e');
      _showErrorMessage('Failed to upload custom image: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Handle default avatar selection (integrates with your existing system)
  Future<void> _selectDefaultAvatar(String avatarId, String? avatarUrl) async {
    try {
      // Step 1: Remove any existing custom images from storage
      if (_currentUserData?.profileImageType == 'custom') {
        await ImageUploadService.removeAllCustomProfilePictures();
      }

      // Step 2: Update user data with default avatar selection
      final updatedUserData = _currentUserData?.copyWith(
        profileImageType: 'default',
        defaultImageId: avatarId,
        customPhotoURL: null, // Clear custom URL
        photoURL: avatarUrl, // Set to default avatar URL if using assets
        photoUpdatedAt: DateTime.now(),
      );

      // Step 3: Save to Firestore
      if (updatedUserData != null) {
        await UserService.updateUserProfileImage(updatedUserData);
        
        setState(() {
          _currentUserData = updatedUserData;
        });

        // Step 4: Notify parent widget
        widget.onUserDataChanged?.call(updatedUserData);

        _showSuccessMessage('Default avatar selected successfully!');
      }

    } catch (e) {
      print('Error selecting default avatar: $e');
      _showErrorMessage('Failed to select avatar: ${e.toString()}');
    }
  }

  /// Remove current picture and reset to initials
  Future<void> _removeCurrentPicture() async {
    try {
      // Step 1: Remove custom images from storage if applicable
      if (_currentUserData?.profileImageType == 'custom') {
        await ImageUploadService.removeAllCustomProfilePictures();
      }

      // Step 2: Reset user data to use initials only
      final updatedUserData = _currentUserData?.copyWith(
        profileImageType: 'default',
        customPhotoURL: null,
        defaultImageId: null,
        photoURL: null,
        photoUpdatedAt: DateTime.now(),
      );

      // Step 3: Save to Firestore
      if (updatedUserData != null) {
        await UserService.updateUserProfileImage(updatedUserData);
        
        setState(() {
          _currentUserData = updatedUserData;
        });

        // Step 4: Notify parent widget
        widget.onUserDataChanged?.call(updatedUserData);

        _showSuccessMessage('Profile picture removed successfully!');
      }

    } catch (e) {
      print('Error removing picture: $e');
      _showErrorMessage('Failed to remove picture: ${e.toString()}');
    }
  }

  /// Get default avatar options (replace with your existing logic)
  List<Map<String, dynamic>> _getDefaultAvatarOptions() {
    // REPLACE THIS with your existing default avatar system
    // This is just an example - use your actual avatar options
    
    if (widget.availableDefaultImages != null) {
      return widget.availableDefaultImages!.map((imagePath) => {
        'id': imagePath.split('/').last.split('.').first,
        'url': imagePath,
      }).toList();
    }
    
    // Fallback example options - replace with your actual system
    return [
      {'id': 'avatar_1', 'url': 'assets/images/avatars/avatar_1.png'},
      {'id': 'avatar_2', 'url': 'assets/images/avatars/avatar_2.png'},
      {'id': 'avatar_3', 'url': 'assets/images/avatars/avatar_3.png'},
      {'id': 'avatar_4', 'url': 'assets/images/avatars/avatar_4.png'},
      {'id': 'initials', 'url': null, 'initials': _getInitials(), 'color': AppColors.primaryColor.withOpacity(0.2)},
    ];
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? _showImageSelectionModal : null,
      child: Stack(
        children: [
          // Profile picture container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _isUploading
                  ? _buildLoadingState()
                  : _buildProfileImage(),
            ),
          ),

          // Edit button overlay
          if (widget.isEditable && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: widget.size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.surfaceColor,
      child: Center(
        child: SizedBox(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final effectivePhotoURL = _currentUserData?.effectivePhotoURL;
    
    if (effectivePhotoURL != null && effectivePhotoURL.isNotEmpty) {
      // Show custom or Google image with caching
      return CachedNetworkImage(
        imageUrl: effectivePhotoURL,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingState(),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
        memCacheWidth: 400, // Optimize memory usage
        memCacheHeight: 400,
        cacheKey: '${_currentUserData?.uid}_${_currentUserData?.photoUpdatedAt?.millisecondsSinceEpoch}',
      );
    } else if (_currentUserData?.profileImageType == 'default' && 
               _currentUserData?.defaultImageId != null &&
               _currentUserData?.defaultImageId != 'initials') {
      // Show selected default avatar from assets
      final avatarOptions = _getDefaultAvatarOptions();
      final selectedAvatar = avatarOptions.firstWhere(
        (option) => option['id'] == _currentUserData?.defaultImageId,
        orElse: () => avatarOptions.first,
      );
      
      if (selectedAvatar['url'] != null) {
        return Image.asset(
          selectedAvatar['url'],
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    }
    
    // Fallback to initials avatar
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final displayName = _currentUserData?.displayNameForSearch ?? _currentUserData?.displayName ?? '';
    
    if (displayName.isNotEmpty) {
      final words = displayName.trim().split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.length == 1) {
        return words[0][0].toUpperCase();
      }
    }
    
    // Fallback to email initial
    final email = _currentUserData?.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    
    return '?';
  }
}
```

### Step 9: Enhance User Service (Extend Existing)

**IMPORTANT:** These are additions to your existing `UserService`. Don't replace your existing methods.

Add these methods to your existing `lib/services/user_service.dart`:

```dart
// ADD THESE METHODS to your existing UserService class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  // ... ALL your existing methods remain unchanged ...
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Enhanced method to update user profile image data
  static Future<void> updateUserProfileImage(AppUser updatedUserData) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('📝 Updating user profile image data for: ${user.uid}');

      // Update Firestore document with new profile image data
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageType': updatedUserData.profileImageType,
        'customPhotoURL': updatedUserData.customPhotoURL,
        'defaultImageId': updatedUserData.defaultImageId,
        'photoURL': updatedUserData.photoURL, // For backward compatibility
        'photoUpdatedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth profile for consistency (optional)
      if (updatedUserData.effectivePhotoURL != null) {
        await user.updatePhotoURL(updatedUserData.effectivePhotoURL);
      }

      print('✅ User profile image data updated successfully');
      
    } catch (e) {
      print('❌ Error updating user profile image data: $e');
      rethrow;
    }
  }

  /// KEEP your existing updateUserPhotoURL method for backward compatibility
  static Future<void> updateUserPhotoURL(String? photoURL) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth profile (optional)
      await user.updatePhotoURL(photoURL);

      print('✅ User photo URL updated successfully (legacy method)');
      
    } catch (e) {
      print('❌ Error updating user photo URL: $e');
      rethrow;
    }
  }

  /// Get user's complete profile data including new image fields
  static Future<AppUser?> getEnhancedUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Create AppUser from Firestore data with enhanced fields
        return AppUser.fromFirebaseAndFirestore(
          uid: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'],
          photoURL: data['photoURL'],
          phoneNumber: data['phoneNumber'],
          emailVerified: data['emailVerified'] ?? false,
          signInMethod: data['signInMethod'] ?? 'email',
          firestoreData: data,
        );
      }
      
      return null;
      
    } catch (e) {
      print('❌ Error getting enhanced user profile: $e');
      return null;
    }
  }

  /// Get current user's profile with real-time updates
  static Stream<AppUser?> getCurrentUserProfileStream() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((DocumentSnapshot doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser.fromFirebaseAndFirestore(
          uid: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'],
          photoURL: data['photoURL'],
          phoneNumber: data['phoneNumber'],
          emailVerified: data['emailVerified'] ?? false,
          signInMethod: data['signInMethod'] ?? 'email',
          firestoreData: data,
        );
      }
      return null;
    });
  }

  /// Migrate existing users to new profile image system
  static Future<void> migrateUserToEnhancedProfileSystem() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      // Check if user already has new profile image fields
      if (data.containsKey('profileImageType')) {
        print('✅ User already migrated to enhanced profile system');
        return;
      }

      // Migrate existing user data
      Map<String, dynamic> migrationData = {
        'profileImageType': 'default',
        'customPhotoURL': null,
        'defaultImageId': null,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      };

      // If user has existing photoURL, determine its type
      if (data['photoURL'] != null && data['photoURL'].toString().isNotEmpty) {
        final String photoURL = data['photoURL'];
        
        if (photoURL.contains('firebasestorage.googleapis.com')) {
          // It's a custom uploaded image
          migrationData['profileImageType'] = 'custom';
          migrationData['customPhotoURL'] = photoURL;
        } else if (photoURL.contains('googleusercontent.com')) {
          // It's a Google profile image
          migrationData['profileImageType'] = 'google';
        } else {
          // It might be a default avatar or asset
          migrationData['profileImageType'] = 'default';
          migrationData['defaultImageId'] = 'existing_avatar';
        }
      }

      await _firestore.collection('users').doc(user.uid).update(migrationData);
      
      print('✅ User migrated to enhanced profile system');
      
    } catch (e) {
      print('❌ Error migrating user to enhanced profile system: $e');
    }
  }
}
```

### Step 10: Integration with Existing Profile Screens

**This shows how to integrate the new widget with your existing profile screens without breaking anything.**

#### Option A: Replace Existing Profile Picture Display

Find your existing profile screen (likely in `lib/screens/profile/` or similar) and replace the current profile picture widget:

```dart
// BEFORE (your existing code):
// CircleAvatar(
//   backgroundImage: NetworkImage(user.photoURL ?? ''),
//   radius: 50,
// )

// AFTER (new enhanced widget):
import '../widgets/enhanced_profile_picture_widget.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _currentUserData;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Migrate user to enhanced system if needed (run once)
        await UserService.migrateUserToEnhancedProfileSystem();
        
        // Load enhanced user data
        final userData = await UserService.getEnhancedUserProfile(user.uid);
        setState(() {
          _currentUserData = userData;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your existing app bar ...
      
      body: Column(
        children: [
          // Replace your existing profile picture with enhanced widget
          Container(
            padding: EdgeInsets.all(20),
            child: EnhancedProfilePictureWidget(
              userData: _currentUserData,
              size: 120,
              isEditable: true,
              // Pass your existing default avatar options if you have them
              availableDefaultImages: [
                'assets/images/avatars/avatar_1.png',
                'assets/images/avatars/avatar_2.png',
                'assets/images/avatars/avatar_3.png',
                // ... add your existing avatar assets here
              ],
              onUserDataChanged: (updatedUserData) {
                // Handle user data changes
                setState(() {
                  _currentUserData = updatedUserData;
                });
                
                // Optional: Update any other parts of your UI that depend on user data
                _handleUserDataUpdate(updatedUserData);
              },
            ),
          ),
          
          // ... rest of your existing profile screen widgets ...
          
          // User name and email display
          if (_currentUserData != null) ...[
            Text(
              _currentUserData!.displayNameForSearch,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTextColor,
              ),
            ),
            Text(
              _currentUserData!.email,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ],
          
          // ... continue with your existing widgets ...
        ],
      ),
    );
  }

  void _handleUserDataUpdate(AppUser updatedUserData) {
    // Optional: Handle any additional logic when user data changes
    print('User data updated: ${updatedUserData.profileImageType}');
    
    // Example: Update other parts of your UI, notify other screens, etc.
    // You might want to update a global state management solution here
  }
}
```

#### Option B: Gradual Integration (Keep Both)

If you want to be extra careful, you can keep both the old and new systems temporarily:

```dart
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _currentUserData;
  bool _useEnhancedWidget = true; // Toggle this to switch between old/new
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: _useEnhancedWidget
                ? EnhancedProfilePictureWidget(
                    userData: _currentUserData,
                    size: 120,
                    isEditable: true,
                    onUserDataChanged: (updatedUserData) {
                      setState(() => _currentUserData = updatedUserData);
                    },
                  )
                : YourExistingProfilePictureWidget(
                    // ... your existing parameters
                  ),
          ),
          
          // Toggle button for testing (remove in production)
          if (kDebugMode)
            ElevatedButton(
              onPressed: () {
                setState(() => _useEnhancedWidget = !_useEnhancedWidget);
              },
              child: Text(_useEnhancedWidget ? 'Use Old Widget' : 'Use New Widget'),
            ),
          
          // ... rest of your widgets
        ],
      ),
    );
  }
}
```

### Step 11: Update Other Screens (Gradual Rollout)

Replace profile picture displays in other screens gradually:

#### Navigation Drawer
```dart
// In your navigation drawer or app bar
UserAccountsDrawerHeader(
  accountName: Text(_currentUserData?.displayNameForSearch ?? ''),
  accountEmail: Text(_currentUserData?.email ?? ''),
  currentAccountPicture: EnhancedProfilePictureWidget(
    userData: _currentUserData,
    size: 72,
    isEditable: false, // Not editable in drawer
  ),
)
```

#### Small Profile Pictures in Lists
```dart
// In user lists, chat lists, etc.
ListTile(
  leading: EnhancedProfilePictureWidget(
    userData: userData,
    size: 50,
    isEditable: false,
  ),
  title: Text(userData.displayNameForSearch),
  // ...
)
```

### Step 12: Testing Migration

Create a test file `lib/utils/profile_migration_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../services/user_service.dart';
import '../services/image_upload_service.dart';

class ProfileMigrationTest {
  /// Test the migration process for existing users
  static Future<void> testMigration() async {
    if (!kDebugMode) return; // Only run in debug mode
    
    try {
      print('🧪 Starting profile migration test...');
      
      // Test migration
      await UserService.migrateUserToEnhancedProfileSystem();
      
      // Test storage usage
      final storageUsage = await ImageUploadService.getStorageUsage();
      print('📊 Storage usage: $storageUsage');
      
      // Test user profile loading
      final userProfile = await UserService.getEnhancedUserProfile(
        FirebaseAuth.instance.currentUser?.uid ?? ''
      );
      print('👤 User profile: ${userProfile?.toFirestore()}');
      
      print('✅ Migration test completed successfully');
      
    } catch (e) {
      print('❌ Migration test failed: $e');
    }
  }
}
```

Add this to your debug menu or run it once during development.

## 🔧 Detailed Integration Steps

### Phase 1: Setup (1-2 hours)
1. **Add dependencies** to `pubspec.yaml`
2. **Run** `flutter pub get`
3. **Add platform permissions** (Android/iOS)
4. **Update Firebase Storage rules**
5. **Test Firebase Storage** connection

### Phase 2: Backend Implementation (2-3 hours)
1. **Enhance your `AppUser` model** with new fields
2. **Create `ImageUploadService`** class
3. **Extend your `UserService`** with new methods
4. **Test backend functionality** with simple uploads

### Phase 3: UI Implementation (3-4 hours)
1. **Create `EnhancedProfilePictureWidget`**
2. **Integrate with your existing default avatar system**
3. **Style to match your app theme**
4. **Test UI interactions and modal**

### Phase 4: Integration (2-3 hours)
1. **Replace profile picture in main profile screen**
2. **Test migration for existing users**
3. **Update other screens gradually**
4. **Test across all profile picture locations**

### Phase 5: Testing & Optimization (2-3 hours)
1. **Test image compression and upload**
2. **Test caching and performance**
3. **Test edge cases (no network, large files, etc.)**
4. **Optimize compression settings**

**Total Estimated Time: 10-15 hours**

## 📋 Pre-Integration Checklist

Before you start implementing, complete this checklist:

- [ ] **Backup your current code** (git commit/branch)
- [ ] **Document your existing profile image system** (how it currently works)
- [ ] **Identify all screens** that show profile pictures
- [ ] **Test your current Firebase setup** (Authentication and Firestore working)
- [ ] **Check your existing user model** and note all current fields
- [ ] **Verify you have storage space** in Firebase Storage
- [ ] **Test on both Android and iOS** devices
- [ ] **Have test images ready** (various sizes and formats)

## 🧪 Testing Strategy

### Manual Testing Checklist
- [ ] Camera capture works on physical device
- [ ] Gallery selection works properly
- [ ] Image compression reduces file size (check before/after)
- [ ] Upload shows progress and completes successfully
- [ ] Old images are deleted when new ones are uploaded
- [ ] Default avatar selection still works
- [ ] Profile picture updates across all screens
- [ ] Error handling works (no network, permissions denied)
- [ ] Migration works for existing users
- [ ] Performance is acceptable (images load quickly)

### Automated Testing
```dart
// Example test in test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shopple_app/widgets/enhanced_profile_picture_widget.dart';

void main() {
  group('Enhanced Profile Picture Widget Tests', () {
    testWidgets('Widget displays default avatar when no image set', (WidgetTester tester) async {
      // Test default avatar display
      await tester.pumpWidget(MaterialApp(
        home: EnhancedProfilePictureWidget(
          userData: AppUser(uid: 'test', email: 'test@example.com'),
          isEditable: false,
        ),
      ));
      
      expect(find.text('T'), findsOneWidget); // Should show initial
    });
    
    // Add more tests for different scenarios
  });
}
```

## 🚨 Common Issues & Solutions

### Issue 1: "Permission denied" on Firebase Storage
**Solution:** Check Firebase Storage rules and ensure user is authenticated

### Issue 2: Images not displaying after upload
**Solution:** 
- Clear image cache: `CachedNetworkImage` cache
- Verify download URL format
- Check network connectivity

### Issue 3: Large memory usage
**Solution:** 
- Implement proper image compression settings
- Use `memCacheWidth` and `memCacheHeight` in `CachedNetworkImage`
- Monitor app memory usage during testing

### Issue 4: Slow upload on poor network
**Solution:** 
- Reduce compression quality for slower networks
- Implement retry logic
- Show better upload progress

### Issue 5: Migration fails for existing users
**Solution:**
- Run migration in a try-catch block
- Handle edge cases (missing fields, null values)
- Provide fallback to default behavior

## 🎯 Success Metrics

After implementation, verify these metrics:

- **Image upload success rate**: >95%
- **Image compression ratio**: 60-80% size reduction
- **Upload time**: <30 seconds on good network
- **Cache hit rate**: >80% for subsequent loads
- **User satisfaction**: No complaints about image quality or performance
- **Storage usage**: Efficient use of Firebase Storage quota

## 📝 Final Notes

- **Preserve existing functionality** - Your current profile image selection must continue to work
- **Gradual rollout** - Test with a small group first
- **Monitor performance** - Watch Firebase Storage usage and costs
- **User feedback** - Collect feedback on the new upload experience
- **Documentation** - Update your app's user documentation with new features

This implementation provides a robust, production-ready profile picture system that enhances your existing functionality without breaking anything. The hybrid approach ensures users can choose between your existing default avatars or upload custom images while maintaining a consistent user experience.

### 4. **Update Profile Screen Integration**

Update your existing profile screen to use the new widget:

```dart
// In your existing profile screen (e.g., lib/screens/profile/profile_screen.dart)

import '../widgets/profile_picture_widget.dart';

class ProfileScreen extends StatefulWidget {
  // ... existing code
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing app bar and other widgets
      
      body: Column(
        children: [
          // Profile picture section
          Container(
            padding: EdgeInsets.all(20),
            child: ProfilePictureWidget(
              currentPhotoURL: _userData?.photoURL,
              size: 120,
              isEditable: true,
              userName: _userData?.displayNameForSearch,
              onImageChanged: (newImageUrl) {
                // Handle image change - update local state
                setState(() {
                  // Update your local user data
                  _userData = _userData?.copyWith(photoURL: newImageUrl);
                });
              },
            ),
          ),
          
          // ... rest of your profile screen widgets
        ],
      ),
    );
  }
}
```

### 5. **Firebase Storage Security Rules**

Update your Firebase Storage security rules in the Firebase Console:

```javascript
// Storage rules for profile pictures
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can read/write their own profile pictures
    match /users/{userId}/profile_pictures/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read other users' profile pictures (for collaboration features)
    match /users/{userId}/profile_pictures/{allPaths=**} {
      allow read: if request.auth != null;
    }
    
    // Limit file size to 5MB and only allow images
    match /{allPaths=**} {
      allow write: if request.auth != null 
        && resource.size < 5 * 1024 * 1024 
        && resource.contentType.matches('image/.*');
    }
  }
}
```

### 6. **Optimize App Performance**

#### A. Add Image Caching Configuration

Create `lib/config/cache_config.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheConfig {
  // Custom cache manager for profile pictures
  static final CacheManager profilePictureCache = CacheManager(
    Config(
      'profile_pictures_cache',
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 100, // Limit cache size
      repo: JsonCacheInfoRepository(databaseName: 'profile_pictures_cache'),
      fileService: HttpFileService(),
    ),
  );

  // Pre-cache important profile pictures
  static Future<void> preCacheProfilePicture(String imageUrl) async {
    try {
      await profilePictureCache.downloadFile(imageUrl);
      print('✅ Pre-cached profile picture: $imageUrl');
    } catch (e) {
      print('⚠️ Failed to pre-cache profile picture: $e');
    }
  }

  // Clear cache when needed
  static Future<void> clearProfilePictureCache() async {
    await profilePictureCache.emptyCache();
    print('🧹 Profile picture cache cleared');
  }
}
```

#### B. Add Permissions Configuration

**Android**: Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS**: Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take profile pictures</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select profile pictures</string>
```

## 🧪 Testing Checklist

### Functional Testing
- [ ] Camera capture works on both Android and iOS
- [ ] Gallery selection works properly
- [ ] Image compression reduces file size significantly
- [ ] Upload progress is shown to user
- [ ] Old images are deleted when new ones are uploaded
- [ ] Remove image functionality works
- [ ] Error handling works for network issues
- [ ] Profile picture updates across all screens
- [ ] Caching works - images load quickly on subsequent views

### Performance Testing
- [ ] Images load quickly (< 1 second for cached images)
- [ ] App doesn't crash with large images
- [ ] Memory usage remains stable
- [ ] Network usage is optimized (compressed uploads)
- [ ] Storage usage is reasonable (old images cleaned up)

### UI/UX Testing
- [ ] Image picker modal follows app design theme
- [ ] Loading states are smooth and informative
- [ ] Error messages are user-friendly
- [ ] Profile picture widget integrates seamlessly
- [ ] Touch targets are appropriate size
- [ ] Works well on different screen sizes

## 🔧 Integration Steps

### Step 1: Dependencies
```bash
flutter pub add image_picker flutter_image_compress firebase_storage cached_network_image path_provider permission_handler uuid
```

### Step 2: File Creation
1. Create `lib/services/image_upload_service.dart`
2. Create `lib/widgets/profile_picture_widget.dart`
3. Create `lib/config/cache_config.dart`
4. Update existing `lib/services/user_service.dart`

### Step 3: Profile Screen Integration
- Replace existing profile picture display with `ProfilePictureWidget`
- Handle image change callbacks
- Update user state management

### Step 4: Firebase Configuration
- Update Storage security rules
- Test upload/download permissions
- Verify folder structure in Storage console

### Step 5: Testing & Optimization
- Test on multiple devices
- Monitor performance metrics
- Optimize compression settings if needed
- Test edge cases (no network, large files, etc.)

## 🚀 Advanced Features (Optional)

### 1. **Batch Image Processing**
```dart
// Process multiple images for group profiles
static Future<List<String>> uploadMultipleImages(List<XFile> images) async {
  // Implementation for multiple image upload
}
```

### 2. **Image Cropping**
Add `image_cropper` package for better image editing:
```yaml
dependencies:
  image_cropper: ^5.0.1
```

### 3. **Background Upload**
Implement background upload using `background_task` for better UX.

### 4. **Analytics Integration**
Track image upload success rates and performance metrics.

## 📝 Notes

- **Storage Structure**: Images are stored as `users/{userId}/profile_pictures/{filename}`
- **Compression**: Images are compressed to ~75% quality and max 800x800px
- **Caching**: Uses `cached_network_image` for efficient loading
- **Cleanup**: Old images are automatically deleted when new ones are uploaded
- **Security**: Proper Firebase Storage rules ensure users can only access their own images
- **Performance**: Images are pre-compressed and cached for optimal performance
- **Fallback**: Default avatar with user initials when no image is set

## 🐛 Common Issues & Solutions

### Issue: "Permission denied" on image upload
**Solution**: Check Firebase Storage rules and user authentication

### Issue: Images not displaying after upload
**Solution**: Clear image cache and verify download URL format

### Issue: Large memory usage
**Solution**: Implement proper image compression and cache management

### Issue: Slow upload on poor network
**Solution**: Reduce compression quality for slower networks

---
