# 🔍 Complete Telegram-Style Contact Syncing & User Search Implementation Guide

## 📋 **CRITICAL INSTRUCTIONS - READ FIRST**

**⚠️ EXTREMELY IMPORTANT:**
1. **DO NOT modify or remove ANY existing functionality**
2. **Study the ENTIRE codebase thoroughly before making ANY changes**
3. **Follow existing UI patterns, components, and themes exactly**
4. **Test each step before proceeding to the next**
5. **Implement step-by-step and document all changes**
6. **Use existing widgets/components first, create new ones only if necessary**

## 🎯 **PROJECT OVERVIEW**

You will implement a **Contact Syncing & User Search** feature similar to Telegram, with these capabilities:
- **Contact Permission & Syncing** - Ask permission, sync phone contacts
- **Contact Matching** - Match synced contacts with app users (server-side)
- **User Search** - Search by name, email, phone with fuzzy matching
- **Fast Performance** - Optimized search with auto-complete functionality
- **New Tab Interface** - Following the notifications tab pattern

## 🏗️ **ARCHITECTURE OVERVIEW**

```
Flutter App                 Firebase                    Performance Layer
├── Contacts Tab           ├── Cloud Functions         ├── 3-Level Caching
├── Contact Sync Service   ├── Firestore Rules         ├── Smart Debouncing  
├── User Search Service    ├── Contact Collections     ├── Hybrid Search
├── Phone Normalization    └── Security Rules          └── Result Ranking
└── Permission Manager
```

### **Contact Syncing Flow**
```
User Grants Permission → Get Device Contacts → Normalize Phone Numbers → 
Hash for Privacy → Upload to Firestore → Cloud Function Matching → 
Store Results → Display in UI
```

### **Search Performance Strategy (Industry Best Practice)**
```
Memory Cache (< 50ms) → Local Storage (< 100ms) → 
Firestore Query (< 200ms) → Cloud Functions (< 1s)
```

## 📱 **UI REQUIREMENTS & EXISTING PATTERN ANALYSIS**

### **Step 1: Study Existing App Structure**
Before starting implementation, you MUST:

1. **Analyze Navigation Structure:**
   ```bash
   # Find the main navigation/tab implementation
   find lib/ -name "*.dart" | xargs grep -l "notification\|tab\|bottom.*navigation" 
   ```

2. **Study Existing UI Patterns:**
   ```bash
   # Find notification tab implementation
   find lib/ -name "*notification*" -o -name "*tab*"
   
   # Study existing search implementations
   find lib/ -name "*.dart" | xargs grep -l "search\|query"
   
   # Study existing list/contact UI patterns
   find lib/ -name "*.dart" | xargs grep -l "ListView\|ListTile\|Card"
   ```

3. **Identify Existing Components:**
   ```bash
   # Find reusable widgets
   ls lib/widgets/
   ls lib/components/
   
   # Find existing form/input components
   find lib/ -name "*.dart" | xargs grep -l "TextField\|TextFormField\|input"
   ```

### **Step 2: Create New Tab Following Existing Pattern**

Based on your analysis, create the new contacts tab:

1. **Find the main navigation file** (likely in `lib/screens/` or `lib/navigation/`)
2. **Add contacts tab following the EXACT same pattern as notifications tab**
3. **Use existing icons, colors, and styling**
4. **Ensure tab order: Home, Search, Contacts (NEW), Notifications, Profile**

## 🔧 **TECHNICAL IMPLEMENTATION ROADMAP**

### **PHASE 1: Firebase Setup & Dependencies**

#### **Step 1.1: Add Required Dependencies**
Add to `pubspec.yaml` (maintain existing format):
```yaml
dependencies:
  # Existing dependencies - DO NOT MODIFY
  
  # Add these NEW dependencies:
  contacts_service: ^0.6.3
  permission_handler: ^10.4.3
  libphonenumber: ^2.0.2
  crypto: ^3.0.3
  fuzzywuzzy: ^1.1.6  # For client-side fuzzy matching
  cloud_functions: ^4.3.0  # If not already present
```

#### **Step 1.2: Update Firebase Rules**
Deploy these testing Firebase rules to allow contact syncing collections:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // TESTING RULES - PERMISSIVE FOR DEVELOPMENT
    // WARNING: These rules are for TESTING ONLY
    
    // USERS COLLECTION (existing - contains phone in E.164)
    match /users/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // PRODUCTS COLLECTION (existing)
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // CATEGORIES COLLECTION (existing)
    match /categories/{categoryId} {
      allow read, write: if request.auth != null;
    }
    
    // NEW: CONTACT SYNCING COLLECTIONS
    match /contact_syncs/{userId} {
      allow read, write: if request.auth != null;
    }
    
    match /user_contacts/{userId} {
      allow read, write: if request.auth != null;
    }
    
    match /contact_invitations/{inviteId} {
      allow read, write: if request.auth != null;
    }
    
    // FUTURE COLLECTIONS
    match /shopping_lists/{listId} {
      allow read, write: if request.auth != null;
    }
    
    match /user_favorites/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // CATCH-ALL for development
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### **Step 1.3: Deploy Cloud Functions**
Create `functions/index.js` with this complete implementation:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const libphonenumber = require('google-libphonenumber');
const crypto = require('crypto');

admin.initializeApp();

const phoneUtil = libphonenumber.PhoneNumberUtil.getInstance();

// Contact Matching Function - Triggered when user uploads contact hashes
exports.matchContacts = functions.firestore
  .document('contact_syncs/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const data = snap.data();
    const hashedContacts = data.hashedContacts || [];
    
    console.log(`Processing contact sync for user: ${userId}`);
    console.log(`Number of contact hashes: ${hashedContacts.length}`);
    
    try {
      // Get all registered users with phone numbers
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('phoneNumber', '!=', null)
        .get();
      
      console.log(`Found ${usersSnapshot.size} registered users`);
      
      const matches = [];
      const userPhoneMap = new Map();
      
      // Build map of all possible phone number variations for registered users
      usersSnapshot.forEach(userDoc => {
        const userData = userDoc.data();
        if (userData.phoneNumber) {
          const variations = generatePhoneVariations(userData.phoneNumber);
          
          variations.forEach(variation => {
            const hash = hashPhoneNumber(variation);
            userPhoneMap.set(hash, {
              uid: userDoc.id,
              name: `${userData.firstName || ''} ${userData.lastName || ''}`.trim(),
              phoneNumber: userData.phoneNumber,
              profilePicture: userData.photoURL || null,
              email: userData.email || null
            });
          });
        }
      });
      
      console.log(`Generated ${userPhoneMap.size} phone hash variations`);
      
      // Find matches between contact hashes and user hashes
      hashedContacts.forEach(contactHash => {
        if (userPhoneMap.has(contactHash)) {
          const matchedUser = userPhoneMap.get(contactHash);
          
          // Avoid adding the user themselves
          if (matchedUser.uid !== userId) {
            matches.push(matchedUser);
          }
        }
      });
      
      // Remove duplicates based on uid
      const uniqueMatches = matches.reduce((acc, current) => {
        const existing = acc.find(item => item.uid === current.uid);
        if (!existing) {
          acc.push(current);
        }
        return acc;
      }, []);
      
      console.log(`Found ${uniqueMatches.length} unique matches`);
      
      // Store matches for the user
      await admin.firestore()
        .collection('user_contacts')
        .doc(userId)
        .set({
          matches: uniqueMatches,
          totalProcessed: hashedContacts.length,
          totalMatches: uniqueMatches.length,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          syncStatus: 'completed'
        });
      
      // Update sync status
      await snap.ref.update({ 
        status: 'completed',
        matchCount: uniqueMatches.length,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Contact sync completed for user ${userId}: ${uniqueMatches.length} matches`);
      
    } catch (error) {
      console.error('Contact matching error:', error);
      await snap.ref.update({ 
        status: 'failed', 
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

// Advanced User Search Function with Performance Optimization
exports.advancedUserSearch = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { query, queryType, limit = 15 } = data;
  
  // Input validation
  if (!query || query.trim().length < 2) {
    return { results: [], fromCache: false };
  }
  
  try {
    // Execute optimized search based on type
    let results = [];
    switch (queryType) {
      case 'name':
        results = await searchByNameOptimized(query, limit);
        break;
      case 'email':
        results = await searchByEmailOptimized(query, limit);
        break;
      case 'phone':
        results = await searchByPhoneOptimized(query, limit);
        break;
      case 'mixed':
        results = await searchMixedOptimized(query, limit);
        break;
    }
    
    // Apply server-side ranking
    results = rankResults(results, query);
    
    return { results, fromCache: false };
    
  } catch (error) {
    console.error('Search error:', error);
    return { results: [], error: error.message };
  }
});

// Helper Functions
function generatePhoneVariations(phoneNumber) {
  const variations = new Set();
  
  // Add original number
  variations.add(phoneNumber);
  
  // Clean the number
  const cleaned = phoneNumber.replace(/[^\d+]/g, '');
  variations.add(cleaned);
  
  try {
    // Use libphonenumber for proper parsing
    const parsed = phoneUtil.parse(phoneNumber);
    
    if (phoneUtil.isValidNumber(parsed)) {
      // E.164 format
      const e164 = phoneUtil.format(parsed, libphonenumber.PhoneNumberFormat.E164);
      variations.add(e164);
      
      // National format without formatting
      const national = phoneUtil.format(parsed, libphonenumber.PhoneNumberFormat.NATIONAL);
      variations.add(national.replace(/[^\d]/g, ''));
      
      // Without country code
      const nationalNumber = parsed.getNationalNumber().toString();
      variations.add(nationalNumber);
    }
  } catch (e) {
    console.log('Phone parsing error:', e.message);
  }
  
  // Manual variations for common formats
  if (cleaned.startsWith('+1') && cleaned.length === 12) {
    const withoutCountryCode = cleaned.substring(2);
    variations.add(withoutCountryCode);
    variations.add(`1${withoutCountryCode}`);
  }
  
  return Array.from(variations);
}

function hashPhoneNumber(phoneNumber) {
  return crypto.createHash('sha256').update(phoneNumber).digest('hex');
}

async function searchByNameOptimized(query, limit) {
  const promises = [];
  const fields = ['firstName', 'lastName', 'displayName'];
  
  for (const field of fields) {
    promises.push(
      admin.firestore()
        .collection('users')
        .where(field, '>=', query)
        .where(field, '<=', query + '\uf8ff')
        .limit(Math.ceil(limit / fields.length))
        .get()
    );
  }
  
  const snapshots = await Promise.all(promises);
  const results = [];
  const seenIds = new Set();
  
  // Merge results and remove duplicates
  for (const snapshot of snapshots) {
    snapshot.forEach(doc => {
      if (!seenIds.has(doc.id)) {
        seenIds.add(doc.id);
        results.push({
          uid: doc.id,
          ...doc.data()
        });
      }
    });
  }
  
  return results.slice(0, limit);
}

async function searchByEmailOptimized(query, limit) {
  const snapshot = await admin.firestore()
    .collection('users')
    .where('email', '>=', query)
    .where('email', '<=', query + '\uf8ff')
    .limit(limit)
    .get();
  
  return snapshot.docs.map(doc => ({
    uid: doc.id,
    ...doc.data()
  }));
}

async function searchByPhoneOptimized(query, limit) {
  // Generate phone variations and search
  const variations = generatePhoneVariations(query);
  const promises = variations.slice(0, 3).map(variation => // Limit to prevent too many queries
    admin.firestore()
      .collection('users')
      .where('phoneNumber', '==', variation)
      .limit(limit)
      .get()
  );
  
  const snapshots = await Promise.all(promises);
  const results = [];
  const seenIds = new Set();
  
  for (const snapshot of snapshots) {
    snapshot.forEach(doc => {
      if (!seenIds.has(doc.id)) {
        seenIds.add(doc.id);
        results.push({
          uid: doc.id,
          ...doc.data()
        });
      }
    });
  }
  
  return results;
}

async function searchMixedOptimized(query, limit) {
  // Try multiple search strategies for mixed queries
  const results = [];
  
  // Try name search
  const nameResults = await searchByNameOptimized(query, Math.ceil(limit / 2));
  results.push(...nameResults);
  
  // Try email search if query contains @
  if (query.includes('@')) {
    const emailResults = await searchByEmailOptimized(query, Math.ceil(limit / 2));
    results.push(...emailResults);
  }
  
  // Remove duplicates
  const seenIds = new Set();
  return results.filter(result => {
    if (seenIds.has(result.uid)) {
      return false;
    }
    seenIds.add(result.uid);
    return true;
  }).slice(0, limit);
}

function rankResults(results, query) {
  // Simple ranking based on query match
  return results.sort((a, b) => {
    const aScore = calculateMatchScore(a, query);
    const bScore = calculateMatchScore(b, query);
    return bScore - aScore;
  });
}

function calculateMatchScore(result, query) {
  let score = 0;
  const queryLower = query.toLowerCase();
  
  // Exact name match
  const fullName = `${result.firstName || ''} ${result.lastName || ''}`.toLowerCase();
  if (fullName.includes(queryLower)) {
    score += 10;
  }
  
  // First name match
  if (result.firstName && result.firstName.toLowerCase().includes(queryLower)) {
    score += 8;
  }
  
  // Last name match
  if (result.lastName && result.lastName.toLowerCase().includes(queryLower)) {
    score += 6;
  }
  
  // Email match
  if (result.email && result.email.toLowerCase().includes(queryLower)) {
    score += 7;
  }
  
  // Display name match (for Google users)
  if (result.displayName && result.displayName.toLowerCase().includes(queryLower)) {
    score += 5;
  }
  
  return score;
}
```

Deploy with:
```bash
cd functions
npm install
firebase deploy --only functions
```

### **PHASE 2: Contacts Permission & Data Models**

#### **Step 2.1: Create Permission Service**
Create `lib/services/contact_permission_service.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';

class ContactPermissionService {
  
  /// Request contact permission with user-friendly explanation
  static Future<bool> requestContactPermission() async {
    try {
      // Check current status first
      PermissionStatus status = await Permission.contacts.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        // Request permission
        status = await Permission.contacts.request();
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        // Guide user to settings
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error requesting contact permission: $e');
      return false;
    }
  }
  
  /// Check current permission status
  static Future<bool> hasContactPermission() async {
    try {
      PermissionStatus status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking contact permission: $e');
      return false;
    }
  }
  
  /// Get contacts only if permission granted
  static Future<List<Contact>> getContacts() async {
    try {
      if (!await hasContactPermission()) {
        return [];
      }
      
      // Get contacts with phone numbers only
      Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, // For performance
        photoHighResolution: false,
      );
      
      // Filter contacts with phone numbers
      return contacts.where((contact) => 
        contact.phones != null && contact.phones!.isNotEmpty
      ).toList();
      
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }
  
  /// Get contact count for UI display
  static Future<int> getContactCount() async {
    try {
      if (!await hasContactPermission()) {
        return 0;
      }
      
      Iterable<Contact> contacts = await ContactsService.getContacts();
      return contacts.where((contact) => 
        contact.phones != null && contact.phones!.isNotEmpty
      ).length;
      
    } catch (e) {
      print('Error getting contact count: $e');
      return 0;
    }
  }
}
```

#### **Step 2.2: Create Contact Data Models**
Create `lib/models/contact_models.dart`:

```dart
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
      matchedContacts: (json['matchedContacts'] as List?)
          ?.map((e) => AppContact.fromJson(e))
          .toList() ?? [],
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
  phone,      // +1234567890, (555) 123-4567
  email,      // user@domain.com
  name,       // John Doe, john
  partial,    // jo, joh (< 3 chars)
  mixed       // john@gmail or John +123
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
```

### **PHASE 3: Phone Number Normalization Service**

#### **Step 3.1: Create Phone Number Service**
Create `lib/services/phone_number_service.dart`:

```dart
import 'package:libphonenumber/libphonenumber.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PhoneNumberService {
  
  /// Normalize phone number to E.164 format for consistent storage
  static Future<String?> normalizeToE164(String rawNumber, [String? countryCode]) async {
    if (rawNumber.isEmpty) return null;
    
    try {
      // Clean the number first
      String cleaned = _cleanPhoneNumber(rawNumber);
      
      // If it already has country code, parse directly
      if (cleaned.startsWith('+')) {
        PhoneNumber phoneNumber = await PhoneNumberUtil.instance.parse(cleaned);
        if (await PhoneNumberUtil.instance.isValidNumber(phoneNumber)) {
          return await PhoneNumberUtil.instance.format(phoneNumber, PhoneNumberFormat.e164);
        }
      }
      
      // Try parsing with provided or default country code
      String region = countryCode ?? await _getUserCountryCode();
      PhoneNumber phoneNumber = await PhoneNumberUtil.instance.parse(cleaned, regionCode: region);
      
      if (await PhoneNumberUtil.instance.isValidNumber(phoneNumber)) {
        return await PhoneNumberUtil.instance.format(phoneNumber, PhoneNumberFormat.e164);
      }
      
      // Try common country codes if the default fails
      List<String> commonCountries = ['US', 'GB', 'CA', 'AU', 'IN', 'DE', 'FR'];
      for (String country in commonCountries) {
        try {
          PhoneNumber testNumber = await PhoneNumberUtil.instance.parse(cleaned, regionCode: country);
          if (await PhoneNumberUtil.instance.isValidNumber(testNumber)) {
            return await PhoneNumberUtil.instance.format(testNumber, PhoneNumberFormat.e164);
          }
        } catch (e) {
          continue;
        }
      }
      
    } catch (e) {
      print('Error normalizing phone number: $e');
    }
    
    return null;
  }
  
  /// Generate multiple phone number variations for fuzzy matching
  static List<String> generateVariations(String phoneNumber) {
    List<String> variations = [];
    
    // Original number
    variations.add(phoneNumber);
    
    // Clean version
    String cleaned = _cleanPhoneNumber(phoneNumber);
    variations.add(cleaned);
    
    // Different country code variations
    if (cleaned.startsWith('+1')) {
      // Remove country code for US numbers
      variations.add(cleaned.substring(2));
      // Add with different formatting
      String withoutCountry = cleaned.substring(2);
      if (withoutCountry.length == 10) {
        variations.add('(${withoutCountry.substring(0,3)}) ${withoutCountry.substring(3,6)}-${withoutCountry.substring(6)}');
        variations.add('${withoutCountry.substring(0,3)}-${withoutCountry.substring(3,6)}-${withoutCountry.substring(6)}');
        variations.add('${withoutCountry.substring(0,3)}.${withoutCountry.substring(3,6)}.${withoutCountry.substring(6)}');
      }
    }
    
    // Add common prefixes for different countries
    if (!cleaned.startsWith('+')) {
      variations.add('+1$cleaned'); // US
      variations.add('+44$cleaned'); // UK
      variations.add('+91$cleaned'); // India
      variations.add('+61$cleaned'); // Australia
    }
    
    return variations.toSet().toList(); // Remove duplicates
  }
  
  /// Hash phone number for privacy protection
  static String hashPhoneNumber(String phoneNumber) {
    var bytes = utf8.encode(phoneNumber);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Calculate similarity score between two phone numbers (0.0 to 1.0)
  static double calculateSimilarity(String phone1, String phone2) {
    List<String> variations1 = generateVariations(phone1);
    List<String> variations2 = generateVariations(phone2);
    
    // Check for exact matches first
    for (String var1 in variations1) {
      for (String var2 in variations2) {
        if (var1 == var2) return 1.0;
      }
    }
    
    // Check for partial matches (last 7+ digits)
    for (String var1 in variations1) {
      String clean1 = _cleanPhoneNumber(var1);
      for (String var2 in variations2) {
        String clean2 = _cleanPhoneNumber(var2);
        
        if (clean1.length >= 7 && clean2.length >= 7) {
          String suffix1 = clean1.substring(clean1.length - 7);
          String suffix2 = clean2.substring(clean2.length - 7);
          if (suffix1 == suffix2) return 0.9;
        }
      }
    }
    
    return 0.0;
  }
  
  /// Detect if string is a phone number
  static bool isPhoneNumber(String input) {
    String cleaned = _cleanPhoneNumber(input);
    
    // Basic phone number patterns
    return RegExp(r'^[\+]?[1-9][\d\s\-\(\)\.]{7,15}$').hasMatch(input) ||
           RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleaned);
  }
  
  /// Clean phone number by removing all non-digit characters except +
  static String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }
  
  /// Get user's country code from device/location (implement based on your app's location handling)
  static Future<String> _getUserCountryCode() async {
    // You can implement this based on:
    // 1. User's device locale
    // 2. User's IP geolocation  
    // 3. User's previously selected country
    // For now, default to US
    return 'US';
  }
}
```

### **PHASE 4: Advanced Contact Syncing Service**

#### **Step 4.1: Create Contact Sync Service with Performance Optimization**
Create `lib/services/contact_sync_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/contact_models.dart';
import 'contact_permission_service.dart';
import 'phone_number_service.dart';

class ContactSyncService {
  static const String CACHE_KEY = 'contact_sync_cache_v1';
  static const String LAST_SYNC_KEY = 'last_contact_sync';
  static const Duration SYNC_INTERVAL = Duration(hours: 24); // Daily sync
  
  /// Main contact sync function - call on app launch or manual sync
  static Future<ContactSyncResult> syncContacts() async {
    try {
      print('Starting contact sync...');
      
      // 1. Check permissions
      if (!await ContactPermissionService.hasContactPermission()) {
        throw Exception('Contact permission not granted');
      }
      
      // 2. Get contacts from device
      List<Contact> contacts = await ContactPermissionService.getContacts();
      print('Found ${contacts.length} contacts with phone numbers');
      
      if (contacts.isEmpty) {
        return ContactSyncResult(
          matchedContacts: [],
          totalContactsProcessed: 0,
          totalMatches: 0,
          syncTime: DateTime.now(),
          status: 'completed',
        );
      }
      
      // 3. Process and normalize phone numbers
      List<String> hashedContacts = await _processContacts(contacts);
      print('Processed ${hashedContacts.length} contact hashes');
      
      // 4. Upload to Firestore for server-side matching
      await _uploadContactHashes(hashedContacts);
      
      // 5. Wait for Cloud Function processing
      ContactSyncResult result = await _waitForSyncCompletion();
      
      // 6. Store results locally for fast access
      await _cacheContactResults(result);
      
      // 7. Update last sync time
      await _updateLastSyncTime();
      
      print('Contact sync completed: ${result.totalMatches} matches found');
      return result;
      
    } catch (e) {
      print('Contact sync error: $e');
      return ContactSyncResult(
        matchedContacts: [],
        totalContactsProcessed: 0,
        totalMatches: 0,
        syncTime: DateTime.now(),
        status: 'failed',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Get cached synced contacts (for fast UI loading)
  static Future<List<AppContact>> getCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(CACHE_KEY);
      
      if (cacheData != null) {
        final Map<String, dynamic> cache = json.decode(cacheData);
        final contactSyncResult = ContactSyncResult.fromJson(cache);
        
        // Check if cache is still valid (24 hours)
        if (DateTime.now().difference(contactSyncResult.syncTime).inHours < 24) {
          return contactSyncResult.matchedContacts;
        }
      }
    } catch (e) {
      print('Error loading cached contacts: $e');
    }
    
    return [];
  }
  
  /// Check if sync is needed (daily sync or force refresh)
  static Future<bool> needsSync([bool forceRefresh = false]) async {
    if (forceRefresh) return true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(LAST_SYNC_KEY);
      
      if (lastSyncString == null) return true;
      
      final lastSync = DateTime.parse(lastSyncString);
      return DateTime.now().difference(lastSync) > SYNC_INTERVAL;
      
    } catch (e) {
      print('Error checking sync status: $e');
      return true;
    }
  }
  
  /// Get sync status for UI display
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(LAST_SYNC_KEY);
      final cacheData = prefs.getString(CACHE_KEY);
      
      Map<String, dynamic> status = {
        'hasPermission': await ContactPermissionService.hasContactPermission(),
        'lastSync': lastSyncString != null ? DateTime.parse(lastSyncString) : null,
        'needsSync': await needsSync(),
        'contactCount': await ContactPermissionService.getContactCount(),
        'matchedContacts': 0,
      };
      
      if (cacheData != null) {
        final cache = json.decode(cacheData);
        final syncResult = ContactSyncResult.fromJson(cache);
        status['matchedContacts'] = syncResult.totalMatches;
      }
      
      return status;
      
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'hasPermission': false,
        'lastSync': null,
        'needsSync': true,
        'contactCount': 0,
        'matchedContacts': 0,
      };
    }
  }
  
  // Private helper methods
  
  static Future<List<String>> _processContacts(List<Contact> contacts) async {
    List<String> hashedContacts = [];
    
    for (Contact contact in contacts) {
      if (contact.phones != null && contact.phones!.isNotEmpty) {
        for (Item phone in contact.phones!) {
          String rawNumber = phone.value ?? '';
          
          // Generate all possible normalized formats
          List<String> normalizedNumbers = await _normalizeContactNumber(rawNumber);
          
          // Hash each variation for privacy
          for (String normalized in normalizedNumbers) {
            String hash = PhoneNumberService.hashPhoneNumber(normalized);
            hashedContacts.add(hash);
          }
        }
      }
    }
    
    return hashedContacts.toSet().toList(); // Remove duplicates
  }
  
  static Future<List<String>> _normalizeContactNumber(String rawNumber) async {
    List<String> normalized = [];
    
    // Try to get the primary normalized format
    String? primary = await PhoneNumberService.normalizeToE164(rawNumber);
    if (primary != null) {
      normalized.add(primary);
    }
    
    // Add variations for fuzzy matching
    List<String> variations = PhoneNumberService.generateVariations(rawNumber);
    for (String variation in variations) {
      String? norm = await PhoneNumberService.normalizeToE164(variation);
      if (norm != null && !normalized.contains(norm)) {
        normalized.add(norm);
      }
    }
    
    return normalized;
  }
  
  static Future<void> _uploadContactHashes(List<String> hashedContacts) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    await FirebaseFirestore.instance
        .collection('contact_syncs')
        .doc(user.uid)
        .set({
          'hashedContacts': hashedContacts,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending'
        });
  }
  
  static Future<ContactSyncResult> _waitForSyncCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    // Wait for Cloud Function to process (max 30 seconds)
    const maxWaitTime = Duration(seconds: 30);
    const checkInterval = Duration(seconds: 2);
    
    DateTime startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < maxWaitTime) {
      // Check contact_syncs document for completion
      DocumentSnapshot syncDoc = await FirebaseFirestore.instance
          .collection('contact_syncs')
          .doc(user.uid)
          .get();
      
      if (syncDoc.exists) {
        Map<String, dynamic> data = syncDoc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending';
        
        if (status == 'completed') {
          // Get the results from user_contacts collection
          DocumentSnapshot contactsDoc = await FirebaseFirestore.instance
              .collection('user_contacts')
              .doc(user.uid)
              .get();
          
          if (contactsDoc.exists) {
            Map<String, dynamic> contactsData = contactsDoc.data() as Map<String, dynamic>;
            List<dynamic> matches = contactsData['matches'] ?? [];
            
            List<AppContact> matchedContacts = matches.map((match) => 
              AppContact(
                id: match['uid'] ?? '',
                name: match['name'] ?? '',
                phoneNumber: match['phoneNumber'],
                email: match['email'],
                profilePicture: match['profilePicture'],
                hasAppAccount: true,
              )
            ).toList();
            
            return ContactSyncResult(
              matchedContacts: matchedContacts,
              totalContactsProcessed: data['hashedContacts']?.length ?? 0,
              totalMatches: matches.length,
              syncTime: DateTime.now(),
              status: 'completed',
            );
          }
        } else if (status == 'failed') {
          throw Exception(data['error'] ?? 'Contact sync failed');
        }
      }
      
      // Wait before checking again
      await Future.delayed(checkInterval);
    }
    
    throw Exception('Contact sync timeout');
  }
  
  static Future<void> _cacheContactResults(ContactSyncResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CACHE_KEY, json.encode(result.toJson()));
    } catch (e) {
      print('Error caching contact results: $e');
    }
  }
  
  static Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating last sync time: $e');
    }
  }
  
  /// Clear all cached contact data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CACHE_KEY);
      await prefs.remove(LAST_SYNC_KEY);
    } catch (e) {
      print('Error clearing contact cache: $e');
    }
  }
}
```

### **PHASE 5: Advanced User Search Service with Performance Optimization**

#### **Step 5.1: Implement High-Performance Search Service**
Create `lib/services/user_search_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'dart:convert';
import 'dart:async';

import '../models/contact_models.dart';
import 'phone_number_service.dart';
import 'contact_sync_service.dart';

class UserSearchService {
  
  // Performance optimization: Multi-level caching
  static final Map<String, CachedSearchResult> _memoryCache = {};
  static const String STORAGE_CACHE_PREFIX = 'search_cache_v1_';
  static const int MAX_MEMORY_CACHE_SIZE = 100;
  static const Duration MEMORY_CACHE_TTL = Duration(minutes: 5);
  static const Duration STORAGE_CACHE_TTL = Duration(hours: 24);
  
  // Debouncing for performance
  static Timer? _debounceTimer;
  static const Duration DEBOUNCE_DELAY = Duration(milliseconds: 300);
  
  /// Main search function with comprehensive optimization
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final String normalizedQuery = query.trim().toLowerCase();
    
    try {
      // 1. Check memory cache first (fastest < 10ms)
      List<UserSearchResult>? cachedResults = _getFromMemoryCache(normalizedQuery);
      if (cachedResults != null) {
        print('Search results from memory cache');
        return cachedResults;
      }
      
      // 2. Check local storage cache (fast < 50ms)
      cachedResults = await _getFromStorageCache(normalizedQuery);
      if (cachedResults != null) {
        print('Search results from storage cache');
        _setMemoryCache(normalizedQuery, cachedResults);
        return cachedResults;
      }
      
      // 3. Determine search strategy based on query
      QueryType queryType = _detectQueryType(normalizedQuery);
      
      // 4. Execute hybrid search strategy
      List<UserSearchResult> results = await _executeHybridSearch(normalizedQuery, queryType);
      
      // 5. Apply advanced ranking and relevance scoring
      results = _rankAndScoreResults(results, normalizedQuery);
      
      // 6. Cache results for future searches
      _setMemoryCache(normalizedQuery, results);
      await _setStorageCache(normalizedQuery, results);
      
      print('Search completed: ${results.length} results for "$query"');
      return results;
      
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }
  
  /// Real-time search with intelligent debouncing
  static Stream<List<UserSearchResult>> searchRealTime(Stream<String> queryStream) {
    return queryStream
        .where((query) => query.trim().isNotEmpty)
        .transform(StreamTransformer<String, String>.fromHandlers(
          handleData: (query, sink) {
            _debounceTimer?.cancel();
            
            // Smart debouncing: shorter delay for cached queries
            Duration delay = _isLikelyCached(query.trim().toLowerCase()) 
                ? Duration(milliseconds: 150) 
                : DEBOUNCE_DELAY;
            
            _debounceTimer = Timer(delay, () => sink.add(query));
          },
        ))
        .asyncMap((query) => searchUsers(query));
  }
  
  /// Get search suggestions for autocomplete
  static Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Get suggestions from cached searches
      List<String> suggestions = [];
      
      // Check recent searches
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = prefs.getStringList('recent_searches') ?? [];
      
      for (String recent in recentSearches) {
        if (recent.toLowerCase().startsWith(query.toLowerCase())) {
          suggestions.add(recent);
        }
      }
      
      // Add common name patterns if it looks like a name
      if (_detectQueryType(query) == QueryType.name) {
        suggestions.addAll(_getNameSuggestions(query));
      }
      
      return suggestions.take(5).toList();
      
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }
  
  /// Clear all search caches
  static Future<void> clearCache() async {
    _memoryCache.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(STORAGE_CACHE_PREFIX));
      for (String key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing search cache: $e');
    }
  }
  
  // Private implementation methods
  
  static QueryType _detectQueryType(String query) {
    // Phone number patterns
    if (PhoneNumberService.isPhoneNumber(query)) {
      return QueryType.phone;
    }
    
    // Email pattern
    if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(query)) {
      return QueryType.email;
    }
    
    // Too short for meaningful search
    if (query.length < 3) {
      return QueryType.partial;
    }
    
    // Mixed (contains @ or +)
    if (query.contains('@') || query.contains('+')) {
      return QueryType.mixed;
    }
    
    return QueryType.name;
  }
  
  static Future<List<UserSearchResult>> _executeHybridSearch(String query, QueryType type) async {
    List<UserSearchResult> allResults = [];
    
    switch (type) {
      case QueryType.partial:
        // For short queries, only search local contacts
        allResults = await _searchLocalContacts(query);
        break;
        
      case QueryType.phone:
        // Phone search: try local first, then server
        allResults.addAll(await _searchLocalContacts(query));
        allResults.addAll(await _searchServerByPhone(query));
        break;
        
      case QueryType.email:
        // Email search: primarily server-based
        allResults.addAll(await _searchServerByEmail(query));
        allResults.addAll(await _searchLocalContacts(query));
        break;
        
      case QueryType.name:
        // Name search: parallel local and server search
        final futures = [
          _searchLocalContacts(query),
          _searchServerByName(query),
        ];
        final results = await Future.wait(futures);
        for (var resultList in results) {
          allResults.addAll(resultList);
        }
        break;
        
      case QueryType.mixed:
        // Mixed search: try all strategies
        allResults.addAll(await _searchLocalContacts(query));
        allResults.addAll(await _searchServerMixed(query));
        break;
    }
    
    // Remove duplicates based on UID
    final seenUids = <String>{};
    return allResults.where((result) => seenUids.add(result.uid)).toList();
  }
  
  static Future<List<UserSearchResult>> _searchLocalContacts(String query) async {
    try {
      List<AppContact> contacts = await ContactSyncService.getCachedContacts();
      List<UserSearchResult> results = [];
      
      for (AppContact contact in contacts) {
        double score = _calculateLocalMatchScore(contact, query);
        if (score > 0.3) { // Minimum relevance threshold
          results.add(UserSearchResult(
            uid: contact.id,
            name: contact.name,
            email: contact.email,
            phoneNumber: contact.phoneNumber,
            profilePicture: contact.profilePicture,
            matchScore: score,
            isContact: true,
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('Error searching local contacts: $e');
      return [];
    }
  }
  
  static Future<List<UserSearchResult>> _searchServerByName(String query) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('advancedUserSearch');
      final result = await callable.call({
        'query': query,
        'queryType': 'name',
        'limit': 15,
      });
      
      List<dynamic> results = result.data['results'] ?? [];
      return results.map((data) => UserSearchResult(
        uid: data['uid'] ?? '',
        name: _buildFullName(data),
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        profilePicture: data['photoURL'],
        matchScore: 0.8, // Server results get high base score
        isContact: false,
      )).toList();
      
    } catch (e) {
      print('Error in server name search: $e');
      return [];
    }
  }
  
  static Future<List<UserSearchResult>> _searchServerByEmail(String query) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('advancedUserSearch');
      final result = await callable.call({
        'query': query,
        'queryType': 'email',
        'limit': 10,
      });
      
      List<dynamic> results = result.data['results'] ?? [];
      return results.map((data) => UserSearchResult(
        uid: data['uid'] ?? '',
        name: _buildFullName(data),
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        profilePicture: data['photoURL'],
        matchScore: 0.9, // Email matches are very relevant
        isContact: false,
      )).toList();
      
    } catch (e) {
      print('Error in server email search: $e');
      return [];
    }
  }
  
  static Future<List<UserSearchResult>> _searchServerByPhone(String query) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('advancedUserSearch');
      final result = await callable.call({
        'query': query,
        'queryType': 'phone',
        'limit': 5,
      });
      
      List<dynamic> results = result.data['results'] ?? [];
      return results.map((data) => UserSearchResult(
        uid: data['uid'] ?? '',
        name: _buildFullName(data),
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        profilePicture: data['photoURL'],
        matchScore: 1.0, // Phone matches are exact
        isContact: false,
      )).toList();
      
    } catch (e) {
      print('Error in server phone search: $e');
      return [];
    }
  }
  
  static Future<List<UserSearchResult>> _searchServerMixed(String query) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('advancedUserSearch');
      final result = await callable.call({
        'query': query,
        'queryType': 'mixed',
        'limit': 15,
      });
      
      List<dynamic> results = result.data['results'] ?? [];
      return results.map((data) => UserSearchResult(
        uid: data['uid'] ?? '',
        name: _buildFullName(data),
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        profilePicture: data['photoURL'],
        matchScore: 0.7, // Mixed search results
        isContact: false,
      )).toList();
      
    } catch (e) {
      print('Error in server mixed search: $e');
      return [];
    }
  }
  
  static List<UserSearchResult> _rankAndScoreResults(List<UserSearchResult> results, String query) {
    // Enhanced scoring with multiple factors
    for (var result in results) {
      result = UserSearchResult(
        uid: result.uid,
        name: result.name,
        email: result.email,
        phoneNumber: result.phoneNumber,
        profilePicture: result.profilePicture,
        matchScore: _calculateAdvancedScore(result, query),
        isContact: result.isContact,
      );
    }
    
    // Sort by score (highest first), then by contact status
    results.sort((a, b) {
      int scoreComparison = b.matchScore.compareTo(a.matchScore);
      if (scoreComparison != 0) return scoreComparison;
      
      // Prioritize contacts over non-contacts at same score
      if (a.isContact && !b.isContact) return -1;
      if (!a.isContact && b.isContact) return 1;
      
      return 0;
    });
    
    return results;
  }
  
  static double _calculateLocalMatchScore(AppContact contact, String query) {
    double score = 0.0;
    String queryLower = query.toLowerCase();
    
    // Name matching with fuzzy logic
    if (contact.name.toLowerCase().contains(queryLower)) {
      score += 0.8;
    } else {
      // Use fuzzy matching for partial matches
      int fuzzyScore = ratio(queryLower, contact.name.toLowerCase());
      if (fuzzyScore > 60) { // 60% similarity threshold
        score += (fuzzyScore / 100.0) * 0.6;
      }
    }
    
    // Phone number matching
    if (contact.phoneNumber != null) {
      double phoneScore = PhoneNumberService.calculateSimilarity(query, contact.phoneNumber!);
      score += phoneScore * 0.3;
    }
    
    // Email matching
    if (contact.email != null && contact.email!.toLowerCase().contains(queryLower)) {
      score += 0.4;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  static double _calculateAdvancedScore(UserSearchResult result, String query) {
    double score = result.matchScore; // Start with existing score
    String queryLower = query.toLowerCase();
    
    // Exact match bonuses
    if (result.name.toLowerCase() == queryLower) {
      score += 0.3;
    } else if (result.name.toLowerCase().startsWith(queryLower)) {
      score += 0.2;
    }
    
    // Email exact match
    if (result.email != null && result.email!.toLowerCase() == queryLower) {
      score += 0.25;
    }
    
    // Contact bonus (known contacts are more relevant)
    if (result.isContact) {
      score += 0.1;
    }
    
    // Profile completeness bonus
    if (result.profilePicture != null && result.profilePicture!.isNotEmpty) {
      score += 0.05;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  // Caching implementation
  
  static List<UserSearchResult>? _getFromMemoryCache(String query) {
    final cached = _memoryCache[query];
    if (cached != null && !cached.isExpired) {
      return cached.results;
    }
    _memoryCache.remove(query);
    return null;
  }
  
  static void _setMemoryCache(String query, List<UserSearchResult> results) {
    // Implement LRU eviction
    if (_memoryCache.length >= MAX_MEMORY_CACHE_SIZE) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    
    _memoryCache[query] = CachedSearchResult(
      results: results,
      timestamp: DateTime.now(),
      cacheDuration: MEMORY_CACHE_TTL,
    );
  }
  
  static Future<List<UserSearchResult>?> _getFromStorageCache(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('$STORAGE_CACHE_PREFIX$query');
      
      if (cacheData != null) {
        final Map<String, dynamic> cache = json.decode(cacheData);
        final timestamp = DateTime.parse(cache['timestamp']);
        
        if (DateTime.now().difference(timestamp) < STORAGE_CACHE_TTL) {
          return (cache['results'] as List)
              .map((e) => UserSearchResult.fromJson(e))
              .toList();
        } else {
          // Remove expired cache
          await prefs.remove('$STORAGE_CACHE_PREFIX$query');
        }
      }
    } catch (e) {
      print('Error reading storage cache: $e');
    }
    return null;
  }
  
  static Future<void> _setStorageCache(String query, List<UserSearchResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'results': results.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('$STORAGE_CACHE_PREFIX$query', json.encode(cacheData));
    } catch (e) {
      print('Error storing cache: $e');
    }
  }
  
  // Helper methods
  
  static bool _isLikelyCached(String query) {
    return _memoryCache.containsKey(query);
  }
  
  static String _buildFullName(Map<String, dynamic> data) {
    String firstName = data['firstName'] ?? '';
    String lastName = data['lastName'] ?? '';
    String displayName = data['displayName'] ?? '';
    
    if (displayName.isNotEmpty) {
      return displayName;
    }
    
    return '$firstName $lastName'.trim();
  }
  
  static List<String> _getNameSuggestions(String query) {
    // Simple name completion suggestions
    // In a real app, you might maintain a list of common names
    return [];
  }
}
```

### **PHASE 6: UI Implementation Following Existing Patterns**

#### **Step 6.1: Create Main Contacts Screen**
Create `lib/screens/contacts/contacts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Assuming your app uses GetX
// Import your existing app components and themes

import '../../models/contact_models.dart';
import '../../services/contact_sync_service.dart';
import '../../services/user_search_service.dart';
import '../../services/contact_permission_service.dart';
import '../../widgets/contacts/advanced_search_bar.dart';
import '../../widgets/contacts/contact_list_item.dart';
import '../../widgets/contacts/contact_sync_button.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  // State variables
  List<AppContact> _syncedContacts = [];
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isSyncing = false;
  bool _hasContactPermission = false;
  String _searchQuery = '';
  
  // Animation controllers (follow existing app patterns)
  late AnimationController _syncAnimationController;
  late AnimationController _searchAnimationController;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }
  
  void _initializeAnimations() {
    // Follow existing animation patterns in your app
    _syncAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  Future<void> _loadInitialData() async {
    setState(() => _isSyncing = true);
    
    try {
      // Check permission status
      _hasContactPermission = await ContactPermissionService.hasContactPermission();
      
      // Load cached contacts
      _syncedContacts = await ContactSyncService.getCachedContacts();
      
      // Auto-sync if needed
      if (_hasContactPermission && await ContactSyncService.needsSync()) {
        await _syncContacts();
      }
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      // Use EXACT same AppBar styling as other tabs in your app
      appBar: _buildAppBar(),
      
      // Main content
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Search section
            _buildSearchSection(),
            
            // Sync status and button
            if (!_isSearching) _buildSyncSection(),
            
            // Content area
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildContactsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    // CRITICAL: Copy the exact AppBar implementation from other tabs
    // Look at notifications_screen.dart or other tab files for the exact pattern
    return AppBar(
      // Use existing app bar styling
      title: Text(
        'Contacts',
        style: TextStyle(
          // Use existing font family and styling
          fontFamily: 'YourAppFont', // Replace with your app's font
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Use existing colors and elevation
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      // Add any existing app bar actions/styling
    );
  }
  
  Widget _buildSearchSection() {
    return Container(
      // Use existing container styling and padding
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AdvancedSearchBar(
        onSearchChanged: _handleSearchChanged,
        onResultSelected: _handleSearchResultSelected,
        onFocusChanged: _handleSearchFocusChanged,
      ),
    );
  }
  
  Widget _buildSyncSection() {
    return Container(
      // Follow existing section styling
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ContactSyncButton(
        hasPermission: _hasContactPermission,
        isSyncing: _isSyncing,
        contactCount: _syncedContacts.length,
        onSyncPressed: _handleSyncPressed,
        onPermissionPressed: _handlePermissionPressed,
      ),
    );
  }
  
  Widget _buildContactsList() {
    if (_isSyncing) {
      return _buildLoadingState();
    }
    
    if (!_hasContactPermission) {
      return _buildPermissionPrompt();
    }
    
    if (_syncedContacts.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      // Use existing list styling
      itemCount: _syncedContacts.length,
      itemBuilder: (context, index) {
        return ContactListItem(
          contact: _syncedContacts[index],
          onTap: () => _handleContactTap(_syncedContacts[index]),
          showOnlineStatus: true,
        );
      },
    );
  }
  
  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildSearchPrompt();
    }
    
    if (_searchResults.isEmpty && !_isSearching) {
      return _buildNoResultsState();
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return ContactListItem.fromSearchResult(
          searchResult: _searchResults[index],
          onTap: () => _handleSearchResultTap(_searchResults[index]),
          query: _searchQuery,
        );
      },
    );
  }
  
  Widget _buildLoadingState() {
    // Use existing loading widget styling
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            // Use existing loading indicator styling
          ),
          SizedBox(height: 16),
          Text(
            'Syncing contacts...',
            style: TextStyle(
              // Use existing text styling
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionPrompt() {
    // Use existing empty state styling
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 64,
              // Use existing icon styling
            ),
            SizedBox(height: 16),
            Text(
              'Find Your Friends',
              style: TextStyle(
                // Use existing heading styling
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Allow access to your contacts to find friends who are already using the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                // Use existing subtitle styling
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handlePermissionPressed,
              child: Text('Allow Contacts'),
              // Use existing button styling
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    // Use existing empty state styling
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              // Use existing styling
            ),
            SizedBox(height: 16),
            Text(
              'No Contacts Found',
              style: TextStyle(
                // Use existing styling
              ),
            ),
            Text(
              'None of your contacts are using the app yet. Invite them to join!',
              textAlign: TextAlign.center,
              style: TextStyle(
                // Use existing styling
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              // Use existing styling
            ),
            SizedBox(height: 16),
            Text(
              'Search Users',
              style: TextStyle(
                // Use existing styling
              ),
            ),
            Text(
              'Search by name, email, or phone number to find users.',
              textAlign: TextAlign.center,
              style: TextStyle(
                // Use existing styling
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              // Use existing styling
            ),
            SizedBox(height: 16),
            Text(
              'No Results Found',
              style: TextStyle(
                // Use existing styling
              ),
            ),
            Text(
              'Try searching with a different name, email, or phone number.',
              textAlign: TextAlign.center,
              style: TextStyle(
                // Use existing styling
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Event handlers
  
  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    // Use the real-time search with debouncing
    UserSearchService.searchUsers(query).then((results) {
      if (mounted && _searchQuery == query) {
        setState(() => _searchResults = results);
      }
    });
  }
  
  void _handleSearchFocusChanged(bool hasFocus) {
    if (hasFocus) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }
  
  void _handleSearchResultSelected(UserSearchResult result) {
    // Handle search result selection
    _handleSearchResultTap(result);
  }
  
  Future<void> _handleSyncPressed() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    _syncAnimationController.repeat();
    
    try {
      await _syncContacts();
    } finally {
      setState(() => _isSyncing = false);
      _syncAnimationController.stop();
    }
  }
  
  Future<void> _handlePermissionPressed() async {
    bool granted = await ContactPermissionService.requestContactPermission();
    
    setState(() => _hasContactPermission = granted);
    
    if (granted) {
      await _handleSyncPressed();
    }
  }
  
  void _handleContactTap(AppContact contact) {
    // Navigate to user profile or chat
    // Use existing navigation patterns
    print('Contact tapped: ${contact.name}');
  }
  
  void _handleSearchResultTap(UserSearchResult result) {
    // Navigate to user profile or start conversation
    // Use existing navigation patterns
    print('Search result tapped: ${result.name}');
  }
  
  Future<void> _handleRefresh() async {
    await _syncContacts();
  }
  
  Future<void> _syncContacts() async {
    try {
      ContactSyncResult result = await ContactSyncService.syncContacts();
      
      if (result.status == 'completed') {
        setState(() => _syncedContacts = result.matchedContacts);
        
        // Show success message using existing snackbar styling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${result.totalMatches} contacts'),
            // Use existing snackbar styling
          ),
        );
      } else {
        throw Exception(result.errorMessage ?? 'Sync failed');
      }
    } catch (e) {
      print('Sync error: $e');
      
      // Show error message using existing error styling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync contacts'),
          backgroundColor: Colors.red,
          // Use existing error styling
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _syncAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true; // Keep tab state alive
}
```

#### **Step 6.2: Create Advanced Search Bar Component**
Create `lib/widgets/contacts/advanced_search_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/contact_models.dart';
import '../../services/user_search_service.dart';

class AdvancedSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(UserSearchResult) onResultSelected;
  final Function(bool)? onFocusChanged;
  
  const AdvancedSearchBar({
    Key? key,
    required this.onSearchChanged,
    required this.onResultSelected,
    this.onFocusChanged,
  }) : super(key: key);
  
  @override
  _AdvancedSearchBarState createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        // Use existing search field styling from your app
        decoration: BoxDecoration(
          // Copy styling from existing search fields
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          // Use existing text field styling
          decoration: InputDecoration(
            hintText: 'Search by name, email, or phone...',
            hintStyle: TextStyle(
              // Use existing hint text styling
            ),
            prefixIcon: Icon(
              Icons.search,
              // Use existing icon styling
            ),
            suffixIcon: _controller.text.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // Use existing text styling
          style: TextStyle(
            fontSize: 16,
            // Use existing font styling
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => widget.onSearchChanged(value),
        ),
      ),
    );
  }
  
  void _onTextChanged() {
    final text = _controller.text;
    widget.onSearchChanged(text);
    
    if (text.isNotEmpty && text.length >= 2) {
      _getSuggestions(text);
    } else {
      _hideSuggestions();
    }
  }
  
  void _onFocusChanged() {
    widget.onFocusChanged?.call(_focusNode.hasFocus);
    
    if (!_focusNode.hasFocus) {
      _hideSuggestions();
    }
  }
  
  Future<void> _getSuggestions(String query) async {
    try {
      final suggestions = await UserSearchService.getSuggestions(query);
      
      if (mounted && _controller.text == query) {
        setState(() => _suggestions = suggestions);
        
        if (suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showSuggestionsOverlay();
        }
      }
    } catch (e) {
      print('Error getting suggestions: $e');
    }
  }
  
  void _showSuggestionsOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, 56), // Height of search field
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    leading: Icon(Icons.history),
                    onTap: () => _selectSuggestion(_suggestions[index]),
                    // Use existing list tile styling
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context)?.insert(_overlayEntry!);
    setState(() => _showSuggestions = true);
  }
  
  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showSuggestions = false);
  }
  
  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    widget.onSearchChanged(suggestion);
    _hideSuggestions();
  }
  
  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    _hideSuggestions();
  }
  
  @override
  void dispose() {
    _hideSuggestions();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
```

#### **Step 6.3: Create Contact List Item Component**
Create `lib/widgets/contacts/contact_list_item.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/contact_models.dart';

class ContactListItem extends StatelessWidget {
  final AppContact? contact;
  final UserSearchResult? searchResult;
  final VoidCallback? onTap;
  final bool showOnlineStatus;
  final String? query; // For highlighting search terms
  
  const ContactListItem({
    Key? key,
    this.contact,
    this.searchResult,
    this.onTap,
    this.showOnlineStatus = false,
    this.query,
  }) : super(key: key);
  
  // Constructor for regular contacts
  ContactListItem.fromContact({
    Key? key,
    required AppContact contact,
    VoidCallback? onTap,
    bool showOnlineStatus = false,
  }) : this(
    key: key,
    contact: contact,
    onTap: onTap,
    showOnlineStatus: showOnlineStatus,
  );
  
  // Constructor for search results
  ContactListItem.fromSearchResult({
    Key? key,
    required UserSearchResult searchResult,
    VoidCallback? onTap,
    String? query,
  }) : this(
    key: key,
    searchResult: searchResult,
    onTap: onTap,
    query: query,
  );
  
  @override
  Widget build(BuildContext context) {
    final isSearchResult = searchResult != null;
    final name = isSearchResult ? searchResult!.name : contact!.name;
    final profilePicture = isSearchResult ? searchResult!.profilePicture : contact!.profilePicture;
    final subtitle = _buildSubtitleText();
    
    return ListTile(
      // Use existing ListTile styling from your app
      leading: _buildAvatar(profilePicture),
      title: _buildTitle(name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: _buildTrailing(),
      onTap: onTap,
      // Use existing list tile styling
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
  
  Widget _buildAvatar(String? profilePicture) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          // Use existing avatar styling
          backgroundImage: profilePicture != null && profilePicture.isNotEmpty
              ? NetworkImage(profilePicture)
              : null,
          child: profilePicture == null || profilePicture.isEmpty
              ? Icon(
                  Icons.person,
                  size: 24,
                  // Use existing icon styling
                )
              : null,
        ),
        
        // Online status indicator
        if (showOnlineStatus)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTitle(String name) {
    if (query != null && query!.isNotEmpty) {
      // Highlight search terms
      return RichText(
        text: _highlightSearchTerm(name, query!),
      );
    }
    
    return Text(
      name,
      style: TextStyle(
        // Use existing title text styling
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  String _buildSubtitleText() {
    if (searchResult != null) {
      // For search results, show email or phone
      if (searchResult!.email != null && searchResult!.email!.isNotEmpty) {
        return searchResult!.email!;
      }
      if (searchResult!.phoneNumber != null && searchResult!.phoneNumber!.isNotEmpty) {
        return searchResult!.phoneNumber!;
      }
      return searchResult!.isContact ? 'In your contacts' : 'User';
    }
    
    if (contact != null) {
      // For contacts, show phone or email
      if (contact!.phoneNumber != null && contact!.phoneNumber!.isNotEmpty) {
        return contact!.phoneNumber!;
      }
      if (contact!.email != null && contact!.email!.isNotEmpty) {
        return contact!.email!;
      }
      return 'Contact';
    }
    
    return '';
  }
  
  Widget? _buildTrailing() {
    if (searchResult != null) {
      if (searchResult!.isContact) {
        return Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
      } else {
        return Icon(
          Icons.person_add,
          color: Theme.of(context).primaryColor,
          size: 20,
        );
      }
    }
    
    if (contact != null && contact!.hasAppAccount) {
      return Icon(
        Icons.chat_bubble_outline,
        color: Theme.of(context).primaryColor,
        size: 20,
      );
    }
    
    return null;
  }
  
  TextSpan _highlightSearchTerm(String text, String searchTerm) {
    if (searchTerm.isEmpty) {
      return TextSpan(text: text);
    }
    
    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerSearchTerm = searchTerm.toLowerCase();
    
    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerSearchTerm, start);
    
    while (indexOfHighlight >= 0) {
      // Add text before highlight
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      
      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + searchTerm.length),
        style: TextStyle(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = indexOfHighlight + searchTerm.length;
      indexOfHighlight = lowerText.indexOf(lowerSearchTerm, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return TextSpan(children: spans);
  }
}
```

#### **Step 6.4: Create Contact Sync Button Component**
Create `lib/widgets/contacts/contact_sync_button.dart`:

```dart
import 'package:flutter/material.dart';

class ContactSyncButton extends StatelessWidget {
  final bool hasPermission;
  final bool isSyncing;
  final int contactCount;
  final VoidCallback? onSyncPressed;
  final VoidCallback? onPermissionPressed;
  
  const ContactSyncButton({
    Key? key,
    required this.hasPermission,
    required this.isSyncing,
    required this.contactCount,
    this.onSyncPressed,
    this.onPermissionPressed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // Use existing card/container styling
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPermission ? Icons.sync : Icons.contacts,
                color: hasPermission ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPermission ? 'Contact Sync' : 'Enable Contact Sync',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        // Use existing text styling
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getSubtitleText(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        // Use existing subtitle styling
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButton(context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context) {
    if (isSyncing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          // Use existing loading indicator styling
        ),
      );
    }
    
    if (!hasPermission) {
      return ElevatedButton(
        onPressed: onPermissionPressed,
        child: Text('Allow'),
        // Use existing button styling
      );
    }
    
    return IconButton(
      onPressed: onSyncPressed,
      icon: Icon(Icons.refresh),
      tooltip: 'Sync contacts',
      // Use existing icon button styling
    );
  }
  
  String _getSubtitleText() {
    if (isSyncing) {
      return 'Syncing contacts...';
    }
    
    if (!hasPermission) {
      return 'Find friends who are using the app';
    }
    
    if (contactCount == 0) {
      return 'No contacts synced yet';
    } else if (contactCount == 1) {
      return '1 contact synced';
    } else {
      return '$contactCount contacts synced';
    }
  }
}
```

### **PHASE 7: Integration with Existing Navigation**

#### **Step 7.1: Update Main Navigation**
Find your main navigation file (likely `lib/screens/main_screen.dart` or `lib/navigation/main_navigation.dart`) and add the contacts tab:

```dart
// Example integration - adapt to your existing navigation structure
class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  // Add ContactsScreen to your existing screens list
  final List<Widget> _screens = [
    HomeScreen(),           // Existing
    SearchScreen(),         // Existing  
    ContactsScreen(),       // NEW - Add this
    NotificationsScreen(),  // Existing
    ProfileScreen(),        // Existing
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // If you have 5+ tabs
        // Use your existing styling
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),  // NEW
            label: 'Contacts',          // NEW
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

#### **Step 7.2: Update State Management Integration**

If your app uses GetX, Provider, Bloc, or other state management, integrate contacts functionality:

**For GetX (Example):**
Create `lib/controllers/contacts_controller.dart`:

```dart
import 'package:get/get.dart';
import '../models/contact_models.dart';
import '../services/contact_sync_service.dart';
import '../services/user_search_service.dart';
import '../services/contact_permission_service.dart';

class ContactsController extends GetxController {
  // Observable state
  final RxList<AppContact> syncedContacts = <AppContact>[].obs;
  final RxList<UserSearchResult> searchResults = <UserSearchResult>[].obs;
  final RxBool isSyncing = false.obs;
  final RxBool hasPermission = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, dynamic> syncStatus = <String, dynamic>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeContacts();
  }
  
  /// Initialize contacts on app startup
  Future<void> _initializeContacts() async {
    try {
      // Check permission status
      hasPermission.value = await ContactPermissionService.hasContactPermission();
      
      // Load cached contacts
      syncedContacts.value = await ContactSyncService.getCachedContacts();
      
      // Get sync status
      syncStatus.value = await ContactSyncService.getSyncStatus();
      
      // Auto-sync if needed and permission granted
      if (hasPermission.value && await ContactSyncService.needsSync()) {
        await syncContacts();
      }
    } catch (e) {
      print('Error initializing contacts: $e');
    }
  }
  
  /// Request contact permission
  Future<bool> requestPermission() async {
    try {
      bool granted = await ContactPermissionService.requestContactPermission();
      hasPermission.value = granted;
      
      if (granted) {
        await syncContacts();
      }
      
      return granted;
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }
  
  /// Sync contacts with loading state
  Future<void> syncContacts() async {
    if (isSyncing.value) return;
    
    isSyncing.value = true;
    
    try {
      ContactSyncResult result = await ContactSyncService.syncContacts();
      
      if (result.status == 'completed') {
        syncedContacts.value = result.matchedContacts;
        
        // Update sync status
        syncStatus.value = await ContactSyncService.getSyncStatus();
        
        // Show success message
        Get.snackbar(
          'Contacts Synced',
          'Found ${result.totalMatches} contacts',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception(result.errorMessage ?? 'Sync failed');
      }
    } catch (e) {
      print('Sync error: $e');
      
      Get.snackbar(
        'Sync Failed',
        'Unable to sync contacts. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.errorColor,
        colorText: Get.theme.onError,
      );
    } finally {
      isSyncing.value = false;
    }
  }
  
  /// Search users with loading state
  Future<void> searchUsers(String query) async {
    searchQuery.value = query;
    isSearching.value = query.isNotEmpty;
    
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    
    try {
      List<UserSearchResult> results = await UserSearchService.searchUsers(query);
      
      // Only update if query hasn't changed (avoid race conditions)
      if (searchQuery.value == query) {
        searchResults.value = results;
      }
    } catch (e) {
      print('Search error: $e');
      searchResults.clear();
    }
  }
  
  /// Clear search results
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }
  
  /// Get contact by ID
  AppContact? getContactById(String id) {
    try {
      return syncedContacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if user is in contacts
  bool isUserInContacts(String userId) {
    return syncedContacts.any((contact) => contact.id == userId);
  }
  
  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
```

Register the controller in your app:
```dart
// In your main.dart or binding class
Get.put(ContactsController());
```

**For Provider (Alternative Example):**
```dart
class ContactsProvider with ChangeNotifier {
  List<AppContact> _syncedContacts = [];
  List<UserSearchResult> _searchResults = [];
  bool _isSyncing = false;
  bool _hasPermission = false;
  String _searchQuery = '';
  
  // Getters
  List<AppContact> get syncedContacts => _syncedContacts;
  List<UserSearchResult> get searchResults => _searchResults;
  bool get isSyncing => _isSyncing;
  bool get hasPermission => _hasPermission;
  String get searchQuery => _searchQuery;
  
  // Methods similar to GetX controller...
}
```

### **PHASE 8: Testing & Quality Assurance**

#### **Step 8.1: Unit Tests**
Create comprehensive unit tests for all services:

**Contact Permission Service Tests:**
Create `test/services/contact_permission_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:your_app/services/contact_permission_service.dart';

// Mock classes
class MockPermissionHandler extends Mock implements Permission {}

void main() {
  group('ContactPermissionService', () {
    test('should return true when permission is granted', () async {
      // Arrange
      final mockPermission = MockPermissionHandler();
      when(mockPermission.status).thenAnswer((_) async => PermissionStatus.granted);
      
      // Act
      final result = await ContactPermissionService.hasContactPermission();
      
      // Assert
      expect(result, true);
    });
    
    test('should return false when permission is denied', () async {
      // Arrange & Act & Assert
      // Add more test cases...
    });
    
    // Add more comprehensive tests
  });
}
```

**Phone Number Service Tests:**
Create `test/services/phone_number_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/services/phone_number_service.dart';

void main() {
  group('PhoneNumberService', () {
    test('should normalize US phone number to E.164', () async {
      // Test various US formats
      expect(
        await PhoneNumberService.normalizeToE164('(555) 123-4567', 'US'),
        '+15551234567',
      );
      
      expect(
        await PhoneNumberService.normalizeToE164('555-123-4567', 'US'),
        '+15551234567',
      );
      
      expect(
        await PhoneNumberService.normalizeToE164('+1 555 123 4567', 'US'),
        '+15551234567',
      );
    });
    
    test('should generate phone number variations', () {
      final variations = PhoneNumberService.generateVariations('+15551234567');
      
      expect(variations, contains('+15551234567'));
      expect(variations, contains('5551234567'));
      expect(variations, contains('(555) 123-4567'));
      // Add more assertions
    });
    
    test('should calculate phone similarity correctly', () {
      expect(
        PhoneNumberService.calculateSimilarity('+15551234567', '(555) 123-4567'),
        1.0,
      );
      
      expect(
        PhoneNumberService.calculateSimilarity('+15551234567', '+15551234560'),
        0.9, // Last 7 digits match
      );
    });
    
    // Add more test cases for edge cases
  });
}
```

**User Search Service Tests:**
Create `test/services/user_search_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/services/user_search_service.dart';
import 'package:your_app/models/contact_models.dart';

void main() {
  group('UserSearchService', () {
    test('should detect query types correctly', () {
      // Test phone detection
      expect(UserSearchService._detectQueryType('+15551234567'), QueryType.phone);
      expect(UserSearchService._detectQueryType('(555) 123-4567'), QueryType.phone);
      
      // Test email detection  
      expect(UserSearchService._detectQueryType('user@example.com'), QueryType.email);
      
      // Test name detection
      expect(UserSearchService._detectQueryType('John Doe'), QueryType.name);
      
      // Test partial detection
      expect(UserSearchService._detectQueryType('Jo'), QueryType.partial);
    });
    
    test('should cache search results correctly', () async {
      // Test caching logic
      // Add cache-related tests
    });
    
    // Add performance tests
    test('should return results within performance targets', () async {
      final stopwatch = Stopwatch()..start();
      
      await UserSearchService.searchUsers('John');
      
      stopwatch.stop();
      
      // Should be under 1500ms for complete search
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
    });
  });
}
```

#### **Step 8.2: Widget Tests**
Create widget tests for UI components:

**Contact List Item Tests:**
Create `test/widgets/contact_list_item_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/widgets/contacts/contact_list_item.dart';
import 'package:your_app/models/contact_models.dart';

void main() {
  group('ContactListItem', () {
    testWidgets('should display contact information correctly', (tester) async {
      // Arrange
      final contact = AppContact(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+15551234567',
        email: 'john@example.com',
        hasAppAccount: true,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactListItem.fromContact(contact: contact),
          ),
        ),
      );
      
      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+15551234567'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
    
    testWidgets('should highlight search terms', (tester) async {
      // Test search term highlighting
      // Add more widget tests
    });
  });
}
```

**Search Bar Tests:**
Create `test/widgets/advanced_search_bar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/widgets/contacts/advanced_search_bar.dart';

void main() {
  group('AdvancedSearchBar', () {
    testWidgets('should call onSearchChanged when text changes', (tester) async {
      String? searchQuery;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearchBar(
              onSearchChanged: (query) => searchQuery = query,
              onResultSelected: (_) {},
            ),
          ),
        ),
      );
      
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pump();
      
      expect(searchQuery, 'John');
    });
    
    // Add more search bar tests
  });
}
```

#### **Step 8.3: Integration Tests**
Create integration tests for complete user flows:

Create `integration_test/contacts_flow_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Contacts Flow Integration Tests', () {
    testWidgets('complete contact sync and search flow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to contacts tab
      await tester.tap(find.byIcon(Icons.contacts));
      await tester.pumpAndSettle();
      
      // Test permission flow
      await tester.tap(find.text('Allow Contacts'));
      await tester.pumpAndSettle();
      
      // Test search functionality
      await tester.enterText(find.byType(TextField), 'John');
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify search results appear
      expect(find.byType(ListView), findsOneWidget);
      
      // Test contact interaction
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
      }
    });
    
    testWidgets('performance test - search response time', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.contacts));
      await tester.pumpAndSettle();
      
      final stopwatch = Stopwatch()..start();
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Should respond within 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
```

### **PHASE 9: Error Handling & Edge Cases**

#### **Step 9.1: Comprehensive Error Handling**
Implement robust error handling throughout the system:

**Network Error Handling:**
```dart
class NetworkErrorHandler {
  static Future<T> handleNetworkCall<T>(Future<T> Function() networkCall) async {
    try {
      return await networkCall();
    } on SocketException {
      throw ContactSyncException('No internet connection');
    } on TimeoutException {
      throw ContactSyncException('Request timeout');
    } on FirebaseException catch (e) {
      throw ContactSyncException('Firebase error: ${e.message}');
    } catch (e) {
      throw ContactSyncException('Unknown error: $e');
    }
  }
}

class ContactSyncException implements Exception {
  final String message;
  ContactSyncException(this.message);
  
  @override
  String toString() => message;
}
```

**Permission Error Handling:**
```dart
class PermissionErrorHandler {
  static Future<bool> handlePermissionRequest() async {
    try {
      PermissionStatus status = await Permission.contacts.request();
      
      switch (status) {
        case PermissionStatus.granted:
          return true;
        case PermissionStatus.denied:
          _showPermissionDeniedDialog();
          return false;
        case PermissionStatus.permanentlyDenied:
          _showPermissionPermanentlyDeniedDialog();
          return false;
        default:
          return false;
      }
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }
  
  static void _showPermissionDeniedDialog() {
    // Show user-friendly dialog explaining why permission is needed
  }
  
  static void _showPermissionPermanentlyDeniedDialog() {
    // Show dialog with option to go to app settings
  }
}
```

#### **Step 9.2: Edge Cases Handling**

**Large Contact Lists:**
```dart
class LargeContactListHandler {
  static const int BATCH_SIZE = 500;
  static const int MAX_CONTACTS = 10000;
  
  static Future<List<String>> processBatchedContacts(List<Contact> contacts) async {
    if (contacts.length > MAX_CONTACTS) {
      // Limit to prevent memory issues
      contacts = contacts.take(MAX_CONTACTS).toList();
      
      // Show warning to user
      Get.snackbar(
        'Large Contact List',
        'Processing first ${MAX_CONTACTS} contacts for performance',
      );
    }
    
    List<String> allHashes = [];
    
    for (int i = 0; i < contacts.length; i += BATCH_SIZE) {
      int end = (i + BATCH_SIZE < contacts.length) ? i + BATCH_SIZE : contacts.length;
      List<Contact> batch = contacts.sublist(i, end);
      
      List<String> batchHashes = await _processBatch(batch);
      allHashes.addAll(batchHashes);
      
      // Add small delay to prevent UI blocking
      await Future.delayed(Duration(milliseconds: 10));
    }
    
    return allHashes;
  }
  
  static Future<List<String>> _processBatch(List<Contact> batch) async {
    // Process batch of contacts
    return [];
  }
}
```

**Invalid Phone Numbers:**
```dart
class InvalidPhoneNumberHandler {
  static Future<List<String>> filterValidNumbers(List<String> rawNumbers) async {
    List<String> validNumbers = [];
    
    for (String number in rawNumbers) {
      try {
        String? normalized = await PhoneNumberService.normalizeToE164(number);
        if (normalized != null) {
          validNumbers.add(normalized);
        }
      } catch (e) {
        // Log invalid number but continue processing
        print('Invalid phone number: $number');
      }
    }
    
    return validNumbers;
  }
}
```

**Search Result Deduplication:**
```dart
class SearchResultDeduplicator {
  static List<UserSearchResult> deduplicateResults(List<UserSearchResult> results) {
    final Map<String, UserSearchResult> uniqueResults = {};
    
    for (UserSearchResult result in results) {
      final existingResult = uniqueResults[result.uid];
      
      if (existingResult == null || result.matchScore > existingResult.matchScore) {
        uniqueResults[result.uid] = result;
      }
    }
    
    return uniqueResults.values.toList();
  }
}
```

### **PHASE 10: Performance Optimization & Monitoring**

#### **Step 10.1: Performance Targets & Monitoring**

**Performance Metrics Tracking:**
```dart
class PerformanceMetrics {
  static final Map<String, List<int>> _responseTimesMs = {};
  static final Map<String, int> _cacheHitCounts = {};
  
  static void recordSearchTime(String queryType, int milliseconds) {
    _responseTimesMs[queryType] ??= [];
    _responseTimesMs[queryType]!.add(milliseconds);
    
    // Keep only last 100 measurements
    if (_responseTimesMs[queryType]!.length > 100) {
      _responseTimesMs[queryType]!.removeAt(0);
    }
  }
  
  static void recordCacheHit(String cacheLevel) {
    _cacheHitCounts[cacheLevel] = (_cacheHitCounts[cacheLevel] ?? 0) + 1;
  }
  
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    // Average response times
    _responseTimesMs.forEach((type, times) {
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) / times.length;
        report['avg_${type}_ms'] = avg.round();
      }
    });
    
    // Cache hit rates
    final totalSearches = _cacheHitCounts.values.fold(0, (a, b) => a + b);
    _cacheHitCounts.forEach((level, hits) {
      report['${level}_hit_rate'] = totalSearches > 0 ? 
          (hits / totalSearches * 100).round() : 0;
    });
    
    return report;
  }
}
```

**Performance Alert System:**
```dart
class PerformanceAlerts {
  static const int SLOW_SEARCH_THRESHOLD_MS = 2000;
  static const double LOW_CACHE_HIT_RATE = 0.5; // 50%
  
  static void checkPerformance(String operation, int durationMs) {
    if (durationMs > SLOW_SEARCH_THRESHOLD_MS) {
      _logSlowOperation(operation, durationMs);
    }
  }
  
  static void checkCacheHitRate(double hitRate) {
    if (hitRate < LOW_CACHE_HIT_RATE) {
      _logLowCachePerformance(hitRate);
    }
  }
  
  static void _logSlowOperation(String operation, int durationMs) {
    print('PERFORMANCE ALERT: Slow $operation took ${durationMs}ms');
    
    // In production, send to analytics service
    // Analytics.track('performance_alert', {
    //   'operation': operation,
    //   'duration_ms': durationMs,
    // });
  }
  
  static void _logLowCachePerformance(double hitRate) {
    print('PERFORMANCE ALERT: Low cache hit rate: ${(hitRate * 100).round()}%');
  }
}
```

#### **Step 10.2: Performance Optimization Implementation**

**Search Response Time Optimization:**
```dart
class SearchOptimizer {
  static Future<List<UserSearchResult>> optimizedSearch(String query) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Use hybrid search strategy for optimal performance
      List<UserSearchResult> results = await _executeHybridSearch(query);
      
      stopwatch.stop();
      
      // Record performance metrics
      PerformanceMetrics.recordSearchTime('total', stopwatch.elapsedMilliseconds);
      
      // Check for performance issues
      PerformanceAlerts.checkPerformance('search', stopwatch.elapsedMilliseconds);
      
      return results;
      
    } catch (e) {
      stopwatch.stop();
      print('Search error after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
  
  static Future<List<UserSearchResult>> _executeHybridSearch(String query) async {
    // Implementation with performance tracking for each step
    return [];
  }
}
```

### **IMPLEMENTATION CHECKLIST**

#### **Pre-Implementation (Critical)**
- [ ] **Study existing codebase thoroughly**
  - [ ] Analyze navigation structure and patterns
  - [ ] Identify existing UI components and themes
  - [ ] Understand current state management approach
  - [ ] Review existing service patterns

- [ ] **Set up development environment**
  - [ ] Add required dependencies to pubspec.yaml
  - [ ] Configure Firebase project and rules
  - [ ] Set up Cloud Functions development environment
  - [ ] Configure testing environment

#### **Phase 1: Foundation (Week 1)**
- [ ] **Firebase setup**
  - [ ] Deploy permissive testing Firestore rules
  - [ ] Deploy Cloud Functions for contact matching
  - [ ] Test Firebase connection and functions
  
- [ ] **Core services**
  - [ ] Implement ContactPermissionService
  - [ ] Implement PhoneNumberService with libphonenumber
  - [ ] Create contact data models
  - [ ] Test phone number normalization

#### **Phase 2: Core Features (Week 1-2)**
- [ ] **Contact syncing**
  - [ ] Implement ContactSyncService
  - [ ] Add contact processing and hashing
  - [ ] Test contact sync flow end-to-end
  - [ ] Add caching for performance
  
- [ ] **User search**
  - [ ] Implement UserSearchService with optimization
  - [ ] Add fuzzy matching algorithms
  - [ ] Implement multi-level caching
  - [ ] Test search performance

#### **Phase 3: UI Implementation (Week 2)**
- [ ] **Main contacts screen**
  - [ ] Create ContactsScreen following existing patterns
  - [ ] Implement state management integration
  - [ ] Add loading states and error handling
  - [ ] Test UI responsiveness
  
- [ ] **Search components**
  - [ ] Create AdvancedSearchBar with auto-complete
  - [ ] Create ContactListItem with highlighting
  - [ ] Create ContactSyncButton
  - [ ] Test all UI components

#### **Phase 4: Navigation Integration (Week 2)**
- [ ] **Add contacts tab**
  - [ ] Update main navigation to include contacts tab
  - [ ] Ensure consistent styling with existing tabs
  - [ ] Test navigation flow
  - [ ] Verify state persistence

#### **Phase 5: Testing & Optimization (Week 3)**
- [ ] **Comprehensive testing**
  - [ ] Unit tests for all services (>80% coverage)
  - [ ] Widget tests for all components
  - [ ] Integration tests for complete flows
  - [ ] Performance testing with large datasets
  
- [ ] **Performance optimization**
  - [ ] Implement performance monitoring
  - [ ] Optimize search response times
  - [ ] Add performance alerts
  - [ ] Test with 1000+ contacts

#### **Phase 6: Production Readiness (Week 3)**
- [ ] **Error handling**
  - [ ] Handle all error scenarios gracefully
  - [ ] Add user-friendly error messages
  - [ ] Test offline behavior
  - [ ] Test edge cases (large contact lists, special characters)
  
- [ ] **Final polish**
  - [ ] Add loading animations following app patterns
  - [ ] Implement accessibility features
  - [ ] Add analytics tracking
  - [ ] Complete documentation

### **PERFORMANCE TARGETS**

#### **Response Time Goals**
- **Memory Cache Hits**: < 50ms ⚡
- **Storage Cache Hits**: < 100ms 🔥  
- **Firestore Queries**: < 200ms ☁️
- **Cloud Function Calls**: < 1000ms 🌐
- **Complete Search Flow**: < 1500ms 🎯

#### **User Experience Metrics**
- **Search Result Relevance**: > 80% accuracy
- **Cache Hit Rate**: > 70% for common queries
- **Contact Sync Success Rate**: > 95%
- **Search Abandonment Rate**: < 20%

#### **Technical Metrics**
- **Error Rate**: < 2% for all operations
- **Memory Usage**: < 50MB additional for contact features
- **Battery Impact**: Minimal (background sync only)
- **Network Usage**: Optimized with caching

### **CRITICAL SUCCESS FACTORS**

#### **1. Code Safety & Integration**
- **Never break existing functionality** - Test thoroughly after each change
- **Follow existing patterns exactly** - Study how other features are implemented
- **Use existing components first** - Check widgets folder before creating new ones
- **Test incrementally** - Verify each phase before proceeding

#### **2. UI Consistency & User Experience**
- **Match existing navigation patterns** - Study notifications tab implementation
- **Use existing color schemes and fonts** - Maintain visual consistency
- **Follow existing loading state patterns** - Use same loading indicators
- **Maintain existing component behavior** - Don't change interaction patterns

#### **3. Performance & Scalability**
- **Implement caching from day 1** - Don't add it as an afterthought
- **Optimize for mobile constraints** - Consider battery and data usage
- **Handle large contact lists efficiently** - Test with 1000+ contacts
- **Provide immediate user feedback** - Show loading states for all operations

#### **4. Privacy & Security**
- **Hash phone numbers for privacy** - Never store raw contact data on server
- **Handle permissions properly** - Clear explanations and graceful degradation
- **Secure data transmission** - Use HTTPS and encrypted connections
- **GDPR compliance** - Allow users to delete their data

### **TROUBLESHOOTING & SUPPORT**

#### **Common Issues & Solutions**

**Firebase Connection Issues:**
```bash
# Check Firebase configuration
flutter packages get
flutter clean
flutter run

# Verify Firebase project setup
firebase projects:list
firebase use your-project-id
```

**Performance Issues:**
```dart
// Enable performance debugging
import 'dart:developer' as developer;

void debugPerformance(String operation, Function() code) {
  final stopwatch = Stopwatch()..start();
  code();
  stopwatch.stop();
  developer.log('$operation took ${stopwatch.elapsedMilliseconds}ms');
}
```

**Contact Permission Issues:**
```dart
// Debug permission status
void debugPermissions() async {
  final status = await Permission.contacts.status;
  print('Contact permission status: $status');
  
  if (status.isPermanentlyDenied) {
    print('User must enable in system settings');
  }
}
```

#### **Debug and Development Tips**

**Enable Debug Logging:**
```dart
// Add to main.dart for development
void enableDebugLogging() {
  if (kDebugMode) {
    print('Debug logging enabled for contacts feature');
    
    // Enable Firebase logging
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
```

**Performance Profiling:**
```dart
// Add performance profiling in debug mode
class DebugProfiler {
  static void profileAsyncOperation(String name, Future Function() operation) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      await operation();
      stopwatch.stop();
      print('[$name] took ${stopwatch.elapsedMilliseconds}ms');
    } else {
      await operation();
    }
  }
}
```

## 🎉 **EXPECTED FINAL OUTCOME**

Upon successful implementation, you will have:

✅ **Telegram-like Contact Syncing**
- Permission-based contact access
- Privacy-protected server-side matching  
- Real-time sync with cached results

✅ **Advanced User Search**
- Fast, fuzzy search by name, email, phone
- Auto-complete suggestions
- Smart result ranking and relevance

✅ **Optimized Performance**
- Multi-level caching system
- Sub-200ms search response times
- Efficient handling of large contact lists

✅ **Seamless Integration**
- New contacts tab following existing patterns
- Consistent UI/UX with current app
- No impact on existing functionality

✅ **Production-Ready Quality**
- Comprehensive error handling
- Full test coverage
- Performance monitoring
- Privacy compliance

**Timeline: 2-3 weeks for complete implementation with optimization and testing**

**Result: A professional-grade contact syncing and user search feature that performs as well as industry leaders like Telegram while perfectly matching your existing app's design and functionality!**