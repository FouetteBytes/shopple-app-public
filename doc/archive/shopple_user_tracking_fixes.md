# Shopple App: Color Theme & User Tracking Implementation Guide

## 🚨 **Issues Identified from Screenshot:**

### ❌ **Current Problems:**
1. **Grayish Color Theme** - App shows gray/purple colors instead of original dark theme
2. **Incorrect User Flow** - ALL users go through NewWorkSpace → ChoosePlan → Timeline
3. **No User State Tracking** - Can't differentiate between new and existing users
4. **Missing Firebase Integration** - Onboarding selections not saved to database
5. **Color Integration Issues** - Theme not properly applied throughout app

### ✅ **What Should Happen:**
1. **Original Dark Theme** - Black backgrounds, proper original colors from shopple_previous_build
2. **Smart User Flow** - Only NEW users see workspace setup, existing users go directly to Timeline
3. **Firebase User Tracking** - Track user onboarding status and preferences
4. **Proper Color Integration** - Consistent theme throughout app

---

## 📁 **Reference Materials & Research Findings**

### **Firebase User Tracking Best Practices (2024):**
- Use **Firebase Authentication metadata** to detect user creation time
- Use **Cloud Firestore** to store user onboarding status and preferences
- Track **first-time login** vs **returning user** for both email and Google sign-up
- Store **workspace settings** (name, colors, subscription) in user document

### **Implementation Strategy:**
1. **Fix color theme first** (affects all UI)
2. **Add Firebase user tracking** (new vs existing detection)
3. **Implement smart navigation** (conditional onboarding flow)
4. **Test thoroughly** at each step

---

## 🔧 **Fix 1: Restore Original Color Theme**

### **Issue Analysis:**
Looking at your screenshot, the app shows grayish/purple colors that don't match the original design. The current color definitions seem to be mixing different themes.

### **Step 1A: Extract Original Colors**

**INSTRUCTION:**
1. **Open** `shopple_previous_build/lib/Values/app-colors.dart`
2. **Examine** the original color scheme carefully
3. **Identify** what the background, surface, and accent colors should be
4. **Compare** with current app colors to see what changed

### **Step 1B: Replace Color Definitions**

**File:** `lib/Values/app-colors.dart`

**INSTRUCTION:** Replace your current color definitions with original values from shopple_previous_build. Pay special attention to:

```dart
// Example of what to look for in shopple_previous_build:
// (Extract EXACT values from previous build files)

class AppColors {
  // Extract these from shopple_previous_build/lib/Values/app-colors.dart
  static final Color background = /* EXTRACT FROM PREVIOUS BUILD */;
  static final Color surface = /* EXTRACT FROM PREVIOUS BUILD */;
  static final Color primaryText = /* EXTRACT FROM PREVIOUS BUILD */;
  static final Color secondaryText = /* EXTRACT FROM PREVIOUS BUILD */;
  static final Color primaryAccentColor = /* EXTRACT FROM PREVIOUS BUILD */;
  static final Color lightMauveBackgroundColor = /* EXTRACT FROM PREVIOUS BUILD */;
  
  // Ensure ballColors list matches original exactly
  static List<List<Color>> ballColors = /* EXTRACT FROM PREVIOUS BUILD */;
}
```

### **Step 1C: Fix Current Color Integration Issues**

**INSTRUCTION:** You mentioned these current color definitions that need proper integration:

```dart
static final Color primaryText = Colors.white;
static final Color primaryText70 = Colors.white70;
static final Color primaryText30 = Colors.white30;
static final Color secondaryText = HexColor.fromHex("C395FC"); // Light purple from original theme
static final Color background = primaryBackgroundColor;
static final Color surface = HexColor.fromHex("353645"); // From ballColors - dark blue-gray
static final Color error = Colors.redAccent;
static final Color inactive = Colors.grey[400]!; // Light gray for inactive elements
static final Color primaryGreen = primaryAccentColor; // Use blue as primary action color
static final Color accentGreen = lightMauveBackgroundColor; // Use purple as accent color
static final Color darkGreenBackground = HexColor.fromHex("353645"); // From ballColors
```

**CRITICAL:** Compare these with shopple_previous_build and ensure:
- Background is **black/dark** (not gray)
- Surface colors match **original theme**
- No purple/gray colors unless they were in original
- Color references are consistent

### **Step 1D: Test Color Changes**

**TESTING:**
- [ ] App background is dark/black (not gray)
- [ ] UI elements match original design
- [ ] No unwanted grayish colors visible
- [ ] Text is readable with proper contrast
- [ ] Color selection balls work in NewWorkSpace

---

## 🔧 **Fix 2: Add Firebase User Tracking & Database Integration**

### **Step 2A: Add Required Dependencies**

**File:** `pubspec.yaml`

**INSTRUCTION:** Add these dependencies if not already present:

```yaml
dependencies:
  # Existing dependencies...
  cloud_firestore: ^4.15.8  # For user data storage
  firebase_core: ^2.24.2    # Already have this
  firebase_auth: ^4.15.3    # Already have this
```

### **Step 2B: Create User Tracking Service**

**File:** `lib/services/user_tracking_service.dart` (NEW FILE)

**INSTRUCTION:** Create this service to handle user state tracking:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // New user - create initial document
        await _createUserDocument(user);
        return false;
      }

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return userData['onboardingCompleted'] ?? false;
    } catch (e) {
      if (kDebugMode) print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Create initial user document
  static Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'signInMethod': _getSignInMethod(user),
      });
    } catch (e) {
      if (kDebugMode) print('Error creating user document: $e');
    }
  }

  // Save workspace settings
  static Future<void> saveWorkspaceSettings({
    required String workspaceName,
    required int selectedColorIndex,
    String? workspaceImage,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'workspaceName': workspaceName,
        'selectedColorIndex': selectedColorIndex,
        'workspaceImage': workspaceImage,
        'workspaceSetupAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error saving workspace settings: $e');
    }
  }

  // Save subscription choice
  static Future<void> saveSubscriptionChoice({
    required String planType, // 'free' or 'premium'
    required bool multipleAssignees,
    required bool customLabels,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionPlan': planType,
        'features': {
          'multipleAssignees': multipleAssignees,
          'customLabels': customLabels,
        },
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('Error saving subscription choice: $e');
    }
  }

  // Get user workspace settings
  static Future<Map<String, dynamic>?> getUserWorkspaceSettings() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting user settings: $e');
      return null;
    }
  }

  // Detect sign-in method
  static String _getSignInMethod(User user) {
    if (user.providerData.isEmpty) return 'anonymous';
    
    for (UserInfo provider in user.providerData) {
      switch (provider.providerId) {
        case 'google.com':
          return 'google';
        case 'password':
          return 'email';
        case 'apple.com':
          return 'apple';
        default:
          return provider.providerId;
      }
    }
    return 'unknown';
  }

  // Reset onboarding status (for testing)
  static Future<void> resetOnboardingStatus() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'onboardingCompleted': false,
      });
    } catch (e) {
      if (kDebugMode) print('Error resetting onboarding: $e');
    }
  }
}
```

### **Step 2C: Enhance UserController with Tracking**

**File:** `lib/controllers/user_controller.dart`

**INSTRUCTION:** Add this import and methods to your existing UserController:

```dart
// Add import
import 'package:shopple/services/user_tracking_service.dart';

// Add these methods to your UserController class:

// Check if user should see onboarding
Future<bool> shouldShowOnboarding() async {
  if (!isLoggedIn) return false;
  
  bool hasCompleted = await UserTrackingService.hasCompletedOnboarding();
  return !hasCompleted;
}

// Navigate after successful authentication
Future<void> navigateAfterAuth() async {
  try {
    _isLoading.value = true;
    
    bool needsOnboarding = await shouldShowOnboarding();
    
    if (needsOnboarding) {
      // New user - go to workspace setup
      Get.to(() => NewWorkSpace());
    } else {
      // Existing user - go directly to main app
      Get.offAll(() => Timeline(), transition: Transition.fadeIn);
    }
  } catch (e) {
    // On error, default to onboarding
    Get.to(() => NewWorkSpace());
  } finally {
    _isLoading.value = false;
  }
}
```

---

## 🔧 **Fix 3: Update Authentication Flow with Smart Navigation**

### **Step 3A: Update SignUp Success Navigation**

**File:** `lib/Screens/Auth/signup.dart`

**INSTRUCTION:** Replace success navigation in ElevatedButton onPressed:

```dart
// REPLACE THIS:
if (success) {
  Get.to(() => NewWorkSpace());
}

// WITH THIS:
if (success) {
  // New user always needs onboarding
  Get.to(() => NewWorkSpace());
}
```

### **Step 3B: Update Login Success Navigation**

**File:** `lib/Screens/Auth/login.dart` and `lib/Screens/Auth/existing_user_login.dart`

**INSTRUCTION:** Replace success navigation in both files:

```dart
// REPLACE THIS:
if (success) {
  Get.to(() => NewWorkSpace());
}

// WITH THIS:
if (success) {
  final UserController userController = Get.find<UserController>();
  await userController.navigateAfterAuth();
}
```

### **Step 3C: Update Google Sign-In Navigation**

**File:** `lib/Screens/Onboarding/onboarding_carousel.dart`

**INSTRUCTION:** Update Google Sign-In button onPressed:

```dart
// REPLACE THIS:
if (success) {
  Get.to(() => NewWorkSpace());
}

// WITH THIS:
if (success) {
  final UserController userController = Get.find<UserController>();
  await userController.navigateAfterAuth();
}
```

---

## 🔧 **Fix 4: Save Onboarding Data to Firebase**

### **Step 4A: Update NewWorkSpace Screen**

**File:** `lib/Screens/Auth/new_workspace.dart`

**INSTRUCTION:** Update the "Done" button to save workspace data:

```dart
// Find your PrimaryProgressButton and update its callback:
PrimaryProgressButton(
  width: 120,
  label: "Done",
  callback: () async {
    // Save workspace settings to Firebase
    await UserTrackingService.saveWorkspaceSettings(
      workspaceName: 'My Shopping List', // Get from UI input
      selectedColorIndex: colorTrigger.value, // Get selected color
      workspaceImage: 'assets/plant.png', // Get selected image
    );
    
    // Navigate to subscription selection
    Get.to(() => ChoosePlan());
  }
)
```

### **Step 4B: Update ChoosePlan Screen**

**File:** `lib/Screens/Auth/choose_plan.dart`

**INSTRUCTION:** Update the "Done" button to save subscription choice:

```dart
// Find your PrimaryProgressButton and update its callback:
PrimaryProgressButton(
  width: 120,
  label: "Done",
  callback: () async {
    // Save subscription settings to Firebase
    await UserTrackingService.saveSubscriptionChoice(
      planType: planContainerTrigger.value == 0 ? 'free' : 'premium',
      multipleAssignees: multiUserTrigger.value,
      customLabels: customLabelTrigger.value,
    );
    
    // Mark onboarding as complete and go to main app
    Get.offAll(() => Timeline());
  }
)
```

---

## 🔧 **Fix 5: Enhance Splash Screen with User Detection**

### **File:** `lib/Screens/splash_screen.dart`

**INSTRUCTION:** Update your `_checkAuthStatus()` method:

```dart
void _checkAuthStatus() async {
  try {
    // Show splash for 2 seconds minimum
    await Future.delayed(const Duration(seconds: 2));
    
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (kDebugMode) {
      print("Splash: Current user = ${currentUser?.email}");
    }

    if (currentUser != null) {
      // User is logged in - check onboarding status
      final UserController userController = Get.find<UserController>();
      bool needsOnboarding = await userController.shouldShowOnboarding();
      
      if (kDebugMode) {
        print("Splash: User authenticated, needs onboarding = $needsOnboarding");
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (needsOnboarding) {
          Get.offAll(() => NewWorkSpace(), transition: Transition.fadeIn);
        } else {
          Get.offAll(() => Timeline(), transition: Transition.fadeIn);
        }
      });
    } else {
      // No user - go to onboarding
      if (kDebugMode) {
        print("Splash: No user, going to OnboardingStart");
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => OnboardingStart(), transition: Transition.fadeIn);
      });
    }
  } catch (e) {
    if (kDebugMode) {
      print("Splash: Error occurred = $e, going to OnboardingStart");
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => OnboardingStart(), transition: Transition.fadeIn);
    });
  }
}
```

---

## 🧪 **Testing Protocol**

### **Phase 1: Color Theme Testing**
1. **Run app** and verify background is dark/black (not gray)
2. **Check dashboard** - should match original design from shopple_previous_build
3. **Navigate through screens** - ensure consistent theme
4. **Test NewWorkSpace** - color selection balls should display properly

### **Phase 2: New User Flow Testing**
1. **Create new account** with email → Should go: SignUp → NewWorkSpace → ChoosePlan → Timeline
2. **Test workspace setup** - name, color, image selection should save to Firebase
3. **Test subscription selection** - free/premium choice should save to Firebase
4. **Verify Firebase data** - check Firebase Console for user document creation

### **Phase 3: Existing User Flow Testing**
1. **Login with existing account** → Should go directly to Timeline (skip onboarding)
2. **Test Google Sign-In** with existing Google account → Should skip onboarding
3. **Verify onboarding skip** - existing users should not see NewWorkSpace/ChoosePlan

### **Phase 4: Firebase Integration Testing**
1. **Check Firebase Console** - verify user documents are created
2. **Test data persistence** - workspace settings should be saved
3. **Test onboarding status** - should track completion correctly
4. **Test both sign-in methods** - email and Google should both work

---

## 🔄 **User Flow Matrix**

```
SPLASH SCREEN
├── No User → OnboardingStart → OnboardingCarousel → Auth
└── User Exists
    ├── New User (onboardingCompleted: false) → NewWorkSpace → ChoosePlan → Timeline
    └── Existing User (onboardingCompleted: true) → Timeline

AUTHENTICATION SUCCESS
├── New Email User → NewWorkSpace → ChoosePlan → Timeline
├── New Google User → NewWorkSpace → ChoosePlan → Timeline  
├── Existing Email User → Timeline (skip onboarding)
└── Existing Google User → Timeline (skip onboarding)
```

---

## ⚠️ **Critical Implementation Notes**

### **DO NOT:**
- ❌ Hardcode any color values - extract from shopple_previous_build
- ❌ Skip Firebase error handling
- ❌ Forget to test both email and Google authentication flows
- ❌ Break existing authentication features

### **MUST DO:**
- ✅ Extract original colors exactly from shopple_previous_build
- ✅ Test each phase thoroughly before proceeding
- ✅ Verify Firebase Console data creation
- ✅ Ensure consistent theme throughout app
- ✅ Test both new and existing user flows
