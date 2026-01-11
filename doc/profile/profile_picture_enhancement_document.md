# Profile Picture System Enhancement - Performance & UI Consistency

## 📋 Overview

This document provides detailed instructions to enhance the existing profile picture implementation by addressing critical performance, UI consistency, and user experience issues. The enhancements focus on creating a snappy, responsive application that follows the established Shopple app theme and components.

## 🎯 Issues to Address

### 1. **Permission Management**
- Users need proper camera and gallery permissions
- Permission requests should be handled gracefully with proper UI feedback
- Permission denial should show appropriate fallback options

### 2. **UI Theme Consistency**
- Profile picture options modal doesn't follow app's UI theme
- Need to reference `shopple_previous_build` folder for existing component patterns
- All new components must integrate seamlessly with existing design system

### 3. **Image Loading Performance**
- Custom images take too long to load initially
- Need faster loading and configuration in the app
- Implement progressive loading and caching strategies

### 4. **Dynamic Updates Across Screens**
- Profile picture updates quickly in edit page and main page
- Profile page takes time to update and requires navigation refresh
- Need real-time updates across ALL screens that display profile pictures

### 5. **Profile Edit Page Enhancements**
- Save confirmation when user presses back button after changes
- Proper save feedback notifications
- Unsaved changes detection and handling

### 6. **Notification System Standardization**
- Cool bottom notification style exists in profile pages
- Need to identify and standardize this notification pattern app-wide
- Ensure consistent notification experience throughout the app
- theres already a sucess meaage notification style one in eth profile and profile edit page . didnt you investigae it. you have to use that.not craeting a new one right? throughtout teh whole app the notification box that cokes from eth top but in teh profile and teh profile edit page there a bottom method which is very very smooth and i like that. use that throughtout teh app.why there a shopple_notification_service.dart sepearte file, we already ahev a notification snackbar patter that comes from teh bnnoittom right? why are we using and creating a new file again, use it we should use alrady exuisitng ones and widgets and referain from craetinf duplicates right?

### 7. **Background Color & Pattern Selection for Profile Pictures** ⭐ NEW FEATURE ⭐
- Users currently get automatic blue-like gradient backgrounds for profile pictures
- Implement dynamic background color selection for enhanced personalization
- Add gradient patterns, solid colors, and modern background effects
- Integrate latest Flutter color picker tools (flex_color_picker 3.7.1 - most advanced)
- Use existing app UI theme patterns from shopple_previous_build
- Ensure Material Design 3 compliance with latest color system
- Support for:
  - **Solid Colors**: Material 3 color palette with tonal variations
  - **Gradient Backgrounds**: Linear, radial, and sweep gradients using flutter_gradient_colors
  - **Modern Patterns**: Mesh gradients (mesh_gradient package) for premium look
  - **Animated Backgrounds**: Subtle animations for dynamic profile pictures
- Maintain existing app code structure and UI consistency
- Reference shopple_previous_build for color picker modal implementations

### 8. **Overall Responsiveness**
- All updates should be responsive and dynamic
- Snappy performance across all profile picture interactions
- Real-time synchronization between different app sections

## 🔍 Pre-Implementation Analysis Requirements

### Step 1: Comprehensive Code Analysis

**MANDATORY: Before making ANY changes, perform this analysis:**

```bash
# 1. Analyze current permission handling
find lib/ -name "*.dart" -exec grep -l "permission\|Permission" {} \;

# 2. Find existing notification patterns
find lib/ -name "*.dart" -exec grep -l "SnackBar\|notification\|alert\|dialog" {} \;

# 3. Locate existing UI components and themes
find lib/widgets/ -name "*.dart" -type f
find lib/components/ -name "*.dart" -type f 2>/dev/null

# 4. Examine shopple_previous_build structure
find shopple_previous_build/lib/ -name "*.dart" -type f | head -20

# 5. Find profile-related screens and widgets
find lib/ -name "*profile*" -o -name "*user*" -o -name "*avatar*"

# 6. Analyze current image loading patterns
find lib/ -name "*.dart" -exec grep -l "CachedNetworkImage\|Image\|NetworkImage" {} \;

# 7. Check existing state management patterns
find lib/ -name "*.dart" -exec grep -l "setState\|StreamBuilder\|FutureBuilder\|Provider\|Riverpod\|Bloc" {} \;
```

### Step 2: Document Current Implementation

**Create a comprehensive analysis document:**

```markdown
# Current Implementation Analysis

## Existing Permission Handling
- [ ] Location of current permission requests
- [ ] Libraries used (permission_handler, etc.)
- [ ] Current permission flow and UI

## Current Notification System
- [ ] Existing SnackBar implementations
- [ ] Cool bottom notification pattern location
- [ ] Custom notification widgets being used
- [ ] Styling and animation patterns

## Current UI Theme Structure
- [ ] AppColors location and structure
- [ ] Existing widget components
- [ ] Modal/dialog patterns currently used
- [ ] Bottom sheet implementations

## Current State Management
- [ ] How profile data is managed
- [ ] Real-time update mechanisms
- [ ] Screen-to-screen communication patterns
- [ ] Image caching strategies

## Performance Bottlenecks Identified
- [ ] Image loading delays
- [ ] State update delays
- [ ] Navigation refresh requirements
- [ ] Memory management issues
```

## 🚀 Detailed Enhancement Implementation

### Enhancement 1: Advanced Permission Management

#### 1.1 Create Permission Service

**File:** `lib/services/advanced_permission_service.dart`

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../Values/values.dart';

enum PermissionType { camera, gallery, storage }

class AdvancedPermissionService {
  static final Map<PermissionType, Permission> _permissionMap = {
    PermissionType.camera: Permission.camera,
    PermissionType.gallery: Permission.photos,
    PermissionType.storage: Permission.storage,
  };

  /// Request permission with proper UI feedback using existing app theme
  static Future<bool> requestPermission(
    BuildContext context,
    PermissionType permissionType, {
    bool showRationale = true,
  }) async {
    try {
      final permission = _permissionMap[permissionType];
      if (permission == null) return false;

      // Check current status
      final status = await permission.status;
      
      switch (status) {
        case PermissionStatus.granted:
          return true;
          
        case PermissionStatus.denied:
          if (showRationale) {
            final shouldRequest = await _showPermissionRationaleDialog(
              context, 
              permissionType
            );
            if (!shouldRequest) return false;
          }
          
          // Request permission
          final result = await permission.request();
          return result == PermissionStatus.granted;
          
        case PermissionStatus.permanentlyDenied:
          await _showPermissionDeniedDialog(context, permissionType);
          return false;
          
        case PermissionStatus.restricted:
          await _showPermissionRestrictedDialog(context, permissionType);
          return false;
          
        default:
          return false;
      }
    } catch (e) {
      print('❌ Error requesting permission: $e');
      _showErrorNotification(context, 'Permission request failed');
      return false;
    }
  }

  /// Show permission rationale using existing app UI components
  static Future<bool> _showPermissionRationaleDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    // IMPORTANT: Use existing dialog pattern from shopple_previous_build
    // Reference: shopple_previous_build/lib/widgets/custom_dialog.dart or similar
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface, // Use existing color scheme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Match existing border radius
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
                style: TextStyle(
                  color: AppColors.primaryText70,
                  fontSize: 16,
                ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Show settings redirect dialog for permanently denied permissions
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
                style: TextStyle(
                  color: AppColors.primaryText70,
                  fontSize: 16,
                ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show restriction dialog
  static Future<void> _showPermissionRestrictedDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    _showErrorNotification(
      context,
      '${_getPermissionName(permissionType)} access is restricted on this device',
    );
  }

  /// Show error notification using existing notification pattern
  static void _showErrorNotification(BuildContext context, String message) {
    // Using existing notification pattern from profile pages
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Helper methods for permission messages and icons
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
```

### Enhancement 2: Background Color & Pattern Selection System ⭐ NEW ⭐

#### 2.1 Create Advanced Background Selection Service

**File:** `lib/services/profile_background_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Values/values.dart';

enum BackgroundType { solid, gradient, pattern }

enum GradientStyle { linear, radial, sweep }

enum PatternType { 
  geometric,
  abstract,
  minimal,
  vibrant,
  nature,
  tech
}

class ProfileBackgroundOption {
  final String id;
  final String name;
  final BackgroundType type;
  final Color? primaryColor;
  final Color? secondaryColor;
  final GradientStyle? gradientStyle;
  final PatternType? patternType;
  final List<Color>? colors;
  final String? description;
  final bool isPremium;

  const ProfileBackgroundOption({
    required this.id,
    required this.name,
    required this.type,
    this.primaryColor,
    this.secondaryColor,
    this.gradientStyle,
    this.patternType,
    this.colors,
    this.description,
    this.isPremium = false,
  });

  // Convert to/from Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'primaryColor': primaryColor?.value,
      'secondaryColor': secondaryColor?.value,
      'gradientStyle': gradientStyle?.toString(),
      'patternType': patternType?.toString(),
      'colors': colors?.map((c) => c.value).toList(),
      'description': description,
      'isPremium': isPremium,
    };
  }

  factory ProfileBackgroundOption.fromMap(Map<String, dynamic> map) {
    return ProfileBackgroundOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: BackgroundType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => BackgroundType.solid,
      ),
      primaryColor: map['primaryColor'] != null ? Color(map['primaryColor']) : null,
      secondaryColor: map['secondaryColor'] != null ? Color(map['secondaryColor']) : null,
      gradientStyle: map['gradientStyle'] != null 
          ? GradientStyle.values.firstWhere(
              (e) => e.toString() == map['gradientStyle'],
              orElse: () => GradientStyle.linear,
            )
          : null,
      patternType: map['patternType'] != null
          ? PatternType.values.firstWhere(
              (e) => e.toString() == map['patternType'],
              orElse: () => PatternType.minimal,
            )
          : null,
      colors: map['colors'] != null 
          ? (map['colors'] as List).map((c) => Color(c)).toList()
          : null,
      description: map['description'],
      isPremium: map['isPremium'] ?? false,
    );
  }
}

class ProfileBackgroundService {
  static const String _collection = 'user_profile_backgrounds';

  /// Get predefined background options following Material Design 3
  static List<ProfileBackgroundOption> getPredefinedBackgrounds() {
    return [
      // Solid Colors - Material 3 Core Colors
      ProfileBackgroundOption(
        id: 'solid_primary',
        name: 'Primary Blue',
        type: BackgroundType.solid,
        primaryColor: AppColors.primaryAccentColor,
        description: 'Classic app primary color',
      ),
      ProfileBackgroundOption(
        id: 'solid_purple',
        name: 'Purple Accent',
        type: BackgroundType.solid,
        primaryColor: AppColors.lightMauveBackgroundColor,
        description: 'Elegant purple tone',
      ),
      
      // Material 3 Extended Color Palette
      ProfileBackgroundOption(
        id: 'solid_teal',
        name: 'Modern Teal',
        type: BackgroundType.solid,
        primaryColor: const Color(0xFF00796B),
        description: 'Fresh and modern',
      ),
      ProfileBackgroundOption(
        id: 'solid_orange',
        name: 'Vibrant Orange',
        type: BackgroundType.solid,
        primaryColor: const Color(0xFFFF5722),
        description: 'Energetic and warm',
      ),
      ProfileBackgroundOption(
        id: 'solid_green',
        name: 'Nature Green',
        type: BackgroundType.solid,
        primaryColor: const Color(0xFF4CAF50),
        description: 'Natural and calming',
      ),
      ProfileBackgroundOption(
        id: 'solid_pink',
        name: 'Soft Pink',
        type: BackgroundType.solid,
        primaryColor: const Color(0xFFE91E63),
        description: 'Gentle and friendly',
      ),
      
      // Linear Gradients - Using flutter_gradient_colors patterns
      ProfileBackgroundOption(
        id: 'gradient_blue_purple',
        name: 'Ocean Breeze',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.linear,
        colors: [AppColors.primaryAccentColor, AppColors.lightMauveBackgroundColor],
        description: 'Smooth blue to purple transition',
      ),
      ProfileBackgroundOption(
        id: 'gradient_sunset',
        name: 'Sunset Glow',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.linear,
        colors: [const Color(0xFFFF6B35), const Color(0xFFF7931E), const Color(0xFFFFD23F)],
        description: 'Warm sunset colors',
      ),
      ProfileBackgroundOption(
        id: 'gradient_forest',
        name: 'Forest Mist',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.linear,
        colors: [const Color(0xFF134E5E), const Color(0xFF71B280)],
        description: 'Deep forest vibes',
      ),
      ProfileBackgroundOption(
        id: 'gradient_galaxy',
        name: 'Galaxy Dream',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.linear,
        colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
        description: 'Cosmic purple gradient',
      ),
      
      // Radial Gradients
      ProfileBackgroundOption(
        id: 'radial_warm',
        name: 'Warm Glow',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.radial,
        colors: [const Color(0xFFFFE082), const Color(0xFFFF8A65)],
        description: 'Radial warm glow effect',
      ),
      ProfileBackgroundOption(
        id: 'radial_cool',
        name: 'Cool Burst',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.radial,
        colors: [const Color(0xFF81D4FA), const Color(0xFF3F51B5)],
        description: 'Cool blue radial burst',
      ),
      
      // Sweep Gradients
      ProfileBackgroundOption(
        id: 'sweep_rainbow',
        name: 'Rainbow Arc',
        type: BackgroundType.gradient,
        gradientStyle: GradientStyle.sweep,
        colors: [
          const Color(0xFFE91E63),
          const Color(0xFF9C27B0),
          const Color(0xFF3F51B5),
          const Color(0xFF2196F3),
          const Color(0xFF00BCD4),
          const Color(0xFF4CAF50),
        ],
        description: 'Colorful rainbow sweep',
        isPremium: true,
      ),
      
      // Modern Patterns - Premium
      ProfileBackgroundOption(
        id: 'pattern_geometric',
        name: 'Geometric Flow',
        type: BackgroundType.pattern,
        patternType: PatternType.geometric,
        primaryColor: AppColors.primaryAccentColor,
        description: 'Modern geometric patterns',
        isPremium: true,
      ),
      ProfileBackgroundOption(
        id: 'pattern_minimal',
        name: 'Minimal Lines',
        type: BackgroundType.pattern,
        patternType: PatternType.minimal,
        primaryColor: const Color(0xFF607D8B),
        description: 'Clean minimal design',
        isPremium: true,
      ),
    ];
  }

  /// Save user's selected background
  static Future<void> saveUserBackground(ProfileBackgroundOption background) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileBackground': background.toMap(),
        'backgroundUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Profile background saved successfully');
    } catch (e) {
      print('❌ Error saving profile background: $e');
      throw Exception('Failed to save background: $e');
    }
  }

  /// Get user's current background
  static Future<ProfileBackgroundOption?> getUserBackground() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['profileBackground'] != null) {
        return ProfileBackgroundOption.fromMap(
          doc.data()!['profileBackground'] as Map<String, dynamic>
        );
      }
      
      return null; // Return null for default behavior
    } catch (e) {
      print('❌ Error getting user background: $e');
      return null;
    }
  }

  /// Create custom background from color picker
  static ProfileBackgroundOption createCustomSolidBackground(Color color) {
    return ProfileBackgroundOption(
      id: 'custom_solid_${color.value}',
      name: 'Custom Color',
      type: BackgroundType.solid,
      primaryColor: color,
      description: 'Your custom selected color',
    );
  }

  /// Create custom gradient background
  static ProfileBackgroundOption createCustomGradientBackground({
    required List<Color> colors,
    required GradientStyle style,
    String? name,
  }) {
    return ProfileBackgroundOption(
      id: 'custom_gradient_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Custom Gradient',
      type: BackgroundType.gradient,
      gradientStyle: style,
      colors: colors,
      description: 'Your custom gradient design',
    );
  }
}
```

#### 2.2 Create Background Selection Widget

**File:** `lib/widgets/profile_background_selector.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../services/profile_background_service.dart';
import '../Values/values.dart';

class ProfileBackgroundSelector extends StatefulWidget {
  final ProfileBackgroundOption? currentBackground;
  final Function(ProfileBackgroundOption) onBackgroundSelected;
  final VoidCallback? onClose;

  const ProfileBackgroundSelector({
    Key? key,
    this.currentBackground,
    required this.onBackgroundSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<ProfileBackgroundSelector> createState() => _ProfileBackgroundSelectorState();
}

class _ProfileBackgroundSelectorState extends State<ProfileBackgroundSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Color _customColor = AppColors.primaryAccentColor;
  List<Color> _gradientColors = [AppColors.primaryAccentColor, AppColors.lightMauveBackgroundColor];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryText30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppColors.primaryAccentColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Choose Background',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    Icons.close,
                    color: AppColors.primaryText70,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryAccentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primaryText70,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Solid'),
                Tab(text: 'Gradients'),
                Tab(text: 'Custom'),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSolidColorsTab(),
                _buildGradientsTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidColorsTab() {
    final solidBackgrounds = ProfileBackgroundService.getPredefinedBackgrounds()
        .where((bg) => bg.type == BackgroundType.solid)
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: solidBackgrounds.length,
        itemBuilder: (context, index) {
          final background = solidBackgrounds[index];
          final isSelected = widget.currentBackground?.id == background.id;
          
          return GestureDetector(
            onTap: () => widget.onBackgroundSelected(background),
            child: Container(
              decoration: BoxDecoration(
                color: background.primaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryAccentColor 
                      : AppColors.primaryText30,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAccentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGradientsTab() {
    final gradientBackgrounds = ProfileBackgroundService.getPredefinedBackgrounds()
        .where((bg) => bg.type == BackgroundType.gradient)
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: gradientBackgrounds.length,
        itemBuilder: (context, index) {
          final background = gradientBackgrounds[index];
          final isSelected = widget.currentBackground?.id == background.id;
          
          return GestureDetector(
            onTap: () => widget.onBackgroundSelected(background),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryAccentColor 
                      : AppColors.primaryText30,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAccentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _createGradientFromBackground(background),
                  ),
                  child: Stack(
                    children: [
                      if (isSelected)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            background.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (background.isPremium)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTab() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Custom Background',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 16),
          
          // Custom Solid Color
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryText30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solid Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showColorPicker(context),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _customColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryText30),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final customBackground = ProfileBackgroundService
                              .createCustomSolidBackground(_customColor);
                          widget.onBackgroundSelected(customBackground);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Use This Color'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Custom Gradient (simplified for now)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryText30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Gradient',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'More gradient options coming soon!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Choose Color',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: _customColor,
            onColorChanged: (Color color) => setState(() => _customColor = color),
            width: 44,
            height: 44,
            borderRadius: 22,
            spacing: 5,
            runSpacing: 5,
            wheelDiameter: 155,
            heading: Text(
              'Select color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            subheading: Text(
              'Select color shade',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryText70,
              ),
            ),
            showMaterialName: true,
            showColorName: true,
            showColorCode: true,
            materialNameTextStyle: TextStyle(
              fontSize: 12,
              color: AppColors.primaryText70,
            ),
            colorNameTextStyle: TextStyle(
              fontSize: 12,
              color: AppColors.primaryText70,
            ),
            colorCodeTextStyle: TextStyle(
              fontSize: 12,
              color: AppColors.primaryText70,
            ),
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.primaryText70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccentColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Gradient _createGradientFromBackground(ProfileBackgroundOption background) {
    if (background.colors == null || background.colors!.isEmpty) {
      return LinearGradient(
        colors: [AppColors.primaryAccentColor, AppColors.lightMauveBackgroundColor],
      );
    }

    switch (background.gradientStyle) {
      case GradientStyle.radial:
        return RadialGradient(
          colors: background.colors!,
          center: Alignment.center,
          radius: 0.8,
        );
      case GradientStyle.sweep:
        return SweepGradient(
          colors: background.colors!,
          center: Alignment.center,
        );
      case GradientStyle.linear:
      default:
        return LinearGradient(
          colors: background.colors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
```

#### 2.3 Update Enhanced Profile Picture Widget

**File:** Update `lib/widgets/enhanced_profile_picture_widget.dart`

```dart
// ADD these imports at the top
import '../services/profile_background_service.dart';
import '../widgets/profile_background_selector.dart';

// ADD these fields to the state class
ProfileBackgroundOption? _selectedBackground;

// UPDATE the initState method to load background
@override
void initState() {
  super.initState();
  _loadUserProfileData();
  _loadUserBackground(); // Add this line
}

// ADD this method to load user background
Future<void> _loadUserBackground() async {
  try {
    final background = await ProfileBackgroundService.getUserBackground();
    if (mounted) {
      setState(() {
        _selectedBackground = background;
      });
    }
  } catch (e) {
    print('❌ Error loading user background: $e');
  }
}

// UPDATE the _buildInitialAvatar method to use selected background
Widget _buildInitialAvatar() {
  return Container(
    width: widget.size,
    height: widget.size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: _selectedBackground != null 
          ? _createGradientFromBackground(_selectedBackground!)
          : LinearGradient(
              colors: [
                AppColors.primaryAccentColor,
                AppColors.primaryAccentColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
    ),
    child: Center(
      child: Text(
        _userInitial ?? 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ADD helper method to create gradient
Gradient _createGradientFromBackground(ProfileBackgroundOption background) {
  switch (background.type) {
    case BackgroundType.solid:
      return LinearGradient(
        colors: [
          background.primaryColor ?? AppColors.primaryAccentColor,
          (background.primaryColor ?? AppColors.primaryAccentColor).withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case BackgroundType.gradient:
      if (background.colors == null || background.colors!.isEmpty) {
        return LinearGradient(
          colors: [AppColors.primaryAccentColor, AppColors.lightMauveBackgroundColor],
        );
      }
      
      switch (background.gradientStyle) {
        case GradientStyle.radial:
          return RadialGradient(
            colors: background.colors!,
            center: Alignment.center,
            radius: 0.8,
          );
        case GradientStyle.sweep:
          return SweepGradient(
            colors: background.colors!,
            center: Alignment.center,
          );
        case GradientStyle.linear:
        default:
          return LinearGradient(
            colors: background.colors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
      }
    case BackgroundType.pattern:
    default:
      return LinearGradient(
        colors: [
          background.primaryColor ?? AppColors.primaryAccentColor,
          (background.primaryColor ?? AppColors.primaryAccentColor).withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  }
}

// UPDATE the _showProfilePictureOptions method to include background selection
void _showProfilePictureOptions() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Title
            Text(
              'Profile Picture Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            
            SizedBox(height: 30),
            
            // Photo Options
            _buildOptionTile(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Capture new photo with camera',
              onTap: () {
                Navigator.pop(context);
                _handleCustomImageUpload(ImageSource.camera);
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              onTap: () {
                Navigator.pop(context);
                _handleCustomImageUpload(ImageSource.gallery);
              },
            ),
            _buildOptionTile(
              icon: Icons.face,
              title: 'Choose Avatar',
              subtitle: 'Select from available avatars',
              onTap: () {
                Navigator.pop(context);
                _showAvatarSelector();
              },
            ),
            
            // NEW: Background Selection Option
            _buildOptionTile(
              icon: Icons.palette_outlined,
              title: 'Choose Background',
              subtitle: 'Customize your initials background',
              onTap: () {
                Navigator.pop(context);
                _showBackgroundSelector();
              },
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

// ADD method to show background selector
void _showBackgroundSelector() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfileBackgroundSelector(
      currentBackground: _selectedBackground,
      onBackgroundSelected: (background) async {
        try {
          // Save to Firestore
          await ProfileBackgroundService.saveUserBackground(background);
          
          // Update local state
          setState(() {
            _selectedBackground = background;
          });
          
          // Show success notification using existing pattern
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Background updated successfully!'),
              backgroundColor: AppColors.primaryAccentColor,
            ),
          );
          
          Navigator.pop(context);
          widget.onImageUpdated?.call();
          
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update background: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      onClose: () => Navigator.pop(context),
    ),
  );
}
```

### Enhancement 3: Updated pubspec.yaml Dependencies

**Update:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  
  # NEW: Latest color picker with Material 3 support
  flex_color_picker: ^3.7.1
  
  # NEW: Pre-built gradient colors
  flutter_gradient_colors: ^2.1.1
  
  # NEW: For advanced mesh gradients (premium feature)
  mesh_gradient: ^1.3.8
  
  # NEW: For animated gradients (future enhancement)
  animated_gradient: ^0.0.3
```

#### 1.2 Integrate Permission Service with Image Upload

**Update:** `lib/services/image_upload_service.dart`

```dart
// ADD this method to the existing ImageUploadService class

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
      print('❌ Permission denied for ${permissionType.toString()}');
      return null;
    }

    // Step 2: Proceed with existing image picking logic
    return await pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
    
  } catch (e) {
    print('❌ Error in pickImageWithPermissions: $e');
    return null;
  }
}
```

### Enhancement 2: UI Theme Consistency Enhancement

#### 2.1 Analyze Existing UI Components

**STEP 1: Examine shopple_previous_build folder structure**

```bash
# Navigate and analyze existing components
cd shopple_previous_build/lib/

# Find existing modal/bottom sheet implementations
find . -name "*.dart" -exec grep -l "showModalBottomSheet\|BottomSheet" {} \;

# Find existing button styles
find . -name "*.dart" -exec grep -l "ElevatedButton\|TextButton\|OutlinedButton" {} \;

# Find existing list tile patterns
find . -name "*.dart" -exec grep -l "ListTile\|CustomListTile" {} \;

# Find existing dialog patterns
find . -name "*.dart" -exec grep -l "AlertDialog\|Dialog\|showDialog" {} \;
```

#### 2.2 Create Consistent Profile Picture Selection Modal

**File:** `lib/widgets/shopple_profile_picture_modal.dart`

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../values/app_colors.dart';
import '../services/advanced_permission_service.dart';
// IMPORTANT: Import existing components from shopple_previous_build reference

class ShoppleProfilePictureModal extends StatelessWidget {
  final Function(ImageSource) onCustomImageSelected;
  final Function(String) onDefaultAvatarSelected;
  final VoidCallback? onRemoveImage;
  final bool hasCurrentImage;
  final List<Map<String, dynamic>> defaultAvatarOptions;

  const ShoppleProfilePictureModal({
    Key? key,
    required this.onCustomImageSelected,
    required this.onDefaultAvatarSelected,
    this.onRemoveImage,
    this.hasCurrentImage = false,
    this.defaultAvatarOptions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar (reference shopple_previous_build modal patterns)
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.secondaryTextColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider (reference existing divider style)
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.secondaryTextColor.withOpacity(0.1),
          ),
          
          SizedBox(height: 20),
          
          // Custom Upload Section
          _buildSection(
            context,
            title: 'Upload Custom Picture',
            children: [
              _buildCustomUploadOption(
                context,
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Capture new photo with camera',
                onTap: () async {
                  Navigator.pop(context);
                  onCustomImageSelected(ImageSource.camera);
                },
              ),
              _buildCustomUploadOption(
                context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photos',
                onTap: () async {
                  Navigator.pop(context);
                  onCustomImageSelected(ImageSource.gallery);
                },
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Default Avatars Section
          if (defaultAvatarOptions.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Choose Default Avatar',
              children: [
                _buildDefaultAvatarGrid(context),
              ],
            ),
            SizedBox(height: 20),
          ],
          
          // Remove Option Section
          if (hasCurrentImage && onRemoveImage != null) ...[
            _buildSection(
              context,
              title: 'Remove Picture',
              children: [
                _buildRemoveOption(context),
              ],
            ),
            SizedBox(height: 20),
          ],
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.secondaryTextColor.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildCustomUploadOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.secondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarGrid(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: defaultAvatarOptions.length,
        itemBuilder: (context, index) {
          final option = defaultAvatarOptions[index];
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onDefaultAvatarSelected(option['id']);
            },
            child: Container(
              width: 70,
              height: 70,
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: option['url'] != null
                    ? Image.asset(
                        option['url'],
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            option['initials'] ?? '?',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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

  Widget _buildRemoveOption(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onRemoveImage?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remove Picture',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reset to default avatar with initials',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Enhancement 3: High-Performance Image Loading System

#### 3.1 Create Optimized Image Cache Manager

**File:** `lib/services/optimized_image_cache_service.dart`

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';

class OptimizedImageCacheService {
  // Dedicated cache manager for profile pictures
  static final CacheManager _profilePictureCache = CacheManager(
    Config(
      'shopple_profile_pictures',
      stalePeriod: const Duration(days: 30), // Cache for 30 days
      maxNrOfCacheObjects: 200, // Increased cache size
      repo: JsonCacheInfoRepository(databaseName: 'shopple_profile_pictures'),
      fileService: HttpFileService(),
    ),
  );

  /// Pre-cache profile picture for instant loading
  static Future<void> preCacheProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      
      print('🔄 Pre-caching profile picture: $imageUrl');
      await _profilePictureCache.downloadFile(imageUrl);
      print('✅ Profile picture pre-cached successfully');
      
    } catch (e) {
      print('⚠️ Failed to pre-cache profile picture: $e');
    }
  }

  /// Get optimized cached network image widget
  static Widget buildOptimizedProfileImage({
    required String imageUrl,
    required double size,
    required Widget fallbackWidget,
    String? cacheKey,
  }) {
    if (imageUrl.isEmpty) return fallbackWidget;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: _profilePictureCache,
      cacheKey: cacheKey,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).round(), // 2x for high DPI
      memCacheHeight: (size * 2).round(),
      placeholder: (context, url) => _buildLoadingPlaceholder(size),
      errorWidget: (context, url, error) {
        print('❌ Error loading image: $url - $error');
        return fallbackWidget;
      },
      // Progressive loading for better UX
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return _buildProgressPlaceholder(size, downloadProgress.progress);
      },
      // Fade in animation for smooth appearance
      fadeInDuration: Duration(milliseconds: 200),
      fadeOutDuration: Duration(milliseconds: 100),
    );
  }

  static Widget _buildLoadingPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  static Widget _buildProgressPlaceholder(double size, double? progress) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
            strokeWidth: 2,
            value: progress,
          ),
        ),
      ),
    );
  }

  /// Clear cache when needed
  static Future<void> clearProfilePictureCache() async {
    try {
      await _profilePictureCache.emptyCache();
      print('🧹 Profile picture cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final files = await _profilePictureCache.getFileStream().toList();
      return {
        'cacheSize': files.length,
        'totalCacheFiles': files.length,
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }
}
```

#### 3.2 Create Real-Time Profile Picture Widget

**File:** `lib/widgets/realtime_profile_picture_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/optimized_image_cache_service.dart';
import '../values/app_colors.dart';

class RealtimeProfilePictureWidget extends StatefulWidget {
  final double size;
  final bool isEditable;
  final VoidCallback? onTap;
  final String? userId; // Optional: for viewing other users' profiles
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const RealtimeProfilePictureWidget({
    Key? key,
    this.size = 50,
    this.isEditable = false,
    this.onTap,
    this.userId,
    this.borderRadius,
    this.border,
  }) : super(key: key);

  @override
  State<RealtimeProfilePictureWidget> createState() => _RealtimeProfilePictureWidgetState();
}

class _RealtimeProfilePictureWidgetState extends State<RealtimeProfilePictureWidget> {
  late Stream<DocumentSnapshot> _userStream;
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _setupUserStream();
  }

  void _setupUserStream() {
    _targetUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    
    if (_targetUserId != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_targetUserId)
          .snapshots();
    }
  }

  @override
  void didUpdateWidget(RealtimeProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _setupUserStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetUserId == null) {
      return _buildDefaultAvatar(null);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        AppUser? userData;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          try {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            userData = AppUser.fromFirebaseAndFirestore(
              uid: snapshot.data!.id,
              email: data['email'] ?? '',
              displayName: data['displayName'],
              photoURL: data['photoURL'],
              phoneNumber: data['phoneNumber'],
              emailVerified: data['emailVerified'] ?? false,
              signInMethod: data['signInMethod'] ?? 'email',
              firestoreData: data,
            );
          } catch (e) {
            print('❌ Error parsing user data: $e');
          }
        }

        return GestureDetector(
          onTap: widget.isEditable ? widget.onTap : null,
          child: Stack(
            children: [
              _buildProfileImageContainer(userData),
              if (widget.isEditable) _buildEditOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImageContainer(AppUser? userData) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.size / 2),
        border: widget.border ?? Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.size / 2),
        child: _buildProfileImage(userData),
      ),
    );
  }

  Widget _buildProfileImage(AppUser? userData) {
    final effectivePhotoURL = userData?.effectivePhotoURL;
    
    if (effectivePhotoURL != null && effectivePhotoURL.isNotEmpty) {
      // Generate unique cache key based on user ID and photo update time
      final cacheKey = '${userData?.uid}_${userData?.photoUpdatedAt?.millisecondsSinceEpoch ?? 0}';
      
      return OptimizedImageCacheService.buildOptimizedProfileImage(
        imageUrl: effectivePhotoURL,
        size: widget.size,
        fallbackWidget: _buildDefaultAvatar(userData),
        cacheKey: cacheKey,
      );
    } else if (userData?.profileImageType == 'default' && 
               userData?.defaultImageId != null &&
               userData?.defaultImageId != 'initials') {
      // Show selected default avatar from assets
      return _buildAssetAvatar(userData!.defaultImageId!);
    }
    
    // Fallback to initials avatar
    return _buildDefaultAvatar(userData);
  }

  Widget _buildAssetAvatar(String defaultImageId) {
    // IMPORTANT: Reference your existing default avatar system
    // This should match your existing avatar asset paths
    final assetPath = 'assets/images/avatars/$defaultImageId.png';
    
    return Image.asset(
      assetPath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading asset avatar: $defaultImageId');
        return _buildDefaultAvatar(null);
      },
    );
  }

  Widget _buildDefaultAvatar(AppUser? userData) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          _getInitials(userData),
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEditOverlay() {
    return Positioned(
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
    );
  }

  String _getInitials(AppUser? userData) {
    if (userData?.displayNameForSearch?.isNotEmpty == true) {
      final words = userData!.displayNameForSearch.trim().split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.length == 1) {
        return words[0][0].toUpperCase();
      }
    }
    
    final email = userData?.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    
    return '?';
  }
}
```

### Enhancement 4: Standardized Notification System

#### 4.1 Analyze Existing Notification Pattern

**STEP 1: Find existing notification widget in shopple_previous_build**

```bash
# Look for existing notification patterns
find shopple_previous_build/lib/ -name "*.dart" -exec grep -l "SnackBar\|notification\|toast" {} \;

# Check for custom notification widgets
find shopple_previous_build/lib/widgets/ -name "*notification*" -o -name "*snackbar*" -o -name "*toast*"
```

#### 4.2 Create Standardized Notification Service

**File:** `lib/services/shopple_notification_service.dart`

```dart
import 'package:flutter/material.dart';
import '../values/app_colors.dart';

enum NotificationType { success, error, warning, info }

class ShoppleNotificationService {
  /// Show standardized notification using existing app theme
  static void showNotification(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final theme = _getNotificationTheme(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              theme.icon,
              color: Colors.white,
              size: 20,
            ),
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
        backgroundColor: theme.backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
        // Enhanced animation and styling
        animation: CurvedAnimation(
          parent: AnimationController(
            duration: Duration(milliseconds: 300),
            vsync: Navigator.of(context),
          ),
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  /// Quick success notification
  static void showSuccess(BuildContext context, String message) {
    showNotification(
      context,
      message: message,
      type: NotificationType.success,
      duration: Duration(seconds: 2),
    );
  }

  /// Quick error notification
  static void showError(BuildContext context, String message) {
    showNotification(
      context,
      message: message,
      type: NotificationType.error,
      duration: Duration(seconds: 4),
    );
  }

  /// Quick warning notification
  static void showWarning(BuildContext context, String message) {
    showNotification(
      context,
      message: message,
      type: NotificationType.warning,
      duration: Duration(seconds: 3),
    );
  }

  /// Quick info notification
  static void showInfo(BuildContext context, String message) {
    showNotification(
      context,
      message: message,
      type: NotificationType.info,
      duration: Duration(seconds: 3),
    );
  }

  /// Show loading notification that can be dismissed
  static void showLoading(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    showNotification(
      context,
      message: message,
      type: NotificationType.info,
      duration: Duration(seconds: 30), // Long duration for loading
    );
  }

  /// Dismiss current notification
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static _NotificationTheme _getNotificationTheme(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationTheme(
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
      case NotificationType.error:
        return _NotificationTheme(
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      case NotificationType.warning:
        return _NotificationTheme(
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber_outlined,
        );
      case NotificationType.info:
        return _NotificationTheme(
          backgroundColor: AppColors.primaryColor,
          icon: Icons.info_outline,
        );
    }
  }
}

class _NotificationTheme {
  final Color backgroundColor;
  final IconData icon;

  _NotificationTheme({
    required this.backgroundColor,
    required this.icon,
  });
}
```

### Enhancement 5: Profile Edit Page with Save Confirmation

#### 5.1 Create Unsaved Changes Detection Service

**File:** `lib/services/unsaved_changes_service.dart`

```dart
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/shopple_notification_service.dart';

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
  static Future<bool> showSaveConfirmationDialog(BuildContext context) async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.save_outlined,
                color: AppColors.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Unsaved Changes',
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. Do you want to save them before leaving?',
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Don't save, just leave
              child: Text(
                'Discard',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel, stay on page
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Save and leave
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false; // If null (cancelled), return false
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
      
      ShoppleNotificationService.showSuccess(
        context,
        'Profile updated successfully',
      );
      
      return true;
      
    } catch (e) {
      print('❌ Error saving changes: $e');
      ShoppleNotificationService.showError(
        context,
        'Failed to save changes: ${e.toString()}',
      );
      return false;
    }
  }

  static void _checkForChanges() {
    if (_originalData == null || _currentData == null) {
      _hasUnsavedChanges = false;
      return;
    }

    // Compare relevant fields for changes
    _hasUnsavedChanges = _originalData!.displayName != _currentData!.displayName ||
        _originalData!.firstName != _currentData!.firstName ||
        _originalData!.lastName != _currentData!.lastName ||
        _originalData!.phoneNumber != _currentData!.phoneNumber ||
        _originalData!.profileImageType != _currentData!.profileImageType ||
        _originalData!.customPhotoURL != _currentData!.customPhotoURL ||
        _originalData!.defaultImageId != _currentData!.defaultImageId;
  }
}
```

#### 5.2 Enhanced Profile Edit Page Integration

**Update your existing profile edit page with:**

```dart
// ADD to your existing profile edit page class

class ProfileEditScreen extends StatefulWidget {
  // ... existing code ...

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // ... existing fields ...
  
  @override
  void initState() {
    super.initState();
    // Initialize unsaved changes tracking
    if (_currentUserData != null) {
      UnsavedChangesService.startTracking(_currentUserData!);
    }
  }

  @override
  void dispose() {
    UnsavedChangesService.clearTracking();
    super.dispose();
  }

  // ADD this method to handle back button
  Future<bool> _onWillPop() async {
    if (UnsavedChangesService.hasUnsavedChanges) {
      final result = await UnsavedChangesService.showSaveConfirmationDialog(context);
      
      if (result == true) {
        // Save changes before leaving
        final saveSuccess = await UnsavedChangesService.saveChanges(
          context,
          (userData) => UserService.updateUserProfileImage(userData),
        );
        return saveSuccess;
      } else if (result == false) {
        // Discard changes and leave
        return true;
      } else {
        // Cancel, stay on page
        return false;
      }
    }
    
    return true; // No changes, can leave
  }

  // UPDATE your existing onUserDataChanged method
  void _handleUserDataUpdate(AppUser updatedUserData) {
    setState(() {
      _currentUserData = updatedUserData;
    });
    
    // Track changes for save confirmation
    UnsavedChangesService.updateCurrentData(updatedUserData);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button
      child: Scaffold(
        // ... existing app bar and body ...
        
        // ADD save button in app bar or as floating action button
        appBar: AppBar(
          // ... existing app bar content ...
          actions: [
            if (UnsavedChangesService.hasUnsavedChanges)
              TextButton(
                onPressed: () async {
                  final success = await UnsavedChangesService.saveChanges(
                    context,
                    (userData) => UserService.updateUserProfileImage(userData),
                  );
                  if (success) {
                    setState(() {}); // Refresh to hide save button
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        
        body: Column(
          children: [
            // Profile picture with real-time updates
            RealtimeProfilePictureWidget(
              size: 120,
              isEditable: true,
              onTap: _showProfilePictureModal,
            ),
            
            // ... rest of your existing widgets ...
          ],
        ),
      ),
    );
  }

  void _showProfilePictureModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShoppleProfilePictureModal(
        hasCurrentImage: _currentUserData?.effectivePhotoURL?.isNotEmpty == true,
        defaultAvatarOptions: _getDefaultAvatarOptions(),
        onCustomImageSelected: _handleCustomImageUpload,
        onDefaultAvatarSelected: _handleDefaultAvatarSelection,
        onRemoveImage: _handleImageRemoval,
      ),
    );
  }
  
  // ... implement handler methods ...
}
```

## 🧪 Testing Strategy

### Manual Testing Checklist

#### Permission Testing
- [ ] Camera permission request shows proper UI dialog
- [ ] Gallery permission request works correctly  
- [ ] Permission denial shows settings redirect option
- [ ] Permanent denial handling works properly

#### UI Consistency Testing
- [ ] Profile picture modal follows app theme
- [ ] All buttons and components match existing design
- [ ] Colors and typography are consistent
- [ ] Animations are smooth and appropriate

#### Performance Testing
- [ ] Images load quickly (< 2 seconds)
- [ ] Real-time updates work across all screens
- [ ] No UI lag during image uploads
- [ ] Memory usage remains stable

#### Notification Testing
- [ ] Success notifications appear correctly
- [ ] Error notifications show proper messages
- [ ] Notification styling matches app theme
- [ ] Notifications auto-dismiss appropriately

#### Save Confirmation Testing
- [ ] Unsaved changes detection works
- [ ] Save confirmation dialog appears
- [ ] Back button handling works correctly
- [ ] Save success feedback is shown

### Automated Testing

```dart
// Example test file: test/profile_picture_enhancement_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shopple_app/services/optimized_image_cache_service.dart';
import 'package:shopple_app/services/shopple_notification_service.dart';

void main() {
  group('Profile Picture Enhancement Tests', () {
    
    test('Image cache service initializes correctly', () {
      // Test cache initialization
      expect(OptimizedImageCacheService.getCacheStats, isA<Function>());
    });
    
    test('Notification service shows correct message types', () {
      // Test notification types
      expect(NotificationType.values, hasLength(4));
    });
    
    testWidgets('Real-time profile widget updates correctly', (tester) async {
      // Test widget updates
      // ... implement widget tests
    });
    
    // Add more specific tests
  });
}
```

## 📊 Performance Metrics

Monitor these metrics after implementation:

- **Image load time**: < 2 seconds for cached images
- **Upload success rate**: > 95%
- **UI responsiveness**: No frame drops during interactions
- **Memory usage**: Stable during extended use
- **Cache hit rate**: > 80% for profile pictures
- **User satisfaction**: Positive feedback on performance

## 🎯 Implementation Priority

### Phase 1 (Critical - Week 1)
1. Permission management system
2. UI theme consistency fixes
3. Real-time update system

### Phase 2 (Important - Week 2)  
1. Performance optimizations
2. Notification standardization
3. Save confirmation system

### Phase 3 (Enhancement - Week 3)
1. Advanced caching strategies
2. Analytics integration
3. Edge case handling

## 📝 Final Notes

- **PRESERVE** all existing functionality while enhancing
- **REFERENCE** shopple_previous_build for UI patterns
- **TEST** thoroughly on both Android and iOS
- **MONITOR** performance metrics continuously
- **DOCUMENT** any breaking changes or new dependencies
- **BACKUP** current code before implementing changes

This enhancement will create a snappy, responsive profile picture system that follows your app's design language while providing excellent user experience across all screens and interactions.