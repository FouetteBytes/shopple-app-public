import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/models/app_user.dart';
import 'package:shopple/screens/auth/profile_completion.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/utils/app_logger.dart';
import 'package:shopple/services/user/user_display_service.dart';

import 'package:shopple/widgets/common/liquid_glass_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: AppColors.primaryText70),
              SizedBox(height: 16),
              Text(
                "Please log in to view your profile",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: AppColors.primaryText70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.lato(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        actions: [
          IconButton(onPressed: () => _editProfile(), icon: Icon(Icons.edit)),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Error loading profile",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please try again later",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.primaryText70,
                    ),
                  ),
                  SizedBox(height: 16),
                  LiquidGlassButton.text(
                    onTap: () => setState(() {}),
                    text: "Retry",
                    accentColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    "Loading your profile...",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.primaryText70,
                    ),
                  ),
                ],
              ),
            );
          }

          // DEBUG: Log raw Firestore data
          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> rawData =
                snapshot.data!.data() as Map<String, dynamic>;
            AppLogger.d('=== FIRESTORE RAW DATA DEBUG ===');
            AppLogger.d('Document ID: ${snapshot.data!.id}');
            AppLogger.d('Document exists: ${snapshot.data!.exists}');
            AppLogger.d('Raw data: $rawData');
            AppLogger.d('firstName: ${rawData['firstName']}');
            AppLogger.d('lastName: ${rawData['lastName']}');
            AppLogger.d('phoneNumber: ${rawData['phoneNumber']}');
            AppLogger.d('email: ${rawData['email']}');
            AppLogger.d('signInMethod: ${rawData['signInMethod']}');
            AppLogger.d('===========================');
          } else {
            AppLogger.d('=== FIRESTORE DEBUG ===');
            AppLogger.d(
              'Document exists: ${snapshot.hasData && snapshot.data!.exists}',
            );
            AppLogger.d('HasData: ${snapshot.hasData}');
            AppLogger.d('Document ID would be: ${currentUser.uid}');
            AppLogger.d('====================');
          }

          AppUser? userData;
          Map<String, dynamic>? rawFirestoreData;
          if (snapshot.hasData && snapshot.data!.exists) {
            try {
              rawFirestoreData = snapshot.data!.data() as Map<String, dynamic>;
              userData = AppUser.fromFirestore(snapshot.data!);
              AppLogger.d('=== PARSED USER DATA DEBUG ===');
              AppLogger.d('firstName: ${userData.firstName}');
              AppLogger.d('lastName: ${userData.lastName}');
              AppLogger.d('phoneNumber: ${userData.phoneNumber}');
              AppLogger.d('email: ${userData.email}');
              AppLogger.d('signInMethod: ${userData.signInMethod}');
              AppLogger.d(
                'RAW fullName: ${rawFirestoreData['fullName']}',
              ); // CRITICAL: Check for fullName
              AppLogger.d('==============================');
            } catch (e) {
              AppLogger.e('Error parsing user data', error: e);
            }
          }

          return _buildProfileContent(userData, currentUser, rawFirestoreData);
        },
      ),
    );
  }

  Widget _buildProfileContent(
    AppUser? userData,
    User currentUser,
    Map<String, dynamic>? rawFirestoreData,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture with real-time updates and caching
          UnifiedProfileAvatar(
            radius: 50, // 100px diameter
            showBorder: true,
            enableCache: true,
            isEditable: false,
            borderColor: AppColors.primaryAccentColor,
            borderWidth: 3.0,
          ),

          SizedBox(height: 20),

          // User Name - FIXED: Using centralized UserDisplayService
          Text(
            UserDisplayService.getDisplayName(
              userData: userData,
              currentUser: currentUser,
              rawFirestoreData: rawFirestoreData,
              enableDebugLogs: true, // Remove after testing
            ),
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),

          SizedBox(height: 8),

          // Primary Contact - FIXED: Using centralized UserDisplayService
          Text(
            UserDisplayService.getPrimaryContact(
              userData: userData,
              currentUser: currentUser,
              enableDebugLogs: true, // Remove after testing
            ),
            style: GoogleFonts.lato(
              fontSize: 16,
              color: AppColors.primaryText70,
            ),
          ),

          SizedBox(height: 30),

          // DEBUG INFO CARD (REMOVE AFTER FIXING)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🐛 DEBUG INFO (Remove after fixing)",
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "UID: ${currentUser.uid}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firebase Email: ${currentUser.email ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firebase Phone: ${currentUser.phoneNumber ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firebase DisplayName: ${currentUser.displayName ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Divider(),
                Text(
                  "Firestore firstName: ${userData?.firstName ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firestore lastName: ${userData?.lastName ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firestore email: ${userData?.email ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firestore phone: ${userData?.phoneNumber ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Firestore signInMethod: ${userData?.signInMethod ?? 'null'}",
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText,
                  ),
                ),
                Divider(),
                Text(
                  "Display Name Result: ${UserDisplayService.getDisplayName(userData: userData, currentUser: currentUser, rawFirestoreData: rawFirestoreData)}",
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.green),
                ),
                Text(
                  "Contact Result: ${UserDisplayService.getPrimaryContact(userData: userData, currentUser: currentUser)}",
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Profile Details Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Profile Details",
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 15),

                // Email (always show if available)
                if (userData?.email != null || currentUser.email != null)
                  _buildDetailRow(
                    icon: Icons.email,
                    label: "Email",
                    value:
                        userData?.email ?? currentUser.email ?? "Not available",
                  ),

                // Phone (always show if available)
                if (userData?.phoneNumber != null ||
                    currentUser.phoneNumber != null)
                  _buildDetailRow(
                    icon: Icons.phone,
                    label: "Phone",
                    value:
                        userData?.phoneNumber ??
                        currentUser.phoneNumber ??
                        "Not available",
                  ),

                // Age
                if (userData?.age != null)
                  _buildDetailRow(
                    icon: Icons.cake,
                    label: "Age",
                    value: userData!.age.toString(),
                  ),

                // Gender
                if (userData?.gender != null)
                  _buildDetailRow(
                    icon: Icons.person,
                    label: "Gender",
                    value: userData!.gender!,
                  ),

                // Sign-in Method
                _buildDetailRow(
                  icon: Icons.login,
                  label: "Sign-in Method",
                  value: UserDisplayService.getSignInMethodDisplay(userData),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Complete Profile Button (if profile not complete)
          if (userData?.profileCompleted == false)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen, width: 1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.primaryGreen,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Complete Your Profile",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Add missing details for a better experience",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.primaryText70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  LiquidGlassGradientButton(
                    onTap: () => _completeProfile(),
                    gradientColors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                    borderRadius: 8,
                    text: "Complete Now",
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build detail row widget
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.primaryText70,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    // Navigate to profile edit screen or profile completion
    Get.to(() => ProfileCompletionScreen());
  }

  void _completeProfile() {
    // Navigate to profile completion screen
    Get.to(() => ProfileCompletionScreen());
  }
}
