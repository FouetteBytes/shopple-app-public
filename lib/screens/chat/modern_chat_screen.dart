import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/widgets/chat/badged_title.dart';
import 'package:shopple/widgets/chat/selection_tab.dart';
import 'package:shopple/widgets/chat/modern_search_bar.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/screens/chat/new_chat_screen.dart';
import 'package:shopple/screens/chat/chat_conversation_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shopple/widgets/chat/chat_channel_tile.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({super.key});

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh channels when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatManagementController.instance.refreshChannels();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh channels when app becomes active
    if (state == AppLifecycleState.resumed) {
      ChatManagementController.instance.refreshChannels();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                    hintText: 'Search conversations...',
                    onChanged: (query) {
                      // Implement search functionality if needed
                    },
                  ),
                ),

                // Chat List with Groups and Direct Messages
                Expanded(child: _buildStructuredChatList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const NewChatScreen()),
        backgroundColor: AppColors.primaryAccentColor,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Messages',
            style: GoogleFonts.lato(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          Row(
            children: [
              // Connection Status Indicator
              Obx(() {
                final chatSession = ChatSessionController.instance;
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatSession.isConnected
                        ? AppColors.primaryGreen
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                );
              }),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showChatOptions(),
                icon: Icon(Icons.more_vert, color: AppColors.primaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredChatList() {
    return Obx(() {
      final chatManagement = ChatManagementController.instance;
      final chatSession = ChatSessionController.instance;

      if (chatSession.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!chatSession.isConnected) {
        return _buildConnectionErrorState();
      }

      if (chatManagement.channels.isEmpty) {
        return _buildEmptyState();
      }

      // Filter out uninitialized channels and separate into groups and direct messages
      final initializedChannels = chatManagement.channels.where((channel) {
        try {
          // Check if channel is properly initialized by accessing memberCount safely
          final _ = channel.memberCount;
          return true;
        } catch (e) {
          // Channel not initialized yet, skip it
          return false;
        }
      }).toList();

      final groupChannels = initializedChannels
          .where((channel) => (channel.memberCount ?? 0) > 2)
          .toList();
      final directMessageChannels = initializedChannels
          .where((channel) => (channel.memberCount ?? 0) == 2)
          .toList();

      return CustomScrollView(
        slivers: [
          // Groups Section
          if (groupChannels.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SelectionTab(
                  title: "GROUPS",
                  page: const NewChatScreen(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MemoizedGroupChannelWidget(
                    key: ValueKey(groupChannels[index].cid),
                    channel: groupChannels[index],
                    onTap: () => _openConversation(groupChannels[index]),
                  ),
                ),
                childCount: groupChannels.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],

          // Direct Messages Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SelectionTab(
                title: "DIRECT MESSAGES",
                page: const NewChatScreen(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Direct message channels list
          if (directMessageChannels.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: _MemoizedChatChannelTile(
                    key: ValueKey(directMessageChannels[index].cid),
                    channel: directMessageChannels[index],
                    onTap: () =>
                        _openConversation(directMessageChannels[index]),
                  ),
                ),
                childCount: directMessageChannels.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildNoDirectMessagesWidget(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildConnectionErrorState() {
    final chatSession = ChatSessionController.instance;
    final errorMessage = chatSession.errorMessage;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            errorMessage != null ? Icons.error_outline : Icons.wifi_off,
            size: 64,
            color: errorMessage != null ? Colors.red : AppColors.inactive,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Connecting to chat...',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: errorMessage != null ? Colors.red : AppColors.inactive,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              chatSession.connectUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorMessage != null
                  ? Colors.red
                  : AppColors.primaryAccentColor,
            ),
            child: Text(errorMessage != null ? 'Retry Connection' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.inactive),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your friends',
            style: GoogleFonts.lato(fontSize: 14, color: AppColors.inactive),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const NewChatScreen()),
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDirectMessagesWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.message_outlined, size: 48, color: AppColors.inactive),
            const SizedBox(height: 12),
            Text(
              'No direct messages yet',
              style: GoogleFonts.lato(fontSize: 14, color: AppColors.inactive),
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(Channel channel) {
    Get.to(() => ChatConversationScreen(channel: channel))?.then((_) {
      // Ensure unread badges are updated upon return
      ChatManagementController.instance.refreshChannels();
    });
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.group_add, color: AppColors.primaryText),
                title: Text(
                  'New Group',
                  style: GoogleFonts.lato(color: AppColors.primaryText),
                ),
                onTap: () {
                  Get.back();
                  // TODO: Navigate to create group screen
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: AppColors.primaryText),
                title: Text(
                  'Chat Settings',
                  style: GoogleFonts.lato(color: AppColors.primaryText),
                ),
                onTap: () {
                  Get.back();
                  // TODO: Navigate to chat settings
                },
              ),
              Obx(() {
                final chatSession = ChatSessionController.instance;
                return ListTile(
                  leading: Icon(
                    chatSession.isConnected ? Icons.wifi_off : Icons.wifi,
                    color: AppColors.primaryText,
                  ),
                  title: Text(
                    chatSession.isConnected ? 'Disconnect' : 'Reconnect',
                    style: GoogleFonts.lato(color: AppColors.primaryText),
                  ),
                  onTap: () {
                    Get.back();
                    if (chatSession.isConnected) {
                      chatSession.disconnectUser();
                    } else {
                      chatSession.connectUser();
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Memoized widgets for better performance
class _MemoizedGroupChannelWidget extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _MemoizedGroupChannelWidget({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get channel display name and member count safely
    String channelName;
    int memberCount;

    try {
      channelName = channel.name ?? 'Group Chat';
      memberCount = channel.memberCount ?? 0;
    } catch (e) {
      // Fallback if channel not properly initialized
      channelName = 'Group Chat';
      memberCount = 0;
    }

    // Generate a color based on channel name hash for consistency
    const availableColors = [
      '87EFB5', // Light green
      'FCA3FF', // Pink/Purple
      'A5EB9B', // Green
      'FFB74D', // Orange
      '64B5F6', // Blue
      'F48FB1', // Pink
    ];
    final colorIndex = channelName.hashCode.abs() % availableColors.length;
    final channelColor = availableColors[colorIndex];

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BadgedTitle(
            title: channelName,
            color: channelColor,
            number: memberCount.toString(),
          ),
          AppSpaces.verticalSpace20,
          Transform.scale(
            alignment: Alignment.centerLeft,
            scale: 0.8,
            child: buildStackedImages(numberOfMembers: memberCount.toString()),
          ),
          AppSpaces.verticalSpace20,
        ],
      ),
    );
  }
}

class _MemoizedChatChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _MemoizedChatChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChatChannelTile(channel: channel, onTap: onTap);
  }
}
