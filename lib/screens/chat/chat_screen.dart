import 'package:flutter/material.dart';
import 'package:shopple/constants/constants.dart';
import 'package:shopple/screens/chat/new_group.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/chat/add_chat_icon.dart';
import 'package:shopple/widgets/chat/badged_title.dart';
import 'package:shopple/widgets/chat/selection_tab.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/forms/search_box.dart';
import 'package:shopple/widgets/navigation/app_header.dart';
import 'new_message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShoppleAppHeader(
                    title: "Chat",
                    widget: AppAddIcon(page: NewMessageScreen()),
                  ),
                  AppSpaces.verticalSpace20,
                  SearchBox(
                    placeholder: 'Search',
                    controller: searchController,
                  ),
                  AppSpaces.verticalSpace20,
                  SelectionTab(title: "GROUP", page: NewGroupScreen()),
                  AppSpaces.verticalSpace20,
                  BadgedTitle(
                    title: "Marketing",
                    color: 'A5EB9B',
                    number: '12',
                  ),
                  AppSpaces.verticalSpace20,
                  Transform.scale(
                    alignment: Alignment.centerLeft,
                    scale: 0.8,
                    child: buildStackedImages(numberOfMembers: "8"),
                  ),
                  AppSpaces.verticalSpace20,
                  BadgedTitle(title: "Design", color: 'FCA3FF', number: '6'),
                  AppSpaces.verticalSpace20,
                  Transform.scale(
                    alignment: Alignment.centerLeft,
                    scale: 0.8,
                    child: buildStackedImages(numberOfMembers: "2"),
                  ),
                  AppSpaces.verticalSpace20,
                  SelectionTab(
                    title: "DIRECT MESSAGES",
                    page: NewMessageScreen(),
                  ),
                  AppSpaces.verticalSpace20,
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView(children: [...onlineUsers]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
