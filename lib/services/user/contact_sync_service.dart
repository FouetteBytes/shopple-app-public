import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // For compute isolate offload
import '../../utils/app_logger.dart';

import '../../models/contact_models.dart';
import 'contact_permission_service.dart';
import './../auth/phone_number_service.dart';

/// 🔥 Contact Sync Service v2.0
///
/// Enhanced with custom phone number validation and more robust error handling.
/// This service handles the entire process of syncing device contacts with the app's backend,
/// finding which contacts are already users, and caching the results securely.
///
/// Key Features:
/// - ✅ Uses custom `PhoneNumberService` for professional phone number processing.
/// - ✅ Daily sync interval with manual override.
/// - ✅ Securely caches results for 24 hours to reduce network usage.
/// - ✅ Handles permissions, fetching, processing, and server communication.
/// - ✅ Detailed status and error reporting via `ContactSyncResult`.
class ContactSyncService {
  static const String cacheKey = 'contact_sync_cache_v2'; // Cache key updated
  static const String lastSyncKey = 'last_contact_sync_v2';
  static const Duration syncInterval = Duration(hours: 24); // Daily sync

  /// Main contact sync function - call on app launch or manual sync
  static Future<ContactSyncResult> syncContacts() async {
    try {
      AppLogger.d('[ContactSync] Starting contact sync');

      // 1. Check permissions
      if (!await ContactPermissionService.hasContactPermission()) {
        throw Exception('Contact permission not granted');
      }

      // 2. Get contacts from device
      List<AppContact> contacts = await ContactPermissionService.getContacts();
      AppLogger.d(
        '[ContactSync] Found ${contacts.length} contacts with phone numbers',
      );

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
      AppLogger.d(
        '[ContactSync] Processed ${hashedContacts.length} contact hashes',
      );

      // 4. Upload to Firestore for server-side matching
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _uploadContactHashes(userId, hashedContacts);
      AppLogger.d('[ContactSync] Uploaded contact hashes to Firestore');

      // 5. Wait for Cloud Function processing
      ContactSyncResult result = await _waitForSyncCompletion(userId);
      AppLogger.d('[ContactSync] Completed: ${result.totalMatches} matches');

      // 6. Cache results locally
      await _cacheResults(result);
      await _updateLastSyncTime();

      return result;
    } catch (e, st) {
      AppLogger.e('[ContactSync] Error during sync', error: e, stackTrace: st);
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

  /// Get cached contact sync results
  static Future<ContactSyncResult?> getCachedResults() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cached = prefs.getString(cacheKey);

      if (cached != null) {
        Map<String, dynamic> json = jsonDecode(cached);
        ContactSyncResult result = ContactSyncResult.fromJson(json);

        // Check if cache is still valid (24 hours)
        Duration diff = DateTime.now().difference(result.syncTime);
        if (diff < syncInterval) {
          return result;
        }
      }
    } catch (e, st) {
      AppLogger.e(
        '[ContactSync] Error getting cached results',
        error: e,
        stackTrace: st,
      );
    }

    return null;
  }

  /// Check if sync is needed based on last sync time
  static Future<bool> shouldSync() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? lastSync = prefs.getInt(lastSyncKey);

      if (lastSync == null) return true;

      DateTime lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      Duration diff = DateTime.now().difference(lastSyncTime);

      return diff > syncInterval;
    } catch (e, st) {
      AppLogger.e(
        '[ContactSync] Error checking sync time',
        error: e,
        stackTrace: st,
      );
      return true;
    }
  }

  /// Force clear cache and sync
  static Future<void> clearCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastSyncKey);
    } catch (e, st) {
      AppLogger.e(
        '[ContactSync] Error clearing cache',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Process contacts and generate privacy-protected hashes.
  /// Large lists are offloaded to a background isolate to avoid jank.
  static const int isolateThreshold = 80; // Tunable: when to offload
  static Future<List<String>> _processContacts(
    List<AppContact> contacts,
  ) async {
    // Fast path: nothing to do
    if (contacts.isEmpty) return [];

    // Decide whether to offload based on size
    final phoneNumbers = contacts
        .map((c) => c.phoneNumber)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();

    if (phoneNumbers.length >= isolateThreshold) {
      // Offload heavy hashing work
      try {
        return await compute(_hashContactsIsolate, phoneNumbers);
      } catch (e, st) {
        // Fallback to in-isolate processing if compute fails (e.g., platform constraints)
        AppLogger.w(
          '[ContactSync] Isolate hashing failed, falling back to main isolate',
        );
        AppLogger.e(
          '[ContactSync] Isolate error detail',
          error: e,
          stackTrace: st,
        );
      }
    }

    // Small list or fallback: process inline
    return await _hashContactsInline(phoneNumbers);
  }

  /// Inline hashing logic (shared with isolate path)
  static Future<List<String>> _hashContactsInline(
    List<String> phoneNumbers,
  ) async {
    final List<String> hashedContacts = [];
    for (final raw in phoneNumbers) {
      try {
        final normalized = await PhoneNumberService.normalizeToE164(raw);
        if (normalized == null) continue;
        final variations = PhoneNumberService.generateVariations(normalized);
        for (final v in variations) {
          hashedContacts.add(PhoneNumberService.hashPhoneNumber(v));
        }
      } catch (e) {
        // PII-safe error logging
        AppLogger.w('[ContactSync] Hashing error for one contact');
      }
    }
    return hashedContacts.toSet().toList();
  }

  /// Background isolate entry for hashing phone numbers.
  /// Must be a top-level, synchronous function (compute requirement).
  static List<String> _hashContactsIsolate(List<String> phoneNumbers) {
    final List<String> hashedContacts = [];
    for (final raw in phoneNumbers) {
      try {
        final normalized = _normalizeForIsolate(raw);
        if (normalized == null) continue;
        final variations = PhoneNumberService.generateVariations(normalized);
        for (final v in variations) {
          hashedContacts.add(PhoneNumberService.hashPhoneNumber(v));
        }
      } catch (_) {
        // Ignore individual failures
      }
    }
    return hashedContacts.toSet().toList();
  }

  /// Minimal synchronous normalization logic (mirrors PhoneNumberService.normalizeToE164)
  static String? _normalizeForIsolate(String rawNumber) {
    if (rawNumber.isEmpty) return null;
    try {
      String cleaned = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleaned.startsWith('+')) {
        cleaned = '+1$cleaned'; // Default to US country code
      }
      final digits = cleaned.substring(1);
      if (digits.length < 7 || digits.length > 15) return null;
      return cleaned;
    } catch (_) {
      return null;
    }
  }

  /// Upload contact hashes to Firestore for server-side matching
  static Future<void> _uploadContactHashes(
    String userId,
    List<String> hashedContacts,
  ) async {
    await FirebaseFirestore.instance
        .collection('contact_syncs')
        .doc(userId)
        .set({
          'hashedContacts': hashedContacts,
          'totalContacts': hashedContacts.length,
          'uploadTime': FieldValue.serverTimestamp(),
          'status': 'uploaded',
        });
  }

  /// Wait for Cloud Function to process contacts and return results
  static Future<ContactSyncResult> _waitForSyncCompletion(String userId) async {
    // Wait for Cloud Function processing (max 30 seconds)
    for (int i = 0; i < 30; i++) {
      await Future.delayed(Duration(seconds: 1));

      try {
        // Check sync status
        DocumentSnapshot syncDoc = await FirebaseFirestore.instance
            .collection('contact_syncs')
            .doc(userId)
            .get();

        if (syncDoc.exists) {
          Map<String, dynamic> data = syncDoc.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'uploaded';

          if (status == 'completed') {
            // Get matched contacts
            DocumentSnapshot contactsDoc = await FirebaseFirestore.instance
                .collection('user_contacts')
                .doc(userId)
                .get();

            if (contactsDoc.exists) {
              Map<String, dynamic> contactsData =
                  contactsDoc.data() as Map<String, dynamic>;
              List<dynamic> matches = contactsData['matches'] ?? [];

              List<AppContact> matchedContacts = matches.map((match) {
                return AppContact(
                  id: match['uid'],
                  name: match['name'] ?? '',
                  phoneNumber: match['phoneNumber'],
                  email: match['email'],
                  profilePicture: match['profilePicture'],
                  hasAppAccount: true,
                );
              }).toList();

              return ContactSyncResult(
                matchedContacts: matchedContacts,
                totalContactsProcessed: contactsData['totalProcessed'] ?? 0,
                totalMatches: contactsData['totalMatches'] ?? 0,
                syncTime: DateTime.now(),
                status: 'completed',
              );
            }
          } else if (status == 'failed') {
            throw Exception('Contact sync failed on server: ${data['error']}');
          }
        }
      } catch (e, st) {
        AppLogger.e(
          '[ContactSync] Error checking sync status',
          error: e,
          stackTrace: st,
        );
      }
    }

    throw Exception('Contact sync timeout');
  }

  /// Cache results locally for offline access
  static Future<void> _cacheResults(ContactSyncResult result) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String json = jsonEncode(result.toJson());
      await prefs.setString(cacheKey, json);
    } catch (e, st) {
      AppLogger.e(
        '[ContactSync] Error caching results',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Update last sync time
  static Future<void> _updateLastSyncTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e, st) {
      AppLogger.e(
        '[ContactSync] Error updating sync time',
        error: e,
        stackTrace: st,
      );
    }
  }
}
