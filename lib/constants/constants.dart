import 'package:flutter/material.dart';
import 'package:shopple/data/data_model.dart';
import 'package:shopple/screens/dashboard/dashboard.dart';
import 'package:shopple/screens/dashboard/projects.dart';
import 'package:shopple/screens/dashboard/search_screen.dart';
import 'package:shopple/screens/dashboard/ai_assistant_screen.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/chat/online_user.dart';

String tabSpace = "\t\t\t";

final List<Widget> dashBoardScreens = [
  Dashboard(), // 0 Dashboard
  ShoppingListsScreen(), // 1 Shopping Lists
  SearchScreen(), // 2 Search
  Container(), // 3 Placeholder (was AI)
  Container(), // 4 Placeholder
  const AIAssistantScreen(), // 5 Intelligence (matches nav index)
];

List<Color> progressCardGradientList = [
  //primary green
  AppColors.primaryGreen,
  //accent green
  AppColors.accentGreen,
  //light green
  HexColor.fromHex("87EFB5"),
];

final onlineUsers = List.generate(
  AppData.onlineUsers.length,
  (index) => OnlineUser(
    userId: AppData.onlineUsers[index]['id'] ?? '',
    userName: AppData.onlineUsers[index]['name'],
  ),
);
