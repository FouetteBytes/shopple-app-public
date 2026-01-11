import 'package:cloud_firestore/cloud_firestore.dart';

/// User privacy settings model
/// Controls searchability and contact visibility
class UserPrivacySettings {
  /// Allow searching by name
  final bool searchableByName;
  
  /// Allow searching by email
  final bool searchableByEmail;
  
  /// Allow searching by phone number
  final bool searchableByPhone;
  
  /// Fully private mode - only existing friends can see you
  final bool isFullyPrivate;
  
  /// Email visibility to friends: 'full', 'partial', 'hidden'
  final ContactVisibility emailVisibility;
  
  /// Phone visibility to friends: 'full', 'partial', 'hidden'
  final ContactVisibility phoneVisibility;
  
  /// Name visibility to friends: 'full', 'partial', 'hidden'
  final ContactVisibility nameVisibility;

  const UserPrivacySettings({
    this.searchableByName = true,
    this.searchableByEmail = true,
    this.searchableByPhone = true,
    this.isFullyPrivate = false,
    this.emailVisibility = ContactVisibility.partial,
    this.phoneVisibility = ContactVisibility.partial,
    this.nameVisibility = ContactVisibility.full,
  });

  /// Default privacy settings (user is searchable, contact info partially visible)
  static const UserPrivacySettings defaultSettings = UserPrivacySettings();

  /// Fully private settings (not searchable, minimal visibility)
  static const UserPrivacySettings fullyPrivate = UserPrivacySettings(
    searchableByName: false,
    searchableByEmail: false,
    searchableByPhone: false,
    isFullyPrivate: true,
    emailVisibility: ContactVisibility.hidden,
    phoneVisibility: ContactVisibility.hidden,
    nameVisibility: ContactVisibility.full,
  );

  factory UserPrivacySettings.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return UserPrivacySettings.defaultSettings;
    
    return UserPrivacySettings(
      searchableByName: data['searchableByName'] as bool? ?? true,
      searchableByEmail: data['searchableByEmail'] as bool? ?? true,
      searchableByPhone: data['searchableByPhone'] as bool? ?? true,
      isFullyPrivate: data['isFullyPrivate'] as bool? ?? false,
      emailVisibility: ContactVisibility.fromString(
        data['emailVisibility'] as String? ?? 'partial',
      ),
      phoneVisibility: ContactVisibility.fromString(
        data['phoneVisibility'] as String? ?? 'partial',
      ),
      nameVisibility: ContactVisibility.fromString(
        data['nameVisibility'] as String? ?? 'full',
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'searchableByName': searchableByName,
      'searchableByEmail': searchableByEmail,
      'searchableByPhone': searchableByPhone,
      'isFullyPrivate': isFullyPrivate,
      'emailVisibility': emailVisibility.value,
      'phoneVisibility': phoneVisibility.value,
      'nameVisibility': nameVisibility.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserPrivacySettings copyWith({
    bool? searchableByName,
    bool? searchableByEmail,
    bool? searchableByPhone,
    bool? isFullyPrivate,
    ContactVisibility? emailVisibility,
    ContactVisibility? phoneVisibility,
    ContactVisibility? nameVisibility,
  }) {
    return UserPrivacySettings(
      searchableByName: searchableByName ?? this.searchableByName,
      searchableByEmail: searchableByEmail ?? this.searchableByEmail,
      searchableByPhone: searchableByPhone ?? this.searchableByPhone,
      isFullyPrivate: isFullyPrivate ?? this.isFullyPrivate,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      nameVisibility: nameVisibility ?? this.nameVisibility,
    );
  }

  /// Check if the user is searchable at all
  bool get isSearchable => !isFullyPrivate && (searchableByName || searchableByEmail || searchableByPhone);

  @override
  String toString() {
    return 'UserPrivacySettings('
        'searchableByName: $searchableByName, '
        'searchableByEmail: $searchableByEmail, '
        'searchableByPhone: $searchableByPhone, '
        'isFullyPrivate: $isFullyPrivate, '
        'emailVisibility: ${emailVisibility.value}, '
        'phoneVisibility: ${phoneVisibility.value}, '
        'nameVisibility: ${nameVisibility.value})';
  }
}

/// Contact visibility levels
enum ContactVisibility {
  /// Show full contact info (e.g., "john.doe@email.com")
  full('full'),
  
  /// Show partial/masked contact info (e.g., "jo***@email.com")
  partial('partial'),
  
  /// Hide contact info completely
  hidden('hidden');

  final String value;
  const ContactVisibility(this.value);

  static ContactVisibility fromString(String value) {
    switch (value.toLowerCase()) {
      case 'full':
        return ContactVisibility.full;
      case 'partial':
        return ContactVisibility.partial;
      case 'hidden':
        return ContactVisibility.hidden;
      default:
        return ContactVisibility.partial;
    }
  }

  String get displayName {
    switch (this) {
      case ContactVisibility.full:
        return 'Visible';
      case ContactVisibility.partial:
        return 'Partially Hidden';
      case ContactVisibility.hidden:
        return 'Hidden';
    }
  }

  String get description {
    switch (this) {
      case ContactVisibility.full:
        return 'Friends can see your full contact info';
      case ContactVisibility.partial:
        return 'Friends can see masked contact info';
      case ContactVisibility.hidden:
        return 'Friends cannot see this info';
    }
  }
}

/// Utility class for masking contact information
class ContactMasker {
  /// Mask an email address (e.g., "jo***@email.com")
  static String maskEmail(String email) {
    if (email.isEmpty) return '';
    
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    
    final localPart = parts[0];
    final domainPart = parts[1];
    
    String maskedLocal;
    if (localPart.length <= 2) {
      maskedLocal = '${localPart[0]}***';
    } else {
      maskedLocal = '${localPart.substring(0, 2)}***';
    }
    
    // Mask domain but keep TLD
    final domainParts = domainPart.split('.');
    String maskedDomain;
    if (domainParts.length >= 2) {
      final domainName = domainParts[0];
      final tld = domainParts.sublist(1).join('.');
      if (domainName.length <= 2) {
        maskedDomain = '***.$tld';
      } else {
        maskedDomain = '${domainName[0]}***.$tld';
      }
    } else {
      maskedDomain = '***';
    }
    
    return '$maskedLocal@$maskedDomain';
  }

  /// Mask a phone number (e.g., "+1 *** *** 1234")
  static String maskPhone(String phone) {
    if (phone.isEmpty) return '';
    
    // Remove all non-digit characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.length < 4) return '*** ***';
    
    // Keep last 4 digits visible
    final lastFour = cleaned.substring(cleaned.length - 4);
    final prefix = cleaned.startsWith('+') ? '+' : '';
    
    return '$prefix*** *** $lastFour';
  }

  /// Mask a name (show first name, hide last name)
  static String maskName(String fullName) {
    if (fullName.isEmpty) return '';
    
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0];
    
    // Show first name, mask last name
    final firstName = parts[0];
    final lastNameInitial = parts.length > 1 && parts[1].isNotEmpty 
        ? parts[1][0].toUpperCase() 
        : '';
    
    return '$firstName ${lastNameInitial.isNotEmpty ? "$lastNameInitial." : ""}';
  }

  /// Apply visibility setting to a contact value
  static String? applyVisibility(
    String? value, 
    ContactVisibility visibility, 
    ContactType type,
  ) {
    if (value == null || value.isEmpty) return null;
    
    switch (visibility) {
      case ContactVisibility.full:
        return value;
      case ContactVisibility.partial:
        switch (type) {
          case ContactType.email:
            return maskEmail(value);
          case ContactType.phone:
            return maskPhone(value);
          case ContactType.name:
            return maskName(value);
        }
      case ContactVisibility.hidden:
        return null;
    }
  }
}

enum ContactType {
  email,
  phone,
  name,
}
