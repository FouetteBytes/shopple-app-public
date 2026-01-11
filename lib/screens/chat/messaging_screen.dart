import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/chat/post_bottom_widget.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/app_header.dart';
import 'package:shopple/widgets/unified_profile_avatar.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';

class MessagingScreen extends StatelessWidget {
  final String userId;
  final String userName;
  const MessagingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> sentImage = [
      "assets/slider-background-1.png",
      "assets/slider-background-2.png",
      "assets/slider-background-3.png",
    ];

    List<SentImage> imageCards = List.generate(
      sentImage.length,
      (index) => SentImage(image: sentImage[index]),
    );
    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ShoppleAppHeader(
                      title: userName,
                      messagingPage: true,
                      widget: Row(
                        children: [
                          Icon(Icons.phone, color: AppColors.primaryText),
                          AppSpaces.horizontalSpace20,
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                width: 3,
                                color: HexColor.fromHex("31333D"),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.more_vert,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          //Chat
          Positioned(
            top: 80,
            child: SizedBox(
              width: Utils.screenWidth,
              height: Utils.screenHeight * 2,
              child: ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MessengerDetails(userId: userId, userName: userName),
                      Padding(
                        padding: EdgeInsets.only(left: 70.0),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          width: 250,
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 15,
                            bottom: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBackgroundColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            "Hi man, how are you doing?",
                            style: GoogleFonts.lato(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  SenderMessage(message: "Doing well, thanks! 👋"),
                  AppSpaces.verticalSpace20,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MessengerDetails(userId: userId, userName: userName),
                      Padding(
                        padding: EdgeInsets.only(left: 70.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 250,
                              //height: 50,
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 15,
                                bottom: 15,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackgroundColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50),
                                  bottomRight: Radius.circular(50),
                                ),
                              ),
                              child: Text(
                                "Just one question 😂",
                                style: GoogleFonts.lato(
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            AppSpaces.verticalSpace10,
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 250,
                              //height: 50,
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 15,
                                bottom: 15,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackgroundColor,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(50),
                                  topRight: Radius.circular(50),
                                  bottomRight: Radius.circular(50),
                                ),
                              ),
                              child: Text(
                                "Can you please send me your latest mockup? ",
                                style: GoogleFonts.lato(
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            AppSpaces.verticalSpace10,
                            SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [...imageCards],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpaces.verticalSpace20,
                  SenderMessage(message: "Sure, wait for a minute."),
                  AppSpaces.verticalSpace20,
                  Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBackgroundColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            color: HexColor.fromHex("7F8088"),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PostBottomWidget(label: "Write a message"),
        ],
      ),
    );
  }
}

class SentImage extends StatelessWidget {
  final String image;
  const SentImage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image(
          width: 200,
          fit: BoxFit.fitWidth,
          image: AssetImage(image),
        ),
      ),
    );
  }
}

class SenderMessage extends StatelessWidget {
  final String message;
  const SenderMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: 200,
            padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccentColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              message,
              style: GoogleFonts.lato(color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class MessengerDetails extends StatelessWidget {
  const MessengerDetails({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20.0),
      child: Row(
        children: [
          UnifiedProfileAvatar(userId: userId, radius: 24, enableCache: true),
          AppSpaces.horizontalSpace10,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              StreamBuilder<UserPresenceStatus>(
                stream: PresenceService.getUserPresenceStream(userId),
                builder: (context, snapshot) {
                  final isOnline = snapshot.data?.isOnline ?? false;
                  return Text(
                    isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: isOnline
                          ? AppColors.primaryGreen
                          : AppColors.inactive,
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpaces.horizontalSpace10,
          const TimeReceipt(time: "12:11 PM"),
        ],
      ),
    );
  }
}

class TimeReceipt extends StatelessWidget {
  final String time;
  const TimeReceipt({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Text(time, style: GoogleFonts.lato(color: AppColors.primaryText));
  }
}
