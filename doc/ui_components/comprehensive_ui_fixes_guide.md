# 🔧 Comprehensive Shopple UI & UX Fixes Implementation Guide

## 📋 **CRITICAL ISSUES IDENTIFIED (From App Screenshots Analysis)**

Based on the detailed analysis of the provided screenshots, the following 7 critical issues need immediate resolution:

---

## 🔧 **ISSUE 1: Session Expired Dialog Theme Inconsistency**

### **Problem Analysis:**
The "Session Expired" dialog (Image 1) is not following the app's theme and UI components. It appears generic and doesn't match the app's design language.

### **Current Issue:**
- Dialog uses default Flutter styling
- Background, colors, and typography don't match app theme
- Button styling is inconsistent with app's button design

### **Solution Implementation:**

#### **Step 1.1: Study Existing Dialog Components**

**INSTRUCTION:** 
1. **Examine** `shopple_previous_build/lib/widgets/` for existing dialog components
2. **Study** `shopple_previous_build/lib/Values/app-colors.dart` for proper color scheme
3. **Identify** existing custom dialog implementations and styling patterns

#### **Step 1.2: Create Custom Session Expired Dialog**

**File:** `lib/widgets/Dialogs/session_expired_dialog.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/Values/app-colors.dart';

class SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onLoginAgain;
  final String reason;

  const SessionExpiredDialog({
    Key? key,
    required this.onLoginAgain,
    required this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface, // Use existing app color
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button (top right)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.inactive.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.inactive,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Session expired icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                color: AppColors.primaryGreen,
                size: 40,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Title
            Text(
              "Session Expired",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12),
            
            // Message
            Text(
              "Your session has expired for security reasons.",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 8),
            
            // Reason
            Text(
              "Reason: $reason",
              style: GoogleFonts.lato(
                color: AppColors.inactive,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Login Again Button - Use existing app button style
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onLoginAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Login Again",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### **Step 1.3: Update Session Management to Use Custom Dialog**

**INSTRUCTION:** Find where the session expired dialog is shown and replace with:

```dart
// Replace existing showDialog call with:
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => SessionExpiredDialog(
    reason: "Idle timeout - no activity detected",
    onLoginAgain: () {
      Navigator.of(context).pop();
      // Navigate to login screen
      Get.offAllNamed('/login');
    },
  ),
);
```

---

## 🔧 **ISSUE 2: Sign Out Dialog Theme Inconsistency**

### **Problem Analysis:**
The "Sign Out" confirmation dialog (Image 2) doesn't follow the app's theme and design patterns.

### **Solution Implementation:**

#### **Step 2.1: Create Custom Sign Out Dialog**

**File:** `lib/widgets/Dialogs/sign_out_dialog.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/Values/app-colors.dart';

class SignOutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SignOutDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface, // Use existing app color
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sign out icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Title
            Text(
              "Sign Out",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12),
            
            // Confirmation message
            Text(
              "Are you sure you want to sign out?",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Buttons row
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        side: BorderSide(
                          color: AppColors.inactive,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Sign out button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Sign Out",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### **Step 2.2: Update Profile Screen Sign Out Implementation**

**INSTRUCTION:** Find the profile screen sign out functionality and replace with:

```dart
// Replace existing sign out dialog with:
showDialog(
  context: context,
  builder: (context) => SignOutDialog(
    onConfirm: () {
      Navigator.of(context).pop();
      _performSignOut();
    },
    onCancel: () {
      Navigator.of(context).pop();
    },
  ),
);
```

---

## 🔧 **ISSUE 3: Email User Creation - Duplicate Screens & Header Inconsistency**

### **Problem Analysis:**
In email new user creation, there are two user details collecting screens appearing. Need to keep only the second one with age and details. The header implementation is inconsistent with other screens.

### **Solution Implementation:**

#### **Step 3.1: Identify and Remove Duplicate Data Collection Screen**

**INSTRUCTION:**
1. **Find** all data collection screens in the email signup flow
2. **Identify** which screen appears first and which appears second
3. **Remove** the first/duplicate screen from the navigation flow
4. **Keep** only the comprehensive data collection screen with age, gender, etc.

#### **Step 3.2: Standardize Header Implementation**

**INSTRUCTION:** Study the header pattern from the "Welcome back!" screen and apply to data collection screen.

**Reference Pattern (from Welcome back screen):**
```dart
child: SafeArea(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NavigationBack(),
        SizedBox(height: 40),
        Text(
          "Welcome\nback!",
          style: GoogleFonts.lato(
            color: AppColors.primaryText,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        // Rest of content...
      ],
    ),
  ),
)
```

#### **Step 3.3: Update Data Collection Screen Header**

**File:** `lib/Screens/Auth/data_collection_screen.dart` (or equivalent)

**INSTRUCTION:** Replace the AppBar with the standardized header pattern:

```dart
class DataCollectionScreen extends StatefulWidget {
  @override
  _DataCollectionScreenState createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standardized navigation back
                NavigationBack(),
                SizedBox(height: 40),
                
                // Title following the same pattern
                Text(
                  "Complete your\nprofile",
                  style: GoogleFonts.lato(
                    color: AppColors.primaryText,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Tell us a bit about yourself to personalize your experience.",
                  style: GoogleFonts.lato(
                    color: AppColors.inactive,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Progress indicator
                _buildProgressIndicator(),
                
                SizedBox(height: 32),
                
                // Form fields
                _buildFormFields(),
                
                SizedBox(height: 40),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Rest of the implementation...
}
```

---

## 🔧 **ISSUE 4: Email Verification Screen Overflow Issues**

### **Problem Analysis:**
The email verification screen (Image 4) has text overflow issues when the email sending text refreshes. Components need dynamic adjustment according to screen size.

### **Solution Implementation:**

#### **Step 4.1: Fix Email Verification Screen Layout**

**File:** `lib/Screens/Auth/email_verification_screen.dart` (or equivalent)

**INSTRUCTION:** Replace the existing layout with responsive implementation:

```dart
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);
  
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isCheckingVerification = false;
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navigation back
                  NavigationBack(),
                  SizedBox(height: 40),
                  
                  // Title
                  Text(
                    "Verify your\nemail address",
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.05), // Dynamic spacing
                  
                  // Email icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.email,
                        color: AppColors.primaryGreen,
                        size: 60,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Verification message with proper text wrapping
                  Column(
                    children: [
                      Text(
                        "We sent a verification link to:",
                        style: GoogleFonts.lato(
                          color: AppColors.primaryText.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Email with proper text wrapping
                      Container(
                        width: double.infinity,
                        child: Text(
                          widget.email,
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Status indicator with proper constraint
                  Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        if (isCheckingVerification) ...[
                          CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Checking verification status...",
                            style: GoogleFonts.lato(
                              color: AppColors.inactive,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.05),
                  
                  // Instructions with proper spacing
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Please follow these steps:",
                          style: GoogleFonts.lato(
                            color: AppColors.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInstructionStep("1. Check your email inbox", Icons.inbox),
                        _buildInstructionStep("2. Look for email from Shopple", Icons.email),
                        _buildInstructionStep("3. Click the verification link", Icons.link),
                        _buildInstructionStep("4. Return to this app", Icons.phone_android),
                        SizedBox(height: 12),
                        Text(
                          "Don't forget to check your spam folder!",
                          style: GoogleFonts.lato(
                            color: AppColors.inactive,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Action buttons
                  Column(
                    children: [
                      // Check verification button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isCheckingVerification ? null : _checkVerificationStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "Check Verification Status",
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Resend email button
                      TextButton(
                        onPressed: _resendVerificationEmail,
                        child: Text(
                          "Resend verification email",
                          style: GoogleFonts.lato(
                            color: AppColors.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkVerificationStatus() async {
    setState(() {
      isCheckingVerification = true;
    });
    
    // Add your verification checking logic here
    await Future.delayed(Duration(seconds: 2)); // Simulate check
    
    setState(() {
      isCheckingVerification = false;
    });
  }
  
  Future<void> _resendVerificationEmail() async {
    // Add resend logic here
  }
}
```

---

## 🔧 **ISSUE 5: TextEditingController Disposal Exception**

### **Problem Analysis:**
TextEditingController disposal exception occurs on the main screen after login, causing the stuck notification issue.

### **Solution Implementation:**

#### **Step 5.1: Find and Fix TextEditingController Usage**

**INSTRUCTION:**
1. **Search** for all TextEditingController instances in the app
2. **Check** their disposal in dispose() methods
3. **Identify** controllers used in authentication screens that might not be properly disposed

#### **Step 5.2: Implement Proper Controller Management**

**Common Fix Pattern:**
```dart
class _SomeScreenState extends State<SomeScreen> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose(); // CRITICAL: Always dispose
    super.dispose();
  }
  
  // If using GetX, also check:
  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }
}
```

#### **Step 5.3: Add Controller Safety Check**

**INSTRUCTION:** Add this safety pattern to critical controllers:

```dart
@override
void dispose() {
  if (_controller.hasListeners) {
    _controller.dispose();
  }
  super.dispose();
}
```

---

## 🔧 **ISSUE 6: Profile Picture Consistency & Selection**

### **Problem Analysis:**
Profile picture inconsistency across the app - showing 'U' in main screen but correct initial in profile page. Profile picture selection from memoji folder not working.

### **Solution Implementation:**

#### **Step 6.1: Create Profile Picture Management Service**

**File:** `lib/services/profile_picture_service.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePictureService {
  static const List<String> availableMemojis = [
    'assets/memoji/memoji_1.png',
    'assets/memoji/memoji_2.png',
    'assets/memoji/memoji_3.png',
    'assets/memoji/memoji_4.png',
    'assets/memoji/memoji_5.png',
    'assets/memoji/memoji_6.png',
    'assets/memoji/memoji_7.png',
    'assets/memoji/memoji_8.png',
    'assets/memoji/memoji_9.png',
    'assets/memoji/memoji_10.png',
  ];
  
  // Get user's current profile picture
  static Future<String?> getCurrentProfilePicture() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          return userData['profilePicture'] ?? userData['photoURL'];
        }
      }
    } catch (e) {
      print('Error getting profile picture: $e');
    }
    return null;
  }
  
  // Update user's profile picture
  static Future<bool> updateProfilePicture(String memojiPath) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'profilePicture': memojiPath,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      print('Error updating profile picture: $e');
    }
    return false;
  }
  
  // Get user initial for avatar
  static Future<String> getUserInitial() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // For Google users
          if (userData['signInMethod'] == 'google' && userData['displayName'] != null) {
            return userData['displayName'][0].toUpperCase();
          }
          
          // For phone/email users - use firstName
          if (userData['firstName'] != null && userData['firstName'].isNotEmpty) {
            return userData['firstName'][0].toUpperCase();
          }
          
          // Fallback to displayName
          if (userData['displayName'] != null && userData['displayName'].isNotEmpty) {
            return userData['displayName'][0].toUpperCase();
          }
        }
      }
    } catch (e) {
      print('Error getting user initial: $e');
    }
    return 'U';
  }
}
```

#### **Step 6.2: Create Profile Picture Selection Widget**

**File:** `lib/widgets/profile_picture_selector.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/Values/app-colors.dart';
import 'package:shopple/services/profile_picture_service.dart';

class ProfilePictureSelector extends StatefulWidget {
  final String? currentPicture;
  final Function(String) onPictureSelected;
  
  const ProfilePictureSelector({
    Key? key,
    this.currentPicture,
    required this.onPictureSelected,
  }) : super(key: key);
  
  @override
  _ProfilePictureSelectorState createState() => _ProfilePictureSelectorState();
}

class _ProfilePictureSelectorState extends State<ProfilePictureSelector> {
  String? selectedPicture;
  
  @override
  void initState() {
    super.initState();
    selectedPicture = widget.currentPicture;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Choose Profile Picture",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Memoji grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: ProfilePictureService.availableMemojis.length,
              itemBuilder: (context, index) {
                String memojiPath = ProfilePictureService.availableMemojis[index];
                bool isSelected = selectedPicture == memojiPath;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPicture = memojiPath;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.asset(
                        memojiPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Select button
          Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedPicture != null ? () {
                  widget.onPictureSelected(selectedPicture!);
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  "Select Picture",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### **Step 6.3: Create Universal Profile Avatar Widget**

**File:** `lib/widgets/profile_avatar.dart` (CREATE NEW FILE)

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shopple/services/profile_picture_service.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final bool showBorder;
  final VoidCallback? onTap;
  
  const ProfileAvatar({
    Key? key,
    this.radius = 25,
    this.showBorder = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return _buildDefaultAvatar();
    }
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDefaultAvatar();
        }
        
        Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
        String? profilePicture = userData['profilePicture'];
        String? photoURL = userData['photoURL'];
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: showBorder ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ) : null,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.cyan.shade300,
              backgroundImage: _getBackgroundImage(profilePicture, photoURL),
              child: _getBackgroundImage(profilePicture, photoURL) == null
                  ? FutureBuilder<String>(
                      future: _getUserInitial(userData),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'U',
                          style: TextStyle(
                            fontSize: radius * 0.6,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDefaultAvatar() {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.cyan.shade300,
        child: Text(
          'U',
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  ImageProvider? _getBackgroundImage(String? profilePicture, String? photoURL) {
    if (profilePicture != null && profilePicture.startsWith('assets/')) {
      return AssetImage(profilePicture);
    }
    if (photoURL != null) {
      return NetworkImage(photoURL);
    }
    return null;
  }
  
  Future<String> _getUserInitial(Map<String, dynamic> userData) async {
    // For Google users
    if (userData['signInMethod'] == 'google' && userData['displayName'] != null) {
      return userData['displayName'][0].toUpperCase();
    }
    
    // For phone/email users - use firstName
    if (userData['firstName'] != null && userData['firstName'].toString().isNotEmpty) {
      return userData['firstName'][0].toUpperCase();
    }
    
    // Fallback to displayName
    if (userData['displayName'] != null && userData['displayName'].toString().isNotEmpty) {
      return userData['displayName'][0].toUpperCase();
    }
    
    return 'U';
  }
}
```

#### **Step 6.4: Update Main Screen Profile Picture**

**INSTRUCTION:** Replace the profile picture in the main screen (top right) with:

```dart
// In main screen/timeline screen, replace existing profile picture with:
ProfileAvatar(
  radius: 20,
  showBorder: true,
  onTap: () {
    // Navigate to profile screen
    Get.to(() => ProfileScreen());
  },
)
```

#### **Step 6.5: Update Profile Edit Screen**

**INSTRUCTION:** Add profile picture selection to profile edit screen:

```dart
// In profile edit screen, add this for profile picture selection:
GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePictureSelector(
        currentPicture: currentProfilePicture,
        onPictureSelected: (selectedPicture) async {
          bool success = await ProfilePictureService.updateProfilePicture(selectedPicture);
          if (success) {
            setState(() {
              currentProfilePicture = selectedPicture;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile picture updated!")),
            );
          }
        },
      ),
    );
  },
  child: Stack(
    children: [
      ProfileAvatar(radius: 50),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    ],
  ),
)
```

---

## 🔧 **ISSUE 7: Profile Edit Section Not Loading User Details**

### **Problem Analysis:**
Profile edit section for email users only shows email correctly but other details show default values.

### **Solution Implementation:**

#### **Step 7.1: Fix Profile Edit Data Loading**

**File:** `lib/Screens/Profile/edit_profile_screen.dart` (or equivalent)

**INSTRUCTION:** Implement proper data loading:

```dart
class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String? selectedGender;
  DateTime? selectedDOB;
  String? currentProfilePicture;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }
  
  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
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
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            // Load all user data properly
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _emailController.text = userData['email'] ?? currentUser.email ?? '';
            _phoneController.text = userData['phoneNumber'] ?? currentUser.phoneNumber ?? '';
            
            selectedGender = userData['gender'];
            currentProfilePicture = userData['profilePicture'] ?? userData['photoURL'];
            
            // Handle DOB
            if (userData['dateOfBirth'] != null) {
              selectedDOB = userData['dateOfBirth'].toDate();
            }
            
            isLoading = false;
          });
        } else {
          // Create user document from Firebase Auth data
          await _createUserDocumentFromAuth(currentUser);
          _loadUserData(); // Reload after creating
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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
      print('Error creating user document: $e');
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text("Edit Profile"),
          backgroundColor: AppColors.background,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Standardized navigation back
                  NavigationBack(),
                  SizedBox(height: 40),
                  
                  // Title
                  Text(
                    "Edit your\nprofile",
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Update your information to keep your profile current.",
                    style: GoogleFonts.lato(
                      color: AppColors.inactive,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Profile picture section
                  Center(
                    child: GestureDetector(
                      onTap: _selectProfilePicture,
                      child: Stack(
                        children: [
                          ProfileAvatar(radius: 60),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.background, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Form fields
                  _buildTextField(
                    controller: _firstNameController,
                    label: "First Name",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "First name is required";
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _lastNameController,
                    label: "Last Name",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Last name is required";
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    enabled: false, // Email should not be editable
                  ),
                  
                  SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    enabled: false, // Phone should not be editable for phone users
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Gender selection
                  _buildGenderSelection(),
                  
                  SizedBox(height: 20),
                  
                  // Date of birth
                  _buildDOBSelection(),
                  
                  SizedBox(height: 40),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        "Save Changes",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: GoogleFonts.lato(
        color: enabled ? AppColors.primaryText : AppColors.inactive,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(
          color: AppColors.inactive,
          fontSize: 14,
        ),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1),
        ),
      ),
    );
  }
  
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Gender",
          style: GoogleFonts.lato(
            color: AppColors.inactive,
            fontSize: 14,
          ),
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
          style: GoogleFonts.lato(
            color: AppColors.inactive,
            fontSize: 14,
          ),
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
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDOB != null
                        ? "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}"
                        : "Select date of birth",
                    style: GoogleFonts.lato(
                      color: selectedDOB != null ? AppColors.primaryText : AppColors.inactive,
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
      initialDate: selectedDOB ?? DateTime.now().subtract(Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 13)),
    );
    
    if (picked != null && picked != selectedDOB) {
      setState(() {
        selectedDOB = picked;
      });
    }
  }
  
  void _selectProfilePicture() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePictureSelector(
        currentPicture: currentProfilePicture,
        onPictureSelected: (selectedPicture) async {
          bool success = await ProfilePictureService.updateProfilePicture(selectedPicture);
          if (success) {
            setState(() {
              currentProfilePicture = selectedPicture;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Profile picture updated!")),
            );
          }
        },
      ),
    );
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Map<String, dynamic> updateData = {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'gender': selectedGender,
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully!")),
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile. Please try again.")),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
```

---

## 📋 **IMPLEMENTATION PRIORITY & TESTING**

### **Day 1: Dialog & Header Fixes**
- ✅ Implement custom session expired dialog (Issue 1)
- ✅ Implement custom sign out dialog (Issue 2)  
- ✅ Fix email user creation header consistency (Issue 3)

### **Day 2: Layout & Controller Fixes**
- ✅ Fix email verification screen overflow (Issue 4)
- ✅ Fix TextEditingController disposal exception (Issue 5)

### **Day 3: Profile Picture System**
- ✅ Create profile picture management service (Issue 6)
- ✅ Implement memoji selection functionality
- ✅ Fix profile picture consistency across app

### **Day 4: Profile Edit & Testing**
- ✅ Fix profile edit data loading (Issue 7)
- ✅ Comprehensive testing of all fixes
- ✅ Verify user experience improvements

### **Comprehensive Testing Checklist:**
- [ ] **Session Expired Dialog**: Matches app theme perfectly
- [ ] **Sign Out Dialog**: Uses app colors and typography  
- [ ] **Email User Creation**: No duplicate screens, consistent header
- [ ] **Email Verification**: No overflow on any screen size
- [ ] **Main Screen**: No TextEditingController exceptions
- [ ] **Profile Pictures**: Consistent across app (main screen & profile)
- [ ] **Memoji Selection**: Working selection and saving
- [ ] **Profile Edit**: Loads all user data correctly
- [ ] **Email Users**: Profile shows name initial, not email initial
- [ ] **Phone Users**: Profile shows name initial consistently

---

## 🚨 **CRITICAL SUCCESS CRITERIA**

### **MUST ACHIEVE:**
- ✅ **All dialogs follow app theme** (session expired, sign out)
- ✅ **No duplicate data collection screens** for email users
- ✅ **Headers consistent** across all auth screens  
- ✅ **No UI overflow** on email verification screen
- ✅ **No controller disposal exceptions** on main screen
- ✅ **Profile pictures consistent** everywhere in app
- ✅ **Memoji selection working** and saving properly
- ✅ **Profile edit loads real data** for all user types
- ✅ **Profile initials based on name** not email

### **MUST NOT:**
- ❌ Break any existing authentication functionality
- ❌ Create new UI inconsistencies  
- ❌ Leave any controller disposal issues
- ❌ Allow profile picture inconsistencies
- ❌ Show default values in profile edit when real data exists

This comprehensive implementation addresses all 7 critical issues identified in the screenshots while maintaining consistency with the existing app architecture and design patterns.