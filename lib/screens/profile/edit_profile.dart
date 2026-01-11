import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shopple/widgets/common/liquid_snack.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_progress_button.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/form_input_with_label.dart';
import 'package:shopple/widgets/navigation/app_header.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/unsaved_changes_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _aboutController;

  String? selectedGender;
  DateTime? selectedDOB;
  bool isLoading = true;

  // Unsaved changes tracking
  Map<String, dynamic>?
  _originalData; // Make nullable to avoid late initialization error
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
    _setupChangeListeners();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _roleController = TextEditingController();
    _aboutController = TextEditingController();
  }

  void _setupChangeListeners() {
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _roleController.addListener(_onFieldChanged);
    _aboutController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // Only check for changes if _originalData has been initialized and widget is still mounted
    if (_originalData == null || !mounted) return;

    final hasChanges = UnsavedChangesService.hasChanges(
      originalData: _originalData!,
      currentData: _getCurrentFormData(),
    );

    if (hasChanges != _hasUnsavedChanges && mounted) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Map<String, dynamic> _getCurrentFormData() {
    // Safety check to prevent accessing disposed controllers
    if (!mounted) return {};

    return {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'role': _roleController.text.trim(),
      'about': _aboutController.text.trim(),
      'gender': selectedGender,
      'dateOfBirth': selectedDOB?.toIso8601String(),
    };
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            // Load all user data properly
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _emailController.text =
                userData['email'] ?? currentUser.email ?? '';
            _phoneController.text =
                userData['phoneNumber'] ?? currentUser.phoneNumber ?? '';
            _roleController.text = userData['role'] ?? '';
            _aboutController.text = userData['about'] ?? '';

            selectedGender = userData['gender'];

            // Handle DOB with proper error handling
            if (userData['dateOfBirth'] != null) {
              try {
                if (userData['dateOfBirth'] is Timestamp) {
                  selectedDOB = userData['dateOfBirth'].toDate();
                } else if (userData['dateOfBirth'] is String) {
                  selectedDOB = DateTime.parse(userData['dateOfBirth']);
                } else {
                  AppLogger.w(
                    '⚠️ Invalid dateOfBirth format: ${userData['dateOfBirth']}',
                  );
                }
              } catch (e) {
                AppLogger.e('❌ Error parsing dateOfBirth', error: e);
                selectedDOB = null; // Reset to null if parsing fails
              }
            }

            // Store original data for change tracking
            _originalData = {
              'firstName': _firstNameController.text,
              'lastName': _lastNameController.text,
              'email': _emailController.text,
              'phoneNumber': _phoneController.text,
              'role': _roleController.text,
              'about': _aboutController.text,
              'gender': selectedGender,
              'dateOfBirth': selectedDOB?.toIso8601String(),
            };

            isLoading = false;
          });
        } else {
          // Create user document from Firebase Auth data
          await _createUserDocumentFromAuth(currentUser);
          _loadUserData(); // Reload after creating
        }
      }
    } catch (e) {
      AppLogger.e('Error loading user data', error: e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createUserDocumentFromAuth(User user) async {
    try {
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'signInMethod': _determineSignInMethod(user),
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);
    } catch (e) {
      AppLogger.e('Error creating user document', error: e);
    }
  }

  String _determineSignInMethod(User user) {
    if (user.providerData.any((info) => info.providerId == 'google.com')) {
      return 'google';
    } else if (user.providerData.any((info) => info.providerId == 'phone')) {
      return 'phone';
    } else {
      return 'email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tabSpace = "\t\t\t";
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            DarkRadialBackground(
              color: HexColor.fromHex("#181a1f"),
              position: "topLeft",
            ),
            Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAccentColor,
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !(_hasUnsavedChanges && _originalData != null),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldDiscard =
            await UnsavedChangesService.showSaveConfirmationDialog(context);
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            DarkRadialBackground(
              color: HexColor.fromHex("#181a1f"),
              position: "topLeft",
            ),
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ShoppleAppHeader(
                          title: "$tabSpace Edit Profile",
                          widget: PrimaryProgressButton(
                            label: "Save",
                            textStyle: GoogleFonts.lato(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                            callback: _saveProfile,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),

                        // Unified Profile picture section with custom upload capabilities
                        Center(
                          child: UnifiedProfileAvatar(
                            radius: 60, // 120px diameter
                            showBorder: true,
                            enableCache: true,
                            isEditable: true,
                            borderColor: AppColors.primaryAccentColor,
                            borderWidth: 3.0,
                            onImageUpdated: () {
                              // Refresh the UI when profile picture is updated
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        Text(
                          "Tap to change profile photo",
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: HexColor.fromHex("666A7A"),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        AppSpaces.verticalSpace20,

                        // Enhanced form fields with proper data loading
                        LabelledFormInput(
                          placeholder: "Enter your first name",
                          keyboardType: "text",
                          controller: _firstNameController,
                          obscureText: false,
                          label: "First Name",
                        ),
                        AppSpaces.verticalSpace20,
                        LabelledFormInput(
                          placeholder: "Enter your last name",
                          keyboardType: "text",
                          controller: _lastNameController,
                          obscureText: false,
                          label: "Last Name",
                        ),
                        AppSpaces.verticalSpace20,
                        LabelledFormInput(
                          placeholder: "Email address",
                          keyboardType: "email",
                          controller: _emailController,
                          obscureText: false,
                          label: "Email (cannot be changed)",
                          // Make email field read-only
                        ),
                        AppSpaces.verticalSpace20,
                        LabelledFormInput(
                          placeholder: "Phone number",
                          keyboardType: "phone",
                          controller: _phoneController,
                          obscureText: false,
                          label: "Phone Number",
                        ),
                        AppSpaces.verticalSpace20,

                        // Gender selection
                        _buildGenderSelection(),

                        AppSpaces.verticalSpace20,

                        // Date of birth selection
                        _buildDOBSelection(),

                        AppSpaces.verticalSpace20,
                        LabelledFormInput(
                          placeholder: "Enter your role",
                          keyboardType: "text",
                          controller: _roleController,
                          obscureText: false,
                          label: "Role",
                        ),
                        AppSpaces.verticalSpace20,
                        LabelledFormInput(
                          placeholder: "Tell us about yourself",
                          keyboardType: "text",
                          controller: _aboutController,
                          obscureText: false,
                          label: "About Me",
                        ),
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ), // Closing parenthesis for WillPopScope child
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: GoogleFonts.lato(color: AppColors.inactive, fontSize: 14),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              hint: Text(
                "Select Gender",
                style: GoogleFonts.lato(color: AppColors.inactive),
              ),
              isExpanded: true,
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.lato(color: AppColors.primaryText),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDOBSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: GoogleFonts.lato(color: AppColors.inactive, fontSize: 14),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryAccentColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDOB != null
                        ? "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}"
                        : "Select date of birth",
                    style: GoogleFonts.lato(
                      color: selectedDOB != null
                          ? AppColors.primaryText
                          : AppColors.inactive,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDOB ?? DateTime.now().subtract(Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 13)),
    );

    if (picked != null && picked != selectedDOB) {
      setState(() {
        selectedDOB = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted) return; // Safety check

    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && mounted) {
          Map<String, dynamic> updateData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'gender': selectedGender,
            'role': _roleController.text.trim(),
            'about': _aboutController.text.trim(),
            'lastUpdated': FieldValue.serverTimestamp(),
            'isProfileComplete': true,
          };

          if (selectedDOB != null) {
            updateData['dateOfBirth'] = Timestamp.fromDate(selectedDOB!);
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update(updateData);

          if (mounted) {
            LiquidSnack.show(
              title: "Success",
              message: "Profile updated successfully!",
              accentColor: AppColors.primaryAccentColor,
              icon: Icons.check_circle_outline,
            );

            // Clear tracking after successful save
            _hasUnsavedChanges = false;
            _originalData = _getCurrentFormData();

            Get.back();
          }
        }
      } catch (e) {
        AppLogger.e('Error saving profile', error: e);
        if (mounted) {
          LiquidSnack.error(
            title: "Error",
            message: "Error updating profile. Please try again.",
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers to prevent accessing disposed controllers
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _roleController.removeListener(_onFieldChanged);
    _aboutController.removeListener(_onFieldChanged);

    // Now safely dispose the controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}
