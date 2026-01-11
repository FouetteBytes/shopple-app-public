import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/widgets/common/liquid_glass.dart';
import 'package:shopple/services/media/pattern_background_service.dart';
import 'package:shopple/services/user/user_display_service.dart';
import 'package:shopple/services/media/image_upload_service.dart';
import 'package:shopple/services/media/profile_picture_service.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/widgets/profile/pattern_background_preview.dart';
import 'package:shopple/widgets/profile_picture_selector.dart';
import '../utils/app_logger.dart';

/// Unified Profile Avatar Component with Smart Caching
///
/// This component provides a consistent profile picture experience across all screens:
/// - Real-time updates when profile changes
/// - Smart caching to prevent flickering
/// - Consistent appearance across Dashboard, Profile, and Edit screens
/// - Handles all profile types: custom images, memojis, Google photos, and initials
class UnifiedProfileAvatar extends StatefulWidget {
  final double radius;
  final bool showBorder;
  final VoidCallback? onTap;
  final String? userId; // Optional: for viewing other users' profiles
  final bool isEditable; // Show edit overlay
  final bool enableCache; // Enable aggressive caching
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onImageUpdated; // Callback when image is updated
  final BorderRadius? borderRadius; // Flexible border radius
  final BoxBorder? border; // Custom border styling

  static FirebaseAuth firebaseAuthInstance = FirebaseAuth.instance;

  const UnifiedProfileAvatar({
    super.key,
    this.radius = 25,
    this.showBorder = false,
    this.onTap,
    this.userId,
    this.isEditable = false,
    this.enableCache = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.onImageUpdated,
    this.borderRadius,
    this.border,
  });

  @override
  State<UnifiedProfileAvatar> createState() => _UnifiedProfileAvatarState();
}

class _UnifiedProfileAvatarState extends State<UnifiedProfileAvatar> {
  Stream<Map<String, dynamic>?>? _userStream;
  String? _targetUserId;
  bool _isUploading = false;
  bool _forceRefresh = false; // Flag to force bypass cache after update

  // Cache management
  static final Map<String, Map<String, dynamic>> _userDataCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  // Optimistic overrides (e.g., user picked new memoji / uploaded image)
  static final Map<String, String> _optimisticImage = {};
  // Optimistic background override (stores serialized map for immediate UI reflection)
  static final Map<String, Map<String, dynamic>> _optimisticBackground = {};
  // Global revision notifier to trigger rebuilds across all avatar instances
  static final ValueNotifier<int> _globalRevision = ValueNotifier<int>(0);

  static void _broadcastRevision() {
    _globalRevision.value = _globalRevision.value + 1;
  }

  @override
  void initState() {
    super.initState();
    _setupUserStream();
  }

  @override
  void didUpdateWidget(UnifiedProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-setup stream if userId changes
    if (widget.userId != oldWidget.userId) {
      _setupUserStream();
    }
  }

  void _setupUserStream() {
    _targetUserId =
        widget.userId ??
        UnifiedProfileAvatar.firebaseAuthInstance.currentUser?.uid;

    if (_targetUserId != null) {
      // Use centralized profile stream service to dedupe listeners and reuse cache
      _userStream = UserProfileStreamService.instance.watchUser(_targetUserId!);
    }
  }

  bool _isCacheValid(String userId) {
    if (!widget.enableCache) return false;

    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  void _updateCache(String userId, Map<String, dynamic> userData) {
    if (widget.enableCache) {
      _userDataCache[userId] = Map<String, dynamic>.from(userData);
      _cacheTimestamps[userId] = DateTime.now();
    }
  }

  Map<String, dynamic>? _getCachedData(String userId) {
    if (_isCacheValid(userId)) {
      return _userDataCache[userId];
    }
    return null;
  }

  // Sticky cache: returns the last known non-null user map regardless of age.
  // This prevents avatars from disappearing if the stream temporarily emits null
  // or when the timed cache entry is considered stale.
  Map<String, dynamic>? _getLastKnownData(String userId) {
    return _userDataCache[userId];
  }

  @override
  Widget build(BuildContext context) {
    if (_targetUserId == null) {
      return _buildDefaultAvatar();
    }
    return ValueListenableBuilder<int>(
      valueListenable: _globalRevision,
      builder: (context, revision, _) {
        // Optimistic path: show optimistic image immediately if present
        final optimistic = _optimisticImage[_targetUserId!];
        if (optimistic != null) {
          final synthetic = <String, dynamic>{
            'profileImageType': optimistic.endsWith('.png')
                ? 'memoji'
                : 'custom',
            'defaultImageId': optimistic.endsWith('.png') ? optimistic : null,
            'customPhotoURL': optimistic.endsWith('.png') ? null : optimistic,
            'photoURL': null,
            'profilePicture': optimistic, // backward compatibility
          };
          final optBg = _optimisticBackground[_targetUserId!];
          if (optBg != null) {
            synthetic['profileBackground'] = optBg;
          }
          return _buildProfileWidget(synthetic, fromCache: false);
        }

        // Try cache first (skip if force refresh). If timed cache is missing,
        // fall back to last-known sticky cache to avoid visual dropouts.
        if (!_forceRefresh) {
          Map<String, dynamic>? cachedData = _getCachedData(_targetUserId!);
          cachedData ??= _getLastKnownData(_targetUserId!);
          if (cachedData != null) {
            // Overlay optimistic background if present
            final optBg = _optimisticBackground[_targetUserId!];
            if (optBg != null) {
              final merged = Map<String, dynamic>.from(cachedData);
              merged['profileBackground'] = optBg;
              return _buildProfileWidget(merged, fromCache: true);
            }
            return _buildProfileWidget(cachedData, fromCache: true);
          }
        }

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _userStream,
          // Provide last-known data as initialData so UI never falls back to default
          initialData: _getLastKnownData(_targetUserId!),
          builder: (context, snapshot) {
            Map<String, dynamic>? userData = snapshot.data;
            // If stream temporarily emits null (e.g., permission change or disconnect),
            // use last known cached data (sticky) to avoid disappearance.
            userData ??= _getLastKnownData(_targetUserId!);
            if (userData == null) {
              return _buildDefaultAvatar();
            }

            // If snapshot now matches optimistic state, clear optimistic override
            final opt = _optimisticImage[_targetUserId!];
            if (opt != null) {
              final currentEffective = _getEffectiveProfilePictureUrl(userData);
              if (currentEffective == opt) {
                _optimisticImage.remove(_targetUserId!);
              }
            }

            // If we had an optimistic background, clear it after real data with background arrives
            if (_optimisticBackground.containsKey(_targetUserId!)) {
              final optBg = _optimisticBackground[_targetUserId!];
              final realBg = userData['profileBackground'];
              if (realBg != null && realBg is Map<String, dynamic>) {
                // Compare by id if present; if matches, remove optimistic entry
                if (optBg?['id'] == realBg['id']) {
                  _optimisticBackground.remove(_targetUserId!);
                }
              } else if (realBg != null) {
                // Any non-null background returned clears optimistic to avoid stale state
                _optimisticBackground.remove(_targetUserId!);
              }
            }

            // Merge optimistic background (if still present) before caching so UI picks it instantly
            if (_optimisticBackground.containsKey(_targetUserId!)) {
              userData = {
                ...userData,
                'profileBackground': _optimisticBackground[_targetUserId!],
              };
            }

            _updateCache(_targetUserId!, userData);
            if (_forceRefresh) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _forceRefresh = false);
                }
              });
            }
            return _buildProfileWidget(userData, fromCache: false);
          },
        );
      },
    );
  }

  Widget _buildProfileWidget(
    Map<String, dynamic> userData, {
    required bool fromCache,
  }) {
    final decoration = _buildContainerDecoration();

    return GestureDetector(
      onTap: widget.isEditable ? _showProfilePictureOptions : widget.onTap,
      child: SizedBox(
        // Add extra space when editable to accommodate the camera overlay
        width: widget.isEditable ? (widget.radius * 2) + 8 : widget.radius * 2,
        height: widget.isEditable ? (widget.radius * 2) + 8 : widget.radius * 2,
        child: Stack(
          clipBehavior: Clip.none, // Allow overflow for the camera icon
          children: [
            // Main avatar container
            Positioned(
              top: widget.isEditable ? 4 : 0,
              left: widget.isEditable ? 4 : 0,
              child: Container(
                width: widget.radius * 2,
                height: widget.radius * 2,
                decoration: decoration,
                clipBehavior: decoration != null ? Clip.antiAlias : Clip.none,
                child: _buildProfileContent(userData),
              ),
            ),
            if (_isUploading)
              Positioned(
                top: widget.isEditable ? 4 : 0,
                left: widget.isEditable ? 4 : 0,
                child: _buildLoadingOverlay(),
              ),
            if (widget.isEditable)
              Positioned(bottom: 0, right: 0, child: _buildEditOverlay()),
          ],
        ),
      ),
    );
  }

  /// Build container decoration with flexible options
  BoxDecoration? _buildContainerDecoration() {
    // Use custom border if provided
    if (widget.border != null || widget.borderRadius != null) {
      return BoxDecoration(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(widget.radius),
        border: widget.border,
      );
    }

    // Use legacy showBorder logic
    if (widget.showBorder) {
      return BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.borderColor ?? Colors.white,
          width: widget.borderWidth,
        ),
      );
    }

    // Return default circular decoration to enable clipping
    return BoxDecoration(shape: BoxShape.circle);
  }

  Widget _buildProfileContent(Map<String, dynamic> userData) {
    // Get effective profile picture URL using the hybrid system
    String? profileImageUrl = _getEffectiveProfilePictureUrl(userData);
    String? profileImageType = userData['profileImageType'];

    // Only log in debug mode when needed - remove excessive logging
    // AppLogger.d('UnifiedProfileAvatar - Building profile content:');
    // AppLogger.d('   profileImageUrl: ${AppLogger.sanitizeUrl(profileImageUrl)}');
    // AppLogger.d('   profileImageType: $profileImageType');
    // AppLogger.d('   defaultImageId: ${userData['defaultImageId']}');
    // AppLogger.d('   profilePicture: ${userData['profilePicture']}');

    return PatternBackgroundPreview(
      size: widget.radius * 2,
      profileImageUrl: profileImageUrl,
      profileImageType: profileImageType,
      userInitial: UserDisplayService.getUserInitial(
        userData: userData,
        enableDebugLogs: false, // Disable debug logs for performance
      ),
      backgroundOption: _getBackgroundFromUserData(userData),
    );
  }

  /// Get effective profile picture URL using enhanced logic from RealtimeProfilePictureWidget
  String? _getEffectiveProfilePictureUrl(Map<String, dynamic> userData) {
    try {
      String? profileImageType = userData['profileImageType'];

      // Only log in debug mode when needed - remove excessive logging
      // AppLogger.d('URL Resolution - profileImageType: $profileImageType');
      // AppLogger.d('URL Resolution - customPhotoURL: ${AppLogger.sanitizeUrl(userData['customPhotoURL'])}');
      // AppLogger.d('URL Resolution - defaultImageId: ${userData['defaultImageId']}');
      // AppLogger.d('URL Resolution - photoURL: ${AppLogger.sanitizeUrl(userData['photoURL'])}');

      // If profileImageType is 'memoji' or 'default', prioritize that over everything else
      if ((profileImageType == 'memoji' || profileImageType == 'default') &&
          userData['defaultImageId'] != null &&
          userData['defaultImageId'] != 'initials') {
        // AppLogger.d('Using memoji/default image: ${userData['defaultImageId']}');
        return userData['defaultImageId'];
      }

      // Priority 1: Custom uploaded photos (only if profileImageType is 'custom')
      if (profileImageType == 'custom' &&
          userData['customPhotoURL'] != null &&
          userData['customPhotoURL'].toString().isNotEmpty) {
        return userData['customPhotoURL'];
      }

      // Priority 2: Google/social login photos (only if no explicit profileImageType or if it's 'google')
      if ((profileImageType == null || profileImageType == 'google') &&
          userData['photoURL'] != null &&
          userData['photoURL'].toString().isNotEmpty) {
        return userData['photoURL'];
      }

      // Priority 3: Backward compatibility
      if (userData['profilePicture'] != null &&
          userData['profilePicture'].toString().isNotEmpty) {
        return userData['profilePicture'];
      }

      // Priority 4: Use ImageUploadService as final fallback
      final fallbackUrl = ImageUploadService.getEffectiveProfilePictureUrl(
        profileImageType: userData['profileImageType'],
        customPhotoURL: userData['customPhotoURL'],
        photoURL: userData['photoURL'],
        defaultImageId:
            userData['defaultImageId'] ?? userData['profilePicture'],
      );
      return fallbackUrl;
    } catch (e) {
      AppLogger.w(
        'UnifiedProfileAvatar - Error resolving profile image URL: $e',
      );
      return null;
    }
  }

  Widget _buildEditOverlay() {
    return Container(
      width: widget.radius * 0.7, // Slightly larger for better visibility
      height: widget.radius * 0.7,
      decoration: BoxDecoration(
        color: AppColors.primaryAccentColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ), // Thicker border for better contrast
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.camera_alt,
        size: widget.radius * 0.35,
        color: Colors.white,
      ),
    );
  }

  /// Loading overlay for upload progress
  Widget _buildLoadingOverlay() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: SizedBox(
          width: widget.radius * 0.8,
          height: widget.radius * 0.8,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryAccentColor,
            ),
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  /// Show profile picture selection options
  void _showProfilePictureOptions() {
    showAppBottomSheet(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),

          // Upload from Camera
          _buildProfileOption(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Use camera to take a new photo',
            onTap: () {
              Navigator.pop(context);
              _pickCustomImage(ImageSource.camera);
            },
          ),

          SizedBox(height: 12),

          // Upload from Gallery
          _buildProfileOption(
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            subtitle: 'Select a photo from your gallery',
            onTap: () {
              Navigator.pop(context);
              _pickCustomImage(ImageSource.gallery);
            },
          ),

          SizedBox(height: 12),

          // Select Default Avatar with Background Colors
          _buildProfileOption(
            icon: Icons.face,
            title: 'Choose Avatar & Background',
            subtitle: 'Select from available avatars and colors',
            onTap: () {
              Navigator.pop(context);
              _selectDefaultAvatarWithBackground();
            },
          ),

          SizedBox(height: 12),

          // Remove Current Picture
          _buildProfileOption(
            icon: Icons.delete,
            title: 'Remove Picture',
            subtitle: 'Reset to default avatar with initials',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _removeCurrentPicture();
            },
          ),

          SizedBox(height: 20),
        ],
      ),
      title: 'Profile Picture',
    );
  }

  /// Build profile option widget
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: LiquidGlass(
            borderRadius: 16,
            enableBlur: true,
            padding: EdgeInsets.all(16),
            gradientColors: isDestructive
                ? [
                    Colors.red.withValues(alpha: 0.12),
                    Colors.red.withValues(alpha: 0.06),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
            borderColor: isDestructive
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDestructive
                        ? Colors.red.withValues(alpha: 0.15)
                        : AppColors.primaryAccentColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : AppColors.primaryAccentColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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

  /// Pick custom image from camera or gallery
  Future<void> _pickCustomImage(ImageSource source) async {
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      // Step 1: Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Step 2: Upload to Firebase Storage
      final ImageUploadResponse response =
          await ImageUploadService.uploadCustomProfilePicture(image);

      if (response.result == ImageUploadResult.success &&
          response.downloadUrl != null) {
        // Step 3: Update user data with custom image
        final bool success =
            await ProfilePictureService.updateCustomProfilePicture(
              response.downloadUrl!,
            );

        if (success && mounted) {
          // Clear cache to force refresh
          if (_targetUserId != null) {
            clearUserCache(_targetUserId!);
          }

          // Set optimistic override so other widgets update instantly
          _optimisticImage[_targetUserId!] = response.downloadUrl!;
          _broadcastRevision();

          // Notify parent widget
          widget.onImageUpdated?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.primaryAccentColor,
            ),
          );
        }
      } else {
        throw Exception(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Select default avatar with background
  Future<void> _selectDefaultAvatarWithBackground() async {
    final results = await showAppBottomSheet(
      ProfilePictureSelector(
        currentPicture: null,
        onPictureSelected: (selectedPicture) {
          // Handled by modal return
        },
      ),
      title: 'Choose Profile Picture',
      isScrollControlled: true,
      maxHeightFactor: 0.75,
    );

    if (results != null && mounted) {
      setState(() => _isUploading = true);

      try {
        // Get the selected picture and background from results
        final String? selectedPicture = results['picture'];
        final ProfileBackgroundOption? selectedBackground =
            results['background'];

        AppLogger.d('UnifiedProfileAvatar - Processing selection:');
        AppLogger.d('   Picture: $selectedPicture');
        AppLogger.d('   Background: ${selectedBackground?.name}');

        if (selectedPicture == null || selectedPicture.isEmpty) {
          throw Exception('No picture selected');
        }

        // Update profile picture
        // Optimistic overrides BEFORE server write so UI updates instantly
        if (_targetUserId != null) {
          _optimisticImage[_targetUserId!] = selectedPicture;
          if (selectedBackground != null) {
            _optimisticBackground[_targetUserId!] = selectedBackground.toMap();
          }
          _broadcastRevision();
        }

        final bool success = await ProfilePictureService.updateProfilePicture(
          selectedPicture,
        );

        if (!success) {
          throw Exception('Failed to update profile picture');
        }

        // Save background if selected (after optimistic assignment)
        if (selectedBackground != null) {
          try {
            await PatternBackgroundService.saveUserBackground(
              selectedBackground,
            );
            AppLogger.d(
              'Background saved successfully: ${selectedBackground.name}',
            );
          } catch (backgroundError) {
            AppLogger.w('Warning: Failed to save background: $backgroundError');
            // Retain optimistic state on failure
          }
        }

        if (mounted) {
          // Clear cache to force refresh - be more aggressive
          AppLogger.d('UnifiedProfileAvatar: Clearing cache for refresh…');
          if (_targetUserId != null) {
            clearUserCache(_targetUserId!);
            // Preserve optimistic background until stream delivers updated doc
            if (_optimisticBackground.containsKey(_targetUserId!)) {
              _userDataCache[_targetUserId!] = {
                ...?_userDataCache[_targetUserId!],
                'profileBackground': _optimisticBackground[_targetUserId!],
              };
            }
            AppLogger.d(
              'UnifiedProfileAvatar: Cleared cache & applied optimistic background for target user: $_targetUserId',
            );
          }

          // Also clear cache for current user if different
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.uid != _targetUserId) {
            clearUserCache(currentUser.uid);
            AppLogger.d(
              'UnifiedProfileAvatar: Cleared cache for current user: ${currentUser.uid}',
            );
          }

          // Force a complete widget rebuild by calling setState
          setState(() {
            _forceRefresh = true;
            // Do NOT clear all cache globally; keep optimistic entries until stream catches up
            AppLogger.d(
              'UnifiedProfileAvatar: Force refresh set (kept optimistic cache)',
            );
          });
          _broadcastRevision();

          // Add a small delay and then trigger another rebuild to ensure the Firebase update is picked up
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                AppLogger.d(
                  'UnifiedProfileAvatar: Secondary refresh triggered',
                );
              });
            }
          });

          // Notify parent widget
          widget.onImageUpdated?.call();
          AppLogger.d('UnifiedProfileAvatar: Notified parent widget');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: AppColors.primaryAccentColor,
            ),
          );
        }
      } catch (e, st) {
        AppLogger.e(
          'UnifiedProfileAvatar: Error updating avatar',
          error: e,
          stackTrace: st,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update avatar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  /// Remove current picture
  Future<void> _removeCurrentPicture() async {
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      final bool success = await ProfilePictureService.resetToDefaultAvatar();

      if (success && mounted) {
        // Clear cache to force refresh
        if (_targetUserId != null) {
          clearUserCache(_targetUserId!);
        }

        // Notify parent widget
        widget.onImageUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture removed successfully!'),
            backgroundColor: AppColors.primaryAccentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildDefaultAvatar() {
    final decoration = _buildContainerDecoration();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: decoration,
        clipBehavior: decoration != null ? Clip.antiAlias : Clip.none,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HexColor.fromHex("94F0F1"),
          ),
          child: Center(
            child: Text(
              'U',
              style: TextStyle(
                fontSize: widget.radius * 0.6,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get background option from user data with enhanced error handling
  ProfileBackgroundOption? _getBackgroundFromUserData(
    Map<String, dynamic> userData,
  ) {
    try {
      // Check both field names for compatibility
      final backgroundData =
          userData['profileBackground'] ?? userData['selectedBackground'];

      if (backgroundData != null && backgroundData is Map<String, dynamic>) {
        // Try using fromMap first (proper way)
        try {
          return ProfileBackgroundOption.fromMap(backgroundData);
        } catch (e) {
          AppLogger.w(
            'UnifiedProfileAvatar: Error using fromMap, falling back to manual parsing: $e',
          );

          // Fallback for legacy colorHex format
          final colorHex = backgroundData['colorHex'];
          if (colorHex != null) {
            return ProfileBackgroundOption(
              id: 'user_selected',
              name: 'User Selected Color',
              type: BackgroundType.solid,
              colors: [
                Color(int.parse(colorHex.replaceFirst('#', ''), radix: 16)),
              ],
            );
          }

          // Additional fallback for colors array
          if (backgroundData['colors'] != null &&
              backgroundData['colors'] is List) {
            return ProfileBackgroundOption(
              id: backgroundData['id'] ?? 'solid_default',
              name: backgroundData['name'] ?? 'Default',
              type: BackgroundType.solid,
              colors: (backgroundData['colors'] as List)
                  .map((c) => Color(c))
                  .toList(),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.w('UnifiedProfileAvatar: Error parsing background data: $e');
    }
    return null;
  }

  /// Cache Management Methods (for future use)
  /// These methods can be called externally to manage profile picture cache

  /// Clear cache for specific user (useful when profile is updated)
  /// Example: UnifiedProfileAvatar.clearUserCache(userId);
  static void clearUserCache(String userId) {
    _userDataCache.remove(userId);
    _cacheTimestamps.remove(userId);
    // Also clear centralized stream cache so next listen fetches fresh data
    UserProfileStreamService.instance.clearUser(userId);
  }

  /// Clear all cached data
  /// Example: UnifiedProfileAvatar.clearAllCache();
  /// ignore: unused_element
  static void clearAllCache() {
    _userDataCache.clear();
    _cacheTimestamps.clear();
  }
}
