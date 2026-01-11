import 'package:flutter/material.dart';
import 'package:shopple/data/data_model.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/default_back.dart';
import 'package:shopple/widgets/notification/notification_card.dart';
import 'package:shopple/widgets/dummy/profile_dummy.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic notificationData = AppData.notificationMentions;

    final notificationCards = List<Widget>.generate(
      notificationData.length,
      (index) => NotificationCard(
        read: notificationData[index]['read'],
        userName: notificationData[index]['mentionedBy'],
        date: notificationData[index]['date'],
        image: notificationData[index]['profileImage'],
        mentioned: notificationData[index]['hashTagPresent'],
        message: notificationData[index]['message'],
        mention: notificationData[index]['mentionedIn'],
        imageBackground: notificationData[index]['color'],
        userOnline: notificationData[index]['userOnline'],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: AppColors.background,
            position: "topLeft",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SafeArea(
              child: Column(
                children: [
                  DefaultNav(
                    title: "Shopping Alerts",
                    type: ProfileDummyType.image,
                  ),
                  AppSpaces.verticalSpace20,
                  Expanded(child: ListView(children: notificationCards)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
