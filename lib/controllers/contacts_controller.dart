import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact_models.dart';
import '../services/user/contact_permission_service.dart';
import '../services/user/contact_sync_service.dart';
import '../services/user/user_search_service.dart';
import '../config/feature_flags.dart';
import 'package:shopple/utils/app_logger.dart';

class ContactsController extends GetxController {
  static ContactsController get instance => Get.find();

  // Reactive observables for contacts
  final RxList<AppContact> _matchedContacts = <AppContact>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSyncing = false.obs;
  final RxBool _hasPermission = false.obs;
  final RxString _syncStatus = 'not_started'.obs;
  final RxInt _totalContactsProcessed = 0.obs;
  final RxInt _totalMatches = 0.obs;
  final RxString _lastSyncTime = ''.obs;

  // Reactive observables for search
  final RxList<UserSearchResult> _searchResults = <UserSearchResult>[].obs;
  final RxBool _isSearching = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _hasSearchResults = false.obs;
  final RxBool _userOptedIn = false.obs; // privacy opt-in

  // Search debouncing
  Timer? _searchDebounceTimer;

  // Getters
  List<AppContact> get matchedContacts => _matchedContacts;
  bool get isLoading => _isLoading.value;
  bool get isSyncing => _isSyncing.value;
  bool get hasPermission => _hasPermission.value;
  String get syncStatus => _syncStatus.value;
  int get totalContactsProcessed => _totalContactsProcessed.value;
  int get totalMatches => _totalMatches.value;
  String get lastSyncTime => _lastSyncTime.value;

  // Search getters
  List<UserSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching.value;
  String get searchQuery => _searchQuery.value;
  bool get hasSearchResults => _hasSearchResults.value;
  bool get userOptedIn => _userOptedIn.value;

  static const _prefsKeyOptIn = 'contacts_user_opted_in_v1';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  /// Load persisted state + lightweight permission / cache init.
  Future<void> _bootstrap() async {
    _isLoading.value = true;
    try {
      // Load persisted opt-in state
      final prefs = await SharedPreferences.getInstance();
      _userOptedIn.value = prefs.getBool(_prefsKeyOptIn) ?? false;

      await checkPermissionStatus();

      // If permission already granted from earlier session, implicitly treat as opt-in
      if (_hasPermission.value && !_userOptedIn.value) {
        _userOptedIn.value = true;
        await prefs.setBool(_prefsKeyOptIn, true);
      }

      if (_hasPermission.value) {
        await loadCachedContacts();
      }
    } catch (e) {
      AppLogger.w('ContactsController: Error bootstrapping contacts: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Trigger a deferred sync (call after login or when user opens contacts feature)
  Future<void> triggerDeferredSyncIfNeeded() async {
    if (!FeatureFlags.requireContactSyncOptIn) {
      _userOptedIn.value = true; // auto-enable if flag disabled
    }
    if (!_hasPermission.value || !_userOptedIn.value) return;
    bool should = await ContactSyncService.shouldSync();
    if (should) {
      await syncContacts(showUserFeedback: false);
    }
  }

  void setUserOptIn(bool value) {
    _userOptedIn.value = value;
    if (value) {
      // Attempt deferred sync once opted in
      triggerDeferredSyncIfNeeded();
    }
    // Persist opt-in selection
    SharedPreferences.getInstance().then(
      (p) => p.setBool(_prefsKeyOptIn, value),
    );
  }

  /// Check contact permission status
  Future<void> checkPermissionStatus() async {
    try {
      bool hasPermission =
          await ContactPermissionService.hasContactPermission();
      _hasPermission.value = hasPermission;
    } catch (e) {
      AppLogger.w('ContactsController: Error checking permission: $e');
      _hasPermission.value = false;
    }
  }

  /// Request contact permission
  Future<bool> requestPermission() async {
    try {
      _isLoading.value = true;
      bool granted = await ContactPermissionService.requestContactPermission();
      _hasPermission.value = granted;

      if (granted) {
        Fluttertoast.showToast(
          msg: "Contact permission granted! Syncing contacts...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // Auto opt-in on first permission grant
        setUserOptIn(true);

        // Auto-sync after permission granted
        await syncContacts();
      } else {
        Fluttertoast.showToast(
          msg: "Contact permission is required to find friends",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }

      return granted;
    } catch (e) {
      AppLogger.w('ContactsController: Error requesting permission: $e');
      Fluttertoast.showToast(
        msg: "Error requesting permission: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load cached contact results
  Future<void> loadCachedContacts() async {
    try {
      ContactSyncResult? cached = await ContactSyncService.getCachedResults();
      if (cached != null) {
        _updateContactResults(cached);
      }
    } catch (e) {
      AppLogger.w('ContactsController: Error loading cached contacts: $e');
    }
  }

  /// Sync contacts with server
  Future<void> syncContacts({bool showUserFeedback = true}) async {
    if (!_hasPermission.value) {
      await requestPermission();
      return;
    }

    try {
      _isSyncing.value = true;
      _syncStatus.value = 'in_progress';

      ContactSyncResult result = await ContactSyncService.syncContacts();
      _updateContactResults(result);

      if (showUserFeedback) {
        if (result.status == 'completed') {
          Fluttertoast.showToast(
            msg: "Found ${result.totalMatches} friends using Shopple!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: "Contact sync failed: ${result.errorMessage}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      AppLogger.w('ContactsController: Error syncing contacts: $e');
      _syncStatus.value = 'failed';
      if (showUserFeedback) {
        Fluttertoast.showToast(
          msg: "Sync failed: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      _isSyncing.value = false;
    }
  }

  /// 🚀 INSTANT SEARCH - Ultra-fast Google-like search with real-time results
  Future<void> searchUsers(String query) async {
    _searchQuery.value = query;

    // Cancel any pending search requests for instant responsiveness
    UserSearchService.cancelPendingSearches();

    // Cancel previous timer
    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }

    // Clear results if query is empty
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _hasSearchResults.value = false;
      _isSearching.value = false;
      return;
    }

    // Start searching indicator immediately for UI responsiveness
    _isSearching.value = true;

    // GOOGLE-LIKE INSTANT SEARCH: Zero debouncing for instant results
    int debounceMs;

    // Single character: INSTANT (Google-like behavior)
    if (query.length == 1) {
      debounceMs = 0; // ZERO delay for instant results
    }
    // Email-like queries: Almost instant
    else if (query.contains('@') ||
        query.toLowerCase().contains('gmail') ||
        query.toLowerCase().contains('yahoo') ||
        query.toLowerCase().contains('duck')) {
      debounceMs = 5; // Almost instant for emails
    }
    // Phone-like queries: Almost instant
    else if (RegExp(r'^[+]?[\d\s\-\(\)]+$').hasMatch(query) ||
        RegExp(r'^(\+1|1|\+|0|\(\d)').hasMatch(query)) {
      debounceMs = 5; // Almost instant for phone numbers
    }
    // Two characters: Very fast
    else if (query.length == 2) {
      debounceMs = 10; // Very fast for 2 chars
    }
    // Three or more characters: Fast
    else {
      debounceMs = 20; // Fast for longer queries
    }

    // Set debounce timer with instant search capability
    if (debounceMs == 0) {
      // INSTANT: No debouncing for single characters
      await _performInstantSearch(query);
    } else {
      // ULTRA-FAST: Minimal debouncing for other queries
      _searchDebounceTimer = Timer(
        Duration(milliseconds: debounceMs),
        () async {
          await _performInstantSearch(query);
        },
      );
    }
  }

  /// Perform instant search with streaming results
  Future<void> _performInstantSearch(String query) async {
    try {
      // Use the new instant search method with streaming results
      List<UserSearchResult> results = await UserSearchService.instantSearch(
        query,
        limit: 25, // More results for better UX
        onStreamResults: (streamResults) {
          // Update UI immediately as results stream in
          if (_searchQuery.value == query) {
            // Ensure still relevant
            _searchResults.assignAll(streamResults);
            _hasSearchResults.value = streamResults.isNotEmpty;
            _isSearching.value = false;
          }
        },
      );

      // Final update
      if (_searchQuery.value == query) {
        _searchResults.assignAll(results);
        _hasSearchResults.value = results.isNotEmpty;
      }
    } catch (e) {
      AppLogger.w('ContactsController: Instant search error: $e');
      _searchResults.clear();
      _hasSearchResults.value = false;
    } finally {
      _isSearching.value = false;
    }
  }

  /// Clear search results and cancel pending requests
  void clearSearch() {
    // Cancel any pending search requests
    UserSearchService.cancelPendingSearches();

    _searchQuery.value = '';
    _searchResults.clear();
    _hasSearchResults.value = false;
    _isSearching.value = false;

    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }
  }

  /// Clear all caches
  Future<void> clearCaches() async {
    try {
      _isLoading.value = true;

      // Clear contact sync cache
      await ContactSyncService.clearCache();

      // Clear search cache
      await UserSearchService.clearCache();

      // Reset local data
      _matchedContacts.clear();
      _searchResults.clear();
      _totalContactsProcessed.value = 0;
      _totalMatches.value = 0;
      _lastSyncTime.value = '';
      _syncStatus.value = 'not_started';
      _hasSearchResults.value = false;

      Fluttertoast.showToast(
        msg: "Cache cleared successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    } catch (e) {
      AppLogger.w('ContactsController: Error clearing caches: $e');
      Fluttertoast.showToast(
        msg: "Error clearing cache: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update contact results from sync
  void _updateContactResults(ContactSyncResult result) {
    _matchedContacts.assignAll(result.matchedContacts);
    _totalContactsProcessed.value = result.totalContactsProcessed;
    _totalMatches.value = result.totalMatches;
    _syncStatus.value = result.status;
    _lastSyncTime.value = result.syncTime.toString();
  }

  /// Get contact by ID
  AppContact? getContactById(String id) {
    try {
      return _matchedContacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get search result by UID
  UserSearchResult? getSearchResultByUid(String uid) {
    try {
      return _searchResults.firstWhere((result) => result.uid == uid);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is in contacts
  bool isUserInContacts(String uid) {
    return _matchedContacts.any((contact) => contact.id == uid);
  }

  /// Get contacts count
  int get contactsCount => _matchedContacts.length;

  /// Get search results count
  int get searchResultsCount => _searchResults.length;

  @override
  void onClose() {
    // Cancel any pending search requests
    UserSearchService.cancelPendingSearches();

    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }
    super.onClose();
  }
}
