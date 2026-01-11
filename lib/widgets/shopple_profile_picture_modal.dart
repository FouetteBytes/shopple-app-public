import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../values/values.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ShoppleProfilePictureModal extends StatelessWidget {
  final Function(ImageSource) onCustomImageSelected;
  final Function(String) onDefaultAvatarSelected;
  final VoidCallback? onRemoveImage;
  final bool hasCurrentImage;
  final List<Map<String, dynamic>> defaultAvatarOptions;

  const ShoppleProfilePictureModal({
    super.key,
    required this.onCustomImageSelected,
    required this.onDefaultAvatarSelected,
    this.onRemoveImage,
    this.hasCurrentImage = false,
    this.defaultAvatarOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar (consistent with existing bottom sheets)
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
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryAccentColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Spacer(),
                LiquidGlassButton.icon(
                  onTap: () => Navigator.pop(context),
                  icon: Icons.close,
                  iconColor: AppColors.primaryText70,
                  size: 40,
                  iconSize: 24,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 20),
            color: AppColors.primaryText30.withValues(alpha: 0.1),
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
              children: [_buildDefaultAvatarGrid(context)],
            ),
            SizedBox(height: 20),
          ],

          // Remove Option Section
          if (hasCurrentImage && onRemoveImage != null) ...[
            _buildSection(
              context,
              title: 'Remove Picture',
              children: [_buildRemoveOption(context)],
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
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.primaryText30.withValues(alpha: 0.2),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
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
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryAccentColor,
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
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryText70,
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
                  color: AppColors.primaryAccentColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: option['url'] != null
                    ? Image.asset(option['url'], fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primaryAccentColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Center(
                          child: Text(
                            option['initials'] ?? '?',
                            style: TextStyle(
                              color: AppColors.primaryAccentColor,
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
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
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
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
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
                          color: AppColors.error,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reset to default avatar with initials',
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
          ),
        ),
      ),
    );
  }
}
