import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/user_privacy_settings.dart';
import 'package:shopple/services/privacy/privacy_settings_service.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/back_button.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';

/// Privacy Settings Screen
/// Allows users to control their searchability and contact visibility
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final PrivacySettingsService _privacyService = PrivacySettingsService.instance;
  
  UserPrivacySettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _privacyService.getCurrentUserSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading privacy settings: $e');
      if (mounted) {
        setState(() {
          _settings = UserPrivacySettings.defaultSettings;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings(UserPrivacySettings newSettings) async {
    setState(() => _isSaving = true);
    
    try {
      await _privacyService.saveSettings(newSettings);
      setState(() {
        _settings = newSettings;
        _isSaving = false;
      });
      
      if (mounted) {
        LiquidSnack.show(
          title: 'Saved',
          message: 'Privacy settings saved',
          accentColor: AppColors.primaryGreen,
        );
      }
    } catch (e) {
      AppLogger.e('Error saving privacy settings: $e');
      setState(() => _isSaving = false);
      
      if (mounted) {
        LiquidSnack.error(
          title: 'Error',
          message: 'Failed to save settings',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          _buildFullyPrivateCard(),
                          SizedBox(height: 24),
                          _buildSearchabilitySection(),
                          SizedBox(height: 24),
                          _buildVisibilitySection(),
                          SizedBox(height: 24),
                          _buildPreviewSection(),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          AppBackButton(),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Privacy Settings',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Icon(
            Icons.shield_outlined,
            color: AppColors.primaryGreen,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildFullyPrivateCard() {
    final settings = _settings!;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: settings.isFullyPrivate
              ? [AppColors.primaryGreen.withValues(alpha: 0.2), AppColors.surface]
              : [AppColors.surface, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.isFullyPrivate
              ? AppColors.primaryGreen.withValues(alpha: 0.5)
              : AppColors.inactive.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: settings.isFullyPrivate
                      ? AppColors.primaryGreen.withValues(alpha: 0.2)
                      : AppColors.inactive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility_off_rounded,
                  color: settings.isFullyPrivate
                      ? AppColors.primaryGreen
                      : AppColors.inactive,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fully Private Mode',
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hide from all searches',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.inactive,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: settings.isFullyPrivate,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (value) {
                  final newSettings = settings.copyWith(
                    isFullyPrivate: value,
                    searchableByName: value ? false : true,
                    searchableByEmail: value ? false : true,
                    searchableByPhone: value ? false : true,
                  );
                  _saveSettings(newSettings);
                },
              ),
            ],
          ),
          if (settings.isFullyPrivate) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only existing friends can see your profile. You won\'t appear in search results.',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchabilitySection() {
    final settings = _settings!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.search_rounded,
          title: 'Who Can Find You',
          subtitle: 'Control how others can search for you',
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSearchToggle(
                icon: Icons.person_outline,
                title: 'By Name',
                subtitle: 'Others can find you by searching your name',
                value: settings.searchableByName && !settings.isFullyPrivate,
                enabled: !settings.isFullyPrivate,
                onChanged: (value) {
                  _saveSettings(settings.copyWith(searchableByName: value));
                },
              ),
              _buildDivider(),
              _buildSearchToggle(
                icon: Icons.email_outlined,
                title: 'By Email',
                subtitle: 'Others can find you by your email address',
                value: settings.searchableByEmail && !settings.isFullyPrivate,
                enabled: !settings.isFullyPrivate,
                onChanged: (value) {
                  _saveSettings(settings.copyWith(searchableByEmail: value));
                },
              ),
              _buildDivider(),
              _buildSearchToggle(
                icon: Icons.phone_outlined,
                title: 'By Phone',
                subtitle: 'Others can find you by your phone number',
                value: settings.searchableByPhone && !settings.isFullyPrivate,
                enabled: !settings.isFullyPrivate,
                onChanged: (value) {
                  _saveSettings(settings.copyWith(searchableByPhone: value));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    final settings = _settings!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.remove_red_eye_outlined,
          title: 'What Friends See',
          subtitle: 'Control what info your friends can view',
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildVisibilityOption(
                icon: Icons.person_outline,
                title: 'Name',
                visibility: settings.nameVisibility,
                onChanged: (visibility) {
                  _saveSettings(settings.copyWith(nameVisibility: visibility));
                },
              ),
              _buildDivider(),
              _buildVisibilityOption(
                icon: Icons.email_outlined,
                title: 'Email Address',
                visibility: settings.emailVisibility,
                onChanged: (visibility) {
                  _saveSettings(settings.copyWith(emailVisibility: visibility));
                },
              ),
              _buildDivider(),
              _buildVisibilityOption(
                icon: Icons.phone_outlined,
                title: 'Phone Number',
                visibility: settings.phoneVisibility,
                onChanged: (visibility) {
                  _saveSettings(settings.copyWith(phoneVisibility: visibility));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final settings = _settings!;
    
    // Example data for preview
    const sampleName = 'John Doe';
    const sampleEmail = 'john.doe@example.com';
    const samplePhone = '+1 234 567 8901';
    
    final displayName = ContactMasker.applyVisibility(
      sampleName,
      settings.nameVisibility,
      ContactType.name,
    );
    final displayEmail = ContactMasker.applyVisibility(
      sampleEmail,
      settings.emailVisibility,
      ContactType.email,
    );
    final displayPhone = ContactMasker.applyVisibility(
      samplePhone,
      settings.phoneVisibility,
      ContactType.phone,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.preview_outlined,
          title: 'Preview',
          subtitle: 'How your friends will see you',
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.inactive.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'Hidden',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: displayName != null
                            ? AppColors.primaryText
                            : AppColors.inactive,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (displayEmail != null)
                      Text(
                        displayEmail,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppColors.primaryText70,
                        ),
                      )
                    else if (displayPhone != null)
                      Text(
                        displayPhone,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppColors.primaryText70,
                        ),
                      )
                    else
                      Text(
                        'No contact info visible',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppColors.inactive,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.inactive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? AppColors.primaryGreen : AppColors.inactive,
              size: 22,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.primaryGreen,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required IconData icon,
    required String title,
    required ContactVisibility visibility,
    required ValueChanged<ContactVisibility> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: visibility != ContactVisibility.hidden
                ? AppColors.primaryGreen
                : AppColors.inactive,
            size: 22,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          _buildVisibilitySelector(visibility, onChanged),
        ],
      ),
    );
  }

  Widget _buildVisibilitySelector(
    ContactVisibility current,
    ValueChanged<ContactVisibility> onChanged,
  ) {
    return GestureDetector(
      onTap: () => _showVisibilityPicker(current, onChanged),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getVisibilityColor(current).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getVisibilityColor(current).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getVisibilityIcon(current),
              color: _getVisibilityColor(current),
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              current.displayName,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _getVisibilityColor(current),
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: _getVisibilityColor(current),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getVisibilityColor(ContactVisibility visibility) {
    switch (visibility) {
      case ContactVisibility.full:
        return AppColors.primaryGreen;
      case ContactVisibility.partial:
        return Colors.orange;
      case ContactVisibility.hidden:
        return AppColors.inactive;
    }
  }

  IconData _getVisibilityIcon(ContactVisibility visibility) {
    switch (visibility) {
      case ContactVisibility.full:
        return Icons.visibility;
      case ContactVisibility.partial:
        return Icons.visibility_outlined;
      case ContactVisibility.hidden:
        return Icons.visibility_off;
    }
  }

  void _showVisibilityPicker(
    ContactVisibility current,
    ValueChanged<ContactVisibility> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inactive.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select Visibility',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 16),
              ...ContactVisibility.values.map((visibility) {
                final isSelected = visibility == current;
                return ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getVisibilityColor(visibility).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getVisibilityIcon(visibility),
                      color: _getVisibilityColor(visibility),
                    ),
                  ),
                  title: Text(
                    visibility.displayName,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    visibility.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.inactive,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(visibility);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.inactive.withValues(alpha: 0.15),
      indent: 52,
    );
  }
}
