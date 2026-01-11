import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shopple/bottom_sheets/bottom_sheets.dart';
import 'package:shopple/constants/constants.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/dashboard/bottom_navigation_item.dart';
import 'package:shopple/widgets/dashboard/dashboard_add_icon.dart';
import 'package:shopple/widgets/dashboard/dashboard_add_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:shopple/config/runtime_toggles.dart';
import 'package:shopple/widgets/dashboard/liquid_nav_bar.dart';

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  ValueNotifier<int> bottomNavigatorTrigger = ValueNotifier(0);

  // Dashboard is now a StatefulWidget; we access it through dashBoardScreens list.

  @override
  void initState() {
    super.initState();
  }

  final PageStorageBucket bucket = PageStorageBucket();
  int _secretTapCount = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true,
      body: Stack(
        children: [
          DarkRadialBackground(
            color: AppColors.background,
            position: "topLeft",
          ),
          if (kDebugMode)
            Positioned(
              top: 0,
              left: 0,
              width: 120,
              height: 80,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _secretTapCount++;
                  if (_secretTapCount >= 7) {
                    _secretTapCount = 0;
                    _showDebugPanel();
                  }
                },
              ),
            ),
          ValueListenableBuilder(
            valueListenable: bottomNavigatorTrigger,
            builder: (BuildContext context, _, _) {
              return PageStorage(
                bucket: bucket,
                child: dashBoardScreens[bottomNavigatorTrigger.value],
              );
            },
          ),
          // Custom Floating Nav Bar positioned at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 100, // Increased height to accommodate safe area
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  LiquidNavBar(
                    height: 80, // Taller glass bar
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left group (2 icons)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              BottomNavigationItem(
                                itemIndex: 0,
                                notifier: bottomNavigatorTrigger,
                                icon: Icons.widgets, // Dashboard
                              ),
                              BottomNavigationItem(
                                itemIndex: 1,
                                notifier: bottomNavigatorTrigger,
                                icon: FeatherIcons.clipboard, // Projects
                              ),
                            ],
                          ),
                        ),
                        // Center spacer for button
                        const SizedBox(width: 60),
                        // Right group (2 icons)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              BottomNavigationItem(
                                itemIndex: 2,
                                notifier: bottomNavigatorTrigger,
                                icon: FeatherIcons.search, // Search
                              ),
                              BottomNavigationItem(
                                itemIndex: 5, // AI Intelligence
                                notifier: bottomNavigatorTrigger,
                                icon: Icons.auto_awesome, 
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Center button (kept at original position relative to glass)
                  Positioned(
                    bottom: 35, // Adjusted for new height
                    child: DashboardAddButton(
                      iconTapped: (() {
                        // Show the multi-action add sheet
                        showAppBottomSheet(
                          const DashboardAddBottomSheet(),
                          isScrollControlled: true,
                        );
                      }),
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

  void _showDebugPanel() {
    final toggles = RuntimeToggles.instance;
    showAppBottomSheet(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleRow(
              'Performance Overlay',
              toggles.showPerformanceOverlay,
            ),
            _buildToggleRow('Frame Timings Log', toggles.logFrameTimings),
            _buildToggleRow(
              'Disable Precache',
              toggles.disableOnboardingPrecache,
            ),
            const SizedBox(height: 8),
            const Text(
              '7 taps top-left to reopen. Debug only.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      title: 'Debug Tools',
    );
  }

  Widget _buildToggleRow(String label, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Switch(
          value: value,
          onChanged: (_) {
            if (notifier == RuntimeToggles.instance.showPerformanceOverlay) {
              RuntimeToggles.instance.togglePerfOverlay();
            } else if (notifier == RuntimeToggles.instance.logFrameTimings) {
              RuntimeToggles.instance.toggleFrameTimings();
            } else if (notifier ==
                RuntimeToggles.instance.disableOnboardingPrecache) {
              RuntimeToggles.instance.toggleDisablePrecache();
            }
            setState(() {});
          },
        ),
      ),
    );
  }
}
