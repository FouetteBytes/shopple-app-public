import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/profile/edit_profile.dart';
import 'package:shopple/screens/profile/privacy_settings_screen.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/back_button.dart';
import 'package:shopple/widgets/onboarding/toggle_option.dart';
import 'package:shopple/widgets/profile/profile_text_option.dart';
import 'package:shopple/widgets/profile/text_outlined_button.dart';
import 'package:shopple/controllers/user_controller.dart';
import 'package:shopple/widgets/dialogs/sign_out_dialog.dart';
import 'package:shopple/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/widgets/common/privacy_aware_contact_display.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ValueNotifier<bool> totalTaskNotifier = ValueNotifier(true);
  final String tabSpace = "\t\t";
  final UserController userController = Get.find<UserController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enhanced name display with AppUser support
  String _getEnhancedDisplayName(AppUser? userData, User? currentUser) {
    AppLogger.d('🔍 MY_PROFILE DEBUG: _getEnhancedDisplayName called');
    AppLogger.d('🔍 userData: $userData');
    AppLogger.d('🔍 currentUser: ${currentUser?.email}');

    if (userData != null) {
      String result = userData.displayFullName;
      AppLogger.d('✅✅✅ SUCCESS: Using userData.displayFullName: "$result" ✅✅✅');
      return result;
    }

    // Fallback to current user data
    if (currentUser?.displayName?.isNotEmpty == true) {
      AppLogger.d(
        '📧 Fallback: Using currentUser.displayName: "${currentUser!.displayName}"',
      );
      return currentUser.displayName!;
    }

    AppLogger.w('❌ Ultimate fallback: "User"');
    return 'User';
  }

  // Enhanced contact display with common sense logic
  String _getEnhancedContactInfo(AppUser? userData, User? currentUser) {
    AppLogger.d('🔍 MY_PROFILE DEBUG: _getEnhancedContactInfo called');
    AppLogger.d('🔍 userData?.signInMethod: ${userData?.signInMethod}');
    AppLogger.d('🔍 userData?.phoneNumber: ${userData?.phoneNumber}');
    AppLogger.d('🔍 userData?.email: ${userData?.email}');

    // COMMON SENSE LOGIC: Based on sign-in method
    String signInMethod = userData?.signInMethod ?? 'email';

    switch (signInMethod) {
      case 'phone':
        // Phone users should see PHONE NUMBER first
        if (userData?.phoneNumber?.isNotEmpty ?? false) {
          AppLogger.d('✅ Phone user - showing phone: ${userData!.phoneNumber}');
          return userData.phoneNumber!;
        }
        if (currentUser?.phoneNumber?.isNotEmpty ?? false) {
          AppLogger.d(
            '✅ Phone user - fallback currentUser phone: ${currentUser!.phoneNumber}',
          );
          return currentUser.phoneNumber!;
        }
        break;

      case 'google':
      case 'email':
        // Email/Google users should see EMAIL first
        String? userEmail = userData?.email;
        if (userEmail != null && userEmail.isNotEmpty) {
          AppLogger.d('✅ Email user - showing email: $userEmail');
          return userEmail;
        }
        String? currentUserEmail = currentUser?.email;
        if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
          AppLogger.d(
            '✅ Email user - fallback currentUser email: $currentUserEmail',
          );
          return currentUserEmail;
        }
        break;
    }

    AppLogger.w('❌ No contact available');
    return 'No contact available';
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: SafeArea(
              child: SingleChildScrollView(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: currentUser != null
                      ? _firestore
                            .collection('users')
                            .doc(currentUser.uid)
                            .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    AppUser? userData;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      try {
                        userData = AppUser.fromFirestore(snapshot.data!);
                        AppLogger.d(
                          '🔍 MY_PROFILE: Loaded AppUser: ${userData.displayFullName}',
                        );
                        AppLogger.d(
                          '🔍 MY_PROFILE: firstName: ${userData.firstName}, lastName: ${userData.lastName}',
                        );
                        AppLogger.d(
                          '🔍 MY_PROFILE: signInMethod: ${userData.signInMethod}',
                        );
                      } catch (e) {
                        AppLogger.e(
                          '❌ MY_PROFILE: Error loading AppUser',
                          error: e,
                        );
                      }
                    }

                    return Obx(() {
                      // Show loading state if needed
                      if (userController.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: [
                          // Custom header without the button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppBackButton(),
                              Expanded(
                                child: Text(
                                  "$tabSpace Profile",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 20,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 48), // Balance the back button
                            ],
                          ),
                          SizedBox(height: 30),
                          // Unified User Avatar with hybrid support and caching
                          UnifiedProfileAvatar(
                            radius: 50, // 100px diameter
                            showBorder: true,
                            enableCache: true,
                            isEditable: false, // Display only in profile view
                            borderColor: AppColors.primaryAccentColor,
                            borderWidth: 3.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _getEnhancedDisplayName(userData, currentUser),
                              style: GoogleFonts.lato(
                                color: AppColors.primaryText,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _getEnhancedContactInfo(userData, currentUser),
                            style: GoogleFonts.lato(
                              color: HexColor.fromHex("B0FFE1"),
                              fontSize: 17,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: OutlinedButtonWithText(
                              width: 75,
                              content: "Edit",
                              onPressed: () {
                                Get.to(() => EditProfilePage());
                              },
                            ),
                          ),
                          AppSpaces.verticalSpace20,
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF262A34),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    ToggleLabelOption(
                                      label: '$tabSpace Show me as away',
                                      notifierValue: totalTaskNotifier,
                                      icon: Icons.directions_run_rounded,
                                      margin: 7.0,
                                    ),
                                  ],
                                ),
                              ),
                              AppSpaces.verticalSpace10,
                              ProfileTextOption(
                                label: '$tabSpace My Projects',
                                icon: Icons.cast,
                                margin: 5.0,
                              ),
                              AppSpaces.verticalSpace10,
                              ProfileTextOption(
                                label: '$tabSpace Join A Team',
                                icon: Icons.group_add,
                                margin: 5.0,
                              ),
                              AppSpaces.verticalSpace10,
                              ProfileTextOption(
                                label: '$tabSpace Privacy & Sharing',
                                icon: Icons.shield_outlined,
                                margin: 5.0,
                                onTap: () {
                                  Get.to(() => PrivacySettingsScreen());
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PrivacyStatusBadge(isCompact: true),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.inactive,
                                    ),
                                  ],
                                ),
                              ),
                              AppSpaces.verticalSpace10,
                              ProfileTextOption(
                                label: '$tabSpace All My Task',
                                icon: Icons.check_circle_outline,
                                margin: 5.0,
                              ),
                              AppSpaces.verticalSpace20,

                              // Security Settings Section
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.security,
                                          color: AppColors.primaryGreen,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Security Settings',
                                          style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),

                                    // Auto Logout Toggle
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Auto Logout',
                                              style: GoogleFonts.lato(
                                                fontSize: 16,
                                                color: AppColors.primaryText,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              'Logout when inactive for security',
                                              style: GoogleFonts.lato(
                                                fontSize: 12,
                                                color: AppColors.inactive,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Obx(
                                          () => Switch(
                                            value: userController
                                                .autoLogoutEnabled,
                                            onChanged: (_) => userController
                                                .toggleAutoLogout(),
                                            activeThumbColor:
                                                AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),

                                    // Session Status
                                    Obx(
                                      () => userController.isLoggedIn
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Session Status',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.primaryText,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      userController
                                                                  .sessionStatus ==
                                                              'active'
                                                          ? Icons.check_circle
                                                          : Icons.warning,
                                                      color:
                                                          userController
                                                                  .sessionStatus ==
                                                              'active'
                                                          ? AppColors
                                                                .primaryGreen
                                                          : AppColors.error,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      userController
                                                                  .sessionStatus ==
                                                              'active'
                                                          ? 'Active (${userController.sessionRemainingMinutes}m left)'
                                                          : 'Inactive',
                                                      style: GoogleFonts.lato(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.inactive,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),

                              AppSpaces.verticalSpace20,
                              // Logout option
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => SignOutDialog(
                                      onConfirm: () {
                                        Navigator.of(context).pop();
                                        userController.signOut();
                                      },
                                      onCancel: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF262A34),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      SizedBox(width: 15),
                                      Text(
                                        '$tabSpace Logout',
                                        style: GoogleFonts.lato(
                                          color: Colors.red,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
