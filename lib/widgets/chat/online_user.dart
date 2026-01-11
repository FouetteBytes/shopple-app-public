import 'package:flutter/material.dart';
import '../../values/values.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/screens/chat/messaging_screen.dart';

import 'online_user_profile.dart';

class OnlineUser extends StatelessWidget {
  final String userId;
  final String userName;
  final bool showPresence;
  const OnlineUser({
    super.key,
    required this.userId,
    required this.userName,
    this.showPresence = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: InkWell(
        onTap: () {
          Get.to(() => MessagingScreen(userId: userId, userName: userName));
        },
        child: Row(
          children: [
            OnlineUserProfile(userId: userId, showPresence: showPresence),
            AppSpaces.horizontalSpace20,
            Text(
              userName,
              style: GoogleFonts.lato(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
