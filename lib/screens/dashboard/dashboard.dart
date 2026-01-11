import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/screens/profile/my_profile.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/bottom_sheets/dashboard_settings_sheet.dart';
import 'package:shopple/widgets/buttons/primary_tab_buttons.dart';
import 'package:shopple/widgets/navigation/dasboard_header.dart';
import 'package:shopple/widgets/shapes/app_settings_icon.dart';
import 'package:shopple/widgets/dashboard/greeting_header.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';

import 'dashboardtabscreens/overview.dart';
import 'dashboardtabscreens/productivity.dart';

// ignore: must_be_immutable
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ValueNotifier<bool> _totalTaskTrigger = ValueNotifier(true);
  final ValueNotifier<bool> _totalDueTrigger = ValueNotifier(false);
  final ValueNotifier<bool> _totalCompletedTrigger = ValueNotifier(true);
  final ValueNotifier<bool> _workingOnTrigger = ValueNotifier(false);
  final ValueNotifier<int> _buttonTrigger = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Refresh chat data on load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChatData();
    });
  }

  /// Refreshes chat data for unread counts.
  void _refreshChatData() {
    try {
      // Refresh ChatManagementController.
      if (Get.isRegistered<ChatManagementController>()) {
        final chatManagement = Get.find<ChatManagementController>();
        chatManagement.refreshChannels();
      }
    } catch (e) {
      // Ignore if chat not initialized.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardNav(
                  image:
                      "", // Unused; ProfileAvatar handles data.
                  title: "Dashboard",
                  onImageTapped: () {
                    Get.to(() => ProfilePage());
                  },
                ),
                AppSpaces.verticalSpace20,
                const GreetingHeader(),
                AppSpaces.verticalSpace20,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tab indicators.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        PrimaryTabButton(
                          buttonText: "Shopping",
                          itemIndex: 0,
                          notifier: _buttonTrigger,
                        ),
                        PrimaryTabButton(
                          buttonText: "Budget",
                          itemIndex: 1,
                          notifier: _buttonTrigger,
                        ),
                      ],
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      child: AppSettingsIcon(
                        callback: () {
                          showAppBottomSheet(
                            DashboardSettingsBottomSheet(
                              totalTaskNotifier: _totalTaskTrigger,
                              totalDueNotifier: _totalDueTrigger,
                              workingOnNotifier: _workingOnTrigger,
                              totalCompletedNotifier: _totalCompletedTrigger,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                AppSpaces.verticalSpace20,
                ValueListenableBuilder<int>(
                  valueListenable: _buttonTrigger,
                  builder: (BuildContext context, int value, Widget? child) {
                    // Use conditional rendering instead of IndexedStack to avoid
                    // taking up the height of the tallest child (Budget tab),
                    // which causes empty scrollable space on the Overview tab.
                    return value == 0
                        ? const DashboardOverview()
                        : const DashboardBudget();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
