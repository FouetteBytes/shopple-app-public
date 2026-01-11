// Replace: lib/Screens/auth/new_workspace.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopple/values/values.dart';
import 'package:shopple/widgets/buttons/primary_progress_button.dart';
import 'package:shopple/widgets/dark_background/dark_radial_background.dart';
import 'package:shopple/widgets/navigation/default_back.dart';
import 'package:shopple/widgets/onboarding/gradient_color_ball.dart';
import 'package:shopple/widgets/container_label.dart';
import 'package:shopple/widgets/dummy/profile_dummy.dart';
import 'package:shopple/services/user/user_tracking_service.dart';
import 'package:shopple/services/user/user_state_service.dart';

import 'choose_plan.dart';

class NewWorkSpace extends StatefulWidget {
  const NewWorkSpace({super.key});

  @override
  State<NewWorkSpace> createState() => _NewWorkSpaceState();
}

class _NewWorkSpaceState extends State<NewWorkSpace> {
  final TextEditingController _householdSizeController = TextEditingController(
    text: '3',
  );
  final TextEditingController _familyEmailController = TextEditingController();
  final ValueNotifier<int> colorTrigger = ValueNotifier(5);

  @override
  void dispose() {
    _householdSizeController.dispose();
    _familyEmailController.dispose();
    colorTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: DefaultNav(title: "New Shopping List"),
              ),
              AppSpaces.verticalSpace20,
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecorationStyles.fadingGlory,
                  child: Padding(
                    padding: EdgeInsets.all(3.0),
                    child: DecoratedBox(
                      decoration: BoxDecorationStyles.fadingInnerDecor,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ProfileDummy(
                                color: HexColor.fromHex("9F69F9"),
                                dummyType: ProfileDummyType.image,
                                scale: 2.5,
                                image: "assets/plant.png",
                              ),
                              AppSpaces.verticalSpace10,
                              Text(
                                'My Shopping List',
                                style: GoogleFonts.lato(
                                  fontSize: 30,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              AppSpaces.verticalSpace10,
                              Text(
                                'Tap the logo to upload a new image.',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: HexColor.fromHex("666A7A"),
                                ),
                              ),
                              SizedBox(height: 50),
                              ContainerLabel(
                                label: 'HOW MANY PEOPLE IN YOUR HOUSEHOLD',
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _householdSizeController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.lato(
                                          color: AppColors.primaryText,
                                          fontSize: 20,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '2 - 5',
                                          hintStyle: GoogleFonts.lato(
                                            color: AppColors.primaryText
                                                .withValues(alpha: 0.5),
                                            fontSize: 20,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Icon(
                                        Icons.share,
                                        color: AppColors.primaryText,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpaces.verticalSpace20,
                              ContainerLabel(
                                label: 'INVITE FAMILY TO YOUR SHOPPING LIST',
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _familyEmailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: GoogleFonts.lato(
                                          color: Colors.blue,
                                          fontSize: 17,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Email Address',
                                          hintStyle: GoogleFonts.lato(
                                            color: Colors.blue.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 17,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.add,
                                      color: AppColors.primaryText,
                                      size: 30,
                                    ),
                                  ],
                                ),
                              ),
                              AppSpaces.verticalSpace20,
                              ContainerLabel(label: 'CHOOSE COLOR THEME'),

                              // BULLETPROOF COLOR SECTION
                              Container(
                                width: screenWidth - 40, // Safe width
                                padding: EdgeInsets.only(top: 15.0),
                                child: Column(
                                  children: [
                                    // Row 1
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (AppColors.ballColors.isNotEmpty)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 0,
                                            gradientList: [
                                              ...AppColors.ballColors[0],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 1)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 1,
                                            gradientList: [
                                              ...AppColors.ballColors[1],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 2)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 2,
                                            gradientList: [
                                              ...AppColors.ballColors[2],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 3)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 3,
                                            gradientList: [
                                              ...AppColors.ballColors[3],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 4)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 4,
                                            gradientList: [
                                              ...AppColors.ballColors[4],
                                            ],
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    // Row 2
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (AppColors.ballColors.length > 5)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 5,
                                            gradientList: [
                                              ...AppColors.ballColors[5],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 6)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 6,
                                            gradientList: [
                                              ...AppColors.ballColors[6],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 7)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 7,
                                            gradientList: [
                                              ...AppColors.ballColors[7],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 8)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 8,
                                            gradientList: [
                                              ...AppColors.ballColors[8],
                                            ],
                                          ),
                                        if (AppColors.ballColors.length > 9)
                                          GradientColorBall(
                                            valueChanger: colorTrigger,
                                            selectIndex: 9,
                                            gradientList: [
                                              ...AppColors.ballColors[9],
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              AppSpaces.verticalSpace20,
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
                    'Skip',
                    style: GoogleFonts.lato(
                      color: HexColor.fromHex("616575"),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PrimaryProgressButton(
                    width: 120,
                    label: "Next",
                    callback: () async {
                      // Save workspace settings to Firebase
                      await UserTrackingService.saveWorkspaceSettings(
                        workspaceName: 'My Shopping List',
                        selectedColorIndex: colorTrigger.value,
                        workspaceImage: 'assets/plant.png',
                        householdSize: _householdSizeController.text.trim(),
                        familyEmail: _familyEmailController.text.trim(),
                      );

                      // Mark workspace setup as completed
                      await UserStateService.markWorkspaceCompleted();

                      // Navigate to plan selection
                      Get.to(() => ChoosePlan());
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
