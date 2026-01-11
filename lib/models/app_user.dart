import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? fullName; // ADDED: Support for fullName field from Firestore
  final int? age;
  final String? gender;
  final String? photoURL;
  final String? phoneNumber;
  final String signInMethod; // 'google', 'email', 'phone'

  // NEW: Hybrid Profile Picture System Fields
  final String? profileImageType; // 'default', 'custom', 'google', 'memoji'
  final String? customPhotoURL; // Firebase Storage URL for custom uploads
  final String? defaultImageId; // ID for selected default/memoji avatar
  final DateTime? photoUpdatedAt; // When profile picture was last updated

  // Authentication verification status
  final bool emailVerified;
  final bool phoneVerified;

  // Profile completion status
  final bool profileCompleted;
  final bool onboardingCompleted;
  final bool profileSkipped; // Track if user skipped profile completion

  // Setup completion tracking (NEW)
  final bool workspaceCompleted;
  final bool shoppingListCompleted;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? profileCompletedAt;
  final DateTime? onboardingCompletedAt;
  final DateTime? workspaceCompletedAt;
  final DateTime? shoppingListCompletedAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.fullName, // ADDED: fullName support
    this.age,
    this.gender,
    this.photoURL,
    this.phoneNumber,
    this.signInMethod = 'email', // Default to email
    // NEW: Hybrid Profile Picture System Fields
    this.profileImageType,
    this.customPhotoURL,
    this.defaultImageId,
    this.photoUpdatedAt,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.profileCompleted = false,
    this.onboardingCompleted = false,
    this.profileSkipped = false, // Default to not skipped
    this.workspaceCompleted = false, // Default to not completed
    this.shoppingListCompleted = false, // Default to not completed
    this.createdAt,
    this.lastUpdated,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.profileCompletedAt,
    this.onboardingCompletedAt,
    this.workspaceCompletedAt,
    this.shoppingListCompletedAt,
  });

  /// Create AppUser from Firebase User and Firestore document
  factory AppUser.fromFirebaseAndFirestore({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    bool emailVerified = false,
    String? signInMethod,
    Map<String, dynamic>? firestoreData,
  }) {
    final data = firestoreData ?? {};

    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? data['displayName'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      fullName: data['fullName'], // ADDED: Support fullName field
      age: data['age'],
      gender: data['gender'],
      photoURL: photoURL ?? data['photoURL'],
      phoneNumber: phoneNumber ?? data['phoneNumber'],
      signInMethod: signInMethod ?? data['signInMethod'] ?? 'email',
      // NEW: Hybrid Profile Picture System Fields
      profileImageType: data['profileImageType'],
      customPhotoURL: data['customPhotoURL'],
      defaultImageId: data['defaultImageId'],
      photoUpdatedAt: data['photoUpdatedAt']?.toDate(),
      emailVerified: emailVerified,
      phoneVerified: data['phoneVerified'] ?? false,
      profileCompleted: data['profileCompleted'] ?? false,
      onboardingCompleted: data['hasCompletedOnboarding'] ?? false,
      profileSkipped: data['profileSkipped'] ?? false,
      workspaceCompleted:
          data['workspaceCompleted'] ?? false, // Add workspace completion
      shoppingListCompleted:
          data['shoppingListCompleted'] ??
          false, // Add shopping list completion
      createdAt: data['createdAt']?.toDate(),
      lastUpdated: data['lastUpdated']?.toDate(),
      emailVerifiedAt: data['emailVerifiedAt']?.toDate(),
      phoneVerifiedAt: data['phoneVerifiedAt']?.toDate(),
      profileCompletedAt: data['profileCompletedAt']?.toDate(),
      onboardingCompletedAt: data['onboardingCompletedAt']?.toDate(),
      workspaceCompletedAt: data['workspaceCompletedAt']
          ?.toDate(), // Add workspace completion timestamp
      shoppingListCompletedAt: data['shoppingListCompletedAt']
          ?.toDate(), // Add shopping list completion timestamp
    );
  }

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      fullName: data['fullName'], // ADDED: Support fullName field
      age: data['age'],
      gender: data['gender'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      signInMethod: data['signInMethod'] ?? 'email',
      // NEW: Hybrid Profile Picture System Fields
      profileImageType: data['profileImageType'],
      customPhotoURL: data['customPhotoURL'],
      defaultImageId: data['defaultImageId'],
      photoUpdatedAt: data['photoUpdatedAt']?.toDate(),
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      profileCompleted: data['profileCompleted'] ?? false,
      onboardingCompleted: data['hasCompletedOnboarding'] ?? false,
      profileSkipped: data['profileSkipped'] ?? false,
      workspaceCompleted:
          data['workspaceCompleted'] ?? false, // Add workspace completion
      shoppingListCompleted:
          data['shoppingListCompleted'] ??
          false, // Add shopping list completion
      createdAt: data['createdAt']?.toDate(),
      lastUpdated: data['lastUpdated']?.toDate(),
      emailVerifiedAt: data['emailVerifiedAt']?.toDate(),
      phoneVerifiedAt: data['phoneVerifiedAt']?.toDate(),
      profileCompletedAt: data['profileCompletedAt']?.toDate(),
      onboardingCompletedAt: data['onboardingCompletedAt']?.toDate(),
      workspaceCompletedAt: data['workspaceCompletedAt']
          ?.toDate(), // Add workspace completion timestamp
      shoppingListCompletedAt: data['shoppingListCompletedAt']
          ?.toDate(), // Add shopping list completion timestamp
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName, // ADDED: Include fullName field
      'age': age,
      'gender': gender,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'signInMethod': signInMethod,
      // NEW: Hybrid Profile Picture System Fields
      'profileImageType': profileImageType,
      'customPhotoURL': customPhotoURL,
      'defaultImageId': defaultImageId,
      if (photoUpdatedAt != null)
        'photoUpdatedAt': Timestamp.fromDate(photoUpdatedAt!),
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'profileCompleted': profileCompleted,
      'hasCompletedOnboarding': onboardingCompleted, // Keep existing field name
      'profileSkipped': profileSkipped,
      'workspaceCompleted':
          workspaceCompleted, // Add workspace completion tracking
      'shoppingListCompleted':
          shoppingListCompleted, // Add shopping list completion tracking
      'lastUpdated': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      if (emailVerifiedAt != null)
        'emailVerifiedAt': Timestamp.fromDate(emailVerifiedAt!),
      if (phoneVerifiedAt != null)
        'phoneVerifiedAt': Timestamp.fromDate(phoneVerifiedAt!),
      if (profileCompletedAt != null)
        'profileCompletedAt': Timestamp.fromDate(profileCompletedAt!),
      if (onboardingCompletedAt != null)
        'onboardingCompletedAt': Timestamp.fromDate(onboardingCompletedAt!),
      if (workspaceCompletedAt != null)
        'workspaceCompletedAt': Timestamp.fromDate(workspaceCompletedAt!),
      if (shoppingListCompletedAt != null)
        'shoppingListCompletedAt': Timestamp.fromDate(shoppingListCompletedAt!),
    };
  }

  /// Copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? fullName, // ADDED: fullName parameter
    int? age,
    String? gender,
    String? photoURL,
    String? phoneNumber,
    String? signInMethod,
    // NEW: Hybrid Profile Picture System Fields
    String? profileImageType,
    String? customPhotoURL,
    String? defaultImageId,
    DateTime? photoUpdatedAt,
    bool? emailVerified,
    bool? phoneVerified,
    bool? profileCompleted,
    bool? onboardingCompleted,
    bool? profileSkipped,
    bool? workspaceCompleted, // Add workspace completion parameter
    bool? shoppingListCompleted, // Add shopping list completion parameter
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? emailVerifiedAt,
    DateTime? phoneVerifiedAt,
    DateTime? profileCompletedAt,
    DateTime? onboardingCompletedAt,
    DateTime?
    workspaceCompletedAt, // Add workspace completion timestamp parameter
    DateTime?
    shoppingListCompletedAt, // Add shopping list completion timestamp parameter
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName, // ADDED: fullName field
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      signInMethod: signInMethod ?? this.signInMethod,
      // NEW: Hybrid Profile Picture System Fields
      profileImageType: profileImageType ?? this.profileImageType,
      customPhotoURL: customPhotoURL ?? this.customPhotoURL,
      defaultImageId: defaultImageId ?? this.defaultImageId,
      photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileSkipped: profileSkipped ?? this.profileSkipped,
      workspaceCompleted:
          workspaceCompleted ??
          this.workspaceCompleted, // Add workspace completion field
      shoppingListCompleted:
          shoppingListCompleted ??
          this.shoppingListCompleted, // Add shopping list completion field
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      workspaceCompletedAt:
          workspaceCompletedAt ??
          this.workspaceCompletedAt, // Add workspace completion timestamp field
      shoppingListCompletedAt:
          shoppingListCompletedAt ??
          this.shoppingListCompletedAt, // Add shopping list completion timestamp field
    );
  }

  /// Get full name (priority: fullName field > first + last > displayName > 'User')
  String get displayFullName {
    // PRIORITY 1: Direct fullName field from Firestore
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }

    // PRIORITY 2: Build from firstName + lastName
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    // PRIORITY 3: displayName fallback
    else if (displayName != null) {
      return displayName!;
    }
    // PRIORITY 4: Default fallback
    else {
      return 'User';
    }
  }

  /// Get effective profile picture URL with hybrid system support
  /// Priority: Custom Upload > Google Photo > Default/Memoji > Initials Fallback
  String? get effectivePhotoURL {
    // PRIORITY 1: Custom uploaded photo (highest priority)
    if (profileImageType == 'custom' &&
        customPhotoURL != null &&
        customPhotoURL!.isNotEmpty) {
      return customPhotoURL;
    }

    // PRIORITY 2: Google account photo (if available and not explicitly overridden)
    if ((profileImageType == 'google' || profileImageType == null) &&
        photoURL != null &&
        photoURL!.isNotEmpty) {
      return photoURL;
    }

    // PRIORITY 3: Default/Memoji (uses Asset Image path)
    if (profileImageType == 'default' &&
        defaultImageId != null &&
        defaultImageId!.isNotEmpty) {
      // Return asset path for memoji/default avatars
      return 'assets/memoji/$defaultImageId.png';
    }

    // PRIORITY 4: No effective photo URL (will trigger initials fallback)
    return null;
  }

  /// Check if basic profile information is complete
  bool get hasBasicProfile {
    return firstName != null &&
        lastName != null &&
        age != null &&
        gender != null;
  }

  /// Check if user needs email verification
  /// Only email users need email verification, not phone users
  bool get needsEmailVerification {
    // Phone users don't need email verification
    if (phoneVerified && phoneNumber != null) {
      return false;
    }

    // Email users need email verification if not already verified
    return !emailVerified;
  }

  /// Check if user needs phone verification
  bool get needsPhoneVerification {
    return phoneNumber != null && !phoneVerified;
  }

  /// Check if user needs profile completion
  bool get needsProfileCompletion {
    return !profileCompleted || !hasBasicProfile;
  }

  /// Check if user needs onboarding
  bool get needsOnboarding {
    return !onboardingCompleted;
  }

  /// Check if user needs workspace setup (NEW)
  bool get needsWorkspaceSetup {
    return !workspaceCompleted;
  }

  /// Check if user needs shopping list setup (NEW)
  bool get needsShoppingListSetup {
    return !shoppingListCompleted;
  }

  /// Check if user needs any setup screens (NEW)
  bool get needsAnySetup {
    return needsProfileCompletion ||
        needsWorkspaceSetup ||
        needsShoppingListSetup;
  }

  /// Check if user is completely set up and can go to main app (NEW)
  bool get isCompletelySetUp {
    return profileCompleted && workspaceCompleted && shoppingListCompleted;
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, fullName: $displayFullName, profileCompleted: $profileCompleted, onboardingCompleted: $onboardingCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
