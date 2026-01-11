import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/services/user/user_state_service.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'dart:math' as math;
import 'package:shopple/widgets/shapes/background_hexagon.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final UserController _userController = UserController.instance;

  // DOB and Progress tracking
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _showEmailField = false;
  bool _showPhoneField = false;
  bool _showNameFields = true;
  bool _isGoogleUser = false;

  // Progress tracking variables
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.5; // Start at 50% (account created)
  final int _totalFields = 4; // firstName, lastName, DOB, gender

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _determineOptionalFields();

    // Initialize animation controller for dynamic progress
    _progressController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.5, end: 0.5).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Add listeners to track progress dynamically
    _firstNameController.addListener(_updateProgress);
    _lastNameController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    int completed = 0;

    if (_firstNameController.text.trim().isNotEmpty) completed++;
    if (_lastNameController.text.trim().isNotEmpty) completed++;
    if (_selectedDate != null) completed++;
    if (_selectedGender != null) completed++;

    setState(() {
      double newProgress =
          0.5 + (completed / _totalFields) * 0.5; // 50% to 100%

      _progressAnimation =
          Tween<double>(begin: _currentProgress, end: newProgress).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );

      _currentProgress = newProgress;
      _progressController.forward(from: 0);
    });
  }

  String _buildProgressText() {
    List<String> completedSteps = ['Account created ✓'];

    if (_isGoogleUser) {
      completedSteps.add('Email verified ✓');
    }

    // Check what's completed
    if (_firstNameController.text.trim().isNotEmpty) {
      completedSteps.add('Name ✓');
    } else if (!_isGoogleUser) {
      completedSteps.add('Name needed');
    }

    if (_selectedDate != null) {
      completedSteps.add('Date of birth ✓');
    } else {
      completedSteps.add('Date of birth needed');
    }

    if (_selectedGender != null) {
      completedSteps.add('Gender ✓');
    } else {
      completedSteps.add('Gender needed');
    }

    return completedSteps.join(' • ');
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        Duration(days: 365 * 18),
      ), // Default to 18 years ago
      firstDate: DateTime.now().subtract(
        Duration(days: 365 * 120),
      ), // Max 120 years ago
      lastDate: DateTime.now().subtract(
        Duration(days: 365 * 13),
      ), // Min 13 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _updateProgress();
    }
  }

  void _determineOptionalFields() async {
    final user = _userController.user;
    if (user != null) {
      // Get current app user to check sign-in method
      try {
        final appUser = await UserStateService.getCurrentAppUser();
        if (appUser != null && appUser.signInMethod == 'google') {
          // GOOGLE USER: Show simplified form
          _isGoogleUser = true;
          _showNameFields = false; // Hide name fields, they're auto-populated
          _showPhoneField = true; // Always show phone for Google users
          _showEmailField = false; // Email already from Google

          // Pre-populate name fields from Google data (but hide them)
          if (appUser.displayName != null) {
            final nameParts = appUser.displayName!.split(' ');
            if (nameParts.isNotEmpty) {
              _firstNameController.text = nameParts.first;
              if (nameParts.length > 1) {
                _lastNameController.text = nameParts.sublist(1).join(' ');
              }
            }
          }

          if (mounted) {
            setState(() {});
          }
          return;
        }
      } catch (e) {
        // Fallback to traditional logic if error
      }

      // TRADITIONAL EMAIL/PHONE USER FLOW
      _isGoogleUser = false;
      _showNameFields = true;

      // If user has phone but no email, show email field as optional
      if (user.phoneNumber != null && (user.email?.isEmpty ?? true)) {
        _showEmailField = true;
      }
      // If user has email but no phone, show phone field as optional
      else if ((user.email?.isNotEmpty ?? false) && user.phoneNumber == null) {
        _showPhoneField = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Complete Your Profile",
          style: GoogleFonts.lato(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => _handleBackNavigation(context),
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            DarkRadialBackground(
              color: AppColors.background,
              position: "topLeft",
            ),
            Positioned(
              top: Utils.screenHeight / 2,
              left: Utils.screenWidth,
              child: Transform.rotate(
                angle: -math.pi / 2,
                child: CustomPaint(painter: BackgroundHexagon()),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),

                      // Subtitle - Dynamic based on user type (REMOVED DUPLICATE TITLE)
                      Text(
                        _isGoogleUser
                            ? 'Just a few more details to personalize your experience.'
                            : 'Tell us a bit about yourself to personalize your experience.',
                        style: GoogleFonts.lato(
                          color: AppColors.primaryText70,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 30),

                      // Progress Indicator - As required by login_system_instructions.md
                      // "Implement progress indicators to show users how much of the process remains"
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile Completion',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      '${(_currentProgress * 100).round()}%',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  value: _currentProgress,
                                  backgroundColor: AppColors.inactive
                                      .withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Text(
                                  _buildProgressText(),
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppColors.primaryText70,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Name Fields - Only show for non-Google users
                      if (_showNameFields) ...[
                        // First Name
                        LabelledFormInput(
                          placeholder: "First Name",
                          keyboardType: "text",
                          controller: _firstNameController,
                          obscureText: false,
                          label: "First Name",
                        ),

                        SizedBox(height: 20),

                        // Last Name
                        LabelledFormInput(
                          placeholder: "Last Name",
                          keyboardType: "text",
                          controller: _lastNameController,
                          obscureText: false,
                          label: "Last Name",
                        ),

                        SizedBox(height: 20),
                      ],

                      // Date of Birth - Cool date selector with birthday cake icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date of Birth",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDateOfBirth(context),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.inactive.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cake,
                                    color: AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null
                                        ? "Select your date of birth"
                                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                    style: GoogleFonts.lato(
                                      color: _selectedDate == null
                                          ? AppColors.primaryText70
                                          : AppColors.primaryText,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "You must be at least 13 years old to use this app",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Gender Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gender",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.inactive.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                hint: Text(
                                  'Select Gender',
                                  style: GoogleFonts.lato(
                                    color: AppColors.primaryText70,
                                    fontSize: 16,
                                  ),
                                ),
                                isExpanded: true,
                                dropdownColor: AppColors.surface,
                                style: GoogleFonts.lato(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                ),
                                items: _genderOptions.map((String gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Text(gender),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                  _updateProgress();
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "This helps us personalize your shopping recommendations",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Optional Email Field (for phone users)
                      if (_showEmailField) ...[
                        LabelledFormInput(
                          placeholder: "Enter email (optional)",
                          keyboardType: "email",
                          controller: _emailController,
                          obscureText: false,
                          label: "Email Address (Optional)",
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add email for account recovery and notifications',
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText70,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      // Optional Phone Field (for email users)
                      if (_showPhoneField) ...[
                        LabelledFormInput(
                          placeholder: "Enter phone number (optional)",
                          keyboardType: "phone",
                          controller: _phoneController,
                          obscureText: false,
                          label: "Phone Number (Optional)",
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add phone for SMS notifications and account security',
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText70,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      SizedBox(height: 30),

                      // Complete Profile Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: (_isFormValid() && !_isLoading)
                              ? _completeProfile
                              : null,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              _isFormValid()
                                  ? AppColors.primaryAccentColor
                                  : AppColors.inactive,
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                  ),
                                ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryText,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Complete Profile',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Privacy notice
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Why is this required?',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Profile completion is mandatory to ensure age-appropriate content, personalized recommendations, and a secure shopping experience. Your information is encrypted and never shared with third parties.',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.primaryText70,
                                height: 1.4,
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
          ],
        ),
      ),
    );
  }

  // Handle back navigation with confirmation - as per login_system_instructions.md
  // "Ensure users cannot bypass data collection through any navigation method"
  void _handleBackNavigation(BuildContext context) async {
    bool shouldExit =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                'Profile Completion Required',
                style: GoogleFonts.lato(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'You must complete your profile to continue using the app. Your information helps us provide age-appropriate content and personalized recommendations.',
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Continue Profile',
                    style: GoogleFonts.lato(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Exit App',
                    style: GoogleFonts.lato(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldExit) {
      // Exit the app entirely rather than allowing bypass
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  bool _isFormValid() {
    // Calculate age from DOB
    if (_selectedDate == null) return false;

    final now = DateTime.now();
    final age = now.year - _selectedDate!.year;
    final hasPassedBirthday =
        now.month > _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day >= _selectedDate!.day);
    final actualAge = hasPassedBirthday ? age : age - 1;

    // Age must be between 13 and 120
    if (actualAge < 13 || actualAge > 120) return false;

    // For Google users: only validate DOB, gender (names auto-populated)
    if (_isGoogleUser) {
      return _selectedDate != null && _selectedGender != null;
    }

    // For traditional users: validate all fields including names
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _selectedGender != null;
  }

  void _completeProfile() async {
    if (!_isFormValid()) {
      // Enhanced error messaging as per login_system_instructions.md
      String errorMessage = 'Please complete all required fields:\n';

      if (_firstNameController.text.trim().isEmpty && !_isGoogleUser) {
        errorMessage += '• First name is required\n';
      }
      if (_lastNameController.text.trim().isEmpty && !_isGoogleUser) {
        errorMessage += '• Last name is required\n';
      }
      if (_selectedDate == null) {
        errorMessage += '• Date of birth is required\n';
      } else {
        final now = DateTime.now();
        final age = now.year - _selectedDate!.year;
        final hasPassedBirthday =
            now.month > _selectedDate!.month ||
            (now.month == _selectedDate!.month &&
                now.day >= _selectedDate!.day);
        final actualAge = hasPassedBirthday ? age : age - 1;

        if (actualAge < 13) {
          errorMessage += '• You must be at least 13 years old\n';
        } else if (actualAge > 120) {
          errorMessage += '• Please enter a valid date of birth\n';
        }
      }
      if (_selectedGender == null) {
        errorMessage += '• Gender selection is required\n';
      }

      LiquidSnack.error(
        title: 'Profile Completion Required',
        message: errorMessage.trim(),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare optional contact info
      String? optionalEmail;
      String? optionalPhone;

      if (_showEmailField && _emailController.text.trim().isNotEmpty) {
        optionalEmail = _emailController.text.trim();
      }

      if (_showPhoneField && _phoneController.text.trim().isNotEmpty) {
        optionalPhone = _phoneController.text.trim();
      }

      // Calculate age from DOB
      final now = DateTime.now();
      final age = now.year - _selectedDate!.year;
      final hasPassedBirthday =
          now.month > _selectedDate!.month ||
          (now.month == _selectedDate!.month && now.day >= _selectedDate!.day);
      final actualAge = hasPassedBirthday ? age : age - 1;

      await UserStateService.updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: actualAge,
        gender: _selectedGender!,
        email: optionalEmail,
        phoneNumber: optionalPhone,
        markProfileComplete: true,
      );

      LiquidSnack.show(
        title: 'Profile Updated',
        message: 'Your profile has been completed successfully!',
        accentColor: AppColors.primaryAccentColor,
        icon: Icons.check_circle_rounded,
      );

      // Navigate to next step in user journey
      await _userController.navigateAfterAuth();
    } catch (e) {
      LiquidSnack.error(
        title: 'Update Failed',
        message: 'Failed to update profile. Please try again.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
