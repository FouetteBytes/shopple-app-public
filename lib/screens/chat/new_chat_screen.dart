import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/widgets/chat/chat_user_tile.dart';
import 'package:shopple/widgets/chat/modern_search_bar.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/screens/chat/chat_conversation_screen.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ModernSearchBar(
                    controller: _searchController,
                    hintText: 'Search friends...',
                    onChanged: (query) {
                      ChatManagementController.instance.searchUsers(query);
                    },
                  ),
                ),

                // Tab Bar
                _buildTabBar(),

                // Content
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          ),
          const SizedBox(width: 8),
          Text(
            'New Chat',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Friends',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'All Users',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inactive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      final chatManagement = ChatManagementController.instance;

      if (chatManagement.isSearching) {
        return const Center(child: CircularProgressIndicator());
      }

      // Show friends for chat
      return FutureBuilder(
        future: chatManagement.searchFriendsForChat(_searchController.text),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data ?? [];

          // Prefetch profiles for visible results
          if (friends.isNotEmpty) {
            // ignore: discarded_futures
            UserProfileStreamService.instance.prefetchUsers(
              friends.map((u) => u.userId),
            );
          }

          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.inactive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No friends yet'
                        : 'No friends found',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Add friends to start chatting'
                        : 'Try searching with a different term',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ChatUserTile(
                user: friend,
                onTap: () => _startChatWithFriend(friend.userId),
                trailing: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryAccentColor,
                ),
              );
            },
          );
        },
      );
    });
  }

  Future<void> _startChatWithFriend(String friendUserId) async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final channel = await ChatManagementController.instance
          .getOrCreateDirectChannel(friendUserId);

      // Hide loading
      Get.back();

      if (channel != null) {
        // Navigate to conversation
        Get.off(() => ChatConversationScreen(channel: channel));
      } else {
        Get.snackbar(
          'Error',
          'Failed to start chat',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Hide loading
      Get.back();

      Get.snackbar(
        'Error',
        'Failed to start chat: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }
}
