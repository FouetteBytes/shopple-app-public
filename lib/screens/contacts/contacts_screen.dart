import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shopple/utils/app_logger.dart';

import '../../values/values.dart';
import '../../controllers/contacts_controller.dart';
import '../../models/contact_models.dart';
import '../../widgets/forms/search_box.dart';
import '../../widgets/buttons/primary_tab_buttons.dart';
import '../../widgets/shapes/app_settings_icon.dart';
import '../../widgets/contacts/contact_card.dart';
import '../../widgets/contacts/contact_permission_card.dart';
import '../../widgets/contacts/contact_sync_status_card.dart';
import '../../config/feature_flags.dart';
import '../../widgets/contacts/search_result_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsController _contactsController = Get.put(ContactsController());
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<int> _tabNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Listen to search changes
    _searchController.addListener(() {
      _contactsController.searchUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              AppSpaces.verticalSpace20,
              _buildSearchBox(),
              AppSpaces.verticalSpace20,
              _buildTabButtons(),
              AppSpaces.verticalSpace20,
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            "Contacts",
            style: GoogleFonts.lato(
              color: AppColors.primaryText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppSettingsIcon(
          callback: () {
            _showContactsSettings();
          },
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: SearchBox(
        placeholder: 'Search people by name, phone, or email',
        controller: _searchController,
        onChanged: (query) {
          // Search is handled by the controller listener
        },
      ),
    );
  }

  Widget _buildTabButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            PrimaryTabButton(
              buttonText: "Contacts",
              itemIndex: 0,
              notifier: _tabNotifier,
            ),
            PrimaryTabButton(
              buttonText: "Search",
              itemIndex: 1,
              notifier: _tabNotifier,
            ),
          ],
        ),
        Obx(
          () => _contactsController.isSyncing
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryAccentColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Syncing...",
                        style: GoogleFonts.lato(
                          color: AppColors.primaryAccentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ValueListenableBuilder<int>(
      valueListenable: _tabNotifier,
      builder: (context, tabIndex, child) {
        if (tabIndex == 0) {
          return _buildContactsTab();
        } else {
          return _buildSearchTab();
        }
      },
    );
  }

  Widget _buildContactsTab() {
    return Obx(() {
      // 1. Permission gate
      if (!_contactsController.hasPermission) {
        return ContactPermissionCard(
          onRequestPermission: () async {
            await _contactsController.requestPermission();
          },
        );
      }

      // 2. Privacy opt-in gate (only if feature flag enabled and user not opted in)
      if (FeatureFlags.requireContactSyncOptIn &&
          !_contactsController.userOptedIn) {
        return _buildOptInCard();
      }

      // Show loading state
      if (_contactsController.isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccentColor,
                ),
              ),
              AppSpaces.verticalSpace20,
              Text(
                "Loading contacts...",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      // Show sync status and contacts
      return Column(
        children: [
          ContactSyncStatusCard(
            status: _contactsController.syncStatus,
            totalContacts: _contactsController.totalContactsProcessed,
            totalMatches: _contactsController.totalMatches,
            lastSyncTime: _contactsController.lastSyncTime,
            onRefresh: () async {
              await _contactsController.syncContacts();
            },
          ),
          AppSpaces.verticalSpace20,
          Expanded(child: _buildContactsList()),
        ],
      );
    });
  }

  Widget _buildOptInCard() {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.userShield,
                  color: AppColors.primaryAccentColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Find friends securely',
                    style: GoogleFonts.lato(
                      color: AppColors.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            AppSpaces.verticalSpace20,
            Text(
              'We privately hash your contacts\' phone numbers to find friends already on Shopple. Raw numbers never leave your device.',
              style: GoogleFonts.lato(
                color: AppColors.primaryText70,
                height: 1.4,
              ),
            ),
            AppSpaces.verticalSpace20,
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                _contactsController.setUserOptIn(true);
              },
              icon: Icon(FontAwesomeIcons.userCheck, size: 16),
              label: Text(
                'Enable secure contact sync',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _showMorePrivacyInfo();
              },
              child: Text(
                'How it works',
                style: GoogleFonts.lato(color: AppColors.primaryText70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMorePrivacyInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '1. We read only names & numbers locally.\n\n'
          '2. Numbers are normalized and multiple variations are created.\n\n'
          '3. Each variation is SHA-256 hashed. Only hashes are uploaded.\n\n'
          '4. Server compares hashes to find friends. Raw numbers are never stored.',
          style: GoogleFonts.lato(height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return Obx(() {
      if (_contactsController.matchedContacts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.userGroup,
                size: 48,
                color: AppColors.primaryText30,
              ),
              AppSpaces.verticalSpace20,
              Text(
                "No contacts found",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpaces.verticalSpace10,
              Text(
                "None of your contacts are using Shopple yet.\nInvite them to join!",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: AppColors.primaryText30,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: _contactsController.matchedContacts.length,
        itemBuilder: (context, index) {
          AppContact contact = _contactsController.matchedContacts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ContactCard(
              contact: contact,
              onTap: () {
                _showContactDetails(contact);
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildSearchTab() {
    return Obx(() {
      // Show search instruction if no query
      if (_contactsController.searchQuery.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.magnifyingGlass,
                size: 48,
                color: AppColors.primaryText30,
              ),
              AppSpaces.verticalSpace20,
              Text(
                "Search for people",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpaces.verticalSpace10,
              Text(
                "Search by name, phone number, or email\nto find people using Shopple",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: AppColors.primaryText30,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      // Show loading state
      if (_contactsController.isSearching) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccentColor,
                ),
              ),
              AppSpaces.verticalSpace20,
              Text(
                "Searching...",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      // Show search results
      if (!_contactsController.hasSearchResults) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.userXmark,
                size: 48,
                color: AppColors.primaryText30,
              ),
              AppSpaces.verticalSpace20,
              Text(
                "No results found",
                style: GoogleFonts.lato(
                  color: AppColors.primaryText70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpaces.verticalSpace10,
              Text(
                "Try searching with a different name,\nphone number, or email",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: AppColors.primaryText30,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: _contactsController.searchResults.length,
        itemBuilder: (context, index) {
          UserSearchResult result = _contactsController.searchResults[index];
          bool isContact = _contactsController.isUserInContacts(result.uid);

          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SearchResultCard(
              result: result,
              isContact: isContact,
              onTap: () {
                _showUserDetails(result);
              },
            ),
          );
        },
      );
    });
  }

  void _showContactDetails(AppContact contact) {
    // TODO: Navigate to contact details screen
    AppLogger.d('Show contact details for: ${contact.name}');
  }

  void _showUserDetails(UserSearchResult result) {
    // TODO: Navigate to user profile screen
    AppLogger.d('Show user details for: ${result.name}');
  }

  void _showContactsSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Contact Settings",
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpaces.verticalSpace20,
            ListTile(
              leading: Icon(
                FontAwesomeIcons.arrowsRotate,
                color: AppColors.primaryAccentColor,
              ),
              title: Text(
                "Sync Contacts",
                style: GoogleFonts.lato(color: AppColors.primaryText),
              ),
              subtitle: Text(
                "Refresh contact list",
                style: GoogleFonts.lato(color: AppColors.primaryText70),
              ),
              onTap: () {
                Navigator.pop(context);
                _contactsController.syncContacts();
              },
            ),
            ListTile(
              leading: Icon(FontAwesomeIcons.trash, color: Colors.orange),
              title: Text(
                "Clear Cache",
                style: GoogleFonts.lato(color: AppColors.primaryText),
              ),
              subtitle: Text(
                "Clear stored contact data",
                style: GoogleFonts.lato(color: AppColors.primaryText70),
              ),
              onTap: () {
                Navigator.pop(context);
                _contactsController.clearCaches();
              },
            ),
          ],
        ),
      ),
    );
  }
}
