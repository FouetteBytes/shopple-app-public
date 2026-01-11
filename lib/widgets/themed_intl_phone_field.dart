import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:shopple/values/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

/// Themed International Phone Field
///
/// A customized IntlPhoneField that matches the app's dark theme and design system.
/// Provides consistent styling across all phone number input screens.
class ThemedIntlPhoneField extends StatelessWidget {
  final Function(PhoneNumber) onChanged;
  final String? Function(PhoneNumber?)? validator;
  final TextEditingController? controller;
  final String? initialCountryCode;
  final bool autovalidateMode;
  final String? hintText;
  final bool showDropdownIcon;
  final bool enabled;
  final FocusNode? focusNode;

  const ThemedIntlPhoneField({
    super.key,
    required this.onChanged,
    this.validator,
    this.controller,
    this.initialCountryCode = 'US',
    this.autovalidateMode = false,
    this.hintText,
    this.showDropdownIcon = true,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Customize the dropdown theme
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          textStyle: GoogleFonts.nunito(
            color: AppColors.primaryText,
            fontSize: 16,
          ),
        ),
      ),
      child: IntlPhoneField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autovalidateMode: autovalidateMode
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,

        // Country Selection Configuration
        initialCountryCode: initialCountryCode,
        showDropdownIcon: showDropdownIcon,

        // Styling Configuration
        style: GoogleFonts.nunito(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        dropdownTextStyle: GoogleFonts.nunito(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        // Country Search Configuration
        pickerDialogStyle: PickerDialogStyle(
          searchFieldInputDecoration: const InputDecoration(
            hintText: 'Search Countries',
          ),
        ),

        // Input Decoration
        decoration: InputDecoration(
          hintText: hintText ?? 'Phone number',
          hintStyle: GoogleFonts.nunito(
            color: AppColors.primaryText.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),

          // Border styling to match app theme
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primaryText.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primaryAccentColor,
              width: 2,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),

          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primaryText.withValues(alpha: 0.2),
              width: 1,
            ),
          ),

          // Fill and background
          filled: true,
          fillColor: AppColors.surface,

          // Content padding
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          // Error style
          errorStyle: GoogleFonts.nunito(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Dropdown decoration for country selection
        dropdownDecoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryText.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),

        // Country search field decoration
        // searchTextStyle not supported in current SDK version

        // Callbacks
        onChanged: onChanged,
        validator: validator,

        // Dropdown icon styling
        dropdownIcon: Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.primaryText.withValues(alpha: 0.7),
          size: 24,
        ),

        // Flag configuration
        flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),

        // Disable country code editing
        disableLengthCheck: false,

        // Language localization support
        languageCode: 'en',
      ),
    );
  }
}

/// Utility class for phone number validation
class PhoneValidationUtils {
  /// Validates phone number format and completeness
  static String? validatePhoneNumber(PhoneNumber? phoneNumber) {
    if (phoneNumber == null || phoneNumber.number.isEmpty) {
      return 'Phone number is required';
    }

    // Check minimum length (varies by country, but 7 is generally minimum)
    if (phoneNumber.number.length < 7) {
      return 'Phone number is too short';
    }

    // Check if the number appears to be complete
    // Basic validation - checking length and structure
    if (phoneNumber.number.length < 7) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Get formatted phone number for display
  static String getFormattedNumber(PhoneNumber phoneNumber) {
    return phoneNumber.completeNumber;
  }

  /// Extract just the numeric part of the phone number
  static String getNumericPhoneNumber(PhoneNumber phoneNumber) {
    return phoneNumber.number.replaceAll(RegExp(r'[^\d]'), '');
  }
}
