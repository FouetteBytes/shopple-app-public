import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../utils/app_logger.dart';

/// Centralized service for consistent user display logic across the app
/// This ensures all profile-related screens show the same information
class UserDisplayService {
  /// Get user's display name with enhanced logic
  ///
  /// Priority:
  /// 1. AppUser.displayFullName (handles all cases including fullName field)
  /// 2. Raw Firestore fullName field (backup compatibility)
  /// 3. Built name from firstName + lastName
  /// 4. displayName (for Google users)
  /// 5. Sign-in method based fallbacks
  static String getDisplayName({
    required AppUser? userData,
    required User currentUser,
    Map<String, dynamic>? rawFirestoreData,
    bool enableDebugLogs = false,
  }) {
    if (enableDebugLogs) {
      AppLogger.d('🏷️ UserDisplayService.getDisplayName DEBUG');
      AppLogger.d('userData: $userData');
      AppLogger.d('rawFirestoreData: $rawFirestoreData');
      AppLogger.d('userData?.firstName: ${userData?.firstName}');
      AppLogger.d('userData?.lastName: ${userData?.lastName}');
      AppLogger.d('userData?.displayName: ${userData?.displayName}');
      AppLogger.d(
        'rawFirestoreData?[fullName]: ${rawFirestoreData?['fullName']}',
      );
    }

    // PRIORITY 1: Use AppUser's displayFullName getter (handles all cases)
    if (userData != null) {
      String result = userData.displayFullName;
      if (enableDebugLogs) {
        AppLogger.d('✅ SUCCESS: Using userData.displayFullName: "$result"');
      }
      return result;
    }

    // PRIORITY 2: Check raw Firestore data for fullName field (backup)
    if (rawFirestoreData != null && rawFirestoreData['fullName'] != null) {
      String fullName = rawFirestoreData['fullName'] as String;
      if (fullName.isNotEmpty) {
        if (enableDebugLogs) {
          AppLogger.d(
            '✅ BACKUP: Using fullName from raw Firestore: "$fullName"',
          );
        }
        return fullName;
      }
    }

    // PRIORITY 3: Use legacy logic as final fallback
    return _getLegacyDisplayName(userData, currentUser, enableDebugLogs);
  }

  /// Get user's primary contact information based on sign-in method
  ///
  /// Logic:
  /// - Phone users see phone number first
  /// - Email/Google users see email first
  /// - Fallbacks handled gracefully
  static String getPrimaryContact({
    required AppUser? userData,
    required User currentUser,
    bool enableDebugLogs = false,
  }) {
    if (enableDebugLogs) {
      AppLogger.d('📞 UserDisplayService.getPrimaryContact DEBUG');
      AppLogger.d('userData?.email: ${userData?.email}');
      AppLogger.d('currentUser.email: ${currentUser.email}');
      AppLogger.d('userData?.phoneNumber: ${userData?.phoneNumber}');
      AppLogger.d('currentUser.phoneNumber: ${currentUser.phoneNumber}');
      AppLogger.d('userData?.signInMethod: ${userData?.signInMethod}');
    }

    // COMMON SENSE LOGIC: Based on sign-in method
    String signInMethod = userData?.signInMethod ?? 'email';

    switch (signInMethod) {
      case 'phone':
        // Phone users should see PHONE NUMBER first
        if (userData?.phoneNumber?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Phone user - using userData phoneNumber');
          }
          return userData!.phoneNumber!;
        }
        if (currentUser.phoneNumber?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Phone user - using currentUser phoneNumber');
          }
          return currentUser.phoneNumber!;
        }
        if (enableDebugLogs) {
          AppLogger.w('❌ Phone user - no phone available');
        }
        return "No phone available";

      case 'google':
      case 'email':
        // Email/Google users should see EMAIL first
        if (userData?.email != null && userData!.email.isNotEmpty) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Email/Google user - using userData email');
          }
          return userData.email;
        }
        if (currentUser.email?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Email/Google user - using currentUser email');
          }
          return currentUser.email!;
        }
        if (enableDebugLogs) {
          AppLogger.w('❌ Email/Google user - no email available');
        }
        return "No email available";

      default:
        // Fallback: Show whatever is available (priority: email > phone)
        if (userData?.email != null && userData!.email.isNotEmpty) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Fallback - using userData email');
          }
          return userData.email;
        }
        if (currentUser.email?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Fallback - using currentUser email');
          }
          return currentUser.email!;
        }
        if (userData?.phoneNumber?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Fallback - using userData phoneNumber');
          }
          return userData!.phoneNumber!;
        }
        if (currentUser.phoneNumber?.isNotEmpty ?? false) {
          if (enableDebugLogs) {
            AppLogger.d('✅ Fallback - using currentUser phoneNumber');
          }
          return currentUser.phoneNumber!;
        }
        if (enableDebugLogs) {
          AppLogger.w('❌ Fallback - no contact info available');
        }
        return "No contact info";
    }
  }

  /// Get user initial for avatar/profile displays
  ///
  /// Priority:
  /// 1. fullName field (from profile completion)
  /// 2. firstName field (from user registration)
  /// 3. displayName (for Google users)
  /// 4. email (last resort fallback)
  static String getUserInitial({
    required Map<String, dynamic>? userData,
    bool enableDebugLogs = false,
  }) {
    if (userData == null) return 'U';

    if (enableDebugLogs) {
      AppLogger.d('🔤 UserDisplayService.getUserInitial DEBUG');
      AppLogger.d('userData keys: ${userData.keys.toList()}');
      AppLogger.d('fullName: ${userData['fullName']}');
      AppLogger.d('displayName: ${userData['displayName']}');
      AppLogger.d('firstName: ${userData['firstName']}');
    }

    // PRIORITY 1: Use fullName field (from profile completion)
    if (userData['fullName'] != null &&
        userData['fullName'].toString().isNotEmpty &&
        userData['fullName'].toString() != 'User') {
      String initial = userData['fullName'][0].toUpperCase();
      if (enableDebugLogs) {
        AppLogger.d('✅ Using fullName initial: $initial');
      }
      return initial;
    }

    // PRIORITY 2: Build full name from firstName + lastName
    String? firstName = userData['firstName']?.toString();
    if (firstName?.isNotEmpty == true) {
      String initial = firstName![0].toUpperCase();
      if (enableDebugLogs) {
        AppLogger.d('✅ Using firstName initial: $initial');
      }
      return initial;
    }

    // PRIORITY 3: Use displayName (for Google users)
    if (userData['displayName'] != null &&
        userData['displayName'].toString().isNotEmpty) {
      String initial = userData['displayName'][0].toUpperCase();
      if (enableDebugLogs) {
        AppLogger.d('✅ Using displayName initial: $initial');
      }
      return initial;
    }

    // PRIORITY 4: Use email as last resort
    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      String initial = userData['email'][0].toUpperCase();
      if (enableDebugLogs) {
        AppLogger.d('✅ Using email initial: $initial');
      }
      return initial;
    }

    if (enableDebugLogs) {
      AppLogger.w('❌ Using fallback initial: U');
    }
    return 'U';
  }

  /// Get sign-in method display name
  static String getSignInMethodDisplay(AppUser? userData) {
    switch (userData?.signInMethod) {
      case 'google':
        return "Google Account";
      case 'email':
        return "Email & Password";
      case 'phone':
        return "Phone Number";
      default:
        return "Unknown";
    }
  }

  /// Build full name from first and last name
  static String? buildFullName(String? firstName, String? lastName) {
    if (firstName?.isNotEmpty ?? false) {
      if (lastName?.isNotEmpty ?? false) {
        return "$firstName $lastName";
      }
      return firstName;
    }
    return lastName?.isNotEmpty ?? false ? lastName : null;
  }

  /// Legacy display name logic (for backwards compatibility)
  static String _getLegacyDisplayName(
    AppUser? userData,
    User currentUser,
    bool enableDebugLogs,
  ) {
    if (enableDebugLogs) {
      AppLogger.d('🔄 Using legacy display name logic');
      AppLogger.d('userData?.firstName: ${userData?.firstName}');
      AppLogger.d('userData?.lastName: ${userData?.lastName}');
      AppLogger.d('userData?.displayName: ${userData?.displayName}');
      AppLogger.d('userData?.signInMethod: ${userData?.signInMethod}');
      AppLogger.d('currentUser.displayName: ${currentUser.displayName}');
    }

    if (userData != null) {
      // For Google users, prefer displayName or build from first/last name
      if (userData.signInMethod == 'google') {
        String result =
            userData.displayName ??
            currentUser.displayName ??
            buildFullName(userData.firstName, userData.lastName) ??
            "Google User";
        if (enableDebugLogs) {
          AppLogger.d('✅ Google user result: $result');
        }
        return result;
      }

      // For email/phone users, prefer built name from profile completion
      String? fullName = buildFullName(userData.firstName, userData.lastName);
      if (fullName != null) {
        if (enableDebugLogs) {
          AppLogger.d('✅ Built full name: $fullName');
        }
        return fullName;
      }

      // Fallback to displayName for email/phone users
      if (userData.displayName?.isNotEmpty ?? false) {
        if (enableDebugLogs) {
          AppLogger.d('✅ Using userData displayName: ${userData.displayName}');
        }
        return userData.displayName!;
      }
    }

    // Fallback to Firebase Auth data
    if (currentUser.displayName?.isNotEmpty ?? false) {
      if (enableDebugLogs) {
        AppLogger.d(
          '✅ Using currentUser displayName: ${currentUser.displayName}',
        );
      }
      return currentUser.displayName!;
    }

    // Final fallbacks based on sign-in method
    String signInMethod = userData?.signInMethod ?? 'email';
    switch (signInMethod) {
      case 'google':
        if (enableDebugLogs) {
          AppLogger.d('✅ Final fallback: Google User');
        }
        return "Google User";
      case 'phone':
        if (enableDebugLogs) {
          AppLogger.d('✅ Final fallback: Phone User');
        }
        return "Phone User";
      case 'email':
      default:
        if (enableDebugLogs) {
          AppLogger.d('✅ Final fallback: Email User');
        }
        return "Email User";
    }
  }
}
