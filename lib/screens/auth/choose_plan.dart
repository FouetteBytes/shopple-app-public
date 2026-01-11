// Replace: lib/Screens/auth/choose_plan.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shopple/screens/dashboard/timeline.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_progress_button.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/default_back.dart';
import 'package:shopple/widgets/onboarding/plan_card.dart';
import 'package:shopple/widgets/onboarding/toggle_option.dart';
import 'package:shopple/services/user/user_tracking_service.dart';
import 'package:shopple/services/user/user_state_service.dart';

class ChoosePlan extends StatelessWidget {
  const ChoosePlan({super.key});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> multiUserTrigger = ValueNotifier(false);
    ValueNotifier<bool> customLabelTrigger = ValueNotifier(false);
    ValueNotifier<int> planContainerTrigger = ValueNotifier(0);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          DarkRadialBackground(
            color: HexColor.fromHex("#181a1f"),
            position: "topLeft",
          ),
          Column(
            children: [
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: DefaultNav(title: "New WorkSpace"),
              ),
              AppSpaces.verticalSpace20,
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecorationStyles.fadingGlory,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: DecoratedBox(
                      decoration: BoxDecorationStyles.fadingInnerDecor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          // ADDED: Prevent overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpaces.verticalSpace10,
                              Text('Choose Plan', style: AppTextStyles.header2),
                              AppSpaces.verticalSpace10,
                              Text(
                                'Unlock all features with Premium Plan',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: HexColor.fromHex("666A7A"),
                                ),
                              ),
                              AppSpaces.verticalSpace20,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  PlanCard(
                                    notifierValue: planContainerTrigger,
                                    selectedIndex: 0,
                                    header: "It's Free",
                                    subHeader: "For team\nfrom 1 - 5",
                                  ),
                                  AppSpaces.horizontalSpace20,
                                  PlanCard(
                                    notifierValue: planContainerTrigger,
                                    selectedIndex: 1,
                                    header: "Premium",
                                    subHeader: "\$19/mo",
                                  ),
                                ],
                              ),
                              AppSpaces.verticalSpace20,
                              Text(
                                'Enable Features',
                                style: AppTextStyles.header2,
                              ),
                              AppSpaces.verticalSpace10,

                              // FIXED: Safe text layout
                              SizedBox(
                                width:
                                    screenWidth * 0.9, // Safe width constraint
                                child: Text(
                                  'You can customize the features in your workspace now. Or you can do it later in Menu - Workspace',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: HexColor.fromHex("666A7A"),
                                  ),
                                  softWrap: true, // Allow text wrapping
                                ),
                              ),

                              AppSpaces.verticalSpace20,
                              ToggleLabelOption(
                                label: '    Multiple Assignees',
                                notifierValue: multiUserTrigger,
                                icon: Icons.groups,
                              ),
                              ToggleLabelOption(
                                label: '    Custom Labels',
                                notifierValue: customLabelTrigger,
                                icon: Icons.category,
                              ),
                              AppSpaces
                                  .verticalSpace40, // Extra space at bottom
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            child: Container(
              padding: EdgeInsets.only(left: 40, right: 20),
              width: screenWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Back',
                    style: GoogleFonts.lato(
                      color: HexColor.fromHex("616575"),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PrimaryProgressButton(
                    width: 120,
                    label: "Done",
                    callback: () async {
                      // Save subscription choice with selected features
                      String selectedPlan = planContainerTrigger.value == 0
                          ? 'free'
                          : 'premium';
                      await UserTrackingService.saveSubscriptionChoice(
                        planType: selectedPlan,
                        multipleAssignees: multiUserTrigger.value,
                        customLabels: customLabelTrigger.value,
                      );

                      // Mark shopping list setup as completed
                      await UserStateService.markShoppingListCompleted();

                      // Navigate to main app (all setup now complete)
                      Get.offAll(() => Timeline());
                    },
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
