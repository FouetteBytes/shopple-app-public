class AppContact {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? profilePicture;
  final bool hasAppAccount;
  final DateTime? lastSeen;
  final String? originalContactName; // Name from phone contacts

  AppContact({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.profilePicture,
    required this.hasAppAccount,
    this.lastSeen,
    this.originalContactName,
  });

  factory AppContact.fromJson(Map<String, dynamic> json) {
    return AppContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      hasAppAccount: json['hasAppAccount'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      originalContactName: json['originalContactName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePicture': profilePicture,
      'hasAppAccount': hasAppAccount,
      'lastSeen': lastSeen?.toIso8601String(),
      'originalContactName': originalContactName,
    };
  }

  AppContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? profilePicture,
    bool? hasAppAccount,
    DateTime? lastSeen,
    String? originalContactName,
  }) {
    return AppContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      hasAppAccount: hasAppAccount ?? this.hasAppAccount,
      lastSeen: lastSeen ?? this.lastSeen,
      originalContactName: originalContactName ?? this.originalContactName,
    );
  }
}

class ContactSyncResult {
  final List<AppContact> matchedContacts;
  final int totalContactsProcessed;
  final int totalMatches;
  final DateTime syncTime;
  final String status; // 'completed', 'failed', 'in_progress'
  final String? errorMessage;

  ContactSyncResult({
    required this.matchedContacts,
    required this.totalContactsProcessed,
    required this.totalMatches,
    required this.syncTime,
    required this.status,
    this.errorMessage,
  });

  factory ContactSyncResult.fromJson(Map<String, dynamic> json) {
    return ContactSyncResult(
      matchedContacts:
          (json['matchedContacts'] as List?)
              ?.map((e) => AppContact.fromJson(e))
              .toList() ??
          [],
      totalContactsProcessed: json['totalContactsProcessed'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      syncTime: DateTime.parse(json['syncTime']),
      status: json['status'] ?? 'unknown',
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchedContacts': matchedContacts.map((e) => e.toJson()).toList(),
      'totalContactsProcessed': totalContactsProcessed,
      'totalMatches': totalMatches,
      'syncTime': syncTime.toIso8601String(),
      'status': status,
      'errorMessage': errorMessage,
    };
  }
}

class UserSearchResult {
  final String uid;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? profilePicture;
  final double matchScore; // For ranking search results
  final bool isContact; // True if this user is in synced contacts

  UserSearchResult({
    required this.uid,
    required this.name,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    required this.matchScore,
    this.isContact = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      profilePicture: json['profilePicture'],
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      isContact: json['isContact'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'matchScore': matchScore,
      'isContact': isContact,
    };
  }
}

enum QueryType {
  phone, // +1234567890, (555) 123-4567
  email, // user@domain.com
  name, // John Doe, john
  partial, // jo, joh (< 3 chars)
  mixed, // john@gmail or John +123
}

class CachedSearchResult {
  final List<UserSearchResult> results;
  final DateTime timestamp;
  final Duration cacheDuration;

  CachedSearchResult({
    required this.results,
    required this.timestamp,
    this.cacheDuration = const Duration(minutes: 5),
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > cacheDuration;
  }
}
