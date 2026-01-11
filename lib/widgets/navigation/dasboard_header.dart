import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:get/get.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/screens/chat/modern_chat_screen.dart';
import 'package:shopple/screens/friends/friends_screen.dart';
import 'package:shopple/screens/requests/request_center_screen.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/screens/dashboard/notifications.dart';
import 'package:shopple/widgets/navigation/slidable_icon_button.dart';
import 'package:shopple/services/chat/chat_dependency_injector.dart';

class DashboardNav extends StatelessWidget {
  final String title;
  final String image;
  final IconData?
  icon; // Optional; modern chat icon used by default
  final Widget? page;
  final VoidCallback? onImageTapped;
  final String? notificationCount; // Make optional
  final double? iconSize; // Add optional icon size parameter

  const DashboardNav({
    super.key,
    required this.title,
    this.icon, // Remove required
    required this.image,
    this.notificationCount, // Remove required
    this.page,
    this.onImageTapped,
    this.iconSize,
  }); // Add iconSize to constructor

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for dynamic sizing
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.header2),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Slidable Icon Button (Friends, Request Center, Notifications)
            SlidableIconButton(
              size: screenWidth * 0.13,
              items: [
                SlidableIconItem(
                  icon: Icons.people_outline,
                  page: const FriendsScreen(),
                ),
                SlidableIconItem(
                  icon: Icons.receipt_long_outlined,
                  page: const RequestCenterScreen(),
                ),
                SlidableIconItem(
                  icon: Icons.notifications_outlined,
                  page: const NotificationScreen(),
                ),
              ],
            ),
            SizedBox(width: screenWidth * 0.04),

            // Chat Icon with unread messages indicator (kept separate)
            Obx(() {
              // Check if chat services are ready to avoid "Controller not found" errors
              bool isReady = ChatDependencyInjector.isChatReady.value;

              // Default values for when chat is not ready
              int unreadCount = 0;
              bool isConnected = false;

              // Only access controllers if chat is ready
              if (isReady) {
                try {
                  final chatSession = ChatSessionController.instance;
                  final chatManagement = ChatManagementController.instance;
                  unreadCount = chatManagement.totalUnreadCount;
                  isConnected = chatSession.isConnected;
                } catch (e) {
                  // Fallback if something goes wrong even if ready flag is true
                  isReady = false;
                }
              }

              return InkWell(
                onTap: () {
                  if (isReady) {
                    Get.to(() => const ModernChatScreen());
                  } else {
                    // Show feedback to user
                    Get.snackbar(
                      "Chat Initializing",
                      "Please wait while we connect to chat services...",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                    
                    // Attempt to re-initialize if stuck
                    ChatDependencyInjector.initializeChat();
                  }
                },
                child: Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: isReady
                            ? AppColors.primaryText
                            : AppColors.primaryText.withValues(alpha: 0.5),
                        size: screenWidth * 0.06,
                      ),
                      // Online status indicator (small dot)
                      if (isConnected)
                        Positioned(
                          top: screenWidth * 0.025,
                          right: screenWidth * 0.025,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      // Unread messages badge
                      if (unreadCount > 0)
                        Positioned(
                          top: screenWidth * 0.015,
                          right: screenWidth * 0.015,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: HexColor.fromHex("FF6B6B"),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(width: screenWidth * 0.05), // Spacing before profile
            UnifiedProfileAvatar(
              radius: 24, // 48px diameter (40 * 1.2)
              showBorder: false,
              enableCache: true,
              onTap: onImageTapped,
            ),
          ],
        ),
      ],
    );
  }
}
